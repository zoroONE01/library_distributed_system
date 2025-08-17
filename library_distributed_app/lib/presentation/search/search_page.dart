import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: AppTextField(
        context,
        labelText: 'Nhập từ khóa tìm kiếm',
        prefixIcon: const Icon(Icons.search),
      ),
      actions: [
        TextButton(
          onPressed: context.maybePop,
          child: Text('Hủy', style: context.bodyLarge),
        ),
        TextButton(
          onPressed: context.maybePop,
          child: Text('Tìm kiếm', style: context.bodyLarge),
        ),
      ],
    );
  }
}
