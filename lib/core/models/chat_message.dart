enum ChatRole { user, assistant, system }

class ChatMessageModel {
  final String id;
  final String videoId;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.id,
    required this.videoId,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}
