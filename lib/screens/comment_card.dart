import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../global/app_colors.dart';

class CommentCard extends StatelessWidget {
  final String commentId;
  final String recipeId;
  final String username;
  final String comment;
  final String profileImageUrl;
  final List<String> likes;
  final bool isOwnerOrCommenter;
  final VoidCallback onDelete;

  const CommentCard({
    Key? key,
    required this.commentId,
    required this.recipeId,
    required this.username,
    required this.comment,
    required this.profileImageUrl,
    required this.likes,
    required this.isOwnerOrCommenter,
    required this.onDelete,
  }) : super(key: key);

  bool get isLiked {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return likes.contains(user.uid);
    }
    return false;
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final commentRef = FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .collection('comments')
          .doc(commentId);

      if (isLiked) {
        await commentRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await commentRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: isOwnerOrCommenter
          ? () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Comment'),
              content: Text('Are you sure you want to delete this comment?'),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Delete'),
                  onPressed: () {
                    onDelete();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
          : null,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: AppColors.transparentColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text(likes.length.toString()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
