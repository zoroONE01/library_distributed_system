import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/domain/entities/book_transfer.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/book_transfer/providers/book_transfer_provider.dart';
import 'package:library_distributed_app/presentation/book_transfer/book_transfer_dialog.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_scaffold.dart';
import 'package:library_distributed_app/core/widgets/app_table.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Book Transfer Page - Dedicated page for book transfer operations
/// Only accessible to QUANLY (Manager) role for transferring books between sites using 2PC protocol
class BookTransferPage extends ConsumerStatefulWidget {
  const BookTransferPage({super.key});

  @override
  ConsumerState<BookTransferPage> createState() => _BookTransferPageState();
}

class _BookTransferPageState extends ConsumerState<BookTransferPage> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoAsync = ref.watch(getUserInfoProvider);

    return userInfoAsync.when(
      data: (userInfo) => _buildPage(context, userInfo),
      loading: () =>
          const AppScaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          AppScaffold(body: Center(child: Text('Lỗi: $error'))),
    );
  }

  Widget _buildPage(BuildContext context, UserInfoEntity userInfo) {
    // Only QUANLY can access this page
    if (userInfo.role != UserRole.manager) {
      return AppScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 64,
                color: context.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Chỉ Quản lý mới có quyền truy cập trang này',
                style: context.headlineSmall.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn cần quyền Quản lý để thực hiện chuyển sách giữa các site',
                style: context.bodyMedium.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [_buildHeader(context), _buildContent(context)],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Expanded(
          child:
              Text(
                'Quản lý chuyển sách giữa các site',
                style: context.headlineSmall.bold,
                overflow: TextOverflow.ellipsis,
              ).withIcon(
                Icons.transfer_within_a_station_rounded,
                iconColor: context.primaryColor,
              ),
        ),
        AppButton(
          label: 'Chuyển sách mới',
          icon: const Icon(Icons.add_circle_rounded, size: 20),
          onPressed: () => _showTransferDialog(context),
          backgroundColor: context.primaryColor,
        ),
      ],
    ).wrapByCard(context);
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 20,
      children: [
        _buildSearchRow(context),
        _buildTransferableBooksList(context),
      ],
    ).wrapByCard(context);
  }

  Widget _buildSearchRow(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  context,
                  controller: _searchController,
                  labelText:
                      'Tìm kiếm sách có thể chuyển (theo tên sách, ISBN)',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  onChanged: (value) {
                    // Cancel previous timer
                    _debounceTimer?.cancel();
                    
                    // Set new timer for debounced search
                    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value && value.isNotEmpty) {
                        ref
                            .read(transferableBookCopiesProvider.notifier)
                            .search(value);
                      } else if (value.isEmpty) {
                        ref.read(transferableBookCopiesProvider.notifier).clear();
                      }
                    });
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _debounceTimer?.cancel();
                    ref.read(transferableBookCopiesProvider.notifier).clear();
                  },
                ),
              ],
            ],
          ),
        ),
        AppButton(
          label: 'Làm mới',
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () {
            _searchController.clear();
            _debounceTimer?.cancel();
            ref.read(transferableBookCopiesProvider.notifier).clear();
          },
          shadowColor: Colors.transparent,
          backgroundColor: context.onSurface.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  Widget _buildTransferableBooksList(BuildContext context) {
    final transferableBooksAsync = ref.watch(transferableBookCopiesProvider);

    return Column(
      children: [
        transferableBooksAsync.when(
          data: (books) => _buildBooksTable(context, books),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Lỗi: $error')),
        ),
      ],
    );
  }

  Widget _buildBooksTable(
    BuildContext context,
    List<BookCopyTransferInfoEntity> books,
  ) {
    if (books.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.book_outlined,
                size: 48,
                color: context.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy sách có thể chuyển',
                style: context.bodyLarge.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tìm kiếm với từ khóa khác hoặc kiểm tra lại dữ liệu',
                style: context.bodyMedium.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final titles = [
      'ISBN',
      'Tên sách',
      'Site hiện tại',
      'Trạng thái',
      'Thao tác',
    ];

    final rows = books
        .map((book) => _buildBookTableRow(context, book))
        .toList();

    return AppTable.build(
      context,
      titles: titles,
      rows: rows,
      columnWidths: const [1.2, 2.5, 1.0, 1.5, 1.0],
    );
  }

  TableRow _buildBookTableRow(
    BuildContext context,
    BookCopyTransferInfoEntity book,
  ) {
    return TableRow(
      children: [
        AppTable.buildTextCell(context, text: book.isbn),
        AppTable.buildTextCell(context, text: book.bookTitle),
        AppTable.buildWidgetCell(
          context,
          child: _buildSiteChip(context, book.currentSite),
        ),
        AppTable.buildTextCell(context, text: book.status),
        AppTable.buildWidgetCell(
          context,
          child: _buildTransferButton(context, book),
        ),
      ],
    );
  }

  Widget _buildSiteChip(BuildContext context, Site site) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: site == Site.q1
            ? context.primaryContainer
            : context.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        site.text,
        style: context.bodySmall.copyWith(
          color: site == Site.q1
              ? context.onPrimaryContainer
              : context.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTransferButton(
    BuildContext context,
    BookCopyTransferInfoEntity book,
  ) {
    return AppButton(
      label: 'Chuyển',
      icon: const Icon(Icons.transfer_within_a_station_rounded, size: 16),
      onPressed: () => _showTransferDialog(context, preSelectedBook: book),
      backgroundColor: context.primaryContainer,
      shadowColor: Colors.transparent,
    );
  }

  void _showTransferDialog(
    BuildContext context, {
    BookCopyTransferInfoEntity? preSelectedBook,
  }) {
    const BookTransferDialog().showAsDialog(context).then((result) {
      if (result != null) {
        // Refresh the list after transfer
        ref.read(transferableBookCopiesProvider.notifier).clear();
      }
    });
  }
}
