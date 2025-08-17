import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/borrow_record.dart';
import 'package:library_distributed_app/data/models/paging.dart';

part 'borrow_records_simple.g.dart';

@JsonSerializable(explicitToJson: true)
class BorrowRecordsSimpleModel {
  final List<BorrowRecordModel> items;
  final PagingModel paging;

  const BorrowRecordsSimpleModel({
    this.items = const [],
    this.paging = const PagingModel(),
  });

  factory BorrowRecordsSimpleModel.fromJson(Map<String, dynamic> json) =>
      _$BorrowRecordsSimpleModelFromJson(json);
  Map<String, dynamic> toJson() => _$BorrowRecordsSimpleModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {items: ${items.length} borrow records, paging: $paging}';
  }
}