import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signUpWithEmailAndPassword(String email, String password, BuildContext context) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
          content: Text("Email is already in use!")));
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password, BuildContext context) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
          content: Text("Incorrect password or email...try again!")));
      return null;
    }
  }

  Future<void> saveUserData(String uid, String email, String username, String imageUrl, BuildContext context) async {
    try {
      await _firestore.collection('user').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
        'imageUrl': imageUrl,
        'followings': [],
        'followers': []
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving user data: ${e.toString()}')));
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser != null) {
        final GoogleSignInAuthentication gAuth = await gUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          DocumentSnapshot userDoc = await _firestore.collection('user').doc(user.uid).get();
          if (!userDoc.exists) {
            await saveUserData(user.uid, user.email!, user.displayName ?? '', user.photoURL ?? '', context);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error signing in with Google: $e")));
    }
  }
}
