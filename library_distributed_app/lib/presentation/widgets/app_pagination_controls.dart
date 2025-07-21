import 'package:flutter/material.dart';

class AppPaginationControls extends StatelessWidget {
  const AppPaginationControls({
    super.key,
    required this.totalItems,
    required this.itemsPerPage,
    required this.currentPage,
    required this.onPageChanged,
  });

  final int totalItems;
  final int itemsPerPage;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / itemsPerPage).ceil();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Trang $currentPage trong $totalPages'),
        IconButton(
          icon: Icon(Icons.chevron_left_rounded),
          onPressed: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
        ),
        IconButton(
          icon: Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}
