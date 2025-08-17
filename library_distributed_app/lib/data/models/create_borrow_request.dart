import 'package:json_annotation/json_annotation.dart';

part 'create_borrow_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateBorrowRequestModel {
  @JsonKey(name: 'maDG')
  final String readerId;

  @JsonKey(name: 'maQuyenSach')
  final String bookCopyId;

  const CreateBorrowRequestModel({this.readerId = '', this.bookCopyId = ''});

  factory CreateBorrowRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateBorrowRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBorrowRequestModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {readerId: $readerId, bookCopyId: $bookCopyId}';
  }
}
