import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_logger.g.dart';

class ErrorLogger {
  const ErrorLogger();

  FutureOr<void> logException(
    Object exception,
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
    String? message,
  }) async {
    // Set custom keys for Crashlytics if context is provided
    if (context != null) {
      for (final entry in context.entries) {
        await FirebaseCrashlytics.instance
            .setCustomKey(entry.key, entry.value.toString());
      }
    }

    // Add message as a custom key if provided
    if (message != null) {
      await FirebaseCrashlytics.instance.setCustomKey('message', message);
    }

    await FirebaseCrashlytics.instance.recordFlutterFatalError(
      FlutterErrorDetails(
        exception: exception,
        stack: stackTrace,
        context: ErrorDescription(context?.toString() ?? message ?? ''),
      ),
    );

    log(
      message ?? exception.toString(),
      name: 'Exception',
      error: exception,
      stackTrace: stackTrace,
    );
  }

  /// Logs informational messages that are not errors
  void logInfo(String message, {Map<String, dynamic>? context}) {
    log(
      message,
      name: 'Info',
    );

    // Optionally log to Crashlytics as breadcrumb
    if (context != null) {
      FirebaseCrashlytics.instance
          .log('INFO: $message - ${context.toString()}');
    } else {
      FirebaseCrashlytics.instance.log('INFO: $message');
    }
  }

  /// Logs warning messages that are not critical errors
  void logWarning(String message, {Map<String, dynamic>? context}) {
    log(
      message,
      name: 'Warning',
    );

    // Log to Crashlytics as breadcrumb
    if (context != null) {
      FirebaseCrashlytics.instance
          .log('WARNING: $message - ${context.toString()}');
    } else {
      FirebaseCrashlytics.instance.log('WARNING: $message');
    }
  }
}

@Riverpod(keepAlive: true)
ErrorLogger errorLogger(Ref ref) {
  return const ErrorLogger();
}
