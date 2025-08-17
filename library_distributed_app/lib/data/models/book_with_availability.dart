import 'package:json_annotation/json_annotation.dart';

part 'book_with_availability.g.dart';

@JsonSerializable(includeIfNull: false)
class BookWithAvailabilityModel {
  final String isbn;
  
  @JsonKey(name: 'tenSach')
  final String title;
  
  @JsonKey(name: 'tacGia')
  final String author;
  
  @JsonKey(name: 'availableCount')
  final int availableCount;
  
  @JsonKey(name: 'totalCount')
  final int totalCount;
  
  @JsonKey(name: 'borrowedCount')
  final int borrowedCount;

  const BookWithAvailabilityModel({
    this.isbn = '',
    this.title = '',
    this.author = '',
    this.availableCount = 0,
    this.totalCount = 0,
    this.borrowedCount = 0,
  });

  factory BookWithAvailabilityModel.fromJson(Map<String, dynamic> json) =>
      _$BookWithAvailabilityModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookWithAvailabilityModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {isbn: $isbn, title: $title, author: $author, availableCount: $availableCount, totalCount: $totalCount}';
  }
}