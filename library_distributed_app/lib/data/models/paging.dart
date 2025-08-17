import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/common.dart';
import 'package:library_distributed_app/domain/entities/paging.dart';

part 'paging.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PagingModel {
  final int page;
  final int size;
  final int? totalPages;

  const PagingModel({this.page = 0, this.size = kPaginationPageSize, this.totalPages});

  factory PagingModel.fromJson(Map<String, dynamic> json) =>
      _$PagingModelFromJson(json);

  factory PagingModel.fromEntity(PagingEntity entity) {
    return PagingModel(
      page: entity.currentPage,
      size: entity.pageSize,
      totalPages: entity.totalPages,
    );
  }

  Map<String, dynamic> toJson() => _$PagingModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {page: $page, size: $size, totalPages: $totalPages}';
  }

  PagingEntity toEntity() {
    return PagingEntity(
      currentPage: page,
      pageSize: size,
      totalPages: totalPages ?? 1,
    );
  }
}
