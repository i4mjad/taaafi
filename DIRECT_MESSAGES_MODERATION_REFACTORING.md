# Direct Messages Moderation Refactoring Guide

This guide outlines how to refactor the direct messages moderation system to work like group messages: handling everything directly in the `direct_messages` document without a separate `moderation_queue` collection.

---

## 📋 Overview

### Current System (To Be Removed)
- Uses separate `moderation_queue` collection
- Messages stored in `direct_messages` collection
- Admin reviews items from `moderation_queue`
- Complex synchronization between two collections

### New System (Target)
- Everything in `direct_messages` collection
- Moderation status stored directly in message document
- No separate queue collection
- Simpler, more maintainable architecture
- Matches group messages behavior

---

## 🗂️ Part 1: Firestore Data Structure Changes

### Direct Message Document Structure

**Collection**: `direct_messages` (top-level collection)

```typescript
interface DirectMessage {
  // Core message fields
  id: string;                    // Auto-generated document ID
  conversationId: string;        // Reference to conversation
  senderCpId: string;            // Sender's community profile ID
  body: string;                  // Message content
  type: 'text' | 'image' | 'file'; // Message type
  mediaUrl?: string;             // If type is image/file
  replyToMessageId?: string;     // If replying to another message
  
  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  
  // Moderation fields (NEW - inline, not nested initially)
  moderation: {
    status: 'pending' | 'approved' | 'blocked' | 'manual_review';
    reason?: string;              // Reason for blocking/rejection
    moderatedBy?: string;         // Admin UID who took action
    moderatedAt?: Timestamp;      // When action was taken
    
    // AI Analysis (from Cloud Function)
    ai?: {
      reason: string;
      violationType?: 'spam' | 'harassment' | 'hate_speech' | 'explicit_content' | 
                      'violence' | 'self_harm' | 'misinformation' | 'other';
      severity?: 'low' | 'medium' | 'high';
      confidence?: number;        // 0-100
      detectedContent?: string[]; // What was detected
      culturalContext?: string | null;
    };
    
    // Final Decision (from Cloud Function)
    finalDecision?: {
      action: 'approve' | 'block' | 'manual_review';
      reason: string;
      violationType?: string | null;
      confidence: number;
    };
    
    // Custom Rules Results (from Cloud Function)
    customRules?: Array<{
      ruleName: string;
      matched: boolean;
      action?: string;
      reason?: string;
    }>;
  };
  
  // Visibility flags
  isHidden: boolean;             // Hidden from users (blocked messages)
  isDeleted: boolean;            // Soft deleted
  deletedAt?: Timestamp;
  deletedBy?: string;            // Admin UID
  
  // Read receipts (optional)
  readBy?: {
    [cpId: string]: Timestamp;   // When each participant read the message
  };
}
```

---

## ⚡ Part 2: Cloud Function Changes

### File: `functions/src/moderateDirectMessage.ts`

Replace the entire function with this new implementation:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

interface ModerationResult {
  action: 'approve' | 'block' | 'manual_review';
  reason: string;
  violationType?: string | null;
  confidence: number;
  aiAnalysis?: any;
  customRulesResults?: any[];
}

/**
 * Moderate a direct message using AI and custom rules
 * Called when a new direct message is created
 */
export const moderateDirectMessage = functions.firestore
  .document('direct_messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageId = context.params.messageId;
    const messageData = snap.data();
    
    console.log(`[Moderation] Starting moderation for message: ${messageId}`);
    
    try {
      const messageBody = messageData.body || '';
      const senderCpId = messageData.senderCpId;
      
      // Skip moderation for empty messages
      if (!messageBody.trim()) {
        console.log('[Moderation] Empty message, auto-approving');
        await snap.ref.update({
          'moderation.status': 'approved',
          'moderation.finalDecision': {
            action: 'approve',
            reason: 'Empty message',
            confidence: 100,
          },
          isHidden: false,
        });
        return;
      }
      
      // Run moderation checks in parallel
      const [aiResult, customRulesResult, userHistory] = await Promise.all([
        runOpenAIModeration(messageBody),
        runCustomRules(messageBody, senderCpId),
        getUserModerationHistory(senderCpId),
      ]);
      
      // Determine final decision
      const finalDecision = determineFinalDecision(
        aiResult,
        customRulesResult,
        userHistory
      );
      
      // Update message document with moderation results
      await snap.ref.update({
        'moderation.status': finalDecision.action === 'approve' ? 'approved' : 
                            finalDecision.action === 'block' ? 'blocked' : 
                            'manual_review',
        'moderation.ai': aiResult,
        'moderation.customRules': customRulesResult,
        'moderation.finalDecision': finalDecision,
        isHidden: finalDecision.action === 'block', // Auto-hide blocked messages
      });
      
      console.log(`[Moderation] Message ${messageId} result: ${finalDecision.action}`);
      
      // If requires manual review, notify admins (optional)
      if (finalDecision.action === 'manual_review') {
        await notifyAdminsForReview(messageId, messageData, finalDecision);
      }
      
    } catch (error) {
      console.error('[Moderation] Error moderating message:', error);
      
      // On error, set to manual review to be safe
      await snap.ref.update({
        'moderation.status': 'manual_review',
        'moderation.finalDecision': {
          action: 'manual_review',
          reason: 'Error during automated moderation',
          confidence: 0,
        },
      });
    }
  });

