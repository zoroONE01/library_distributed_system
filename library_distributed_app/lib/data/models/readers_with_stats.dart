import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/reader_with_stats.dart';
import 'package:library_distributed_app/data/models/paging.dart';

part 'readers_with_stats.g.dart';

@JsonSerializable(explicitToJson: true)
class ReadersWithStatsModel {
  final List<ReaderWithStatsModel> items;
  final PagingModel paging;

  const ReadersWithStatsModel({
    this.items = const [],
    this.paging = const PagingModel(),
  });

  factory ReadersWithStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ReadersWithStatsModelFromJson(json);
  Map<String, dynamic> toJson() => _$ReadersWithStatsModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {items: ${items.length} readers, paging: $paging}';
  }
}