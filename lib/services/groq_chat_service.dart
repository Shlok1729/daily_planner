import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:daily_planner/config/environment_config.dart';

class GroqChatService {
  final String apiKey;
  final String baseUrl;
  String _systemPrompt = '';

  static const String defaultModel = 'llama3-8b-8192';
  static const int maxTokens = 1024;
  static const double temperature = 0.7;

  GroqChatService({
    required this.apiKey,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? EnvironmentConfig.groqBaseUrl;

  /// Check if the service is properly configured
  bool get isConfigured => apiKey.isNotEmpty && apiKey != 'your_groq_api_key_here';

  /// Initialize the system prompt for the chat service
  void initializeSystemPrompt(String prompt) {
    _systemPrompt = prompt;
    if (kDebugMode) {
      print('✅ Groq system prompt initialized');
    }
  }

  /// Ask a question and get a response
  Future<String> ask(
      String question, {
        String? model,
        int? maxTokens,
        double? temperature,
      }) async {
    if (!isConfigured) {
      throw GroqApiException('API key not configured', 401);
    }

    try {
      final messages = [
        if (_systemPrompt.isNotEmpty)
          {
            'role': 'system',
            'content': _systemPrompt,
          },
        {
          'role': 'user',
          'content': question,
        },
      ];

      final response = await _makeRequest(
        messages: messages,
        model: model ?? defaultModel,
        maxTokens: maxTokens ?? GroqChatService.maxTokens,
        temperature: temperature ?? GroqChatService.temperature,
      );

      return _extractResponseContent(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in Groq chat service: $e');
      }
      rethrow;
    }
  }

  /// Ask with conversation context
  Future<String> askWithContext(
      String question,
      List<Map<String, String>> conversationHistory, {
        String? model,
        int? maxTokens,
        double? temperature,
      }) async {
    if (!isConfigured) {
      throw GroqApiException('API key not configured', 401);
    }

    try {
      final messages = [
        if (_systemPrompt.isNotEmpty)
          {
            'role': 'system',
            'content': _systemPrompt,
          },
        ...conversationHistory,
        {
          'role': 'user',
          'content': question,
        },
      ];

      final response = await _makeRequest(
        messages: messages,
        model: model ?? defaultModel,
        maxTokens: maxTokens ?? GroqChatService.maxTokens,
        temperature: temperature ?? GroqChatService.temperature,
      );

      return _extractResponseContent(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in Groq chat service with context: $e');
      }
      rethrow;
    }
  }

  /// Make HTTP request to Groq API
  Future<Map<String, dynamic>> _makeRequest({
    required List<Map<String, dynamic>> messages,
    required String model,
    required int maxTokens,
    required double temperature,
  }) async {
    final url = Uri.parse('$baseUrl/chat/completions');

    final requestBody = {
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': false,
    };

    if (kDebugMode) {
      print('🚀 Making Groq API request...');
      print('Model: $model');
      print('Messages count: ${messages.length}');
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw GroqApiException('Request timed out after 30 seconds', 408);
        },
      );

      if (kDebugMode) {
        print('📡 Groq API response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (kDebugMode) {
          final usage = responseData['usage'] as Map<String, dynamic>?;
          if (usage != null) {
            print('📊 Token usage - Prompt: ${usage['prompt_tokens']}, Completion: ${usage['completion_tokens']}, Total: ${usage['total_tokens']}');
          }
        }

        return responseData;
      } else {
        final errorBody = response.body;
        if (kDebugMode) {
          print('❌ Groq API error: ${response.statusCode}');
          print('Error body: $errorBody');
        }

        // Parse error message if available
        try {
          final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
          final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
          throw GroqApiException(
            'Groq API error (${response.statusCode}): $errorMessage',
            response.statusCode,
          );
        } catch (e) {
          if (e is GroqApiException) rethrow;
          throw GroqApiException(
            'Groq API error (${response.statusCode}): $errorBody',
            response.statusCode,
          );
        }
      }
    } on http.ClientException catch (e) {
      throw GroqApiException('Network error: ${e.message}', 0);
    } catch (e) {
      if (e is GroqApiException) rethrow;
      throw GroqApiException('Unexpected error: $e', 0);
    }
  }

  /// Extract response content from API response
  String _extractResponseContent(Map<String, dynamic> response) {
    try {
      final choices = response['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw GroqApiException('No choices in response', 0);
      }

      final firstChoice = choices[0] as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      if (message == null) {
        throw GroqApiException('No message in choice', 0);
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        throw GroqApiException('Empty content in message', 0);
      }

      return content.trim();
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting response content: $e');
        print('Response structure: ${jsonEncode(response)}');
      }
      if (e is GroqApiException) rethrow;
      throw GroqApiException('Failed to extract response content: $e', 0);
    }
  }

  /// Test the connection to Groq API
  Future<bool> testConnection() async {
    if (!isConfigured) {
      if (kDebugMode) {
        print('⚠️ Groq API key not configured');
      }
      return false;
    }

    try {
      await ask('Hello! Please respond with just "OK" to test the connection.');
      if (kDebugMode) {
        print('✅ Groq connection test successful');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Groq connection test failed: $e');
      }
      return false;
    }
  }

  /// Get available models (if supported by Groq API)
  Future<List<String>> getAvailableModels() async {
    if (!isConfigured) {
      return _getDefaultModels();
    }

    try {
      final url = Uri.parse('$baseUrl/models');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = data['data'] as List<dynamic>?;
        if (models != null) {
          return models
              .map((model) => model['id'] as String)
              .toList();
        }
      }

      // Return default models if API call fails
      return _getDefaultModels();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available models: $e');
      }
      // Return default models
      return _getDefaultModels();
    }
  }

  List<String> _getDefaultModels() {
    return [
      'llama3-8b-8192',
      'llama3-70b-8192',
      'mixtral-8x7b-32768',
      'gemma-7b-it',
    ];
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'api_key_configured': isConfigured,
      'base_url': baseUrl,
      'system_prompt_set': _systemPrompt.isNotEmpty,
      'default_model': defaultModel,
      'max_tokens': maxTokens,
      'temperature': temperature,
    };
  }

  /// Get a user-friendly status message
  String getStatusMessage() {
    if (!isConfigured) {
      return 'API key not configured. Using offline responses.';
    }

    return 'AI assistant ready with Groq API integration.';
  }
}

/// Custom exception for Groq API errors
class GroqApiException implements Exception {
  final String message;
  final int statusCode;

  GroqApiException(this.message, this.statusCode);

  @override
  String toString() => 'GroqApiException: $message (Status: $statusCode)';

  /// Check if this is a network-related error
  bool get isNetworkError => statusCode == 0 || statusCode == 408;

  /// Check if this is an authentication error
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// Check if this is a rate limit error
  bool get isRateLimitError => statusCode == 429;

  /// Check if this is a server error
  bool get isServerError => statusCode >= 500;

  /// Get a user-friendly error message
  String get userFriendlyMessage {
    if (isNetworkError) {
      return 'Network connection issue. Please check your internet connection.';
    } else if (isAuthError) {
      return 'API authentication failed. Please check your API key configuration.';
    } else if (isRateLimitError) {
      return 'Too many requests. Please wait a moment before trying again.';
    } else if (isServerError) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else {
      return 'An unexpected error occurred. Using offline responses.';
    }
  }
}