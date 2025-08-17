import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/enums.dart';

part 'reader_with_stats.g.dart';

@JsonSerializable(includeIfNull: false)
class ReaderWithStatsModel {
  @JsonKey(name: 'maDG')
  final String readerId;

  @JsonKey(name: 'hoTen')
  final String fullName;

  @JsonKey(name: 'maCNDangKy')
  final Site registrationSite;

  final int totalBorrowed;
  final int currentBorrowed;
  final int overdueBooks;

  @JsonKey(name: 'lastBorrowDate')
  final String? lastBorrowDate;

  const ReaderWithStatsModel({
    this.readerId = '',
    this.fullName = '',
    this.registrationSite = Site.q1,
    this.totalBorrowed = 0,
    this.currentBorrowed = 0,
    this.overdueBooks = 0,
    this.lastBorrowDate = '',
  });

  factory ReaderWithStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ReaderWithStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReaderWithStatsModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {readerId: $readerId, fullName: $fullName, totalBorrowed: $totalBorrowed, currentBorrowed: $currentBorrowed}';
  }
}
