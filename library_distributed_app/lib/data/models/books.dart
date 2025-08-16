import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/paging.dart';

part 'books.g.dart';

@JsonSerializable(explicitToJson: true)
class BooksModel {
  final List<BookModel> items;
  final PagingModel paging;

  const BooksModel({this.items = const [], this.paging = const PagingModel()});

  factory BooksModel.fromJson(Map<String, dynamic> json) =>
      _$BooksModelFromJson(json);
  Map<String, dynamic> toJson() => _$BooksModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {data: $items, paging: $paging}';
  }

  // BookCopiesEntity toEntity() {
  //   return BookCopiesEntity(
  //     items: items.map((item) => item.toEntity()).toList(),
  //     paging: paging.toEntity(),
  //   );
  // }
}
