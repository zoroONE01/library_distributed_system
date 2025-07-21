import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/presentation/widgets/app_text_field.dart';

class BookListCreateDialog extends StatelessWidget {
  const BookListCreateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Thêm sách mới', style: context.headlineMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text('Hủy', style: context.bodyLarge),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          child: Text('Thêm', style: context.bodyLarge),
        ),
      ],
      content: SingleChildScrollView(
        child: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              context,
              labelText: 'Nhập tên sách',
              prefixIcon: Icon(Icons.book_rounded, size: 20),
            ),
            AppTextField(
              context,
              labelText: 'Nhập tác giả',
              prefixIcon: Icon(Icons.person_rounded, size: 20),
            ),
            AppTextField(
              context,
              labelText: 'Nhập thể loại',
              prefixIcon: Icon(Icons.category_rounded, size: 20),
            ),
            AppTextField(
              context,
              labelText: 'Nhập số lượng',
              prefixIcon: Icon(Icons.format_list_numbered_rounded, size: 20),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
