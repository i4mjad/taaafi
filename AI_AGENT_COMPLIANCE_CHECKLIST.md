# Flutter App Compliance Checklist - Message Moderation Schema & UI

## 📋 Overview
This checklist validates that the Flutter app's data schema and UI components are compatible with the new Firebase AI message moderation system. Focus on database structure and user interface requirements only.

---

## 📊 **SECTION 1: MESSAGE SCHEMA COMPLIANCE**

### ✅ **1.1 Message Model Structure**
**VALIDATION TASK**: Check if Flutter app's message model includes required moderation fields.

**AI AGENT INSTRUCTIONS**:
```dart
// Look for message model/class definition in Flutter app
// Check if it includes these new fields:

class Message {
  // ... existing fields
  
  // NEW REQUIRED FIELDS:
  ModerationData? moderation;
}

class ModerationData {
  String status; // 'pending', 'approved', 'blocked', 'manual_review'
  String? violationType; // 'social_media_sharing', 'sexual_content', etc.
  String? reason;
  String moderatedBy;
  double? confidence;
  int processingTimeMs;
  DateTime moderatedAt;
}
```

**SUCCESS CRITERIA**:
- [ ] Message model has `moderation` field (nullable)
- [ ] ModerationData class exists with all required fields
- [ ] Status field accepts correct enum values
- [ ] DateTime fields use proper Flutter DateTime type
- [ ] Fields match Firestore document structure exactly

**FAILURE INDICATORS**:
- Missing moderation field in message model
- Incorrect field names or types
- Missing required ModerationData properties

---

### ✅ **1.2 Firestore Serialization**
**VALIDATION TASK**: Verify message serialization handles new moderation fields.

**AI AGENT INSTRUCTIONS**:
```dart
// Check toJson() and fromJson() methods include moderation data:

Map<String, dynamic> toJson() {
  return {
    // ... existing fields
    'moderation': moderation?.toJson(),
  };
}

factory Message.fromJson(Map<String, dynamic> json) {
  return Message(
    // ... existing fields
    moderation: json['moderation'] != null 
        ? ModerationData.fromJson(json['moderation']) 
        : null,
  );
}
```

**SUCCESS CRITERIA**:
- [ ] toJson() includes moderation field serialization
- [ ] fromJson() handles null moderation gracefully
- [ ] ModerationData has proper serialization methods
- [ ] No serialization errors when moderation is null

**FAILURE INDICATORS**:
- Serialization methods missing moderation handling
- Crashes when moderation field is null
- Type conversion errors

---

## 🎨 **SECTION 2: UI COMPONENT COMPLIANCE**

### ✅ **2.1 Message Status Display**
**VALIDATION TASK**: Check if message widgets show moderation status appropriately.

**AI AGENT INSTRUCTIONS**:
```dart
// Look for message widget/component that displays messages
// Should handle these status cases:

Widget buildMessage(Message message) {
  switch (message.moderation?.status) {
    case 'pending':
      return PendingMessageWidget(); // Show loading/pending indicator
    case 'blocked':
      return BlockedMessageWidget(); // Show blocked message to sender only
    case 'approved':
      return NormalMessageWidget(); // Show normal message
    case 'manual_review':
      return PendingMessageWidget(); // Show as pending to user
    default:
      return NormalMessageWidget(); // Fallback for old messages
  }
}
```

**SUCCESS CRITERIA**:
- [ ] Message widget handles all moderation statuses
- [ ] Pending messages show loading indicator
- [ ] Blocked messages show appropriate UI to sender
- [ ] Approved messages display normally
- [ ] Graceful handling of null/missing moderation data

**FAILURE INDICATORS**:
- No status handling in message widgets
- Crashes on unknown status values
- Blocked messages visible to other users
- No visual feedback for pending messages

---

### ✅ **2.2 Blocked Message UI**
**VALIDATION TASK**: Verify blocked messages show proper feedback to sender.

**AI AGENT INSTRUCTIONS**:
```dart
// Check for blocked message widget implementation:

class BlockedMessageWidget extends StatelessWidget {
  final Message message;
  
  Widget build(BuildContext context) {
    return Container(
      // Should show:
      // 1. "Message blocked" indicator
      // 2. Reason for blocking (if available)
      // 3. Appropriate styling (red/warning colors)
      // 4. No interaction options (reply, react, etc.)
    );
  }
}
```

**SUCCESS CRITERIA**:
- [ ] Blocked messages show clear "blocked" indicator
- [ ] Reason for blocking is displayed (if available)
- [ ] Uses appropriate warning/error styling
- [ ] Interaction buttons (reply, react) are disabled
- [ ] Only visible to message sender

**FAILURE INDICATORS**:
- No visual indication of blocked status
- Missing reason display
- Interaction options still available
- Visible to other users

---

### ✅ **2.3 Pending Message UI**
**VALIDATION TASK**: Check pending message display during moderation processing.

**AI AGENT INSTRUCTIONS**:
```dart
// Look for pending message handling:

class PendingMessageWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(
      // Should show:
      // 1. Message content with reduced opacity
      // 2. Loading/processing indicator
      // 3. "Checking..." or similar text
      // 4. Disabled interactions
    );
  }
}
```

