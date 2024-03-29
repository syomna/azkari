import 'dart:io';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:azkar_app/pages/azkar.dart';
import 'package:azkar_app/pages/home.dart';
import 'package:azkar_app/providers/theme_provider.dart';
import 'package:azkar_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Layout extends StatefulWidget {
  const Layout({Key? key}) : super(key: key);

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  int _bottomNavIndex = 0;
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: _bottomNavIndex == 0 ? const Home() : const Azkar(), //destination screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          themeProvider.toggleTheme();
        },
        backgroundColor: mainColor,
        child: Icon(
          !themeProvider.isLight
              ? Icons.light_mode
              : Icons.nightlight,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: const [
          Icons.home_outlined,
          Icons.book_outlined,
          
        ],
        height: Platform.isAndroid ? MediaQuery.of(context).size.height * 0.09 : null,
        activeColor: mainColor,
        activeIndex: _bottomNavIndex,
        backgroundColor: themeProvider.isLight ? Colors.green.shade100 : Theme.of(context).primaryColorDark,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }
}
