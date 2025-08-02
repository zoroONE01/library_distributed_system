import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';

extension WidgetExtension on Widget {
  Widget wrapByCard(
    BuildContext context, {
    EdgeInsets? padding,
    double? width,
    double? height,
    Color? backgroundColor,
  }) {
    return Card.filled(
      key: key,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          width: 1,
          color: context.colorScheme.outline.withValues(alpha: .4),
        ),
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(25),
        width: width,
        height: height,
        child: this,
      ),
    );
  }

  Widget withIcon(
    IconData icon, {
    double iconSize = 24,
    double spacing = 8,
    Color? iconColor,
    bool isRightSide = false,
    TextDirection? textDirection,
  }) {
    return Row(
      spacing: spacing,
      mainAxisSize: MainAxisSize.min,
      textDirection: textDirection,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        Flexible(child: this),
      ],
    );
  }

  Future<T?> showAsDialog<T>(BuildContext context) {
    return showAdaptiveDialog<T>(
      context: context,
      barrierDismissible: true,
      routeSettings: RouteSettings(name: 'dialog_$runtimeType'),
      builder: (context) => this,
    );
  }
}