/**
 * Run OpenAI moderation on message content
 */
async function runOpenAIModeration(messageBody: string): Promise<any> {
  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        {
          role: 'system',
          content: `You are a content moderator for a recovery and mental health support app. 
Analyze messages for:
- Harassment, hate speech, or bullying
- Explicit sexual content
- Violence or threats
- Spam or scams
- Self-harm or suicide references (flag for review, don't block)
- Misinformation about recovery/health

Be culturally sensitive, especially to Arabic language and Middle Eastern context.
Recovery discussions about past substance use are OK.
Emotional support and vulnerability are encouraged.

Return JSON with:
{
  "action": "approve" | "block" | "manual_review",
  "reason": "explanation",
  "violationType": "spam" | "harassment" | "hate_speech" | "explicit_content" | "violence" | "self_harm" | "misinformation" | null,
  "severity": "low" | "medium" | "high",
  "confidence": 0-100,
  "detectedContent": ["list of issues"],
  "culturalContext": "any relevant cultural considerations"
}`,
        },
        {
          role: 'user',
          content: messageBody,
        },
      ],
      temperature: 0.3,
      response_format: { type: 'json_object' },
    });

    const result = JSON.parse(completion.choices[0].message.content || '{}');
    
    return {
      reason: result.reason || 'No issues detected',
      violationType: result.violationType || null,
      severity: result.severity || 'low',
      confidence: result.confidence || 0,
      detectedContent: result.detectedContent || [],
      culturalContext: result.culturalContext || null,
    };
  } catch (error) {
    console.error('[OpenAI] Moderation error:', error);
    return {
      reason: 'Error during AI analysis',
      confidence: 0,
    };
  }
}

/**
 * Run custom rules on message content
 */
async function runCustomRules(messageBody: string, senderCpId: string): Promise<any[]> {
  const results = [];
  const lowerBody = messageBody.toLowerCase();
  
  // Rule 1: Check for banned keywords
  const bannedKeywords = ['example-spam-word', 'example-scam-word'];
  const foundBannedKeywords = bannedKeywords.filter(keyword => 
    lowerBody.includes(keyword)
  );
  
  if (foundBannedKeywords.length > 0) {
    results.push({
      ruleName: 'banned_keywords',
      matched: true,
      action: 'block',
      reason: `Contains banned keywords: ${foundBannedKeywords.join(', ')}`,
    });
  }
  
  // Rule 2: Check message length (spam detection)
  if (messageBody.length > 2000) {
    results.push({
      ruleName: 'message_too_long',
      matched: true,
      action: 'manual_review',
      reason: 'Message exceeds 2000 characters',
    });
  }
  
  // Rule 3: Check for excessive caps (spam indicator)
  const capsCount = (messageBody.match(/[A-Z]/g) || []).length;
  const capsRatio = capsCount / messageBody.length;
  
  if (messageBody.length > 20 && capsRatio > 0.7) {
    results.push({
      ruleName: 'excessive_caps',
      matched: true,
      action: 'manual_review',
      reason: 'Excessive use of capital letters',
    });
  }
  
  // Rule 4: Check for URLs (potential spam/phishing)
  const urlRegex = /(https?:\/\/[^\s]+)/g;
  const urls = messageBody.match(urlRegex);
  
  if (urls && urls.length > 2) {
    results.push({
      ruleName: 'multiple_urls',
      matched: true,
      action: 'manual_review',
      reason: `Contains ${urls.length} URLs`,
    });
  }
  
  // Rule 5: Check user's ban status
  try {
    const bansSnapshot = await admin.firestore()
      .collection('bans')
      .where('communityProfileId', '==', senderCpId)
      .where('isActive', '==', true)
      .where('expiresAt', '>', admin.firestore.Timestamp.now())
      .get();
    
    const dmBan = bansSnapshot.docs.find(doc => {
      const data = doc.data();
      return data.type === 'feature_ban' && 
             data.features?.includes('sending_in_groups'); // This covers DMs too
    });
    
    if (dmBan) {
      results.push({
        ruleName: 'user_banned',
        matched: true,
        action: 'block',
        reason: 'User is currently banned from messaging',
      });
    }
  } catch (error) {
    console.error('[CustomRules] Error checking ban status:', error);
  }
  
  return results;
}

