import 'package:json_annotation/json_annotation.dart';

part 'transfer_book_request.g.dart';

@JsonSerializable(explicitToJson: true)
class TransferBookRequestModel {
  @JsonKey(name: 'maQuyenSach')
  final String bookCopyId;

  @JsonKey(name: 'fromSite')
  final String fromSite;

  @JsonKey(name: 'toSite')
  final String toSite;

  const TransferBookRequestModel({
    this.bookCopyId = '',
    this.fromSite = '',
    this.toSite = '',
  });

  factory TransferBookRequestModel.fromJson(Map<String, dynamic> json) =>
      _$TransferBookRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransferBookRequestModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {bookCopyId: $bookCopyId, fromSite: $fromSite, toSite: $toSite}';
  }
}
