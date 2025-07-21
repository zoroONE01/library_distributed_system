// ignore: implementation_imports
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:library_distributed_app/core/constants/app_enum.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';

class BookListSortDialog extends HookWidget {
  const BookListSortDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final sortOption = useState<BookSortOption>(BookSortOption.name);
    final sortOrder = useState<SortOrder>(SortOrder.ascending);
    return AlertDialog(
      title: Text('Sắp xếp danh sách sách', style: context.headlineMedium),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Theo tên sách', style: context.bodyLarge),
              leading: Radio<BookSortOption>(
                value: BookSortOption.name,
                groupValue: sortOption.value,
                onChanged: (value) {
                  sortOption.value = value!;
                },
              ),
            ),
            ListTile(
              title: Text('Theo tác giả', style: context.bodyLarge),
              leading: Radio<BookSortOption>(
                value: BookSortOption.author,
                groupValue: sortOption.value,
                onChanged: (value) {
                  sortOption.value = value!;
                },
              ),
            ),
            ListTile(
              title: Text('Theo thể loại', style: context.bodyLarge),
              leading: Radio<BookSortOption>(
                value: BookSortOption.category,
                groupValue: sortOption.value,
                onChanged: (value) {
                  sortOption.value = value!;
                },
              ),
            ),
            ListTile(
              title: Text('Theo số lượng', style: context.bodyLarge),
              leading: Radio<BookSortOption>(
                value: BookSortOption.quantity,
                groupValue: sortOption.value,
                onChanged: (value) {
                  sortOption.value = value!;
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Tăng dần', style: context.bodyLarge),
              leading: Radio<SortOrder>(
                value: SortOrder.ascending,
                groupValue: sortOrder.value,
                onChanged: (value) {
                  sortOrder.value = value!;
                },
              ),
            ),
            ListTile(
              title: Text('Giảm dần', style: context.bodyLarge),
              leading: Radio<SortOrder>(
                value: SortOrder.descending,
                groupValue: sortOrder.value,
                onChanged: (value) {
                  sortOrder.value = value!;
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text('Hủy', style: context.bodyLarge),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text('Áp dụng', style: context.bodyLarge),
        ),
      ],
    );
  }
}
