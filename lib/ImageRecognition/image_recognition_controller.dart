import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'model/food_model.dart';

class ImageRecognitionController {
  File? _imageFile;
  List<FoodModel>? _recognizedFoods;

  File? get imageFile => _imageFile;
  List<FoodModel>? get recognizedFoods => _recognizedFoods;

  Future<void> getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
    }
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) return;

    final String apiUrl = 'https://api.logmeal.com/v2/image/recognition/complete/v1.0';
    final String apiKey = 'c27aa9ccd21d4f7dabe9f4fbfe30eac8468ebc37';

    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(_imageFile!.path),
      });

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $apiKey';

      final response = await dio.post(apiUrl, data: formData);
      final Map<String, dynamic> jsonResponse = response.data;

      if (jsonResponse['recognition_results'] != null) {
        _recognizedFoods = List<FoodModel>.from(
          jsonResponse['recognition_results'].map((item) => FoodModel.fromJson(item)),
        );
      } else {
        _recognizedFoods = [];
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }
}
