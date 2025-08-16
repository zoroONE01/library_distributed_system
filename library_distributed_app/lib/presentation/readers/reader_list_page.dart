import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';
import 'package:library_distributed_app/presentation/widgets/app_button.dart';
import 'package:library_distributed_app/presentation/widgets/app_pagination_controls.dart';
import 'package:library_distributed_app/presentation/widgets/app_scaffold.dart';
import 'package:library_distributed_app/presentation/widgets/app_table.dart';
import 'package:library_distributed_app/presentation/widgets/app_text_field.dart';

class ReaderListPage extends StatelessWidget {
  const ReaderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Expanded(
                child: Text(
                  'Danh sách cách đầu sách - Chi nhánh Quận 1',
                  style: context.headlineSmall.bold,
                  overflow: TextOverflow.ellipsis,
                ).withIcon(Icons.book_rounded, iconColor: context.primaryColor),
              ),
              AppButton(
                label: 'Thêm sách mới',
                icon: const Icon(Icons.add_rounded, size: 20),
                onPressed: () {},
                backgroundColor: context.primaryColor,
              ),
            ],
          ).wrapByCard(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 20,
            children: [
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: AppTextField(
                      context,
                      labelText: 'Tìm kiếm sách',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    ),
                  ),
                  AppButton(
                    label: 'Sắp xếp',
                    icon: const Icon(Icons.sort_rounded, size: 20),
                    onPressed: () {},
                    shadowColor: Colors.transparent,
                    backgroundColor: context.onSurface.withValues(alpha: 0.2),
                  ),
                  AppButton(
                    label: 'Làm mới',
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: () {},
                    shadowColor: Colors.transparent,
                    backgroundColor: context.onSurface.withValues(alpha: 0.2),
                  ),
                ],
              ),
              AppTable.build(
                context,
                columnWidths: const [1, 5, 2, 1, 1],
                titles: [
                  'Mã sách',
                  'Tên sách',
                  'Tác giả',
                  'Số lượng',
                  'Hành động',
                ],
                rows: List.generate(
                  10,
                  (index) => _buildRow(context, onEdit: () {}, onDelete: () {}),
                ),
              ),
              AppPaginationControls(
                const PagingEntity(),
                onPageChanged: (page) {},
              ),
            ],
          ).wrapByCard(context),
        ],
      ),
    );
  }

  TableRow _buildRow(
    BuildContext context, {
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
