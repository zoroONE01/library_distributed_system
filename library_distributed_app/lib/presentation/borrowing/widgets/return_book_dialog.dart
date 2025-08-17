import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/domain/entities/borrow_record.dart';
import 'package:library_distributed_app/presentation/borrowing/providers/borrowing_provider.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Dialog for returning a book - FR3 Implementation
class ReturnBookDialog extends ConsumerStatefulWidget {
  final BorrowRecordWithDetailsEntity record;

  const ReturnBookDialog({
    super.key,
    required this.record,
  });

  @override
  ConsumerState<ReturnBookDialog> createState() => _ReturnBookDialogState();
}

class _ReturnBookDialogState extends ConsumerState<ReturnBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận trả sách'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookInfo(context),
              const SizedBox(height: 16),
              AppTextField(
                context,
                controller: _noteController,
                labelText: 'Ghi chú (tùy chọn)',
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
          label: _isLoading ? 'Đang xử lý...' : 'Xác nhận trả',
          icon: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.assignment_return_rounded, size: 16),
          onPressed: _isLoading ? null : _handleReturn,
          backgroundColor: context.primaryColor,
        ),
      ],
    );
  }

  Widget _buildBookInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin sách',
            style: context.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Mã phiếu mượn:', widget.record.borrowId.toString()),
          _buildInfoRow('Độc giả:', '${widget.record.readerId} - ${widget.record.readerName}'),
          _buildInfoRow('Sách:', '${widget.record.bookIsbn} - ${widget.record.bookTitle}'),
          _buildInfoRow('Tác giả:', widget.record.bookAuthor),
          _buildInfoRow('Ngày mượn:', widget.record.borrowDate),
          _buildInfoRow('Ngày hẹn trả:', widget.record.dueDate),
          if (widget.record.isOverdue) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sách đã quá hạn ${widget.record.daysOverdue} ngày',
                style: context.bodySmall.copyWith(
                  color: context.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: context.bodySmall.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReturn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(returnBookProvider((
        borrowId: widget.record.borrowId,
        bookCopyId: widget.record.bookCopyId,
      )).future);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trả sách thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi trả sách: $e'),
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
