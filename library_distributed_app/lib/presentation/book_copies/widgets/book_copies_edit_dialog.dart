import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/presentation/book_copies/providers/book_copies_provider.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Dialog for editing book copies - FR9 Implementation
/// Only THUTHU can edit book copies at their site
class BookCopyEditDialog extends ConsumerStatefulWidget {
  const BookCopyEditDialog({super.key, required this.bookCopy});

  final BookCopyEntity bookCopy;

  @override
  ConsumerState<BookCopyEditDialog> createState() => _BookCopyEditDialogState();
}

class _BookCopyEditDialogState extends ConsumerState<BookCopyEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _isbnController = TextEditingController();

  late BookStatus _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isbnController.text = widget.bookCopy.isbn;
    _selectedStatus = widget.bookCopy.status;
  }

  @override
  void dispose() {
    _isbnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa quyển sách'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Book Copy ID (read-only)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Mã quyển sách',
                  border: OutlineInputBorder(),
                ),
                initialValue: widget.bookCopy.bookCopyId,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // ISBN (editable)
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

              // Branch Site (read-only)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Chi nhánh',
                  border: OutlineInputBorder(),
                ),
                initialValue: widget.bookCopy.branchSite.text,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Status (editable)
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
          label: 'Cập nhật',
          onPressed: _isLoading ? null : _updateBookCopy,
          backgroundColor: context.primaryColor,
        ),
      ],
    );
  }

  Future<void> _updateBookCopy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated book copy entity
      final updatedBookCopy = BookCopyEntity(
        bookCopyId: widget.bookCopy.bookCopyId,
        isbn: _isbnController.text.trim(),
        branchSite: widget.bookCopy.branchSite,
        status: _selectedStatus,
      );

      // Call update provider
      await ref.read(
        updateBookCopyProvider((
          bookCopyId: widget.bookCopy.bookCopyId,
          bookCopy: updatedBookCopy,
        )).future,
      );

      if (mounted) {
        context.maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật quyển sách thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật quyển sách: $e'),
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
