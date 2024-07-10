import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/recipe.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> toggleFavorite(Recipe recipe) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userFavoritesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(recipe.id);

      DocumentSnapshot doc = await userFavoritesRef.get();
      if (doc.exists) {
        await userFavoritesRef.delete();
      } else {
        await userFavoritesRef.set(recipe.toJson());
      }
    }
  }

  Stream<List<String>> getFavorites() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
    } else {
      return Stream.value([]);
    }
  }
}
