# Flutter Minimal Changes for Message Moderation

## 🎯 **Improved UX Approach**

**Key Principle**: Messages are **visible immediately** and only get hidden/blocked after AI processing completes. This provides the best user experience.

---

## 📱 **User Experience Flow**

### **1. Message Sending (Immediate Visibility)**
```
User sends message → Message appears immediately as "normal" → AI processes in background → Status updates if needed
```

### **2. Status Outcomes**
- **✅ Approved**: Message stays visible (no change)
- **🚫 Blocked**: Message becomes hidden for others, shows blocked UI to sender
- **⏳ Manual Review**: Message stays visible, admin gets notification

---

## 🔧 **Required Flutter Changes (20 minutes total)**

### **Change 1: Add Manual Review Status (30 seconds)**

```dart
// File: lib/features/groups/domain/entities/group_message_entity.dart
enum ModerationStatusType {
  pending('pending'),
  approved('approved'),
  blocked('blocked'),
  manual_review('manual_review'), // ADD THIS LINE
}
```

### **Change 2: Update Message Visibility Logic (5 minutes)**

```dart
// File: lib/features/groups/presentation/screens/group_chat_screen.dart

// In your _convertEntitiesToChatMessages method or wherever you filter messages:
List<ChatMessage> _convertEntitiesToChatMessages(List<GroupMessageEntity> entities) {
  return entities.where((entity) {
    // Hide blocked messages from OTHER users only
    if (entity.moderation?.status == ModerationStatusType.blocked) {
      return entity.senderCpId == currentUserId; // Only show to sender
    }
    
    // Show all other messages (pending, approved, manual_review)
    return true;
  }).map((entity) => ChatMessage(
    // ... existing mapping
  )).toList();
}
```

### **Change 3: Add Blocked Message UI (10 minutes)**

```dart
// File: lib/features/groups/presentation/screens/group_chat_screen.dart

// In your _buildMessageItem method:
Widget _buildMessageItem(ChatMessage message, GroupMessageEntity entity) {
  // Show blocked status only to sender
  if (entity.moderation?.status == ModerationStatusType.blocked && 
      entity.senderCpId == currentUserId) {
    return _buildBlockedMessageUI(entity);
  }
  
  // Show manual review indicator (optional - could be subtle)
  if (entity.moderation?.status == ModerationStatusType.manual_review && 
      entity.senderCpId == currentUserId) {
    return _buildMessageWithReviewIndicator(message, entity);
  }
  
  // All other messages display normally
  return _buildNormalMessage(message);
}

// Blocked message UI (only visible to sender)
Widget _buildBlockedMessageUI(GroupMessageEntity entity) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      border: Border.all(color: Colors.red.shade300),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text(
              'Message Blocked',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        if (entity.moderation?.reason != null) ...[
          SizedBox(height: 8),
          Text(
            entity.moderation!.reason!,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
            ),
          ),
        ],
        SizedBox(height: 8),
        Text(
          'This message violates community guidelines and is only visible to you.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}

// Optional: Manual review indicator (subtle)
Widget _buildMessageWithReviewIndicator(ChatMessage message, GroupMessageEntity entity) {
  return Stack(
    children: [
      _buildNormalMessage(message),
      Positioned(
        top: 4,
        right: 4,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Under Review',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
  );
}
```

### **Change 4: Remove Initial Pending State (2 minutes)**

```dart
// File: lib/features/groups/application/group_chat_providers.dart

// In your sendMessage method, start with approved status:
final message = GroupMessageEntity(
  id: messageId,
  groupId: groupId,
  senderCpId: currentUser.cpId,
  senderName: currentUser.displayName,
  body: content.trim(),
  createdAt: DateTime.now(),
  // Start as approved - cloud function will change if needed
  moderation: const ModerationStatus(
    status: ModerationStatusType.approved, // Changed from pending
    reason: null,
  ),
  // ... other fields
);
```

---

## 🎯 **How It Works**

### **Immediate Visibility (Best UX)**
1. User sends message → Appears immediately as "normal"
2. Cloud function processes in background (1-3 seconds)
3. If blocked → Message disappears for others, shows blocked UI to sender
4. If approved → No change (stays visible)
5. If manual review → Stays visible, optional subtle indicator

### **Real-time Updates**
- Your existing Firestore listeners automatically pick up status changes
- When `isHidden: true` is set by cloud function, message disappears for others
- Sender sees blocked message with explanation

### **Benefits**
- ✅ **Fast UX**: Messages appear instantly
- ✅ **No waiting**: Users don't wait for moderation
- ✅ **Clear feedback**: Blocked messages show clear reasons to sender
- ✅ **Privacy**: Others never see blocked content
- ✅ **Minimal changes**: Works with existing schema

---

## 🔄 **Updated Cloud Function Logic**

```javascript
// Messages start as "approved" in Flutter
// Cloud function only updates if action needed:

// Rule-based violation → Block immediately
if (definiteViolation) {
  await snap.ref.update({
    moderation: { status: 'blocked', reason: 'Inappropriate content' },
    isHidden: true // Hide from others
  });
}

// AI uncertain → Manual review (stays visible)
if (needsReview) {
  await snap.ref.update({
    moderation: { status: 'manual_review', reason: 'Under review' }
    // No isHidden - stays visible
  });
}

// Clean content → No update needed (stays approved)
```

---

## 📊 **Implementation Priority**

### **Phase 1: Core Functionality (15 minutes)**
1. ✅ Add `manual_review` enum value
2. ✅ Update message visibility logic
3. ✅ Add blocked message UI

### **Phase 2: UX Polish (Optional)**
1. Add manual review indicator
2. Add smooth transitions
3. Add better styling

### **Phase 3: Admin Features (Later)**
1. Admin dashboard for manual review queue
2. Moderation statistics
3. User management tools

---

## ✅ **Testing Checklist**

- [ ] Send normal message → Appears immediately, stays visible
- [ ] Send blocked content → Appears briefly, then shows blocked UI to sender only
- [ ] Other users don't see blocked messages
- [ ] Manual review messages stay visible with optional indicator
- [ ] Real-time updates work correctly

This approach gives you the **best user experience** with **minimal Flutter changes**!
