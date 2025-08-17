import 'package:library_distributed_app/core/constants/enums.dart';

class ReaderEntity {
  final String readerId;
  final String fullName;
  final Site registrationSite;

  const ReaderEntity({
    required this.readerId,
    required this.fullName,
    required this.registrationSite,
  });
}

class ReaderWithStatsEntity {
  final String readerId;
  final String fullName;
  final Site registrationSite;
  final int totalBorrowed;
  final int currentBorrowed;
  final int overdueBooks;
  final String? lastBorrowDate;

  const ReaderWithStatsEntity({
    required this.readerId,
    required this.fullName,
    required this.registrationSite,
    this.totalBorrowed = 0,
    this.currentBorrowed = 0,
    this.overdueBooks = 0,
    this.lastBorrowDate,
  });
}