**SUCCESS CRITERIA**:
- [ ] Pending messages show loading indicator
- [ ] Message content visible but with reduced opacity
- [ ] Clear "processing" or "checking" text
- [ ] Interactions disabled during pending state
- [ ] Real-time updates when status changes

**FAILURE INDICATORS**:
- No visual indication of pending state
- Full opacity/normal appearance
- Interactions still enabled
- No status update handling

---

## 🔄 **SECTION 3: REAL-TIME UPDATE HANDLING**

### ✅ **3.1 Firestore Listeners**
**VALIDATION TASK**: Verify app listens for moderation status changes.

**AI AGENT INSTRUCTIONS**:
```dart
// Check if app has Firestore listeners for message updates:

StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('group_messages')
      .where('groupId', isEqualTo: groupId)
      .snapshots(),
  builder: (context, snapshot) {
    // Should handle real-time updates to moderation status
  },
);
```

**SUCCESS CRITERIA**:
- [ ] App uses StreamBuilder or similar for real-time updates
- [ ] Listens to message collection changes
- [ ] Updates UI when moderation status changes
- [ ] Handles connection issues gracefully

**FAILURE INDICATORS**:
- No real-time listeners implemented
- UI doesn't update when status changes
- Requires app restart to see updates

---

### ✅ **3.2 Status Transition Handling**
**VALIDATION TASK**: Check smooth transitions between moderation statuses.

**AI AGENT INSTRUCTIONS**:
```dart
// Look for status change handling:

void onMessageUpdated(Message oldMessage, Message newMessage) {
  if (oldMessage.moderation?.status != newMessage.moderation?.status) {
    // Should smoothly transition UI
    // From pending → approved/blocked
    // Show animations or transitions
  }
}
```

**SUCCESS CRITERIA**:
- [ ] Smooth transitions between status states
- [ ] No jarring UI changes
- [ ] Appropriate animations (optional)
- [ ] Consistent behavior across all status changes

**FAILURE INDICATORS**:
- Abrupt UI changes
- Flickering or jumping content
- Inconsistent status handling

---

## 📱 **SECTION 4: USER EXPERIENCE VALIDATION**

### ✅ **4.1 Message Sending Flow**
**VALIDATION TASK**: Verify message sending shows immediate pending state.

**AI AGENT INSTRUCTIONS**:
```dart
// Check message sending implementation:

Future<void> sendMessage(String content) async {
  // Should immediately show message as 'pending'
  final message = Message(
    body: content,
    moderation: ModerationData(
      status: 'pending',
      moderatedBy: 'system',
      moderatedAt: DateTime.now(),
      processingTimeMs: 0,
    ),
  );
  
  // Add to Firestore - cloud function will update moderation
}
```

**SUCCESS CRITERIA**:
- [ ] New messages immediately show as pending
- [ ] User sees their message right away
- [ ] Status updates automatically from cloud function
- [ ] No delay in message appearance

**FAILURE INDICATORS**:
- Messages don't appear until moderation complete
- No pending state shown
- Long delays before message appears

---

### ✅ **4.2 Error State Handling**
**VALIDATION TASK**: Check handling of moderation errors.

**AI AGENT INSTRUCTIONS**:
```dart
// Look for error state handling:

if (message.moderation?.status == 'manual_review') {
  // Should show appropriate message to user
  // "Your message is being reviewed" or similar
}

if (message.moderation?.error != null) {
  // Should handle system errors gracefully
  // Maybe retry mechanism or error message
}
```

**SUCCESS CRITERIA**:
- [ ] Manual review status shows appropriate message
- [ ] System errors handled gracefully
- [ ] User gets clear feedback on all states
- [ ] No crashes on error conditions

**FAILURE INDICATORS**:
- No handling of manual review state
- Crashes on error conditions
- Unclear user feedback

---

## 🔧 **SECTION 5: BACKWARD COMPATIBILITY**

### ✅ **5.1 Legacy Message Support**
**VALIDATION TASK**: Ensure app works with existing messages without moderation data.

**AI AGENT INSTRUCTIONS**:
```dart
// Check handling of old messages:

class Message {
  ModerationData? moderation; // Nullable for backward compatibility
  
  bool get isModerated => moderation != null;
  bool get isApproved => moderation?.status == 'approved' || moderation == null;
}
```

**SUCCESS CRITERIA**:
- [ ] Old messages without moderation field display normally
- [ ] No crashes when moderation is null
- [ ] Graceful degradation for legacy data
- [ ] New features don't break old messages

**FAILURE INDICATORS**:
- Crashes on messages without moderation
- Old messages don't display
- Breaking changes to existing functionality

---

## 📝 **AI AGENT REPORTING FORMAT**

**For each section, report**:
```
SECTION: [Section Name]
STATUS: ✅ PASS / ❌ FAIL / ⚠️ NEEDS_UPDATE
DETAILS: [What needs to be changed if failed]
REQUIRED_CHANGES: [Specific code changes needed]
```

**Final Report Summary**:
```
FLUTTER APP COMPLIANCE: [PASS/NEEDS_UPDATES]
SCHEMA_COMPATIBILITY: [Compatible/Needs Changes]
UI_REQUIREMENTS: [Complete/Missing Components]
REQUIRED_UPDATES: [List of necessary changes]
ESTIMATED_EFFORT: [Low/Medium/High]
```
