import 'package:json_annotation/json_annotation.dart';

part 'transfer_book_response.g.dart';

@JsonSerializable(explicitToJson: true)
class TransferBookResponseModel {
  @JsonKey(name: 'message')
  final String message;

  @JsonKey(name: 'maQuyenSach')
  final String bookCopyId;

  @JsonKey(name: 'fromSite')
  final String fromSite;

  @JsonKey(name: 'toSite')
  final String toSite;

  @JsonKey(name: 'protocol')
  final String protocol;

  @JsonKey(name: 'coordinator')
  final String coordinator;

  const TransferBookResponseModel({
    this.message = '',
    this.bookCopyId = '',
    this.fromSite = '',
    this.toSite = '',
    this.protocol = '',
    this.coordinator = '',
  });

  factory TransferBookResponseModel.fromJson(Map<String, dynamic> json) =>
      _$TransferBookResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransferBookResponseModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {message: $message, bookCopyId: $bookCopyId, fromSite: $fromSite, toSite: $toSite}';
  }
}
