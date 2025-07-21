import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/presentation/widgets/app_text_field.dart';

class ReaderListCreateDialog extends StatelessWidget {
  const ReaderListCreateDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Thêm Độc giả mới'),
      content: AppTextField(
        context,
        labelText: 'Nhập tên độc giả',
        prefixIcon: Icon(Icons.person_add_alt_1_rounded),
      ),
      actions: [
        TextButton(
          onPressed: context.maybePop,
          child: Text('Hủy', style: context.bodyLarge),
        ),
        TextButton(
          onPressed: context.maybePop,
          child: Text('Thêm', style: context.bodyLarge),
        ),
      ],
    );
  }
}
