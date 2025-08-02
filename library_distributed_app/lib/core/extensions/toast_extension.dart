import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

const _autoCloseDuration = Duration(seconds: 3);

extension ToastExtension on BuildContext {
  void showError(String message) {
    toastification.show(
      context: this,
      type: ToastificationType.error,
      icon: const Icon(Icons.error_outline_rounded),
      title: Text(message),
      autoCloseDuration: _autoCloseDuration,
    );
  }

  void showSuccess(String message) {
    toastification.show(
      context: this,
      type: ToastificationType.success,
      icon: const Icon(Icons.check_circle_outline_rounded),
      title: Text(message),
      autoCloseDuration: _autoCloseDuration,
    );
  }

  void showInfo(String message) {
    toastification.show(
      context: this,
      type: ToastificationType.info,
      icon: const Icon(Icons.info_outline_rounded),
      title: Text(message),
      autoCloseDuration: _autoCloseDuration,
    );
  }

  void showWarning(String message) {
    toastification.show(
      context: this,
      type: ToastificationType.warning,
      icon: const Icon(Icons.warning_amber_rounded),
      title: Text(message),
      autoCloseDuration: _autoCloseDuration,
    );
  }
}
