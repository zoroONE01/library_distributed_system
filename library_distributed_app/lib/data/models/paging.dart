import 'package:json_annotation/json_annotation.dart';

part 'paging.g.dart';

@JsonSerializable(explicitToJson: true)
class PagingModel {
  final int page;
  final int size;
  final int totalPages;

  const PagingModel({this.page = 0, this.size = 5, this.totalPages = 0});

  factory PagingModel.fromJson(Map<String, dynamic> json) =>
      _$PagingModelFromJson(json);

  Map<String, dynamic> toJson() => _$PagingModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {page: $page, size: $size, totalPages: $totalPages}';
  }

  bool get isFirstPage => page == 0;
  bool get isLastPage => page == totalPages - 1;

  PagingModel copyWith({int? page, int? size, int? totalPages}) {
    return PagingModel(
      page: page ?? this.page,
      size: size ?? this.size,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
