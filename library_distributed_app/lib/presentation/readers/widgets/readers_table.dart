import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/async_value_extension.dart';
import 'package:library_distributed_app/core/extensions/context_extension.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/domain/entities/reader.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/readers/providers/readers_provider.dart';
import 'package:library_distributed_app/presentation/readers/widgets/reader_edit_dialog.dart';
import 'package:library_distributed_app/core/widgets/app_pagination_controls.dart';
import 'package:library_distributed_app/core/widgets/app_table.dart';

/// Readers Table Widget - Supports FR8 and FR11
/// Displays readers based on user role
/// Role-based operations: THUTHU can CRUD at their site, QUANLY can view system-wide
class ReadersTable extends ConsumerWidget {
  const ReadersTable({super.key});

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
    return ref.watch(readersProvider).whenDataOrPreviousWidget((data) {
      final items = data.items;
      final paging = data.paging;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppTable.build(
            context,
            columnWidths: userInfo.role == UserRole.librarian
                ? const [1, 2, 4, 3, 2] // With actions for librarian at their site
                : const [1, 2, 4, 3], // Without actions for manager (view only)
            titles: [
              '#',
              'Mã độc giả',
              'Họ và tên',
              'Chi nhánh đăng ký',
              if (userInfo.role == UserRole.librarian) 'Hành động',
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
              final searchQuery = ref.read(readersSearchProvider);
              ref
                  .read(readersProvider.notifier)
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
    required ReaderEntity item,
  }) {
    final children = [
      AppTable.buildTextCell(context, text: (index + 1).toString()),
      AppTable.buildTextCell(context, text: item.readerId),
      AppTable.buildTextCell(context, text: item.fullName),
      AppTable.buildTextCell(
        context,
        text: item.registrationSite.text,
      ),
    ];

    // Add action buttons only for librarians at their own site (FR8)
    if (userInfo.role == UserRole.librarian) {
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
                tooltip: 'Chỉnh sửa thông tin độc giả',
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 20),
                color: context.errorColor,
                onPressed: () => _showDeleteConfirmation(context, ref, item),
                tooltip: 'Xóa độc giả',
              ),
            ],
          ),
        ),
      );
    }

    return TableRow(children: children);
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ReaderEntity reader) {
    ReaderEditDialog(reader: reader).showAsDialog(context).then((result) {
      if (result != null) {
        // Refresh the list after edit
        ref.read(readersProvider.notifier).refresh();
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, ReaderEntity reader) {
    context.showDialog((context) {
      return AlertDialog(
        title: const Text('Xác nhận xóa độc giả'),
        content: Text(
          'Bạn có chắc chắn muốn xóa độc giả "${reader.fullName}" (${reader.readerId})?\n\n'
          'Chỉ có thể xóa khi độc giả không có phiếu mượn đang hoạt động.',
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
                await ref.read(deleteReaderProvider(reader.readerId).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa độc giả thành công')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi xóa độc giả: $e')),
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
