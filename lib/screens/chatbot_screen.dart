import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/models/message_model.dart';
import 'package:daily_planner/widgets/chatbot/message_bubble.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  const ChatbotScreen({
    Key? key,
    this.initialMessage,
  }) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late AnimationController _typingAnimationController;

  // Mock messages for demonstration
  final List<Message> _messages = [
    Message(
      content: 'Hello! I\'m your productivity assistant. How can I help you today?',
      sender: MessageSender.bot,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // If there's an initial message, send it automatically
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _sendMessage([String? customMessage]) {
    final messageText = customMessage ?? _messageController.text;
    if (messageText.trim().isEmpty) return;

    final userMessage = Message(
      content: messageText,
      sender: MessageSender.user,
    );

    setState(() {
      _messages.add(userMessage);
      if (customMessage == null) {
        _messageController.clear();
      }
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate bot response after a delay
    Future.delayed(Duration(seconds: 2), () {
      final botResponse = _getBotResponse(userMessage.content);

      setState(() {
        _isTyping = false;
        _messages.add(Message(
          content: botResponse,
          sender: MessageSender.bot,
        ));
      });

      _scrollToBottom();
    });
  }

  String _getBotResponse(String message) {
    final lowerMessage = message.toLowerCase();

    // Eisenhower Matrix responses
    if (lowerMessage.contains('eisenhower') || lowerMessage.contains('matrix')) {
      return '''The Eisenhower Matrix is a powerful productivity tool that helps you prioritize tasks by urgency and importance:

🔴 **DO (Urgent + Important)**: Crisis situations, emergencies, deadline-driven projects. Handle these immediately.

🟠 **DECIDE (Important + Not Urgent)**: Strategic planning, personal development, prevention activities. Schedule these for later.

🔵 **DELEGATE (Urgent + Not Important)**: Interruptions, some emails, non-essential meetings. Delegate if possible.

⚪ **DELETE (Not Urgent + Not Important)**: Time wasters, excessive social media, trivial activities. Eliminate these.

**Tips for effective use:**
• Review and categorize your tasks weekly
• Spend most time in the "Decide" quadrant for long-term success
• Be honest about what's truly urgent vs. just feeling urgent
• Regularly eliminate or delegate tasks in the bottom quadrants

Would you like help categorizing any specific tasks?''';
    }

    // Pomodoro Technique responses
    if (lowerMessage.contains('pomodoro') || lowerMessage.contains('technique')) {
      return '''The Pomodoro Technique is a time management method that breaks work into focused intervals:

🍅 **How it works:**
1. Choose a task to work on
2. Set a timer for 25 minutes
3. Work on the task until the timer rings
4. Take a 5-minute break
5. After 4 pomodoros, take a longer 15-30 minute break

🎯 **Benefits:**
• Improves focus and concentration
• Reduces mental fatigue
• Helps overcome procrastination
• Makes large tasks feel manageable
• Provides regular breaks to prevent burnout

💡 **Pro Tips:**
• Turn off notifications during work sessions
• Use breaks for physical movement
• Don't check email/social media during breaks
• If you finish early, use remaining time for review
• Track completed pomodoros to measure productivity

Ready to start your first pomodoro session?''';
    }

    // General productivity responses
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! How can I assist you with your tasks today?';
    } else if (lowerMessage.contains('task') || lowerMessage.contains('todo')) {
      return 'I can help you manage your tasks. Would you like to create a new task, view your existing tasks, or get suggestions for task prioritization using the Eisenhower Matrix?';
    } else if (lowerMessage.contains('focus')) {
      return 'For better focus, I recommend trying the Pomodoro Technique! Work for 25 minutes, then take a 5-minute break. Would you like to start a focus session now?';
    } else if (lowerMessage.contains('schedule') || lowerMessage.contains('plan')) {
      return 'I can help you plan your day. Would you like me to suggest a schedule based on your pending tasks using the Eisenhower Matrix?';
    } else if (lowerMessage.contains('productivity') || lowerMessage.contains('tip')) {
      return 'Here\'s a productivity tip: Try the "2-minute rule" - if a task takes less than 2 minutes to complete, do it immediately instead of scheduling it for later. Also, consider using the Eisenhower Matrix to prioritize your tasks!';
    } else {
      return 'I\'m here to help with your productivity needs. You can ask me about:\n\n• Task management and prioritization\n• The Eisenhower Matrix\n• The Pomodoro Technique\n• Focus and concentration tips\n• Scheduling and time management\n\nWhat would you like to learn about?';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Assistant'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Assistant'),
                  content: Text(
                    'Your productivity assistant can help you with task management, focus sessions, scheduling, and productivity tips. Just ask a question to get started!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildImprovedMessageBubble(
                  message,
                  index == 0 || _messages[index - 1].sender != message.sender,
                );
              },
            ),
          ),

          // Typing indicator
          if (_isTyping) _buildTypingIndicator(),

          // Quick suggestions
          _buildSuggestionsRow(),

          // Message input - FIXED for dark mode
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildImprovedMessageBubble(Message message, bool showAvatar) {
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
        : Color(0xFF1C1C1E);

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
                  Icons.smart_toy,
                  color: Theme.of(context).colorScheme.primary,
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else if (isUser && !showAvatar)
            SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
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
                Icons.smart_toy,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: 4),
                _buildTypingDot(1),
                SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final progress = _typingAnimationController.value;
        final dotProgress = ((progress * 3) - index).clamp(0.0, 1.0);
        final opacity = (dotProgress * 2).clamp(0.0, 1.0);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsRow() {
    return Container(
      height: 50,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildSuggestionChip('Explain Eisenhower Matrix', Theme.of(context).colorScheme.primary),
          _buildSuggestionChip('Pomodoro Technique', Colors.green),
          _buildSuggestionChip('Productivity tips', Colors.orange),
          _buildSuggestionChip('Focus strategies', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
        onPressed: () => _sendMessage(text),
        elevation: 0,
        pressElevation: 2,
      ),
    );
  }

  Widget _buildMessageInput() {
    final brightness = Theme.of(context).brightness;
    final inputBackgroundColor = brightness == Brightness.dark
        ? Colors.grey[800]
        : Colors.grey[100];
    final hintColor = brightness == Brightness.dark
        ? Colors.grey[400]
        : Colors.grey[600];
    final textColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: inputBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: hintColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _sendMessage(),
                icon: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}