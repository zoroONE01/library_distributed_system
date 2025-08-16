// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $appShellRoute,
  $homeRoute,
  $booksRoute,
  $bookCopiesRoute,
  $readerListRoute,
  $borrowRoute,
  $branchesRoute,
  $loginRoute,
];

RouteBase get $appShellRoute => StatefulShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(path: '/', factory: $HomeRouteExtension._fromState),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/books',

          factory: $BooksRouteExtension._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/book-copies',

          factory: $BookCopiesRouteExtension._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/readers',

          factory: $ReaderListRouteExtension._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/borrow',

          factory: $BorrowRouteExtension._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/branches',

          factory: $BranchesRouteExtension._fromState,
        ),
      ],
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

extension $HomeRouteExtension on HomeRoute {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  String get location => GoRouteData.$location('/');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $BooksRouteExtension on BooksRoute {
  static BooksRoute _fromState(GoRouterState state) => const BooksRoute();

  String get location => GoRouteData.$location('/books');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $BookCopiesRouteExtension on BookCopiesRoute {
  static BookCopiesRoute _fromState(GoRouterState state) =>
      const BookCopiesRoute();

  String get location => GoRouteData.$location('/book-copies');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $ReaderListRouteExtension on ReaderListRoute {
  static ReaderListRoute _fromState(GoRouterState state) =>
      const ReaderListRoute();

  String get location => GoRouteData.$location('/readers');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $BorrowRouteExtension on BorrowRoute {
  static BorrowRoute _fromState(GoRouterState state) => const BorrowRoute();

  String get location => GoRouteData.$location('/borrow');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

extension $BranchesRouteExtension on BranchesRoute {
  static BranchesRoute _fromState(GoRouterState state) => const BranchesRoute();

  String get location => GoRouteData.$location('/branches');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $homeRoute =>
    GoRouteData.$route(path: '/', factory: $HomeRouteExtension._fromState);

RouteBase get $booksRoute => GoRouteData.$route(
  path: '/books',

  factory: $BooksRouteExtension._fromState,
);

RouteBase get $bookCopiesRoute => GoRouteData.$route(
  path: '/book-copies',

  factory: $BookCopiesRouteExtension._fromState,
);

RouteBase get $readerListRoute => GoRouteData.$route(
  path: '/readers',

  factory: $ReaderListRouteExtension._fromState,
);

RouteBase get $borrowRoute => GoRouteData.$route(
  path: '/borrow',

  factory: $BorrowRouteExtension._fromState,
);

RouteBase get $branchesRoute => GoRouteData.$route(
  path: '/branches',

  factory: $BranchesRouteExtension._fromState,
);

RouteBase get $loginRoute => GoRouteData.$route(
  path: '/login',

  factory: $LoginRouteExtension._fromState,
);

extension $LoginRouteExtension on LoginRoute {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  String get location => GoRouteData.$location('/login');

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}
