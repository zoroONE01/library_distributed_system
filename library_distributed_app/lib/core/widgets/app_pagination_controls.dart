import 'package:flutter/material.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';

class AppPaginationControls extends StatelessWidget {
  const AppPaginationControls(
    this.data, {
    super.key,
    required this.onPageChanged,
  });

  final PagingEntity data;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Trang ${data.currentPage + 1} trong ${data.totalPages > 0 ? data.totalPages : 1}',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: !data.isFirstPage
              ? () => onPageChanged(data.currentPage - 1)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: data.hasNextPage
              ? () => onPageChanged(data.currentPage + 1)
              : null,
        ),
      ],
    );
  }
}
