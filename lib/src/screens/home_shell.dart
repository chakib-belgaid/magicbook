import 'package:flutter/material.dart';

import '../state/magic_book_scope.dart';
import '../theme/magic_book_theme.dart';
import 'create_screen.dart';
import 'gallery_screen.dart';
import 'my_works_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MagicBookScope.of(context);
    final screens = <Widget>[
      const CreateScreen(),
      const GalleryScreen(),
      const MyWorksScreen(),
    ];

    return Scaffold(
      body: screens[controller.tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.tabIndex,
        onDestinationSelected: controller.setTabIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            selectedIcon: Icon(Icons.image_rounded),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(
              Icons.favorite_rounded,
              color: MagicBookColors.pink,
            ),
            label: 'My Works',
          ),
        ],
      ),
    );
  }
}
