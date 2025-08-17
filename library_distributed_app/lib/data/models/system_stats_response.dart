import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/site_stats.dart';
import 'package:library_distributed_app/data/models/book.dart';

part 'system_stats_response.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SystemStatsResponseModel {
  @JsonKey(name: 'totalBooks')
  final int totalBooks;
  
  @JsonKey(name: 'totalCopies')
  final int totalCopies;
  
  @JsonKey(name: 'totalReaders')
  final int totalReaders;
  
  @JsonKey(name: 'activeBorrows')
  final int activeBorrows;
  
  @JsonKey(name: 'overdueBooks')
  final int overdueBooks;
  
  @JsonKey(name: 'siteStats')
  final List<SiteStatsModel> siteStats;
  
  @JsonKey(name: 'popularBooks')
  final List<BookModel> popularBooks;
  
  @JsonKey(name: 'generatedAt')
  final String generatedAt;

  const SystemStatsResponseModel({
    this.totalBooks = 0,
    this.totalCopies = 0,
    this.totalReaders = 0,
    this.activeBorrows = 0,
    this.overdueBooks = 0,
    this.siteStats = const [],
    this.popularBooks = const [],
    this.generatedAt = '',
  });

  factory SystemStatsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SystemStatsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$SystemStatsResponseModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {totalBooks: $totalBooks, totalReaders: $totalReaders, activeBorrows: $activeBorrows}';
  }
}