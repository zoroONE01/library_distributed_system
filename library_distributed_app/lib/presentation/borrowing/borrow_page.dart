import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';
import 'package:library_distributed_app/core/extensions/widget_extension.dart';
import 'package:library_distributed_app/core/utils/app_utils.dart';
import 'package:library_distributed_app/domain/entities/borrow_record.dart';
import 'package:library_distributed_app/domain/entities/user_info.dart';
import 'package:library_distributed_app/presentation/app/app_provider.dart';
import 'package:library_distributed_app/presentation/auth/auth_provider.dart';
import 'package:library_distributed_app/presentation/borrowing/providers/borrowing_provider.dart';
import 'package:library_distributed_app/presentation/borrowing/widgets/borrow_create_dialog.dart';
import 'package:library_distributed_app/presentation/borrowing/widgets/return_book_dialog.dart';
import 'package:library_distributed_app/core/widgets/app_button.dart';
import 'package:library_distributed_app/core/widgets/app_pagination.dart';
import 'package:library_distributed_app/core/widgets/app_scaffold.dart';
import 'package:library_distributed_app/core/widgets/app_table.dart';
import 'package:library_distributed_app/core/widgets/app_text_field.dart';

/// Borrowing Page - FR2, FR3 Implementation
/// Supports role-based access control:
/// - THUTHU: Can create borrow records and return books at their branch
/// - QUANLY: Can view borrowing statistics across all branches (book transfer moved to dedicated page)
class BorrowPage extends ConsumerStatefulWidget {
  const BorrowPage({super.key});

