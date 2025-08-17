import 'package:json_annotation/json_annotation.dart';

part 'chi_nhanh.g.dart';

@JsonSerializable(explicitToJson: true)
class ChiNhanhModel {
  @JsonKey(name: 'maCN')
  final String branchCode;

  @JsonKey(name: 'tenCN')
  final String branchName;

  @JsonKey(name: 'diaChi')
  final String address;

  const ChiNhanhModel({
    this.branchCode = '',
    this.branchName = '',
    this.address = '',
  });

  factory ChiNhanhModel.fromJson(Map<String, dynamic> json) =>
      _$ChiNhanhModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChiNhanhModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {branchCode: $branchCode, branchName: $branchName, address: $address}';
  }
}
