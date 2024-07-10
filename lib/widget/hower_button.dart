import 'package:flutter/material.dart';
import '../ImageRecognition/image_recognition.dart';
import '../global/app_colors.dart';

class HoverIconButton extends StatefulWidget {
  @override
  _HoverIconButtonState createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: Tooltip(
        message: 'Search Recipe using Image',
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isHovered ? AppColors.mainColor.withOpacity(2.0) : AppColors.mainColor,
          ),
          child: GestureDetector(
            onTap: (){Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => ImageRecognition()),
            );},
            child: const Icon(
              Icons.camera_alt_sharp,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
