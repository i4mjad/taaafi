# Sprint 09: Enhanced Share Feature with Deep Links

**Status**: Not Started
**Previous Sprint**: `sprint_08_checklist_progress_ui.md`
**Next Sprint**: `sprint_10_notifications.md`
**Estimated Duration**: 6-8 hours

---

## Objectives
Enhance referral code sharing with beautiful share templates, deep links, and multi-channel sharing (WhatsApp, SMS, social media).

---

## Prerequisites

### Verify Sprint 08 Completion
- [ ] Checklist progress UI complete
- [ ] Basic share functionality working

### Codebase Checks
1. Check if deep linking is already configured
2. Look for existing share functionality
3. Check `share_plus` package usage
4. Review Firebase Dynamic Links setup (if exists)

---

## Tasks

### Task 1: Set Up Deep Links / Dynamic Links

**Option A: Firebase Dynamic Links**
Configure Firebase Dynamic Links:
- Domain: `ta3afi.page.link` or custom domain
- Link format: `https://ta3afi.app/referral?code=AHMAD7`
- Fallback to App Store / Play Store

**Option B: Branch.io or Custom**
If Dynamic Links deprecated, use alternative.

**File**: Update `AndroidManifest.xml` and `Info.plist` for deep link handling

---

### Task 2: Create Deep Link Handler

**File**: `lib/core/navigation/deep_link_handler.dart`

```dart
class DeepLinkHandler {
  // Parse incoming deep link
  Future<void> handleDeepLink(Uri deepLink) async {
    if (deepLink.path == '/referral' && deepLink.queryParameters['code'] != null) {
      final code = deepLink.queryParameters['code'];
      // Navigate to referral code input screen with pre-filled code
      // Or auto-apply if user is in signup flow
    }
  }
}
```

Integrate with app's initialization flow.

---

### Task 3: Create Share Template Builder

**File**: `lib/features/referral/data/share_template_builder.dart`

```dart
class ShareTemplateBuilder {
  // Generate share message with deep link
  String buildShareMessage(String code, String userId, {String? userName}) {
    final deepLink = _generateDeepLink(code);

    return '''
🌟 Join me on Ta3afi!

I'm using Ta3afi for recovery support and it's been amazing. Join me and get 3 days of Premium features free!

Use my code: $code

$deepLink

Let's support each other! 💪
''';
  }

  String _generateDeepLink(String code) {
    // Generate Firebase Dynamic Link or custom deep link
    return 'https://ta3afi.app/referral?code=$code';
  }

  // WhatsApp-optimized message (shorter)
  String buildWhatsAppMessage(String code) { ... }

  // SMS-optimized message (very short)
  String buildSMSMessage(String code) { ... }

  // Social media message (with hashtags)
  String buildSocialMessage(String code) { ... }
}
```

---

### Task 4: Create Share Options Bottom Sheet

**File**: `lib/features/referral/presentation/widgets/share_options_sheet.dart`

**Options**:
```
Share via:
📱 WhatsApp
💬 SMS
📧 Email
🔗 Copy Link
📲 More Options
```

Each option uses optimized message template.

---

### Task 5: Implement Channel-Specific Sharing

**File**: `lib/features/referral/data/share_service.dart`

```dart
class ShareService {
  // Share via WhatsApp
  Future<void> shareViaWhatsApp(String code) async {
    final message = templateBuilder.buildWhatsAppMessage(code);
    final url = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
    await _launchUrl(url);
  }

  // Share via SMS
  Future<void> shareViaSMS(String code) async {
    final message = templateBuilder.buildSMSMessage(code);
    final url = 'sms:?body=${Uri.encodeComponent(message)}';
    await _launchUrl(url);
  }

  // Share via Email
  Future<void> shareViaEmail(String code) async {
    final subject = 'Join me on Ta3afi';
    final body = templateBuilder.buildShareMessage(code);
    final url = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    await _launchUrl(url);
  }

  // Generic share (uses Share.share)
  Future<void> shareGeneric(String code) async {
    final message = templateBuilder.buildShareMessage(code);
    await Share.share(message);
  }

  // Copy link to clipboard
  Future<void> copyLink(String code) async {
    final link = _generateDeepLink(code);
    await Clipboard.setData(ClipboardData(text: link));
    // Show snackbar: "Link copied!"
  }
}
```

