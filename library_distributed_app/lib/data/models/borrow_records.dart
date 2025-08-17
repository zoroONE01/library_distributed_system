import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/paging.dart';
import 'package:library_distributed_app/data/models/borrow_record_with_details.dart';

part 'borrow_records.g.dart';

@JsonSerializable(explicitToJson: true)
class BorrowRecordsModel {
  final List<BorrowRecordWithDetailsModel> items;
  final PagingModel paging;

  const BorrowRecordsModel({
    this.items = const [],
    this.paging = const PagingModel(),
  });

  factory BorrowRecordsModel.fromJson(Map<String, dynamic> json) =>
      _$BorrowRecordsModelFromJson(json);

  Map<String, dynamic> toJson() => _$BorrowRecordsModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {items: ${items.length} borrow records, paging: $paging}';
  }
}