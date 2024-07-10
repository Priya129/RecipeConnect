import 'package:flutter/material.dart';
import '../Firebase_services/signin_screen.dart';
import '../Firebase_services/signup_screen.dart';
import '../screens/home_page.dart';
import '../navigation_pages/mainPage.dart';

class Routes {


  void navigateToSignUpScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SignUpScreen()),
    );
  }
  void navigateToMainPage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }


  void navigateToHomePages(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  void navigateToSignInScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) =>  SignInScreen()),
    );
  }


  }




