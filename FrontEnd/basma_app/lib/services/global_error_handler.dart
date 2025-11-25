import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:basma_app/services/network_exceptions.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Initialize global error handlers to surface uncaught errors to users
void initGlobalErrorHandler() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _showErrorSnackbar(details.exception);
  };

  // Capture platform-level uncaught async errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _showErrorSnackbar(error);
    return true; // handled
  };
}

void _showErrorSnackbar(Object? error) {
  try {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    String message = 'حدث خطأ غير متوقع';
    if (error is NetworkException) {
      message = error.error.message;
    } else if (error is Exception) {
      message = error.toString();
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));
  } catch (_) {
    // ignore snackbar errors
  }
}
