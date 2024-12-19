import 'package:app/tab_container_screen.dart';
import 'package:go_router/go_router.dart';

class Navigation {
  static final routes = [
    GoRoute(
        path: '/home',
        name: TabContainerScreen.route,
        builder: (_, __) => const TabContainerScreen()),
  ];
}
