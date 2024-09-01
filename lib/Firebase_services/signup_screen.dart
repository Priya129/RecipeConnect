import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../global/button.dart';
import '../global/custom_text_field.dart';
import '../global/app_colors.dart';
import '../routes/routes.dart';
import 'auth/auth_services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  Uint8List? image;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Loading state variable

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    String pattern = r'^[^@]+@[^@]+\.[^@]+';
    if (!RegExp(pattern).hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateRepeatPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the password again';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> selectImage() async {
    try {
      final pickedfile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedfile != null) {
        Uint8List pickedImage = await pickedfile.readAsBytes();
        setState(() {
          image = pickedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<String?> uploadImage(BuildContext context) async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please pick an image")),
      );
      return null;
    } else {
      try {
        Reference storageref = FirebaseStorage.instance.ref().child("profilePic/${DateTime.now().millisecondsSinceEpoch}");
        UploadTask uploadTask = storageref.putData(image!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
        return null;
      }
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      String username = usernameController.text.trim();
      try {
        var user = await _authService.signUpWithEmailAndPassword(email, password, context);
        if (user != null) {
          String? imageUrl = await uploadImage(context);
          if (imageUrl != null) {
            await _authService.saveUserData(user.uid, email, username, imageUrl, context);
          }
          Routes().navigateToMainPage(context);
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
        } else {
          message = 'Sign up failed: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: Text('Register',
                style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 20, color: AppColors.mainColor)),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: GestureDetector(
                      onTap: selectImage,
                      child: CircleAvatar(
                        radius: 64,
                        backgroundImage: image != null
                            ? MemoryImage(image!) as ImageProvider<Object>
                            : const NetworkImage(
                            'https://i.stack.imgur.com/l60Hf.png'),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Center(
                    child: Text(
                      "Register with an email...",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: usernameController,
                            hintText: 'Enter your username',
                            isPassword: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 25),
                          CustomTextField(
                            controller: emailController,
                            hintText: 'Enter your email',
                            isPassword: false,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 25),
                          CustomTextField(
                            controller: passwordController,
                            hintText: 'Enter your password',
                            isPassword: true,
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 25),
                          CustomTextField(
                            controller: repeatPasswordController,
                            hintText: 'Enter your password again',
                            isPassword: true,
                            validator: _validateRepeatPassword,
                          ),
                          const SizedBox(height: 40.0),
                          _isLoading
                              ? Center(child: CircularProgressIndicator(color: AppColors.mainColor,))
                              : Button(
                            name: "Sign Up",
                            onPressed: _signUp,
                          ),
                          const SizedBox(height: 40.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account?",
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.grey)),
                              InkWell(
                                onTap: () {
                                  Routes().navigateToSignInScreen(context);
                                },
                                child: const Text(
                                  " Sign in",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget socialButton(String asset, VoidCallback onTap) {
    return Container(
      height: 70,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.transparentColor,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Image.asset(
            asset,
            height: 40,
            width: 40,
          ),
        ),
      ),
    );
  }
}
