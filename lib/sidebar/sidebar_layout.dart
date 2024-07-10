import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_project/sidebar/sidebar_item.dart';
import '../global/app_colors.dart';
import '../screens/recipe_post_screen.dart';
import '../screens/search_page.dart';

class SidebarLayout extends StatefulWidget {
  int selectedIndex = 0;
  final Function(int) onPressed;

  SidebarLayout({Key? key, required this.selectedIndex, required this.onPressed})
      : super(key: key);

  @override
  _SidebarLayoutState createState() => _SidebarLayoutState();
}

class _SidebarLayoutState extends State<SidebarLayout> {
  final LabeledGlobalKey _walletKey = LabeledGlobalKey("walletKey");
  final LabeledGlobalKey _restaurantKey = LabeledGlobalKey("restaurantKey");
  final LabeledGlobalKey _myCartKey = LabeledGlobalKey("myCartKey");
  final LabeledGlobalKey _myProfileKey = LabeledGlobalKey("myProfileKey");

  double startYPosition = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculatePosition(widget.selectedIndex);
    });
  }

  void calculatePosition(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        break;
      case 2:
        break;
      case 3:
        break;
    }
  }

  void onTabTap(int index) {
    setState(() {
      widget.onPressed(index);
      calculatePosition(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      decoration: const BoxDecoration(
        color: AppColors.transparentColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(100.0),
          bottomRight: Radius.circular(100.0),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RecipePost()));
            },
            child: const Icon(Icons.dashboard, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SearchPage()));
            },
            child: const Icon(Icons.search, color: Colors.grey),
          ),
          const SizedBox(height: 80),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                SidebarItem(
                  key: _walletKey,
                  text: "Snacks",
                  onTabTap: () {
                    onTabTap(0);
                  },
                  isSelected: widget.selectedIndex == 0,
                ),
                SidebarItem(
                  key: _restaurantKey,
                  text: "Food",
                  onTabTap: () {
                    onTabTap(1);
                  },
                  isSelected: widget.selectedIndex == 1,
                ),
                SidebarItem(
                  key: _myCartKey,
                  text: "Drinks",
                  onTabTap: () {
                    onTabTap(2);
                  },
                  isSelected: widget.selectedIndex == 2,
                ),
                SidebarItem(
                  key: _myProfileKey,
                  text: "Dessert",
                  onTabTap: () {
                    onTabTap(3);
                  },
                  isSelected: widget.selectedIndex == 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
