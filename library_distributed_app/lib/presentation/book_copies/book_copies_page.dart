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
import 'package:library_distributed_app/presentation/book_copies/providers/book_copies_provider.dart';
import 'package:library_distributed_app/presentation/book_copies/widgets/book_copies_table.dart';
import 'package:library_distributed_app/presentation/book_copies/widgets/book_copies_create_dialog.dart';
import 'package:library_distributed_app/presentation/shared/book_list_sort_dialog.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_scaffold.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Book Copies Page - FR9 Implementation
/// Supports role-based access control:
/// - THUTHU: Only sees book copies from their branch
/// - QUANLY: Sees book copies from all branches (system-wide view)
class BookCopiesPage extends ConsumerWidget {
  const BookCopiesPage({super.key});

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
                // FR9: Only THUTHU can create book copies at their site
                if (userInfo.role == UserRole.librarian)
                  AppButton(
                    label: 'Thêm quyển sách mới',
                    icon: const Icon(Icons.add_rounded, size: 20),
                    onPressed: () {
                      _showCreateBookCopyDialog(context, ref);
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
                Flexible(child: BookCopiesTable()),
              ],
            ).wrapByCard(context),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }

  void _showCreateBookCopyDialog(BuildContext context, WidgetRef ref) {
    const BookCopyCreateDialog().showAsDialog(context);
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
        ? 'Quản lý quyển sách - Chi nhánh ${branch.text}'
        : 'Danh sách quyển sách - Toàn hệ thống';

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
            labelText: 'Tìm kiếm quyển sách',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            onChanged: (value) {
              ref.read(bookCopiesSearchProvider.notifier).state = value;
              ref
                  .read(bookCopiesProvider.notifier)
                  .fetchData(0, value.isEmpty ? null : value);
            },
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
          onPressed: () => ref.read(bookCopiesProvider.notifier).refresh(),
          shadowColor: Colors.transparent,
          backgroundColor: context.onSurface.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}
