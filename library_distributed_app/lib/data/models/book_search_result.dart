import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/book.dart';
import 'package:library_distributed_app/data/models/chi_nhanh.dart';

part 'book_search_result.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class BookSearchResultModel {
  @JsonKey(name: 'sach')
  final BookModel book;

  @JsonKey(name: 'chiNhanh')
  final List<ChiNhanhModel> availableBranches;

  @JsonKey(name: 'soLuongCo')
  final int availableCount;

  const BookSearchResultModel({
    this.book = const BookModel(),
    this.availableBranches = const [],
    this.availableCount = 0,
  });

  factory BookSearchResultModel.fromJson(Map<String, dynamic> json) =>
      _$BookSearchResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookSearchResultModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {book: ${book.title}, availableCount: $availableCount, branches: ${availableBranches.length}}';
  }
}
