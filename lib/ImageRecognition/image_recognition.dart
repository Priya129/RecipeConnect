import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../global/app_colors.dart';
import '../screens/search_page.dart';
import '../widget/image_picker_dialog.dart';
import 'image_recognition_controller.dart';

class ImageRecognition extends StatefulWidget {
  @override
  _ImageRecognitionState createState() => _ImageRecognitionState();
}

class _ImageRecognitionState extends State<ImageRecognition> {
  final ImageRecognitionController _controller = ImageRecognitionController();

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ImagePickerDialog(
          onCamera: () {
            _controller.getImage(ImageSource.camera).then((_) => setState(() {}));
            Navigator.of(context).pop();
          },
          onGallery: () {
            _controller.getImage(ImageSource.gallery).then((_) => setState(() {}));
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparentColor,
      appBar: AppBar(
        leading: BackButton(
          color: AppColors.mainColor,
        ),
        title: Text(
          'Food Image Recognition',
          style: TextStyle(
            color: AppColors.mainColor,
            fontSize: 15,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              if (_controller.imageFile != null)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    height: 400,
                    width: 500,
                    alignment: Alignment.center,
                    child: Image.file(_controller.imageFile!),
                  ),
                ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20.0),
                  Container(
                    height: 40,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: _showImagePickerDialog,
                      icon: Icon(Icons.camera_enhance_sharp, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _controller.uploadImage().then((_) => setState(() {}));
                      },
                      icon: const Text(
                        'Recognize Image',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              if (_controller.recognizedFoods != null) _buildFoodList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _controller.recognizedFoods!.length,
        itemBuilder: (context, index) {
          final food = _controller.recognizedFoods![index];
          final double probability = food.probability;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchPage(
                    initialQuery: food.name,
                  ),
                ),
              );
            },
            child: Card(
              color: Colors.deepOrange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: LinearProgressIndicator(
                        value: probability,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Probability: ${(probability * 100).toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
