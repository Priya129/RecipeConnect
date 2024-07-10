import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerButton extends StatelessWidget {
  final Function(ImageSource) onPressed;

  const ImagePickerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(ImageSource.gallery),
      child: Text('Select Image'),
    );
  }
}
