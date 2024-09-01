import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../global/app_colors.dart';

class CommentInputField extends StatefulWidget {
  final String recipeId;
  final String? profileImageUrl;
  final String? username;
  final String? userid;
  final Function onCommentSubmitted;

  const CommentInputField({
    Key? key,
    required this.recipeId,
    required this.profileImageUrl,
    required this.username,
    required this.userid,
    required this.onCommentSubmitted,
  }) : super(key: key);

  @override
  _CommentInputFieldState createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _submitComment() async {
    if (_commentController.text.isNotEmpty) {
      String commentId = const Uuid().v1();
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.recipeId)
          .collection('comments')
          .doc(commentId)
          .set({
        'text': _commentController.text,
        'imageUrl': widget.profileImageUrl,
        'username': widget.username,
        'userid': widget.userid,
        'commentId': commentId,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
      });
      print("Comment Submitted: ${_commentController.text}");
      _commentController.clear();
      widget.onCommentSubmitted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  widget.profileImageUrl ?? "https://www.example.com/valid_default_profile_image.png",
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintStyle: TextStyle(color: Colors.black45),
                    hintText: "Leave a comment...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(120),
                    color: AppColors.mainColor,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(3.0),
                    child: Icon(
                      color: Colors.white,
                      Icons.arrow_upward,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
