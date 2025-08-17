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
  final BookStatus status;
  
  // Additional fields that might be included in detailed responses
  @JsonKey(name: 'tenSach')
  final String? bookTitle;
  @JsonKey(name: 'tacGia')
  final String? bookAuthor;

  const BookCopyModel({
    required this.bookCopyId,
    required this.isbn,
    required this.branchSite,
    required this.status,
    this.bookTitle,
    this.bookAuthor,
  });

  factory BookCopyModel.fromJson(Map<String, dynamic> json) =>
      _$BookCopyModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookCopyModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {bookCopyId: $bookCopyId, isbn: $isbn, branchSite: ${branchSite.name}, status: ${status.text}}';
  }
}
