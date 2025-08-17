import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/data/models/paging.dart';

part 'list_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ListResponse<T> {
  final List<T> items;
  final PagingModel paging;

  const ListResponse({
    required this.items,
    required this.paging,
  });

  factory ListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ListResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      _$ListResponseToJson(this, toJsonT);

  @override
  String toString() {
    return '$runtimeType: {items: ${items.length} items, paging: $paging}';
  }
}