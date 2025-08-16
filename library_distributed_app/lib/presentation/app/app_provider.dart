import 'package:library_distributed_app/core/constants/enums.dart';
import 'package:library_distributed_app/core/utils/local_storage_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_provider.g.dart';

@Riverpod(keepAlive: true)
class AppLoading extends _$AppLoading {
  @override
  bool build() {
    return false;
  }

  void startLoading() {
    if (!state) {
      state = true;
    }
  }

  void stopLoading() {
    if (state) {
      state = false;
    }
  }
}

@Riverpod(keepAlive: true)
class LibrarySite extends _$LibrarySite {
  @override
  Site build() {
    final siteValue = localStorage.read(LocalStorageKeys.site);
    return Site.fromString(siteValue);
  }

  Future<void> setSite(Site site) async {
    await localStorage.write(LocalStorageKeys.site, site.name);
    state = site;
  }
}
