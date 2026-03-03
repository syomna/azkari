import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:azkar_app/core/presentation/providers/theme_provider.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/presentation/pages/all_azkar_page.dart';
import 'package:azkar_app/pages/home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = !themeProvider.isLight;

    return Scaffold(
      extendBody:
          true, // This is CRUCIAL for the curved bottom bar to look good
      body: _bottomNavIndex == 0 ? const HomePage() : const AllAzkarPage(),

      floatingActionButton: FloatingActionButton(
        onPressed: () => themeProvider.toggleTheme(),
        backgroundColor: AppPalette.mainColor,
        elevation: 4, // Add some elevation for depth
        shape: const CircleBorder(), // Keeps it perfectly round
        child: Icon(
          !themeProvider.isLight
              ? CupertinoIcons.sun_max_fill
              : CupertinoIcons.moon_fill,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: const [
          CupertinoIcons.house_fill, // Filled icons look better when active
          CupertinoIcons.book_fill,
        ],
        // Change background to match the "Glass" look or solid theme color
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        activeIndex: _bottomNavIndex,
        activeColor: AppPalette.mainColor,
        inactiveColor: Colors.grey.withValues(alpha: 0.5),
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }
}
