import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/domain/entities/book.dart';

class SiteStatsEntity {
  final Site siteId;
  final int booksOnLoan;
  final int totalBooks;
  final int totalReaders;

  const SiteStatsEntity({
    required this.siteId,
    this.booksOnLoan = 0,
    this.totalBooks = 0,
    this.totalReaders = 0,
  });
}

class SystemStatsEntity {
  final int totalBooksOnLoan;
  final Map<Site, SiteStatsEntity> statsBySite;

  const SystemStatsEntity({
    this.totalBooksOnLoan = 0,
    this.statsBySite = const {},
  });

  int get totalBooks => statsBySite.values.fold(0, (sum, stats) => sum + stats.totalBooks);
  int get totalReaders => statsBySite.values.fold(0, (sum, stats) => sum + stats.totalReaders);
}

class SystemStatsResponseEntity {
  final int totalBooks;
  final int totalCopies;
  final int totalReaders;
  final int activeBorrows;
  final int overdueBooks;
  final List<SiteStatsEntity> siteStats;
  final List<BookEntity> popularBooks;
  final String generatedAt;

  const SystemStatsResponseEntity({
    this.totalBooks = 0,
    this.totalCopies = 0,
    this.totalReaders = 0,
    this.activeBorrows = 0,
    this.overdueBooks = 0,
    this.siteStats = const [],
    this.popularBooks = const [],
    required this.generatedAt,
  });
}