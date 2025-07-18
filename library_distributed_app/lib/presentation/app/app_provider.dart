import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_provider.g.dart';

@Riverpod(keepAlive: true)
class AppLoading extends _$AppLoading {
  @override
  bool build() {
    return false;
  }

  void startLoading() {
    state = true;
  }

  void stopLoading() {
    state = false;
  }
}
