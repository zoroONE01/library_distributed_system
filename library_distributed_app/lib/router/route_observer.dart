part of 'router.dart';

class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  AppRouteObserver(this.ref);

  final Ref ref;

  void _logScreen(String action, PageRoute<dynamic> route) {
    final name = route.settings.name ?? route.runtimeType.toString();
    logger.i('$action screen: $name');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _logScreen('PUSH', route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      _logScreen('POP to', previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _logScreen('REPLACE with', newRoute);
    }
  }
}


