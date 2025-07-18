import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';

class AppTextField extends TextFormField {
  AppTextField(
    BuildContext context, {
    super.key,
    super.controller,
    super.obscureText = false,
    super.keyboardType,
    super.validator,
    super.onSaved,
    super.onChanged,
    super.onFieldSubmitted,
    super.focusNode,
    super.textInputAction,
    String? labelText,
    Widget? prefixIcon,
  }) : super(
         decoration: InputDecoration(
           labelText: labelText,
           prefixIcon: prefixIcon,
           filled: true,
           fillColor: context.onSurface.withValues(alpha: .1),
           enabledBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(
               color: context.colorScheme.outline.withValues(alpha: .4),
             ),
           ),
           focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(
               color: context.primaryColor.withValues(alpha: .4),
             ),
           ),
           border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(
               color: context.colorScheme.outline.withValues(alpha: .4),
             ),
           ),
         ),
       );
}
