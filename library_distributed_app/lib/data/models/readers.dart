import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/paging.dart';
import 'package:library_distributed_app/data/models/reader.dart';

part 'readers.g.dart';

@JsonSerializable(explicitToJson: true)
class ReadersModel {
  final List<ReaderModel> items;
  final PagingModel paging;

  const ReadersModel({
    required this.items,
    required this.paging,
  });

  factory ReadersModel.fromJson(Map<String, dynamic> json) =>
      _$ReadersModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReadersModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {items: ${items.length} readers, paging: $paging}';
  }
}