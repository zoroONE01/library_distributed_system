class PagingEntity {
  final int currentPage;
  final int totalPages;
  final int pageSize;

  const PagingEntity({
    this.currentPage = 1,
    this.totalPages = 1,
    this.pageSize = 10,
  });

  bool get hasNextPage => currentPage < totalPages;
  bool get isFirstPage => currentPage == 1;
}
