import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/presentation/book_list/book_list_provider.dart';
import 'package:library_distributed_app/presentation/widgets/app_text_field.dart';

class BookListEditor extends HookConsumerWidget {
  const BookListEditor({super.key, this.bookId});
  final String? bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookNameController = useTextEditingController();
    final authorController = useTextEditingController();
    final quantityController = useTextEditingController();

    final book = ref.watch(bookProvider(bookId));

    useEffect(() {
      book.whenData((data) {
        bookNameController.text = data.title;
        authorController.text = data.author;
        quantityController.text = data.quantity.toString();
      });
      return null;
    }, [book]);

    return AlertDialog(
      title: Text('Thêm sách mới', style: context.headlineMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text('Hủy', style: context.bodyLarge),
        ),
        TextButton(
          onPressed: ref.read(bookProvider().notifier).performCreateNewBook,
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
