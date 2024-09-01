import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String text;
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message(
      senderId: doc['senderId'],
      text: doc['text'],
      timestamp: doc['timestamp'],
    );
  }
}
