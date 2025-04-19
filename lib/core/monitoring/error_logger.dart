import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_logger.g.dart';

class ErrorLogger {
  const ErrorLogger();

  FutureOr<void> logException(
    Object exception,
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
  }) async {
    // Set custom keys for Crashlytics if context is provided
    if (context != null) {
      for (final entry in context.entries) {
        await FirebaseCrashlytics.instance
            .setCustomKey(entry.key, entry.value.toString());
      }
    }

    await FirebaseCrashlytics.instance.recordFlutterFatalError(
      FlutterErrorDetails(
        exception: exception,
        stack: stackTrace,
        context: ErrorDescription(context?.toString() ?? ''),
      ),
    );

    log(
      exception.toString(),
      name: 'Exception',
      error: exception,
      stackTrace: stackTrace,
    );
  }
}

@Riverpod(keepAlive: true)
ErrorLogger errorLogger(ErrorLoggerRef ref) {
  return const ErrorLogger();
}