/**
 * Get user's moderation history
 */
async function getUserModerationHistory(senderCpId: string): Promise<any> {
  try {
    const messagesSnapshot = await admin.firestore()
      .collection('direct_messages')
      .where('senderCpId', '==', senderCpId)
      .where('moderation.status', '==', 'blocked')
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get();
    
    const recentBlocked = messagesSnapshot.docs.length;
    
    // Get user's total message count
    const totalSnapshot = await admin.firestore()
      .collection('direct_messages')
      .where('senderCpId', '==', senderCpId)
      .count()
      .get();
    
    return {
      totalMessages: totalSnapshot.data().count,
      recentBlockedCount: recentBlocked,
      recentBlockedMessages: messagesSnapshot.docs.map(doc => ({
        id: doc.id,
        reason: doc.data().moderation?.reason,
        blockedAt: doc.data().moderation?.moderatedAt,
      })),
    };
  } catch (error) {
    console.error('[History] Error fetching user history:', error);
    return {
      totalMessages: 0,
      recentBlockedCount: 0,
      recentBlockedMessages: [],
    };
  }
}

/**
 * Determine final moderation decision
 */
function determineFinalDecision(
  aiResult: any,
  customRulesResults: any[],
  userHistory: any
): ModerationResult {
  // Check for blocking custom rules first
  const blockingRule = customRulesResults.find(rule => 
    rule.matched && rule.action === 'block'
  );
  
  if (blockingRule) {
    return {
      action: 'block',
      reason: blockingRule.reason,
      violationType: null,
      confidence: 100,
    };
  }
  
  // Check AI decision
  if (aiResult.action === 'block' && aiResult.confidence >= 80) {
    return {
      action: 'block',
      reason: aiResult.reason,
      violationType: aiResult.violationType,
      confidence: aiResult.confidence,
    };
  }
  
  // Check for manual review from AI or custom rules
  const manualReviewRule = customRulesResults.find(rule => 
    rule.matched && rule.action === 'manual_review'
  );
  
  if (aiResult.action === 'manual_review' || manualReviewRule) {
    return {
      action: 'manual_review',
      reason: manualReviewRule?.reason || aiResult.reason,
      violationType: aiResult.violationType,
      confidence: aiResult.confidence || 50,
    };
  }
  
  // Check user history - if user has many blocked messages, flag for review
  if (userHistory.recentBlockedCount >= 3 && userHistory.totalMessages < 20) {
    return {
      action: 'manual_review',
      reason: 'User has history of blocked messages',
      confidence: 70,
    };
  }
  
  // Default: approve
  return {
    action: 'approve',
    reason: aiResult.reason || 'No issues detected',
    violationType: null,
    confidence: aiResult.confidence || 90,
  };
}

/**
 * Notify admins when message requires manual review
 */
