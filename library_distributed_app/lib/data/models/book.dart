import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
class BookModel {
  @JsonKey(name: 'isbn')
  final String id;
  @JsonKey(name: 'tenSach')
  final String title;
  @JsonKey(name: 'tacGia')
  final String author;
  final int availableCount;
  final int totalCount;
  final int borrowedCount;

  const BookModel({
    this.id = '',
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
    return '$runtimeType: {id: $id, title: $title, author: $author, availableCount: $availableCount, totalCount: $totalCount, borrowedCount: $borrowedCount}';
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    int? availableCount,
    int? totalCount,
    int? borrowedCount,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      availableCount: availableCount ?? this.availableCount,
      totalCount: totalCount ?? this.totalCount,
      borrowedCount: borrowedCount ?? this.borrowedCount,
    );
  }
}
