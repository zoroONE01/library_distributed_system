import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/domain/entities/book.dart';

part 'book.g.dart';

@JsonSerializable(includeIfNull: false)
class BookModel {
  @JsonKey(name: 'isbn')
  final String isbn;
  @JsonKey(name: 'tenSach')
  final String title;
  @JsonKey(name: 'tacGia')
  final String author;

  const BookModel({
    this.isbn = '',
    this.title = '',
    this.author = '',
  });

  factory BookModel.fromJson(Map<String, dynamic> json) =>
      _$BookModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {isbn: $isbn, title: $title, author: $author}';
  }

  BookEntity toEntity() {
    return BookEntity(isbn: isbn, title: title, author: author);
  }
}
