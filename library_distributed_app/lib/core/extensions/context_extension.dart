import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  Future<T?> showDialog<T>([Widget Function(BuildContext context)? builder]) {
    return showAdaptiveDialog<T>(
      context: this,
      barrierDismissible: true,
      routeSettings: RouteSettings(name: 'dialog_$runtimeType'),
      builder: (context) => builder?.call(context) ?? const SizedBox.shrink(),
    );
  }
}
