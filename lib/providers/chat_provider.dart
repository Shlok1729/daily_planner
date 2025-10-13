import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/models/message_model.dart';
import 'package:daily_planner/services/chatbot_service.dart';
import 'package:daily_planner/services/storage_service.dart';

// Provider for the chat state
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});

// Chat state class
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Chat notifier class
class ChatNotifier extends Notifier<ChatState> {
  final ChatbotService _chatbotService = ChatbotService();
  final StorageService _storageService = StorageService();

  @override
  ChatState build() {
    _loadMessages();
    return ChatState(messages: [
      Message(
        content: 'Hello! I\'m your productivity assistant. How can I help you today?',
        sender: MessageSender.bot,
      ),
    ]);
  }

  // Load messages from storage
  Future<void> _loadMessages() async {
    try {
      final messages = await _storageService.getAllMessages();

      if (messages.isNotEmpty) {
        state = state.copyWith(messages: messages);
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  // Send a message to the chatbot
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Create user message
    final userMessage = Message(
      content: content,
      sender: MessageSender.user,
    );

    // Update state with user message and loading state
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Save user message to storage
      await _storageService.saveMessage(userMessage);

      // Get response from chatbot
      final botResponse = await _chatbotService.sendMessage(content);

      // Save bot response to storage
      await _storageService.saveMessage(botResponse);

      // Update state with bot response
      state = state.copyWith(
        messages: [...state.messages, botResponse],
        isLoading: false,
      );
    } catch (e) {
      // Handle error
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get response from assistant',
      );
    }
  }

  // Clear chat history
  Future<void> clearChat() async {
    try {
      await _storageService.clearMessages();

      state = ChatState(messages: [
        Message(
          content: 'Hello! I\'m your productivity assistant. How can I help you today?',
          sender: MessageSender.bot,
        ),
      ]);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to clear chat history',
      );
    }
  }

  // Get suggestions based on the last message
  List<String> getSuggestions() {
    if (state.messages.isEmpty) {
      return [
        'How can you help me?',
        'Create a new task',
        'Start a focus session',
      ];
    }

    final lastMessage = state.messages.last;
    return _chatbotService.getSuggestions(lastMessage.content);
  }
}