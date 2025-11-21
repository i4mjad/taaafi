import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/localization.dart';
import 'share_template_builder.dart';

/// Service for sharing referral codes via different channels
class ReferralShareService {
  final AppLocalizations l10n;
  late final ShareTemplateBuilder _templateBuilder;

  ReferralShareService(this.l10n) {
    _templateBuilder = ShareTemplateBuilder(l10n);
  }

  void _log(String message) {
    developer.log(message, name: 'ReferralShareService');
  }

  /// Share via WhatsApp
  Future<bool> shareViaWhatsApp(String code, {String? userName}) async {
    try {
      final message = _templateBuilder.buildWhatsAppMessage(code, userName: userName);
      final encodedMessage = Uri.encodeComponent(message);
      final url = Uri.parse('whatsapp://send?text=$encodedMessage');

      _log('Attempting to share via WhatsApp: $url');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _log('Successfully opened WhatsApp');
        return true;
      } else {
        _log('WhatsApp not available, falling back to generic share');
        // Fallback to generic share if WhatsApp is not installed
        return await shareGeneric(code, userName: userName);
      }
    } catch (e) {
      _log('Error sharing via WhatsApp: $e');
      // Fallback to generic share
      return await shareGeneric(code, userName: userName);
    }
  }

  /// Share via SMS
  Future<bool> shareViaSMS(String code) async {
    try {
      final message = _templateBuilder.buildSMSMessage(code);
      final encodedMessage = Uri.encodeComponent(message);
      final url = Uri.parse('sms:?body=$encodedMessage');

      _log('Attempting to share via SMS: $url');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _log('Successfully opened SMS app');
        return true;
      } else {
        _log('SMS not available, falling back to generic share');
        return await shareGeneric(code);
      }
    } catch (e) {
      _log('Error sharing via SMS: $e');
      return await shareGeneric(code);
    }
  }

  /// Share via Email
  Future<bool> shareViaEmail(String code, {String? userName}) async {
    try {
      final subject = _templateBuilder.getEmailSubject();
      final body = _templateBuilder.buildEmailBody(code, userName: userName);
      final encodedSubject = Uri.encodeComponent(subject);
      final encodedBody = Uri.encodeComponent(body);
      final url = Uri.parse('mailto:?subject=$encodedSubject&body=$encodedBody');

      _log('Attempting to share via Email: $url');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _log('Successfully opened email app');
        return true;
      } else {
        _log('Email not available, falling back to generic share');
        return await shareGeneric(code, userName: userName);
      }
    } catch (e) {
      _log('Error sharing via Email: $e');
      return await shareGeneric(code, userName: userName);
    }
  }

  /// Generic share (uses system share sheet)
  Future<bool> shareGeneric(String code, {String? userName}) async {
    try {
      final message = _templateBuilder.buildShareMessage(code, userName: userName);
      final subject = l10n.translate('referral.share.subject');

      _log('Sharing via generic share sheet');

      final result = await Share.shareWithResult(
        message,
        subject: subject,
      );

      final success = result.status == ShareResultStatus.success;
      _log('Generic share result: ${result.status}');
      return success;
    } catch (e) {
      _log('Error sharing generically: $e');
      return false;
    }
  }

  /// Copy referral code to clipboard
  Future<bool> copyToClipboard(String code) async {
    try {
      final message = _templateBuilder.buildCopyLinkMessage(code);
      await Clipboard.setData(ClipboardData(text: message));
      _log('Successfully copied to clipboard');
      return true;
    } catch (e) {
      _log('Error copying to clipboard: $e');
      return false;
    }
  }

  /// Copy just the code (without extra text)
  Future<bool> copyCodeOnly(String code) async {
    try {
      await Clipboard.setData(ClipboardData(text: code));
      _log('Successfully copied code to clipboard');
      return true;
    } catch (e) {
      _log('Error copying code to clipboard: $e');
      return false;
    }
  }
}

