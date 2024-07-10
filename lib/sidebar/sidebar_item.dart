import 'package:flutter/material.dart';
import 'package:recipe_project/sidebar/textStyles.dart';

class SidebarItem extends StatelessWidget {
  final bool isSelected;
  final String text;
  final VoidCallback onTabTap;

  const SidebarItem({
    Key? key,
    required this.isSelected,
    required this.text,
    required this.onTabTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 1.5708,
      child: GestureDetector(
        onTap: onTabTap,
        child: AnimatedDefaultTextStyle(
          style: isSelected ? selectedTabStyle : defaultTabStyle,
          duration: const Duration(milliseconds: 200),
          child: Text(
            text,
          ),
        ),
      ),
    );
  }
}
