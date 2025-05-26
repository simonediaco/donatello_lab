
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/recipients');
        break;
      case 2:
        context.go('/saved-gifts');
        break;
      case 3:
        context.go('/generate-gifts');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onNavTap(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0F0F0F),
      elevation: 0,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.subtitleColor,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.palette_outlined),
          activeIcon: Icon(Icons.palette),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          activeIcon: Icon(Icons.groups),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          activeIcon: Icon(Icons.favorite),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_outlined),
          activeIcon: Icon(Icons.auto_awesome),
          label: '',
        ),
      ],
    );
  }
}
