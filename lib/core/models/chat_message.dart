part of 'models.dart';

enum ChatRole { user, assistant, system }

class ChatMessage {
  final String id;
  final String videoId;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.videoId,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}
