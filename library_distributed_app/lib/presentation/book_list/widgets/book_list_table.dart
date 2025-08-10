import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/extensions/async_value_extension.dart';
import 'package:library_distributed_app/core/extensions/context_extension.dart';
import 'package:library_distributed_app/core/extensions/router_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/presentation/book_list/book_provider.dart';
import 'package:library_distributed_app/presentation/book_list/widgets/book_list_editor_book_dialog.dart';
import 'package:library_distributed_app/presentation/widgets/app_pagination_controls.dart';
import 'package:library_distributed_app/presentation/widgets/app_table.dart';

class BookListTable extends ConsumerWidget {
  const BookListTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(bookListProvider).whenDataOrPreviousWidget((data) {
      final items = data.items;
      final paging = data.paging;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 10,
        children: [
          AppTable.build(
            context,
            columnWidths: const [1, 3, 5, 2, 1, 1],
            titles: const [
              '#',
              'Mã sách',
              'Tên sách',
              'Tác giả',
              'Số lượng',
              'Hành động',
            ],
            rows: items
                .map(
                  (item) => _buildRow(
                    context,
                    index: items.indexOf(item) + paging.page * paging.size,
                    id: item.id,
                    title: item.title,
                    author: item.author,
                    quantity: item.totalCount,
                    onEdit: () {
                      BookListEditor(bookId: item.id).showAsDialog(context);
                    },
                    onDelete: () {
                      context.showDialog((context) {
                        return AlertDialog(
                          title: const Text('Xác nhận xóa sách'),
                          content: const Text(
                            'Bạn có chắc chắn muốn xóa sách này?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: context.maybePop,
                              child: Text('Hủy', style: context.bodyLarge),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(deleteBookProvider(item.id));
                              },
                              child: Text('Xóa', style: context.bodyLarge),
                            ),
                          ],
                        );
                      });
                    },
                  ),
                )
                .toList(),
          ),
          AppPaginationControls(
            paging,
            onPageChanged: (page) {
              ref
                  .read(bookListProvider.notifier)
                  .fetchData(paging.copyWith(page: page));
            },
          ),
        ],
      );
    });
  }

  TableRow _buildRow(
    BuildContext context, {
    int index = 0,
    String id = '001',
    String title =
        'Flutter for Beginners - A Comprehensive Guide to Mobile App Development',
    String author = 'John Doe',
    int quantity = 10,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return TableRow(
      children: [
        AppTable.buildTextCell(context, text: (index + 1).toString()),
        AppTable.buildTextCell(context, text: id),
        AppTable.buildTextCell(context, text: title),
        AppTable.buildTextCell(context, text: author),
        AppTable.buildTextCell(context, text: quantity.toString()),
        AppTable.buildWidgetCell(
          context,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 20),
                color: context.errorColor,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
