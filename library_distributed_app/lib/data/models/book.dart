import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
class BookModel {
  final String id;
  final String title;
  final String author;
  final int quantity;

  const BookModel({
    this.id = '',
    this.title = '',
    this.author = '',
    this.quantity = 0,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) =>
      _$BookModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {id: $id, title: $title, author: $author, quantity: $quantity}';
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    int? quantity,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      quantity: quantity ?? this.quantity,
    );
  }
}
