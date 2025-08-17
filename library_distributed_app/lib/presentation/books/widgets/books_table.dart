import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/async_value_extension.dart';
import 'package:library_distributed_app/core/extensions/context_extension.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/books/providers/books_provider.dart';
import 'package:library_distributed_app/presentation/books/widgets/book_edit_dialog.dart';
import 'package:library_distributed_app/core/widgets/app_pagination_controls.dart';
import 'package:library_distributed_app/core/widgets/app_table.dart';

/// Books Table Widget - Supports FR7 and FR10
/// Displays books with availability information
/// Role-based operations: QUANLY can edit/delete, THUTHU can only view
class BookTable extends ConsumerWidget {
  const BookTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(getUserInfoProvider);

    return userInfoAsync.when(
      data: (userInfo) => _buildTable(context, ref, userInfo),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Lỗi: $error')),
    );
  }

  Widget _buildTable(
    BuildContext context,
    WidgetRef ref,
    UserInfoEntity userInfo,
  ) {
    return ref.watch(booksProvider).whenDataOrPreviousWidget((data) {
      final items = data.items;
      final paging = data.paging;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppTable.build(
            context,
            columnWidths: userInfo.role == UserRole.manager
                ? const [1, 2, 4, 3, 2, 2] // With actions for manager
                : const [1, 2, 4, 3, 2], // Without actions for librarian
            titles: [
              '#',
              'Mã ISBN',
              'Tên sách',
              'Tác giả',
              'Trạng thái',
              if (userInfo.role == UserRole.manager) 'Hành động',
            ],
            rows: items
                .map(
                  (item) => _buildRow(
                    context,
                    ref,
                    userInfo,
                    index:
                        items.indexOf(item) +
                        paging.currentPage * paging.pageSize,
                    item: item,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          AppPaginationControls(
            paging,
            onPageChanged: (page) {
              final searchQuery = ref.read(booksSearchProvider);
              ref
                  .read(booksProvider.notifier)
                  .fetchData(page, searchQuery.isEmpty ? null : searchQuery);
            },
          ),
        ],
      );
    });
  }

  TableRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    UserInfoEntity userInfo, {
    required int index,
    required item,
  }) {
    final children = [
      AppTable.buildTextCell(context, text: (index + 1).toString()),
      AppTable.buildTextCell(context, text: item.isbn),
      AppTable.buildTextCell(context, text: item.title),
      AppTable.buildTextCell(context, text: item.author),
      AppTable.buildTextCell(
        context,
        text: 'Khả dụng',
      ), // For now, show available
    ];

    // Add action buttons only for managers (FR10)
    if (userInfo.role == UserRole.manager) {
      children.add(
        AppTable.buildWidgetCell(
          context,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: () => _showEditDialog(context, ref, item),
                tooltip: 'Chỉnh sửa đầu sách',
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 20),
                color: context.errorColor,
                onPressed: () => _showDeleteConfirmation(context, ref, item),
                tooltip: 'Xóa đầu sách',
              ),
            ],
          ),
        ),
      );
    }

    return TableRow(children: children);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, item) {
    BookEditDialog(book: item).showAsDialog(context);
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, item) {
    context.showDialog((context) {
      return AlertDialog(
        title: const Text('Xác nhận xóa đầu sách'),
        content: Text(
          'Bạn có chắc chắn muốn xóa đầu sách "${item.title}"?\n\n'
          'Thao tác này sẽ được thực hiện trên toàn hệ thống và không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: context.maybePop,
            child: Text('Hủy', style: context.bodyLarge),
          ),
          TextButton(
            onPressed: () async {
              context.maybePop();
              try {
                await ref.read(deleteBookProvider(item.isbn).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa đầu sách thành công')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa đầu sách: $e')),
                  );
                }
              }
            },
            child: Text(
              'Xóa',
              style: context.bodyLarge.copyWith(color: context.errorColor),
            ),
          ),
        ],
      );
    });
  }
}
