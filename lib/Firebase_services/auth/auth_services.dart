import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signUpWithEmailAndPassword(String email,
      String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email,
      String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  Future<void> saveUserData(String uid, String email, String username,
      String imageUrl) async {
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
      print('Error saving user data: ${e.toString()}');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser != null) {
        final GoogleSignInAuthentication gAuth = await gUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(
            credential);
        User? user = userCredential.user;

        if (user != null) {
          DocumentSnapshot userDoc = await _firestore.collection('user').doc(
              user.uid).get();
          if (!userDoc.exists) {
            await saveUserData(
              user.uid,
              user.email!,
              user.displayName ?? '',
              user.photoURL ?? '',
            );
          }
        }
      }
    } catch (e) {
      print("Error signing in with Google: $e");
    }
  }
}