async function notifyAdminsForReview(
  messageId: string,
  messageData: any,
  decision: ModerationResult
): Promise<void> {
  try {
    // You can implement various notification methods:
    
    // 1. Create a notification document for admins
    await admin.firestore().collection('admin_notifications').add({
      type: 'dm_manual_review',
      messageId: messageId,
      senderCpId: messageData.senderCpId,
      conversationId: messageData.conversationId,
      reason: decision.reason,
      confidence: decision.confidence,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'unread',
    });
    
    // 2. Send email to admins (optional)
    // await sendEmailToAdmins({ messageId, reason: decision.reason });
    
    // 3. Send push notification to admin app (optional)
    // await sendPushToAdmins({ messageId, reason: decision.reason });
    
    console.log(`[Notification] Admin notified for message ${messageId}`);
  } catch (error) {
    console.error('[Notification] Error notifying admins:', error);
  }
}
```

### Deploy the Cloud Function

```bash
firebase deploy --only functions:moderateDirectMessage
```

---

## 📱 Part 3: Flutter App Changes

### File: `lib/models/direct_message.dart`

Update the DirectMessage model:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DirectMessage {
  final String id;
  final String conversationId;
  final String senderCpId;
  final String body;
  final String type; // 'text', 'image', 'file'
  final String? mediaUrl;
  final String? replyToMessageId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MessageModeration moderation;
  final bool isHidden;
  final bool isDeleted;
  final Map<String, DateTime>? readBy;

  DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderCpId,
    required this.body,
    this.type = 'text',
    this.mediaUrl,
    this.replyToMessageId,
    required this.createdAt,
    required this.updatedAt,
    required this.moderation,
    this.isHidden = false,
    this.isDeleted = false,
    this.readBy,
  });

  factory DirectMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DirectMessage(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderCpId: data['senderCpId'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'text',
      mediaUrl: data['mediaUrl'],
      replyToMessageId: data['replyToMessageId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      moderation: MessageModeration.fromMap(data['moderation'] ?? {}),
      isHidden: data['isHidden'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      readBy: _parseReadBy(data['readBy']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderCpId': senderCpId,
      'body': body,
      'type': type,
      'mediaUrl': mediaUrl,
      'replyToMessageId': replyToMessageId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'moderation': moderation.toMap(),
      'isHidden': isHidden,
      'isDeleted': isDeleted,
      'readBy': readBy?.map((key, value) => MapEntry(key, Timestamp.fromDate(value))),
    };
  }

  static Map<String, DateTime>? _parseReadBy(dynamic readByData) {
    if (readByData == null) return null;
    final map = readByData as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(
      key,
      (value as Timestamp).toDate(),
    ));
  }

  // Check if current user can see this message
  bool isVisibleToUser(String currentCpId) {
    // Sender can always see their own messages (even if hidden/blocked)
    if (senderCpId == currentCpId) {
      return !isDeleted; // Hide only if deleted
    }
    
    // Other users can't see hidden or deleted messages
    return !isHidden && !isDeleted;
  }

  // Check if message is approved and visible
  bool get isApproved => moderation.status == 'approved' && !isHidden && !isDeleted;
}

class MessageModeration {
  final String status; // 'pending', 'approved', 'blocked', 'manual_review'
  final String? reason;
  final String? moderatedBy;
  final DateTime? moderatedAt;
  final AIAnalysis? ai;
  final FinalDecision? finalDecision;
  final List<CustomRuleResult>? customRules;

  MessageModeration({
    this.status = 'pending',
    this.reason,
    this.moderatedBy,
    this.moderatedAt,
    this.ai,
    this.finalDecision,
    this.customRules,
  });

  factory MessageModeration.fromMap(Map<String, dynamic> data) {
    return MessageModeration(
      status: data['status'] ?? 'pending',
      reason: data['reason'],
      moderatedBy: data['moderatedBy'],
      moderatedAt: (data['moderatedAt'] as Timestamp?)?.toDate(),
      ai: data['ai'] != null ? AIAnalysis.fromMap(data['ai']) : null,
      finalDecision: data['finalDecision'] != null 
          ? FinalDecision.fromMap(data['finalDecision']) 
          : null,
      customRules: (data['customRules'] as List?)
          ?.map((rule) => CustomRuleResult.fromMap(rule))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'reason': reason,
      'moderatedBy': moderatedBy,
      'moderatedAt': moderatedAt != null ? Timestamp.fromDate(moderatedAt!) : null,
      'ai': ai?.toMap(),
      'finalDecision': finalDecision?.toMap(),
      'customRules': customRules?.map((rule) => rule.toMap()).toList(),
    };
  }
}

class AIAnalysis {
  final String reason;
  final String? violationType;
  final String? severity;
  final int? confidence;
  final List<String>? detectedContent;
  final String? culturalContext;

  AIAnalysis({
    required this.reason,
    this.violationType,
    this.severity,
    this.confidence,
    this.detectedContent,
    this.culturalContext,
  });

  factory AIAnalysis.fromMap(Map<String, dynamic> data) {
    return AIAnalysis(
      reason: data['reason'] ?? '',
      violationType: data['violationType'],
      severity: data['severity'],
      confidence: data['confidence'],
      detectedContent: (data['detectedContent'] as List?)?.cast<String>(),
      culturalContext: data['culturalContext'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reason': reason,
      'violationType': violationType,
      'severity': severity,
      'confidence': confidence,
      'detectedContent': detectedContent,
      'culturalContext': culturalContext,
    };
  }
}

class FinalDecision {
  final String action;
  final String reason;
  final String? violationType;
  final int confidence;

  FinalDecision({
    required this.action,
    required this.reason,
    this.violationType,
    required this.confidence,
  });

  factory FinalDecision.fromMap(Map<String, dynamic> data) {
    return FinalDecision(
      action: data['action'] ?? 'approve',
      reason: data['reason'] ?? '',
      violationType: data['violationType'],
      confidence: data['confidence'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'reason': reason,
      'violationType': violationType,
      'confidence': confidence,
    };
  }
}

class CustomRuleResult {
  final String ruleName;
  final bool matched;
  final String? action;
  final String? reason;

  CustomRuleResult({
    required this.ruleName,
    required this.matched,
    this.action,
    this.reason,
  });

  factory CustomRuleResult.fromMap(Map<String, dynamic> data) {
    return CustomRuleResult(
      ruleName: data['ruleName'] ?? '',
      matched: data['matched'] ?? false,
      action: data['action'],
      reason: data['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ruleName': ruleName,
      'matched': matched,
      'action': action,
      'reason': reason,
    };
  }
}
```

