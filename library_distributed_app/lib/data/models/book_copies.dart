import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/book_copy.dart';
import 'package:library_distributed_app/data/models/paging.dart';

part 'book_copies.g.dart';

@JsonSerializable(explicitToJson: true)
class BookCopiesModel {
  final List<BookCopyModel> items;
  final PagingModel paging;

  const BookCopiesModel({
    this.items = const [],
    this.paging = const PagingModel(),
  });

  factory BookCopiesModel.fromJson(Map<String, dynamic> json) =>
      _$BookCopiesModelFromJson(json);
  Map<String, dynamic> toJson() => _$BookCopiesModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {data: $items, paging: $paging}';
  }
}
