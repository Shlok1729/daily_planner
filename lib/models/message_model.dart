import 'package:uuid/uuid.dart';

enum MessageType { text, suggestion }
enum MessageSender { user, bot }

// FIXED: Added MessageTheme enum with displayName getter
enum MessageTheme {
  funny,
  motivational,
  challenging,
  supportive,
  humorous;

  /// FIXED: Added missing displayName getter
  String get displayName {
    switch (this) {
      case MessageTheme.funny:
        return 'Hilarious (💀 ain\'t no way bro...)';
      case MessageTheme.motivational:
        return 'Motivational (your future self will thank you)';
      case MessageTheme.challenging:
        return 'Challenging (resist the gram, embrace grind)';
      case MessageTheme.supportive:
        return 'Supportive (you got this! stay focused)';
      case MessageTheme.humorous:
        return 'Humorous (light-hearted and fun)';
    }
  }

  /// Get example message for each theme
  String get exampleMessage {
    switch (this) {
      case MessageTheme.funny:
        return '"Ain\'t no way bro tried to open TikTok 💀"';
      case MessageTheme.motivational:
        return '"Your future self will thank you"';
      case MessageTheme.challenging:
        return '"Resist the urge, embrace the grind"';
      case MessageTheme.supportive:
        return '"You got this! Stay focused 💪"';
      case MessageTheme.humorous:
        return '"Looks like someone tried to escape focus mode! 😄"';
    }
  }

  /// Get theme description
  String get description {
    switch (this) {
      case MessageTheme.funny:
        return 'Gen-Z humor with emojis and slang';
      case MessageTheme.motivational:
        return 'Inspiring messages to keep you motivated';
      case MessageTheme.challenging:
        return 'Tough love approach to resist distractions';
      case MessageTheme.supportive:
        return 'Encouraging and positive reinforcement';
      case MessageTheme.humorous:
        return 'Light-hearted jokes and wordplay';
    }
  }
}

class Message {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;

  Message({
    String? id,
    required this.content,
    this.type = MessageType.text,
    required this.sender,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type.index,
      'sender': sender.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      type: MessageType.values[map['type']],
      sender: MessageSender.values[map['sender']],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  /// Create a copy with updated fields
  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageSender? sender,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, content: $content, type: $type, sender: $sender, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}