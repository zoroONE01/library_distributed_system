import 'package:json_annotation/json_annotation.dart';

part 'book_copy.g.dart';

@JsonSerializable(includeIfNull: false)
class BookCopyModel {
  final String isbn;
  @JsonKey(name: 'maQuyenSach')
  final String id;
  @JsonKey(name: 'tenSach')
  final String title;
  @JsonKey(name: 'tacGia')
  final String author;
  @JsonKey(name: 'maCN')
  final String branchId;
  @JsonKey(name: 'tenCN')
  final String branchName;
  @JsonKey(name: 'tinhTrang')
  final String status;

  const BookCopyModel({
    required this.isbn,
    required this.id,
    required this.title,
    required this.author,
    required this.branchId,
    required this.branchName,
    required this.status,
  });

  factory BookCopyModel.fromJson(Map<String, dynamic> json) =>
      _$BookCopyModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookCopyModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {id: $id, title: $title, author: $author, branchId: $branchId, branchName: $branchName, status: $status}';
  }
}
