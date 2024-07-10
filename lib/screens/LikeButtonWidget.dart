import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikeButtonWidget extends StatefulWidget {
  final String postId;
  final List<String> likes;
  final String currentUserId;
  final Function(List<String>) onLikeUpdate; // Callback function to update likes in parent widget

  const LikeButtonWidget({
    required this.postId,
    required this.likes,
    required this.currentUserId,
    required this.onLikeUpdate,
    Key? key,
  }) : super(key: key);

  @override
  _LikeButtonWidgetState createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<LikeButtonWidget> {
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.likes.contains(widget.currentUserId);
  }

  Future<void> _toggleLike() async {
    final postRef = FirebaseFirestore.instance.collection('videos').doc(widget.postId);
    final currentUserUid = widget.currentUserId;

    if (_isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUserUid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUserUid]),
      });
    }

    setState(() {
      _isLiked = !_isLiked;
    });

    final updatedPost = await postRef.get();
    final updatedLikes = List<String>.from(updatedPost['likes']);
    widget.onLikeUpdate(updatedLikes);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isLiked ? Icons.favorite : Icons.favorite_border,
        color: _isLiked ? Colors.red : Colors.white,
      ),
      onPressed: _toggleLike,
    );
  }
}
