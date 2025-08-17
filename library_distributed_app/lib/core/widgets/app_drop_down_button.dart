import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';

class AppDropDownItem<T> {
  final String? label;
  final T value;
  const AppDropDownItem({required this.value, this.label});
}

class AppDropDownButton<T> extends StatelessWidget {
  const AppDropDownButton({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
  });
  final List<AppDropDownItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: value,
      isExpanded: true,
      focusColor: Colors.transparent,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item.value,
              child: Text(
                item.label ?? item.value.toString(),
                style: context.bodyLarge,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (onChanged != null && value != null) {
          onChanged!(value);
        }
      },
    );
  }
}
