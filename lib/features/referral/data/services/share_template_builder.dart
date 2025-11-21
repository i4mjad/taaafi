import '../../../../core/localization/localization.dart';

/// Builds localized share messages for different channels
class ShareTemplateBuilder {
  final AppLocalizations l10n;

  ShareTemplateBuilder(this.l10n);

  /// Build generic share message (for share sheet)
  String buildShareMessage(String code, {String? userName}) {
    return l10n
        .translate('referral.share.generic_message')
        .replaceAll('{code}', code)
        .replaceAll('{userName}', userName ?? l10n.translate('referral.share.default_user'));
  }

  /// Build WhatsApp-optimized message (shorter, emoji-friendly)
  String buildWhatsAppMessage(String code, {String? userName}) {
    return l10n
        .translate('referral.share.whatsapp_message')
        .replaceAll('{code}', code)
        .replaceAll('{userName}', userName ?? l10n.translate('referral.share.default_user'));
  }

  /// Build SMS-optimized message (very short, no emojis)
  String buildSMSMessage(String code) {
    return l10n
        .translate('referral.share.sms_message')
        .replaceAll('{code}', code);
  }

  /// Build email body
  String buildEmailBody(String code, {String? userName}) {
    return l10n
        .translate('referral.share.email_message')
        .replaceAll('{code}', code)
        .replaceAll('{userName}', userName ?? l10n.translate('referral.share.default_user'));
  }

  /// Get email subject
  String getEmailSubject() {
    return l10n.translate('referral.share.email_subject');
  }

  /// Build copy link message (just the code with simple text)
  String buildCopyLinkMessage(String code) {
    return l10n
        .translate('referral.share.copy_link_message')
        .replaceAll('{code}', code);
  }
}

