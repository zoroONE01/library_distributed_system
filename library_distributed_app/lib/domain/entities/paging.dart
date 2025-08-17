import 'package:library_distributed_app/core/constants/common.dart';

class PagingEntity {
  final int currentPage;
  final int totalPages;
  final int pageSize;

  const PagingEntity({
    this.currentPage = 0,  // Start from page 0
    this.totalPages = 1,
    this.pageSize = kPaginationPageSize,
  });

  bool get hasNextPage => currentPage < totalPages - 1;  // Adjusted for 0-based
  bool get isFirstPage => currentPage == 0;  // First page is 0
}
