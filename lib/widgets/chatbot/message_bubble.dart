import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daily_planner/models/message_model.dart';
import 'package:daily_planner/utils/icon_renderer.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;

  const MessageBubble({
    Key? key,
    required this.message,
    this.showAvatar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final brightness = Theme.of(context).brightness;

    // Adjust colors based on theme brightness
    final userBubbleColor = Theme.of(context).colorScheme.primary;
    final botBubbleColor = brightness == Brightness.dark
        ? Theme.of(context).cardColor
        : Colors.white;

    final userTextColor = Colors.white;
    final botTextColor = brightness == Brightness.dark
        ? Theme.of(context).textTheme.bodyLarge?.color
        : Colors.black87;

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 64 : 0,
        right: isUser ? 0 : 64,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && showAvatar)
            Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  IconRenderer.chatIcon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            )
          else if (!isUser && !showAvatar)
            SizedBox(width: 48),

          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? userBubbleColor : botBubbleColor,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? Radius.circular(0) : null,
                      bottomLeft: !isUser ? Radius.circular(0) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? userTextColor : botTextColor,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          if (isUser && showAvatar)
            Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  IconRenderer.personIcon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            )
          else if (isUser && !showAvatar)
            SizedBox(width: 48),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(timestamp);
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}