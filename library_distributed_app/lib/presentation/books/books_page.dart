import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/books/providers/books_provider.dart';
import 'package:library_distributed_app/presentation/books/widgets/books_table.dart';
import 'package:library_distributed_app/presentation/books/widgets/book_list_create_book_dialog.dart';
import 'package:library_distributed_app/presentation/books/widgets/book_search_results.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_scaffold.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Books Page - FR7 and FR10 Implementation
/// Supports role-based access control:
/// - THUTHU: Manages books with availability view for their branch
/// - QUANLY: System-wide book management with CRUD operations (2PC)
class BooksPage extends ConsumerWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch user info for role-based UI
    final userInfoAsync = ref.watch(getUserInfoProvider);

    return AppScaffold(
      body: userInfoAsync.when(
        data: (userInfo) => Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Expanded(child: _Header(userInfo: userInfo)),
                // FR10: Only QUANLY can create/modify books (uses 2PC)
                if (userInfo.role == UserRole.manager)
                  AppButton(
                    label: 'Thêm đầu sách mới',
                    icon: const Icon(Icons.add_rounded, size: 20),
                    onPressed: () {
                      _showCreateBookDialog(context, ref);
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
                Flexible(child: _BookContent()),
              ],
            ).wrapByCard(context),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }

  void _showCreateBookDialog(BuildContext context, WidgetRef ref) {
    const BookListCreateBookDialog().showAsDialog(context);
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.userInfo});

  final UserInfoEntity userInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(librarySiteProvider);

    // Display different titles based on user role
    final title = userInfo.role == UserRole.librarian
        ? 'Danh sách đầu sách - Chi nhánh ${branch.text}'
        : 'Quản lý đầu sách - Toàn hệ thống';

    return Text(
      title,
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
            labelText: 'Tìm kiếm sách (FR7: tìm kiếm toàn hệ thống)',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            onChanged: (value) {
              ref.read(booksSearchProvider.notifier).state = value;
              ref
                  .read(booksProvider.notifier)
                  .fetchData(0, value.isEmpty ? null : value);
            },
          ),
        ),
        AppButton(
          label: 'Sắp xếp',
          icon: const Icon(Icons.sort_rounded, size: 20),
          onPressed: () {
            // Note: Will implement sort dialog later
          },
          shadowColor: Colors.transparent,
          backgroundColor: context.onSurface.withValues(alpha: 0.2),
        ),
        AppButton(
          label: 'Làm mới',
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () => ref.read(booksProvider.notifier).refresh(),
          shadowColor: Colors.transparent,
          backgroundColor: context.onSurface.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}

/// Content widget that switches between normal table view and search results
class _BookContent extends ConsumerWidget {
  const _BookContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(booksSearchProvider);
    
    // Show search results when there's a search query, otherwise show normal table
    if (searchQuery.isNotEmpty) {
      return BookSearchResults(searchQuery: searchQuery);
    } else {
      return const BookTable();
    }
  }
}