### File: `lib/services/direct_messaging_service.dart`

Update the messaging service:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/direct_message.dart';

class DirectMessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a new direct message
  /// Message will be automatically moderated by Cloud Function
  Future<String> sendMessage({
    required String conversationId,
    required String senderCpId,
    required String body,
    String type = 'text',
    String? mediaUrl,
    String? replyToMessageId,
  }) async {
    try {
      // Create message document
      final messageRef = _firestore.collection('direct_messages').doc();
      
      final message = DirectMessage(
        id: messageRef.id,
        conversationId: conversationId,
        senderCpId: senderCpId,
        body: body,
        type: type,
        mediaUrl: mediaUrl,
        replyToMessageId: replyToMessageId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        moderation: MessageModeration(status: 'pending'), // Will be updated by Cloud Function
        isHidden: false,
        isDeleted: false,
      );

      await messageRef.set(message.toFirestore());
      
      // Update conversation's lastMessage
      await _firestore.collection('direct_conversations').doc(conversationId).update({
        'lastMessage': {
          'body': body,
          'senderCpId': senderCpId,
          'createdAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return messageRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Stream messages for a conversation
  /// Filters out hidden/deleted messages for non-senders
  Stream<List<DirectMessage>> streamMessages({
    required String conversationId,
    required String currentCpId,
    int limit = 50,
  }) {
    return _firestore
        .collection('direct_messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DirectMessage.fromFirestore(doc))
          .where((message) => message.isVisibleToUser(currentCpId))
          .toList();
    });
  }

  /// Get a single message by ID
  Future<DirectMessage?> getMessage(String messageId) async {
    try {
      final doc = await _firestore.collection('direct_messages').doc(messageId).get();
      if (!doc.exists) return null;
      return DirectMessage.fromFirestore(doc);
    } catch (e) {
      print('Error getting message: $e');
      return null;
    }
  }

  /// Mark message as read
  Future<void> markAsRead({
    required String messageId,
    required String cpId,
  }) async {
    await _firestore.collection('direct_messages').doc(messageId).update({
      'readBy.$cpId': FieldValue.serverTimestamp(),
    });
  }

  /// Delete message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('direct_messages').doc(messageId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

### File: `lib/screens/chat/direct_message_widget.dart`

Update UI to show moderation status:

```dart
import 'package:flutter/material.dart';
import '../../models/direct_message.dart';

class DirectMessageWidget extends StatelessWidget {
  final DirectMessage message;
  final String currentCpId;
  final bool isOwnMessage;

  const DirectMessageWidget({
    Key? key,
    required this.message,
    required this.currentCpId,
    required this.isOwnMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOwnMessage ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message body
            Text(
              message.body,
              style: TextStyle(fontSize: 16),
            ),
            
            SizedBox(height: 4),
            
            // Timestamp and status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                
                // Show moderation status for sender
                if (isOwnMessage) ...[
                  SizedBox(width: 8),
                  _buildModerationStatusIndicator(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationStatusIndicator() {
    final status = message.moderation.status;
    
    switch (status) {
      case 'pending':
        return Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 4),
            Text('Checking...', style: TextStyle(fontSize: 10, color: Colors.orange)),
          ],
        );
      
      case 'approved':
        return Icon(Icons.check_circle, size: 16, color: Colors.green);
      
      case 'blocked':
        return Tooltip(
          message: message.moderation.reason ?? 'Message blocked',
          child: Row(
            children: [
              Icon(Icons.block, size: 16, color: Colors.red),
              SizedBox(width: 4),
              Text('Blocked', style: TextStyle(fontSize: 10, color: Colors.red)),
            ],
          ),
        );
      
      case 'manual_review':
        return Tooltip(
          message: message.moderation.reason ?? 'Under review',
          child: Row(
            children: [
              Icon(Icons.flag, size: 16, color: Colors.orange),
              SizedBox(width: 4),
              Text('Under review', style: TextStyle(fontSize: 10, color: Colors.orange)),
            ],
          ),
        );
      
      default:
        return SizedBox.shrink();
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
```

---

## 🔐 Part 4: Firestore Security Rules

Update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Direct messages
    match /direct_messages/{messageId} {
      // Allow read if user is a participant in the conversation
      allow read: if request.auth != null && 
                     isParticipantInConversation(resource.data.conversationId);
      
      // Allow create if user is authenticated and is the sender
      // Cloud Function will handle moderation
      allow create: if request.auth != null &&
                       request.resource.data.senderCpId == getUserCommunityProfileId() &&
                       request.resource.data.moderation.status == 'pending' &&
                       !isUserBannedFromMessaging();
      
      // Users can soft-delete their own messages
      allow update: if request.auth != null &&
                       resource.data.senderCpId == getUserCommunityProfileId() &&
                       request.resource.data.isDeleted == true &&
                       onlyUpdating(['isDeleted', 'deletedAt']);
      
      // Admins can update moderation status
      allow update: if request.auth != null && isAdmin();
      
      // No one can delete messages completely
      allow delete: if false;
    }
    
    // Direct conversations
    match /direct_conversations/{conversationId} {
      allow read: if request.auth != null && 
                     getUserCommunityProfileId() in resource.data.participantCpIds;
      
      allow create: if request.auth != null &&
                       getUserCommunityProfileId() in request.resource.data.participantCpIds &&
                       request.resource.data.participantCpIds.size() == 2 &&
                       !isUserBannedFromStartingConversations();
      
      allow update: if request.auth != null &&
                       getUserCommunityProfileId() in resource.data.participantCpIds &&
                       onlyUpdating(['lastMessage', 'updatedAt']);
    }
    
    // Helper functions
    function getUserCommunityProfileId() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.communityProfileId;
    }
    
    function isParticipantInConversation(conversationId) {
      return getUserCommunityProfileId() in 
             get(/databases/$(database)/documents/direct_conversations/$(conversationId)).data.participantCpIds;
    }
    
    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isUserBannedFromMessaging() {
      return exists(/databases/$(database)/documents/bans/$(getUserCommunityProfileId() + '_sending_in_groups')) ||
             exists(/databases/$(database)/documents/bans/$(getUserCommunityProfileId() + '_user_ban'));
    }
    
    function isUserBannedFromStartingConversations() {
      return exists(/databases/$(database)/documents/bans/$(getUserCommunityProfileId() + '_start_conversation')) ||
             exists(/databases/$(database)/documents/bans/$(getUserCommunityProfileId() + '_user_ban'));
    }
    
    function onlyUpdating(allowedFields) {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(allowedFields);
    }
  }
}
```

---

## 🔄 Part 5: Migration Steps

### Step 1: Update Cloud Function First

1. Update your Cloud Function code as shown in Part 2
2. Deploy: `firebase deploy --only functions:moderateDirectMessage`
3. Test with a new message to ensure it works

### Step 2: Update Flutter App

1. Update models as shown in Part 3
2. Update services to use new structure
3. Test sending and receiving messages

### Step 3: Migrate Existing Data (Optional)

If you have existing messages in `moderation_queue`, run this migration:

```typescript
// One-time migration script
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

async function migrateQueueToMessages() {
  console.log('Starting migration...');
  
  const queueSnapshot = await db.collection('moderation_queue').get();
  console.log(`Found ${queueSnapshot.size} items in moderation queue`);
  
  for (const queueDoc of queueSnapshot.docs) {
    const queueData = queueDoc.data();
    const messageId = queueData.messageId;
    
    try {
      // Get the message document
      const messageRef = db.collection('direct_messages').doc(messageId);
      const messageDoc = await messageRef.get();
      
      if (!messageDoc.exists) {
        console.log(`Message ${messageId} not found, skipping`);
        continue;
      }
      
      // Update message with moderation data from queue
      await messageRef.update({
        'moderation.status': queueData.status || 'pending',
        'moderation.ai': queueData.openaiAnalysis || null,
        'moderation.customRules': queueData.customRuleResults || null,
        'moderation.finalDecision': queueData.finalDecision || null,
        isHidden: queueData.status === 'blocked',
      });
      
      console.log(`Migrated message ${messageId}`);
    } catch (error) {
      console.error(`Error migrating message ${messageId}:`, error);
    }
  }
  
  console.log('Migration complete!');
}

// Run migration
migrateQueueToMessages();
```

### Step 4: Update Admin Panel (Already Done)

The admin panel is already updated to work with the new structure! ✅

### Step 5: Cleanup Old Collection (After Testing)

Once everything works:

```typescript
// Delete moderation_queue collection
// Only run after confirming everything works!

async function deleteQueueCollection() {
  const batch = db.batch();
  const snapshot = await db.collection('moderation_queue').limit(500).get();
  
  snapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  console.log('Deleted batch of queue documents');
  
  // Repeat until collection is empty
}
```

### Step 6: Update Firestore Rules

Deploy the new security rules:

```bash
firebase deploy --only firestore:rules
```

---

## ✅ Testing Checklist

After implementing all changes, test:

### Cloud Function Tests
- [ ] Send a clean message → Should auto-approve
- [ ] Send a message with banned keywords → Should auto-block
- [ ] Send a message with potential issues → Should flag for manual review
- [ ] Check that `moderation` object is populated correctly
- [ ] Verify `isHidden` is set correctly for blocked messages

### Flutter App Tests
- [ ] Send a message → See "Checking..." status
- [ ] Wait for Cloud Function → Status updates to approved/blocked/review
- [ ] Blocked message → Shows block indicator to sender, hidden from recipient
- [ ] Manual review message → Shows warning indicator to sender
- [ ] Approved message → Shows checkmark
- [ ] Try sending while banned → Should be rejected

### Admin Panel Tests
- [ ] View all messages in "All Messages" tab
- [ ] Filter by status (pending, approved, blocked)
- [ ] Approve a message → Updates in Firestore and Flutter
- [ ] Block a message → Gets hidden from users
- [ ] Bulk actions → Work correctly
- [ ] View message details → Shows AI analysis and custom rules

---

## 🎯 Summary of Benefits

### Before (With moderation_queue)
- ❌ Two collections to manage
- ❌ Complex synchronization
- ❌ Potential inconsistencies
- ❌ More Firestore reads/writes
- ❌ Harder to query/report

### After (Inline moderation)
- ✅ Single source of truth
- ✅ Simpler architecture
- ✅ Consistent with group messages
- ✅ Fewer database operations
- ✅ Easier to maintain and debug
- ✅ Better real-time updates

---

## 🚀 Deployment Order

1. **Deploy Cloud Function** → Test with new messages
2. **Update Flutter App** → Test message flow
3. **Run Migration** (if needed) → Migrate existing data
4. **Update Security Rules** → Deploy to production
5. **Monitor** → Check for any issues
6. **Cleanup** → Delete old moderation_queue collection

---

## 📞 Support

If you encounter any issues:

1. Check Cloud Function logs: `firebase functions:log`
2. Check Firestore for message documents
3. Verify security rules are deployed
4. Test in development environment first

Good luck with the refactoring! 🎉

