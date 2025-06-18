import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isAdmin;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isAdmin,
    this.imageUrl,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isAdmin: data['isAdmin'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAdmin': isAdmin,
      'imageUrl': imageUrl,
    };
  }
}

class ChatRoom {
  final String id;
  final String userId;
  final String userName;
  final DateTime lastMessageTime;
  final String lastMessage;
  final bool hasUnreadMessages;

  ChatRoom({
    required this.id,
    required this.userId,
    required this.userName,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.hasUnreadMessages,
  });

  factory ChatRoom.fromMap(String id, Map<String, dynamic> data) {
    return ChatRoom(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null 
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessage: data['lastMessage'] ?? '',
      hasUnreadMessages: data['hasUnreadMessages'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessage': lastMessage,
      'hasUnreadMessages': hasUnreadMessages,
    };
  }
} 