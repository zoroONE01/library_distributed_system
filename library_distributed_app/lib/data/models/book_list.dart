import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/paging.dart';

part 'book_list.g.dart';

@JsonSerializable(explicitToJson: true)
class BookListModel {
  final List<BookModel> items;
  final PagingModel paging;

  const BookListModel({
    this.items = const [],
    this.paging = const PagingModel(),
  });

  factory BookListModel.fromJson(Map<String, dynamic> json) =>
      _$BookListModelFromJson(json);
  Map<String, dynamic> toJson() => _$BookListModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {data: $items, paging: $paging}';
  }
}
