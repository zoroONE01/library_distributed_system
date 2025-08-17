import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/enums.dart';

part 'site_stats.g.dart';

@JsonSerializable(includeIfNull: false)
class SiteStatsModel {
  @JsonKey(name: 'siteID')
  final Site siteId;
  
  @JsonKey(name: 'booksOnLoan')
  final int booksOnLoan;
  
  @JsonKey(name: 'totalBooks')
  final int totalBooks;
  
  @JsonKey(name: 'totalReaders')
  final int totalReaders;

  const SiteStatsModel({
    required this.siteId,
    this.booksOnLoan = 0,
    this.totalBooks = 0,
    this.totalReaders = 0,
  });

  factory SiteStatsModel.fromJson(Map<String, dynamic> json) =>
      _$SiteStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$SiteStatsModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {siteId: ${siteId.name}, booksOnLoan: $booksOnLoan, totalBooks: $totalBooks, totalReaders: $totalReaders}';
  }
}