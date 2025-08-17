import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/enums.dart';

part 'reader.g.dart';

@JsonSerializable(includeIfNull: false)
class ReaderModel {
  @JsonKey(name: 'maDG')
  final String readerId;
  
  @JsonKey(name: 'hoTen')
  final String fullName;
  
  @JsonKey(name: 'maCNDangKy')
  final Site registrationSite;

  const ReaderModel({
    required this.readerId,
    required this.fullName,
    required this.registrationSite,
  });

  factory ReaderModel.fromJson(Map<String, dynamic> json) =>
      _$ReaderModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReaderModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {readerId: $readerId, fullName: $fullName, registrationSite: ${registrationSite.name}}';
  }
}