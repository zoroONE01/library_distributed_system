import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.width,
    this.height,
    this.onPressed,
    this.label = '',
    this.icon,
    this.backgroundColor,
    this.shadowColor,
  });

  final double? width, height;
  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;
  final Color? backgroundColor, shadowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 48,
      width: width,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shadowColor: shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          iconColor: context.onSurface,
        ),
        icon: icon,
        label: Text(
          label,
          style: context.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: context.onSurface,
          ),
        ),
      ),
    );
  }
}
