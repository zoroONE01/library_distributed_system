import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/domain/entities/borrow_record.dart';
import 'package:library_distributed_app/presentation/borrowing/providers/borrowing_provider.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Dialog for creating new borrow record - FR2 Implementation
class BorrowCreateDialog extends ConsumerStatefulWidget {
  const BorrowCreateDialog({super.key});

  @override
  ConsumerState<BorrowCreateDialog> createState() => _BorrowCreateDialogState();
}

class _BorrowCreateDialogState extends ConsumerState<BorrowCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _readerIdController = TextEditingController();
  final _bookCopyIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _readerIdController.dispose();
    _bookCopyIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lập phiếu mượn sách'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vui lòng nhập thông tin để tạo phiếu mượn mới',
                style: context.bodyMedium.copyWith(color: context.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              AppTextField(
                context,
                controller: _readerIdController,
                labelText: 'Mã độc giả',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã độc giả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                context,
                controller: _bookCopyIdController,
                labelText: 'Mã bản sao sách',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã bản sao sách';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: context.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hệ thống sẽ tự động kiểm tra tính hợp lệ của độc giả và sách',
                        style: context.bodySmall.copyWith(
                          color: context.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Hủy',
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        AppButton(
          label: _isLoading ? 'Đang xử lý...' : 'Tạo phiếu mượn',
          icon: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_circle_rounded, size: 16),
          onPressed: _isLoading ? null : _handleCreate,
          backgroundColor: context.primaryColor,
        ),
      ],
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if reader has active borrows first
      final hasActiveBorrows = await ref.read(hasActiveReaderBorrowsProvider(_readerIdController.text.trim()).future);
      if (hasActiveBorrows) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Độc giả này đang có sách chưa trả. Vui lòng trả sách trước khi mượn sách mới.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check if book copy is already borrowed
      final isBorrowed = await ref.read(isBookCopyBorrowedProvider(_bookCopyIdController.text.trim()).future);
      if (isBorrowed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bản sao sách này đã được mượn. Vui lòng chọn bản sao khác.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create borrow record
      final request = CreateBorrowRequestEntity(
        readerId: _readerIdController.text.trim(),
        bookCopyId: _bookCopyIdController.text.trim(),
      );

      await ref.read(createBorrowRecordProvider(request).future);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lập phiếu mượn thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lập phiếu mượn: $e'),
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
