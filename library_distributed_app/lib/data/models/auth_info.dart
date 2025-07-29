import 'package:json_annotation/json_annotation.dart';

part 'auth_info.g.dart';

@JsonSerializable(explicitToJson: true)
class AuthInfoModel {
  final String? accessToken;

  const AuthInfoModel({this.accessToken});

  factory AuthInfoModel.fromJson(Map<String, dynamic> json) =>
      _$AuthInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthInfoModelToJson(this);

  @override
  String toString() {
    return 'AuthInfoModel{accessToken: $accessToken}';
  }
}
