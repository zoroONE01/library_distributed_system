import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/toast_extension.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/book_copies/providers/book_copies_provider.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Dialog for creating new book copies - FR9 Implementation
/// Only THUTHU can create book copies at their site
class BookCopyCreateDialog extends HookConsumerWidget {
  const BookCopyCreateDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final bookCopyIdController = useTextEditingController();
    final isbnController = useTextEditingController();
    final selectedStatus = useState<BookStatus>(BookStatus.available);

    final currentSite = ref.watch(librarySiteProvider);

    final onCreateBookCopy = useCallback(
      () {
        if (!formKey.currentState!.validate()) return;

        final bookCopy = BookCopyEntity(
          bookCopyId: bookCopyIdController.text.trim(),
          isbn: isbnController.text.trim(),
          branchSite: currentSite,
          status: selectedStatus.value,
        );

        ref.listenManual(createBookCopyProvider(bookCopy), (previous, next) {
          next.whenOrNull(
            data: (_) {
              context.maybePop();
              context.showSuccess('Thêm quyển sách thành công');
            },
            error: (error, stackTrace) {
              context.showError('Lỗi khi thêm quyển sách: ${error.toString()}');
            },
          );
        });
      },
      [
        bookCopyIdController.text,
        isbnController.text,
        selectedStatus.value,
        currentSite,
      ],
    );

    return AlertDialog(
      title: const Text('Thêm quyển sách mới'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Book Copy ID
              AppTextField(
                context,
                controller: bookCopyIdController,
                labelText: 'Mã quyển sách *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mã quyển sách không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ISBN
              AppTextField(
                context,
                controller: isbnController,
                labelText: 'ISBN *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ISBN không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Branch Site (read-only, auto-set based on user's branch)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Chi nhánh',
                  border: OutlineInputBorder(),
                ),
                initialValue: currentSite.text,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<BookStatus>(
                value: selectedStatus.value,
                decoration: const InputDecoration(
                  labelText: 'Tình trạng',
                  border: OutlineInputBorder(),
                ),
                items: BookStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.text),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedStatus.value = value;
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.maybePop(),
          child: const Text('Hủy'),
        ),
        AppButton(
          label: 'Thêm',
          onPressed: onCreateBookCopy,
          backgroundColor: context.primaryColor,
        ),
      ],
    );
  }
}