---

### Task 6: Add Share Tracking

Track which channel users prefer:

```dart
analytics.logEvent('referral_code_shared', parameters: {
  'method': 'whatsapp' | 'sms' | 'email' | 'generic' | 'copy_link',
  'user_id': userId
});
```

Helps understand most effective channels.

---

### Task 7: Create Shareable Image/Card (Optional)

**File**: `lib/features/referral/presentation/widgets/shareable_referral_card.dart`

Generate a beautiful card image with:
- Referral code prominently displayed
- App logo/branding
- QR code (optional)
- "Join Ta3afi" message

Use `flutter/painting` to generate image, then share it.

---

### Task 8: Implement QR Code (Optional)

**File**: `lib/features/referral/presentation/widgets/referral_qr_code.dart`

Use `qr_flutter` package:
- Generate QR code for deep link
- User can share QR code image
- Another user scans to auto-apply code

---

### Task 9: Add Attribution Tracking

**File**: Update Cloud Function `redeemReferralCode.ts`

```typescript
// When user redeems code, track attribution channel
await db.collection('referralRedemptions').add({
  referrerId,
  refereeId,
  referralCode: code,
  attributionChannel: data.attributionChannel, // 'deep_link', 'manual', 'qr_code'
  redeemedAt: admin.firestore.FieldValue.serverTimestamp()
});
```

Helps measure deep link effectiveness.

---

### Task 10: Handle Deep Link Edge Cases

**Scenarios**:
1. **User not logged in**: Save code, apply after signup
2. **User already has referral**: Show error message
3. **Invalid code in deep link**: Show error, allow manual entry
4. **Deep link to existing user**: Show "Already a member? Check your rewards!"

---

### Task 11: Add Share Incentive Prompt

In dashboard, show prompt:
```
💡 Tip: Share on WhatsApp for best results!
Users who share via WhatsApp see 3x more referrals.
```

Data-driven suggestion based on analytics.

---

## Testing Criteria

### Manual Testing
1. **Generate deep link**: Verify format correct
2. **Share via WhatsApp**: Click link, verify app opens/downloads
3. **Share via SMS**: Test on iOS and Android
4. **Share via Email**: Verify formatting
5. **Copy link**: Paste in browser, verify redirect works
6. **Deep link handling**: Click link, verify code pre-filled or auto-applied
7. **QR code**: Generate, scan, verify works
8. **Attribution**: Check Firestore after redemption via different channels
9. **Edge cases**: Test all error scenarios

### Success Criteria
- [ ] Deep links configured and working
- [ ] Share options sheet functional
- [ ] All share channels work (WhatsApp, SMS, Email, Generic)
- [ ] Copy link works
- [ ] Deep link opens app correctly
- [ ] Code auto-applies from deep link
- [ ] Attribution tracking working
- [ ] QR code generated and scannable (if implemented)
- [ ] Analytics events firing
- [ ] Edge cases handled gracefully

---

## Platform-Specific Considerations

### iOS
- WhatsApp URL scheme: Verify app installed check
- SMS: Uses `MessageUI` framework
- Deep links: Universal Links configuration

### Android
- WhatsApp intent: Handle app not installed
- SMS: Uses intent
- Deep links: App Links configuration

---

## Analytics to Track

```dart
'referral_shared_method': { 'method': string }
'referral_deep_link_clicked': { 'code': string }
'referral_deep_link_opened_app': { 'code': string, 'user_status': 'new' | 'existing' }
'referral_qr_code_scanned': { 'code': string }
```

---

## Notes for Next Sprint

Sprint 10 will implement notification system for referral milestones.

---

**Next Sprint**: `sprint_10_notifications.md`
