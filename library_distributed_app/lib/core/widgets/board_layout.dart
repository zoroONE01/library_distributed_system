import 'package:flutter/material.dart';

class BoardLayout extends StatelessWidget {
  const BoardLayout({
    super.key,
    required this.sideBar,
    required this.mainContent,
  });

  final Widget sideBar, mainContent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: sideBar),
        Expanded(flex: 5, child: mainContent),
      ],
    );
  }
}
