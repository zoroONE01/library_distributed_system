import 'package:json_annotation/json_annotation.dart';

part 'return_book_request.g.dart';

@JsonSerializable(includeIfNull: false)
class ReturnBookRequestModel {
  @JsonKey(name: 'maQuyenSach')
  final String? bookCopyId;
  
  @JsonKey(name: 'ngayTra')
  final String? returnDate;

  const ReturnBookRequestModel({
    this.bookCopyId,
    this.returnDate,
  });

  factory ReturnBookRequestModel.fromJson(Map<String, dynamic> json) =>
      _$ReturnBookRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReturnBookRequestModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {bookCopyId: $bookCopyId, returnDate: $returnDate}';
  }
}