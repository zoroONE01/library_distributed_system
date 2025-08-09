import 'package:flutter/material.dart';
import 'package:library_distributed_app/data/models/paging.dart';

class AppPaginationControls extends StatelessWidget {
  const AppPaginationControls(
    this.data, {
    super.key,
    required this.onPageChanged,
  });

  final PagingModel data;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Trang ${data.page + 1} trong ${data.totalPages}'),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: !data.isFirstPage
              ? () => onPageChanged(data.page - 1)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: !data.isLastPage
              ? () => onPageChanged(data.page + 1)
              : null,
        ),
      ],
    );
  }
}
