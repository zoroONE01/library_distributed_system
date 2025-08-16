import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/domain/entities/book.dart';

part 'book.g.dart';

@JsonSerializable(includeIfNull: false)
class BookModel {
  final String isbn;
  @JsonKey(name: 'tenSach')
  final String title;
  @JsonKey(name: 'tacGia')
  final String author;
  final int availableCount;
  final int totalCount;
  final int borrowedCount;

  const BookModel({
    this.isbn = '',
    this.title = '',
    this.author = '',
    this.availableCount = 0,
    this.totalCount = 0,
    this.borrowedCount = 0,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) =>
      _$BookModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {isbn: $isbn, title: $title, author: $author, availableCount: $availableCount, totalCount: $totalCount, borrowedCount: $borrowedCount}';
  }

  BookEntity toEntity() {
    return BookEntity(isbn: isbn, title: title, author: author);
  }
}
