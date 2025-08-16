import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/books/providers/books_provider.dart';
import 'package:library_distributed_app/presentation/books/widgets/books_table.dart';
import 'package:library_distributed_app/presentation/books/widgets/book_list_create_book_dialog.dart';
import 'package:library_distributed_app/presentation/books/widgets/book_list_sort_dialog.dart';
import 'package:library_distributed_app/presentation/widgets/app_button.dart';
import 'package:library_distributed_app/presentation/widgets/app_scaffold.dart';
import 'package:library_distributed_app/presentation/widgets/app_text_field.dart';

class BookCopiesPage extends ConsumerWidget {
  const BookCopiesPage({super.key});

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
              const Expanded(child: _Header()),
              AppButton(
                label: 'Thêm sách mới',
                icon: const Icon(Icons.add_rounded, size: 20),
                onPressed: () {
                  const BookListCreateBookDialog().showAsDialog(context);
                },
                backgroundColor: context.primaryColor,
              ),
            ],
          ).wrapByCard(context),
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 20,
            children: [
              ToolBar(),
              Flexible(child: BookTable()),
            ],
          ).wrapByCard(context),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(librarySiteProvider);
    return Text(
      'Danh sách cách đầu sách - Chi nhánh ${branch.text}',
      style: context.headlineSmall.bold,
      overflow: TextOverflow.ellipsis,
    ).withIcon(Icons.book_rounded, iconColor: context.primaryColor);
  }
}

class ToolBar extends ConsumerWidget {
  const ToolBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
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
          onPressed: ref.read(booksProvider.notifier).fetchData,
          shadowColor: Colors.transparent,
          backgroundColor: context.onSurface.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}
