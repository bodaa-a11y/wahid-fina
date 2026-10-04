import 'package:cloud_firestore/cloud_firestore.dart';

class OneToOneRoomModel {
  final String roomId;
  final List<String> participants;
  final String status; // 'waiting', 'active', 'closed'
  final List<String> typingUsers;
  final String topic;

  OneToOneRoomModel({
    required this.roomId,
    required this.participants,
    required this.status,
    this.typingUsers = const [],
    this.topic = 'فضفضة عامة ☕',
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'participants': participants,
      'status': status,
      'typingUsers': typingUsers,
      'topic': topic,
    };
  }

  factory OneToOneRoomModel.fromMap(Map<String, dynamic> map) {
    return OneToOneRoomModel(
      roomId: map['roomId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      status: map['status'] ?? 'waiting',
      typingUsers: List<String>.from(map['typingUsers'] ?? []),
      topic: map['topic'] ?? 'فضفضة عامة ☕',
    );
  }
}

class OneToOneMessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String text;
  final String type; // 'text', 'audio', 'system'
  final String? audioBase64;
  final DateTime timestamp;
  final String? reaction;

  OneToOneMessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    this.text = '',
    required this.type,
    this.audioBase64,
    required this.timestamp,
    this.reaction,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
      'audioBase64': audioBase64,
      'timestamp': timestamp,
      'reaction': reaction,
    };
  }

  factory OneToOneMessageModel.fromMap(Map<String, dynamic> map) {
    return OneToOneMessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      audioBase64: map['audioBase64'],
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      reaction: map['reaction'],
    );
  }
}
