import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:library_distributed_app/data/models/auth_info.dart';

import '../../domain/entities/login_form.dart';
import '../models/user_info.dart';

part 'auth_service.chopper.dart';

@ChopperApi(baseUrl: '/auth')
abstract class AuthService extends ChopperService {
  @POST(path: '/login')
  Future<Response<AuthInfoModel>> login(@Body() LoginFormEntity loginForm);

  @POST(path: '/logout')
  Future<Response<void>> logout();

  @GET(path: '/profile')
  Future<Response<UserInfoModel>> getProfile();

  static AuthService create([ChopperClient? client]) => _$AuthService(client);
}
