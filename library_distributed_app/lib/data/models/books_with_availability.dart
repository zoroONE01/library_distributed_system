import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/book_with_availability.dart';
import 'package:library_distributed_app/data/models/paging.dart';

part 'books_with_availability.g.dart';

@JsonSerializable(explicitToJson: true)
class BooksWithAvailabilityModel {
  final List<BookWithAvailabilityModel> items;
  final PagingModel paging;

  const BooksWithAvailabilityModel({
    this.items = const [],
    this.paging = const PagingModel(),
  });

  factory BooksWithAvailabilityModel.fromJson(Map<String, dynamic> json) =>
      _$BooksWithAvailabilityModelFromJson(json);
  Map<String, dynamic> toJson() => _$BooksWithAvailabilityModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {items: ${items.length} books, paging: $paging}';
  }
}