import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/enums.dart';

part 'borrow_record.g.dart';

@JsonSerializable(includeIfNull: false)
class BorrowRecordModel {
  @JsonKey(name: 'maPM')
  final int borrowId;

  @JsonKey(name: 'maDG')
  final String readerId;

  @JsonKey(name: 'maQuyenSach')
  final String bookCopyId;

  @JsonKey(name: 'maCN')
  final Site branchSite;

  @JsonKey(name: 'ngayMuon')
  final String borrowDate;

  @JsonKey(name: 'ngayTra')
  final String returnDate;

  const BorrowRecordModel({
    this.borrowId = 0,
    this.readerId = '',
    this.bookCopyId = '',
    this.branchSite = Site.q1,
    this.borrowDate = '',
    this.returnDate = '',
  });

  factory BorrowRecordModel.fromJson(Map<String, dynamic> json) =>
      _$BorrowRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$BorrowRecordModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {borrowId: $borrowId, readerId: $readerId, bookCopyId: $bookCopyId, returnDate: $returnDate}';
  }
}
