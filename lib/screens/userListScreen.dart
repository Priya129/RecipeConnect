import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../global/app_colors.dart';
import 'profile_screen.dart';

class UserListScreen extends StatelessWidget {
  final List<String> userIds;
  final String title;

  const UserListScreen({
    Key? key,
    required this.userIds,
    required this.title,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
    var userDoc = await FirebaseFirestore.instance.collection('user').doc(userId).get();
    return userDoc.data()!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.mainColor,
      ),
      body: ListView.builder(
        itemCount: userIds.length,
        itemBuilder: (context, index) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserProfile(userIds[index]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(
                  title: Text('Loading...'),
                );
              }

              var userData = snapshot.data!;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userData['imageUrl']),
                ),
                title: Text(userData['username']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userId: userIds[index],
                        currentUserId: FirebaseAuth.instance.currentUser!.uid,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
