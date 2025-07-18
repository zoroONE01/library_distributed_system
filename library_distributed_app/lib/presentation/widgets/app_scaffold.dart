import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool primary;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final DragStartBehavior drawerDragStartBehavior;
  final String? restorationId;

  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.primary = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.restorationId,
  });

  @override
  Widget build(BuildContext context) {
    final gradient1 = RadialGradient(
      colors: [
        context.primaryColor.withValues(alpha: .1),
        context.primaryColor.withValues(alpha: 0),
      ],
      stops: const [0, .5],
      radius: 1.0,
    );
    final gradient2 = RadialGradient(
      colors: [
        context.secondaryColor.withValues(alpha: .08),
        context.secondaryColor.withValues(alpha: 0),
      ],
      stops: const [0, .5],
      radius: 1.0,
    );
    final gradient3 = RadialGradient(
      colors: [
        context.errorColor.withValues(alpha: .1),
        context.errorColor.withValues(alpha: 0),
      ],
      stops: const [0, .5],
      radius: 1.0,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: context.surfaceColor),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient1)),
        ),
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient2)),
        ),
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient3)),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          floatingActionButtonAnimator: floatingActionButtonAnimator,
          persistentFooterButtons: persistentFooterButtons,
          drawer: drawer,
          endDrawer: endDrawer,
          drawerScrimColor: drawerScrimColor,
          drawerEdgeDragWidth: drawerEdgeDragWidth,
          bottomNavigationBar: bottomNavigationBar,
          bottomSheet: bottomSheet,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          primary: primary,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          drawerDragStartBehavior: drawerDragStartBehavior,
          restorationId: restorationId,
        ),
      ],
    );
  }
}
