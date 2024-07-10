import 'package:flutter/material.dart';
import '../navigation_pages/side_bar_navigations/DessertPage.dart';
import '../navigation_pages/side_bar_navigations/Drinks_Pages.dart';

import '../navigation_pages/side_bar_navigations/Food.dart';

import '../navigation_pages/side_bar_navigations/Snack_Page.dart';


import '../sidebar/sidebar_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  List<Widget> screens = [
    SnackPage(),
    FoodPage(),
    DrinksPage(),
    DessertPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: SidebarLayout(
              selectedIndex: selectedIndex,
              onPressed: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),
          ),
          Expanded(child: screens[selectedIndex]),
        ],
      ),

    );
  }
}