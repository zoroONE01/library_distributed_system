import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            onDestinationSelected: (index) {
              navigationShell.goBranch(index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Trang chủ'),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bookmark),
                label: Text('Đầu sách'),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.book),
                label: Text('Quyển sách'),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Độc giả'),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add),
                label: Text('Mượn sách'),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.transfer_within_a_station_rounded),
                label: Text('Chuyển sách'),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ],
            selectedIndex: navigationShell.currentIndex,
          ),
          const VerticalDivider(thickness: 0, width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
