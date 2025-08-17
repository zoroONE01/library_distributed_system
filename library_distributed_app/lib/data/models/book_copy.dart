import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/enums.dart';

part 'book_copy.g.dart';

@JsonSerializable(includeIfNull: false)
class BookCopyModel {
  @JsonKey(name: 'maQuyenSach')
  final String bookCopyId;
  final String isbn;
  @JsonKey(name: 'maCN')
  final Site branchSite;
  @JsonKey(name: 'tinhTrang')
  final String status;

  const BookCopyModel({
    required this.bookCopyId,
    required this.isbn,
    required this.branchSite,
    required this.status,
  });

  factory BookCopyModel.fromJson(Map<String, dynamic> json) =>
      _$BookCopyModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookCopyModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {bookCopyId: $bookCopyId, isbn: $isbn, branchSite: ${branchSite.name}, status: $status}';
  }
}