  @override
  ConsumerState<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends ConsumerState<BorrowPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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
    return AppScaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildHeader(context, userInfo),
          _buildContent(context, userInfo),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserInfoEntity userInfo) {
    return Consumer(
      builder: (context, ref, child) {
        final site = ref.watch(librarySiteProvider);
        final title = userInfo.role == UserRole.librarian
            ? 'Quản lý mượn/trả sách - Chi nhánh ${site.text}'
            : 'Thống kê mượn/trả - Toàn hệ thống';

        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Expanded(
              child:
                  Text(
                    title,
                    style: context.headlineSmall.bold,
                    overflow: TextOverflow.ellipsis,
                  ).withIcon(
                    Icons.book_online_rounded,
                    iconColor: context.primaryColor,
                  ),
            ),
            // Only THUTHU can create borrow records (FR2)
            if (userInfo.role == UserRole.librarian)
              AppButton(
                label: 'Lập phiếu mượn',
                icon: const Icon(Icons.add_circle_rounded, size: 20),
                onPressed: () => _showCreateDialog(context),
                backgroundColor: context.primaryColor,
              ),
          ],
        ).wrapByCard(context);
      },
    );
  }

  Widget _buildContent(BuildContext context, UserInfoEntity userInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 20,
      children: [
        _buildSearchRow(context),
        _buildBorrowTable(context, userInfo),
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
                  labelText: 'Tìm kiếm phiếu mượn (theo mã độc giả, tên sách)',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  onChanged: (value) {
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        ref.read(borrowSearchProvider.notifier).state = value;
                        ref
                            .read(borrowRecordsProvider.notifier)
                            .fetchData(0, value.isEmpty ? null : value);
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
                    ref.read(borrowSearchProvider.notifier).state = '';
                    ref.read(borrowRecordsProvider.notifier).fetchData(0, null);
                  },
                ),
              ],
            ],
          ),
        ),
        AppButton(
          label: 'Làm mới',
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () => ref.read(borrowRecordsProvider.notifier).refresh(),
          shadowColor: Colors.transparent,
          backgroundColor: context.onSurface.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    const BorrowCreateDialog().showAsDialog(context).then((result) {
      if (result != null) {
        // Refresh the list after creation
        ref.read(borrowRecordsProvider.notifier).refresh();
      }
    });
  }

  Widget _buildBorrowTable(BuildContext context, UserInfoEntity userInfo) {
    final borrowRecordsAsync = ref.watch(borrowRecordsProvider);

    return Column(
      children: [
        borrowRecordsAsync.when(
          data: (records) => _buildTable(context, records.items, userInfo),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Lỗi: $error')),
        ),
        _buildPagination(context),
      ],
    );
  }

  Widget _buildTable(
    BuildContext context,
    List<BorrowRecordWithDetailsEntity> records,
    UserInfoEntity userInfo,
  ) {
    if (records.isEmpty) {
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
                Icons.book_online_outlined,
                size: 48,
                color: context.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy phiếu mượn nào',
                style: context.bodyLarge.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final titles = _buildTableHeaders(userInfo);
    final rows = records
        .map((record) => _buildTableRow(context, record, userInfo))
        .toList();

    return AppTable.build(
      context,
      titles: titles,
      rows: rows,
      columnWidths: _getColumnWidths(userInfo),
    );
  }

  List<String> _buildTableHeaders(UserInfoEntity userInfo) {
    final baseHeaders = [
      'Mã phiếu mượn',
      'Mã độc giả',
      'Tên độc giả',
      'Mã sách',
      'Tên sách',
      'Ngày mượn',
      'Ngày hẹn trả',
      'Trạng thái',
    ];

    if (userInfo.role == UserRole.manager) {
      baseHeaders.insert(1, 'Chi nhánh');
    }

    if (userInfo.role == UserRole.librarian) {
      baseHeaders.add('Thao tác');
    }

    return baseHeaders;
  }

  List<double> _getColumnWidths(UserInfoEntity userInfo) {
    final baseWidths = [1.2, 1.0, 1.5, 1.0, 2.0, 1.0, 1.0, 1.0];

    if (userInfo.role == UserRole.manager) {
      baseWidths.insert(1, 1.0); // Chi nhánh column
    }

    if (userInfo.role == UserRole.librarian) {
      baseWidths.add(1.0); // Thao tác column
    }

    return baseWidths;
  }

  TableRow _buildTableRow(
    BuildContext context,
    BorrowRecordWithDetailsEntity record,
    UserInfoEntity userInfo,
  ) {
    final cells = <Widget>[
      AppTable.buildTextCell(context, text: record.borrowId.toString()),
      AppTable.buildTextCell(context, text: record.readerId),
      AppTable.buildTextCell(context, text: record.readerName),
      AppTable.buildTextCell(context, text: record.bookIsbn),
      AppTable.buildTextCell(context, text: record.bookTitle),
      AppTable.buildTextCell(
        context,
        text: AppUtils.formatDate(record.borrowDate),
      ),
      AppTable.buildTextCell(
        context,
        text: AppUtils.formatDate(record.dueDate),
      ),
      AppTable.buildWidgetCell(
        context,
        child: _buildStatusChip(context, record),
      ),
    ];

    if (userInfo.role == UserRole.manager) {
      cells.insert(
        1,
        AppTable.buildTextCell(context, text: record.branch.text),
      );
    }

    if (userInfo.role == UserRole.librarian) {
      cells.add(
        AppTable.buildWidgetCell(
          context,
          child: _buildActionButton(context, record, userInfo),
        ),
      );
    }

    return TableRow(children: cells);
  }

  Widget _buildStatusChip(
    BuildContext context,
    BorrowRecordWithDetailsEntity record,
  ) {
    Color chipColor;
    String statusText;

    if (record.isReturned) {
      chipColor = context.surfaceContainerHighest;
      statusText = 'Đã trả';
    } else if (record.isOverdue) {
      chipColor = context.errorContainer;
      statusText = 'Quá hạn';
    } else {
      chipColor = context.primaryContainer;
      statusText = 'Đang mượn';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: context.bodySmall.copyWith(
          color: record.isReturned
              ? context.onSurfaceVariant
              : record.isOverdue
              ? context.onErrorContainer
              : context.onPrimaryContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    BorrowRecordWithDetailsEntity record,
    UserInfoEntity userInfo,
  ) {
    final currentSite = ref.watch(librarySiteProvider);

    // Only show return button for THUTHU at their branch and if book is not returned yet
    if (userInfo.role != UserRole.librarian ||
        record.isReturned ||
        record.branch != currentSite) {
      return const SizedBox.shrink();
    }

    return AppButton(
      label: 'Trả sách',
      icon: const Icon(Icons.assignment_return_rounded, size: 16),
      onPressed: () => _showReturnBookDialog(context, record),
      backgroundColor: context.primaryContainer,
      shadowColor: Colors.transparent,
    );
  }

  Widget _buildPagination(BuildContext context) {
    final paginationState = ref.watch(borrowRecordsPaginationProvider);

    // Don't show pagination if no data or only one page
    if (paginationState.totalItems == 0 || paginationState.totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return AppPagination(
      currentPage: paginationState.currentPage,
      totalPages: paginationState.totalPages,
      totalItems: paginationState.totalItems,
      itemsPerPage: paginationState.itemsPerPage,
      onPageChanged: (page) {
        final searchQuery = ref.read(borrowSearchProvider);
        ref
            .read(borrowRecordsProvider.notifier)
            .fetchData(page, searchQuery.isEmpty ? null : searchQuery);
      },
    );
  }

  void _showReturnBookDialog(
    BuildContext context,
    BorrowRecordWithDetailsEntity record,
  ) {
    ReturnBookDialog(record: record).showAsDialog(context).then((result) {
      if (result != null) {
        // Refresh the list after return
        ref.read(borrowRecordsProvider.notifier).refresh();
      }
    });
  }
}
