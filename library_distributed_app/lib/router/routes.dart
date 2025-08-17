part of 'router.dart';

// MAIN SHELL ROUTE WITH NESTED NAVIGATION
@TypedStatefulShellRoute<AppShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<StatefulShellBranchData>(
      routes: <TypedGoRoute<HomeRoute>>[TypedGoRoute<HomeRoute>(path: '/')],
    ),
    TypedStatefulShellBranch<StatefulShellBranchData>(
      routes: <TypedGoRoute<BooksRoute>>[
        TypedGoRoute<BooksRoute>(path: '/books'),
      ],
    ),
    TypedStatefulShellBranch<StatefulShellBranchData>(
      routes: <TypedGoRoute<BookCopiesRoute>>[
        TypedGoRoute<BookCopiesRoute>(path: '/book-copies'),
      ],
    ),
    TypedStatefulShellBranch<StatefulShellBranchData>(
      routes: <TypedGoRoute<ReaderListRoute>>[
        TypedGoRoute<ReaderListRoute>(path: '/readers'),
      ],
    ),
    TypedStatefulShellBranch<StatefulShellBranchData>(
      routes: <TypedGoRoute<BorrowRoute>>[
        TypedGoRoute<BorrowRoute>(path: '/borrow'),
      ],
    ),
    TypedStatefulShellBranch<StatefulShellBranchData>(
      routes: <TypedGoRoute<BookTransferRoute>>[
        TypedGoRoute<BookTransferRoute>(path: '/book-transfer'),
      ],
    ),
  ],
)
class AppShellRoute extends StatefulShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return MainPage(navigationShell: navigationShell);
  }
}

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData {
  const HomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

@TypedGoRoute<BooksRoute>(path: '/books')
class BooksRoute extends GoRouteData {
  const BooksRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const BooksPage();
}

@TypedGoRoute<BookCopiesRoute>(path: '/book-copies')
class BookCopiesRoute extends GoRouteData {
  const BookCopiesRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BookCopiesPage();
}

@TypedGoRoute<ReaderListRoute>(path: '/readers')
class ReaderListRoute extends GoRouteData {
  const ReaderListRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ReaderListPage();
}

@TypedGoRoute<BorrowRoute>(path: '/borrow')
class BorrowRoute extends GoRouteData {
  const BorrowRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const BorrowPage();
}

@TypedGoRoute<BookTransferRoute>(path: '/book-transfer')
class BookTransferRoute extends GoRouteData {
  const BookTransferRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BookTransferPage();
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginPage();
}
