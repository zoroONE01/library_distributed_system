import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/site_stats.dart';

part 'system_stats.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class SystemStatsModel {
  @JsonKey(name: 'totalBooksOnLoan')
  final int totalBooksOnLoan;
  
  @JsonKey(name: 'statsBySite')
  final Map<String, SiteStatsModel> statsBySite;

  const SystemStatsModel({
    this.totalBooksOnLoan = 0,
    this.statsBySite = const {},
  });

  factory SystemStatsModel.fromJson(Map<String, dynamic> json) =>
      _$SystemStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$SystemStatsModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {totalBooksOnLoan: $totalBooksOnLoan, sites: ${statsBySite.keys.length}}';
  }
}