import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/toast_extension.dart';
import 'package:library_distributed_app/domain/entities/book.dart';
import 'package:library_distributed_app/presentation/books/providers/books_provider.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Edit Book Dialog - FR10 Implementation
/// Only available for QUANLY role (managers)
/// Uses 2PC for distributed transaction management
class BookEditDialog extends HookConsumerWidget {
  const BookEditDialog({
    super.key,
    required this.book,
  });

  final BookEntity book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isbnController = useTextEditingController(text: book.isbn);
    final bookNameController = useTextEditingController(text: book.title);
    final authorController = useTextEditingController(text: book.author);
    final isLoading = useState(false);

    final onPerformUpdate = useCallback(
      () async {
        // Validate input
        if (bookNameController.text.trim().isEmpty) {
          context.showError('Vui lòng nhập tên sách');
          return;
        }
        if (authorController.text.trim().isEmpty) {
          context.showError('Vui lòng nhập tác giả');
          return;
        }

        isLoading.value = true;
        try {
          final updatedBook = BookEntity(
            isbn: isbnController.text.trim(),
            title: bookNameController.text.trim(),
            author: authorController.text.trim(),
          );

          await ref.read(updateBookProvider((
            isbn: book.isbn,
            book: updatedBook,
          )).future);
          
          if (context.mounted) {
            context.maybePop();
            context.showSuccess('Cập nhật đầu sách thành công');
          }
        } catch (e) {
          if (context.mounted) {
            context.showError('Cập nhật đầu sách thất bại: ${e.toString()}');
          }
        } finally {
          isLoading.value = false;
        }
      },
      [bookNameController, authorController],
    );

    return AlertDialog(
      title: Text('Chỉnh sửa đầu sách (FR10)', style: context.headlineMedium),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : context.maybePop,
          child: Text('Hủy', style: context.bodyLarge),
        ),
        TextButton(
          onPressed: isLoading.value ? null : onPerformUpdate,
          child: isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Cập nhật', style: context.bodyLarge),
        ),
      ],
      content: SingleChildScrollView(
        child: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chỉnh sửa thông tin đầu sách.\nThao tác này sẽ được thực hiện trên toàn hệ thống.',
              style: context.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AppTextField(
              context,
              controller: isbnController,
              labelText: 'Mã ISBN (không thể thay đổi)',
              prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
            ),
            AppTextField(
              context,
              controller: bookNameController,
              labelText: 'Tên sách *',
              prefixIcon: const Icon(Icons.book_rounded, size: 20),
            ),
            AppTextField(
              context,
              controller: authorController,
              labelText: 'Tác giả *',
              prefixIcon: const Icon(Icons.person_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
