import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/book_list/book_list_provider.dart';
import 'package:library_distributed_app/presentation/book_list/widgets/book_list_editor.dart';
import 'package:library_distributed_app/presentation/book_list/widgets/book_list_sort_dialog.dart';
import 'package:library_distributed_app/presentation/book_list/widgets/book_list_table.dart';
import 'package:library_distributed_app/presentation/widgets/app_button.dart';
import 'package:library_distributed_app/presentation/widgets/app_scaffold.dart';
import 'package:library_distributed_app/presentation/widgets/app_text_field.dart';

class BookListPage extends ConsumerWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: Consumer(
                  builder: (context, ref, child) {
                    final branch = ref.watch(librarySiteProvider);
                    return Text(
                      'Danh sách cách đầu sách - Chi nhánh ${branch.text}',
                      style: context.headlineSmall.bold,
                      overflow: TextOverflow.ellipsis,
                    ).withIcon(
                      Icons.book_rounded,
                      iconColor: context.primaryColor,
                    );
                  },
                ),
              ),
              AppButton(
                label: 'Thêm sách mới',
                icon: const Icon(Icons.add_rounded, size: 20),
                onPressed: () {
                  const BookListEditor().showAsDialog(context);
                },
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
                    onPressed: () {
                      const BookListSortDialog().showAsDialog(context);
                    },
                    shadowColor: Colors.transparent,
                    backgroundColor: context.onSurface.withValues(alpha: 0.2),
                  ),
                  AppButton(
                    label: 'Làm mới',
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: ref.read(bookListProvider.notifier).refresh,
                    shadowColor: Colors.transparent,
                    backgroundColor: context.onSurface.withValues(alpha: 0.2),
                  ),
                ],
              ),
              const BookListTable(),
            ],
          ).wrapByCard(context),
        ],
      ),
    );
  }
}
