import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';

extension WidgetExtension on Widget {
  Widget wrapByCard(
    BuildContext context, {
    EdgeInsets? padding,
    double? width,
    double? height,
  }) {
    return Card.filled(
      key: key,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          width: 1,
          color: context.colorScheme.outline.withValues(alpha: .4),
        ),
      ),
      child: Container(
        padding: padding ?? EdgeInsets.all(25),
        width: width,
        height: height,
        child: this,
      ),
    );
  }
}
