import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/book_copies/providers/book_copies_provider.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Dialog for creating new book copies - FR9 Implementation
/// Only THUTHU can create book copies at their site
class BookCopyCreateDialog extends ConsumerStatefulWidget {
  const BookCopyCreateDialog({super.key});

  @override
  ConsumerState<BookCopyCreateDialog> createState() =>
      _BookCopyCreateDialogState();
}

class _BookCopyCreateDialogState extends ConsumerState<BookCopyCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bookCopyIdController = TextEditingController();
  final _isbnController = TextEditingController();

  BookStatus _selectedStatus = BookStatus.available;
  bool _isLoading = false;

  @override
  void dispose() {
    _bookCopyIdController.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSite = ref.watch(librarySiteProvider);

    return AlertDialog(
      title: const Text('Thêm quyển sách mới'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Book Copy ID
              AppTextField(
                context,
                controller: _bookCopyIdController,
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
                controller: _isbnController,
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
                value: _selectedStatus,
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
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => context.maybePop(),
          child: const Text('Hủy'),
        ),
        AppButton(
          label: 'Thêm',
          onPressed: _isLoading ? null : _createBookCopy,
          backgroundColor: context.primaryColor,
        ),
      ],
    );
  }

  Future<void> _createBookCopy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentSite = ref.read(librarySiteProvider);

      // Create book copy entity with auto-assigned branch site
      final bookCopy = BookCopyEntity(
        bookCopyId: _bookCopyIdController.text.trim(),
        isbn: _isbnController.text.trim(),
        branchSite: currentSite, // FR9: Auto-assign to current user's site
        status: _selectedStatus,
      );

      // Call create provider
      await ref.read(createBookCopyProvider(bookCopy).future);

      if (mounted) {
        context.maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm quyển sách thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm quyển sách: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
