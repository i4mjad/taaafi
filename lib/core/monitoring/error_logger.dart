import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_logger.g.dart';

class ErrorLogger {
  const ErrorLogger();

  FutureOr<void> logException(Object exception, StackTrace? stackTrace) async {
    await FirebaseCrashlytics.instance.recordFlutterFatalError(
      FlutterErrorDetails(
        exception: exception,
        stack: stackTrace,
      ),
    );
    log(exception.toString(),
        name: 'Exception', error: exception, stackTrace: stackTrace);
  }
}

@Riverpod(keepAlive: true)
ErrorLogger errorLogger(ErrorLoggerRef ref) {
  return const ErrorLogger();
}
