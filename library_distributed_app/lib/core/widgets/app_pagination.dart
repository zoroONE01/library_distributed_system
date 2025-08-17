import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';

class AppPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final Function(int) onPageChanged;

  const AppPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Validate inputs before building
    if (totalPages <= 1 || totalItems <= 0 || currentPage < 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfo(context),
        _buildPaginationControls(context),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    final startItem = (currentPage * itemsPerPage) + 1;
    final endItem = ((currentPage + 1) * itemsPerPage).clamp(0, totalItems);
    
    return Text(
      'Hiển thị $startItem-$endItem trong tổng số $totalItems mục',
      style: context.bodySmall.copyWith(color: context.onSurfaceVariant),
    );
  }

  Widget _buildPaginationControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First page
        IconButton(
          onPressed: currentPage > 0 ? () => onPageChanged(0) : null,
          icon: const Icon(Icons.first_page),
          tooltip: 'Trang đầu',
        ),
        // Previous page
        IconButton(
          onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Trang trước',
        ),
        // Page numbers
        ..._buildPageNumbers(context),
        // Next page
        IconButton(
          onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Trang sau',
        ),
        // Last page
        IconButton(
          onPressed: currentPage < totalPages - 1 ? () => onPageChanged(totalPages - 1) : null,
          icon: const Icon(Icons.last_page),
          tooltip: 'Trang cuối',
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context) {
    const maxVisiblePages = 5;
    final List<Widget> pageNumbers = [];

    // Ensure we have valid totalPages
    if (totalPages <= 0) return pageNumbers;

    int startPage = (currentPage - maxVisiblePages ~/ 2).clamp(0, (totalPages - maxVisiblePages).clamp(0, totalPages));
    final int endPage = (startPage + maxVisiblePages - 1).clamp(0, totalPages - 1);

    // Adjust startPage if we're near the end
    if (endPage - startPage < maxVisiblePages - 1 && totalPages > maxVisiblePages) {
      startPage = (endPage - maxVisiblePages + 1).clamp(0, totalPages - 1);
    }

    // Add ellipsis at the beginning if needed
    if (startPage > 0) {
      pageNumbers.add(_buildPageButton(context, 0));
      if (startPage > 1) {
        pageNumbers.add(_buildEllipsis(context));
      }
    }

    // Add page numbers - ensure valid range
    final validStartPage = startPage.clamp(0, totalPages - 1);
    final validEndPage = endPage.clamp(validStartPage, totalPages - 1);
    
    for (int i = validStartPage; i <= validEndPage; i++) {
      pageNumbers.add(_buildPageButton(context, i));
    }

    // Add ellipsis at the end if needed
    if (endPage < totalPages - 1) {
      if (endPage < totalPages - 2) {
        pageNumbers.add(_buildEllipsis(context));
      }
      pageNumbers.add(_buildPageButton(context, totalPages - 1));
    }

    return pageNumbers;
  }

  Widget _buildPageButton(BuildContext context, int page) {
    final isCurrentPage = page == currentPage;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isCurrentPage ? context.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onPageChanged(page),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              '${page + 1}',
              style: context.bodyMedium.copyWith(
                color: isCurrentPage ? context.onPrimary : context.onSurface,
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: Text(
        '...',
        style: context.bodyMedium.copyWith(color: context.onSurfaceVariant),
      ),
    );
  }
}
