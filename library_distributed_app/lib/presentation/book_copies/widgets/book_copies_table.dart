import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/async_value_extension.dart';
import 'package:library_distributed_app/core/extensions/context_extension.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/domain/entities/book_copy.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/book_copies/providers/book_copies_provider.dart';
import 'package:library_distributed_app/presentation/book_copies/widgets/book_copies_edit_dialog.dart';
import 'package:library_distributed_app/core/widgets/app_pagination_controls.dart';
import 'package:library_distributed_app/core/widgets/app_table.dart';

/// Book Copies Table - FR9 Implementation
/// Shows book copies with role-based access control:
/// - THUTHU: Only their branch's book copies
/// - QUANLY: All book copies system-wide
class BookCopiesTable extends ConsumerWidget {
  const BookCopiesTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(getUserInfoProvider);

    return userInfoAsync.when(
      data: (userInfo) =>
          ref.watch(bookCopiesProvider).whenDataOrPreviousWidget((data) {
            final items = data.items;
            final paging = data.paging;
            final isThuthu = userInfo.role == UserRole.librarian;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppTable.build(
                  context,
                  columnWidths: const [1, 2, 3, 2, 2, 2, 1],
                  titles: const [
                    '#',
                    'Mã quyển sách',
                    'ISBN',
                    'Chi nhánh',
                    'Tình trạng',
                    'Thao tác',
                  ],
                  rows: items
                      .asMap()
                      .entries
                      .map(
                        (entry) => _buildRow(
                          context,
                          ref,
                          index:
                              entry.key +
                              1 +
                              (paging.currentPage * paging.pageSize),
                          bookCopy: entry.value,
                          canEdit: isThuthu, // FR9: Only THUTHU can edit/delete
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                AppPaginationControls(
                  paging,
                  onPageChanged: (page) =>
                      ref.read(bookCopiesProvider.notifier).fetchData(page),
                ),
              ],
            );
          }),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Lỗi: $error')),
    );
  }

  TableRow _buildRow(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required BookCopyEntity bookCopy,
    required bool canEdit,
  }) {
    return TableRow(
      children: [
        AppTable.buildTextCell(context, text: index.toString()),
        AppTable.buildTextCell(context, text: bookCopy.bookCopyId),
        AppTable.buildTextCell(context, text: bookCopy.isbn),
        AppTable.buildTextCell(context, text: bookCopy.branchSite.text),
        AppTable.buildWidgetCell(
          context,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(bookCopy.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              bookCopy.status.text,
              style: context.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AppTable.buildWidgetCell(
          context,
          child: canEdit
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () => _showEditDialog(context, ref, bookCopy),
                      tooltip: 'Chỉnh sửa',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, size: 18),
                      color: context.errorColor,
                      onPressed: () =>
                          _showDeleteDialog(context, ref, bookCopy),
                      tooltip: 'Xóa',
                    ),
                  ],
                )
              : const Text('N/A'), // QUANLY can only view, not edit
        ),
      ],
    );
  }

  Color _getStatusColor(BookStatus status) {
    switch (status) {
      case BookStatus.available:
        return Colors.green;
      case BookStatus.borrowed:
        return Colors.orange;
      case BookStatus.damaged:
        return Colors.red;
    }
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    BookCopyEntity bookCopy,
  ) {
    showDialog(
      context: context,
      builder: (context) => BookCopyEditDialog(bookCopy: bookCopy),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    BookCopyEntity bookCopy,
  ) {
    context.showDialog((context) {
      return AlertDialog(
        title: const Text('Xác nhận xóa quyển sách'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn xóa quyển sách này?'),
            const SizedBox(height: 8),
            Text('Mã: ${bookCopy.bookCopyId}', style: context.bodySmall),
            Text('ISBN: ${bookCopy.isbn}', style: context.bodySmall),
            const SizedBox(height: 8),
            if (bookCopy.status != BookStatus.available)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lưu ý: Quyển sách hiện đang có tình trạng "${bookCopy.status.text}". '
                  'Chỉ có thể xóa quyển sách khi ở trạng thái "Có sẵn".',
                  style: context.bodySmall.copyWith(color: Colors.orange[800]),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: context.maybePop,
            child: Text('Hủy', style: context.bodyLarge),
          ),
          TextButton(
            onPressed: bookCopy.status == BookStatus.available
                ? () {
                    context.maybePop();
                    _deleteBookCopy(context, ref, bookCopy.bookCopyId);
                  }
                : null,
            child: Text(
              'Xóa',
              style: context.bodyLarge.copyWith(
                color: bookCopy.status == BookStatus.available
                    ? context.errorColor
                    : context.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _deleteBookCopy(
    BuildContext context,
    WidgetRef ref,
    String bookCopyId,
  ) async {
    try {
      await ref.read(deleteBookCopyProvider(bookCopyId).future);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa quyển sách thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa quyển sách: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
