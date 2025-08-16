import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/toast_extension.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/presentation/books/providers/books_provider.dart';
import 'package:library_distributed_app/presentation/widgets/app_text_field.dart';

class BookListCreateBookDialog extends HookConsumerWidget {
  const BookListCreateBookDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookNameController = useTextEditingController();
    final authorController = useTextEditingController();
    final quantityController = useTextEditingController();

    final onPerformCreate = useCallback(
      () => ref.listenManual(
        createBookProvider(
          BookEntity(
            title: bookNameController.text,
            author: authorController.text,
          ),
        ),
        (previous, next) {
          next.whenOrNull(
            data: (_) {
              if (previous == null) return;
              if (previous.hasValue) {
                context.showSuccess('Thêm sách thành công');
              }
            },
            error: (error, stackTrace) {
              context.showError('Thêm sách thất bại: ${error.toString()}');
            },
          );
        },
      ),
      [bookNameController.text, authorController.text, quantityController.text],
    );

    return AlertDialog(
      title: Text('Thêm sách mới', style: context.headlineMedium),
      actions: [
        TextButton(
          onPressed: context.maybePop,
          child: Text('Hủy', style: context.bodyLarge),
        ),
        TextButton(
          onPressed: onPerformCreate,
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
              controller: bookNameController,
              labelText: 'Nhập tên sách',
              prefixIcon: const Icon(Icons.book_rounded, size: 20),
            ),
            AppTextField(
              context,
              controller: authorController,
              labelText: 'Nhập tác giả',
              prefixIcon: const Icon(Icons.person_rounded, size: 20),
            ),
            AppTextField(
              context,
              controller: quantityController,
              labelText: 'Nhập số lượng',
              prefixIcon: const Icon(
                Icons.format_list_numbered_rounded,
                size: 20,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
