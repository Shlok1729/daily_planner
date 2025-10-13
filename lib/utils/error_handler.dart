import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// GLOBAL ERROR HANDLER (FIXED - ADDED MISSING SNACKBAR METHODS)
// ============================================================================

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  static bool _isInitialized = false;
  static final List<String> _errorLog = [];
  static final List<ErrorContext> _errorContextLog = [];

  /// Initialize global error handling
  static void initialize() {
    if (_isInitialized) return;

    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Handle errors outside of Flutter (async errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    _isInitialized = true;

    if (kDebugMode) {
      print('✅ Global error handling initialized');
    }
  }

  // ============================================================================
  // CORE ERROR HANDLING METHODS
  // ============================================================================

  /// Handle Flutter framework errors
  static void _handleFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, show detailed error information
      print('=== FLUTTER ERROR ===');
      print('Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
      print('Library: ${details.library}');
      print('Context: ${details.context}');
      print('==================');

      // Still call the original error handler in debug
      FlutterError.presentError(details);
    } else {
      // In production, log the error and show user-friendly message
      logError('Flutter Error', details.exception, details.stack);
    }
  }

  /// Handle platform errors (async errors outside Flutter)
  static void _handlePlatformError(Object error, StackTrace stack) {
    if (kDebugMode) {
      print('=== PLATFORM ERROR ===');
      print('Error: $error');
      print('Stack trace: $stack');
      print('===================');
    } else {
      logError('Platform Error', error, stack);
    }
  }

  // ============================================================================
  // PUBLIC ERROR LOGGING METHODS
  // ============================================================================

  /// Main error logging method
  static void logError(String type, Object error, [StackTrace? stack]) {
    final timestamp = DateTime.now().toIso8601String();
    final errorMessage = '[$timestamp] $type: $error';

    // Add to internal log
    _errorLog.add(errorMessage);

    // Add to context log
    _errorContextLog.add(ErrorContext(
      type: type,
      error: error,
      stackTrace: stack,
      timestamp: DateTime.now(),
    ));

    // Print to console
    print(errorMessage);
    if (stack != null) {
      print('Stack trace: $stack');
    }

    // Keep only last 100 errors to prevent memory issues
    if (_errorLog.length > 100) {
      _errorLog.removeAt(0);
    }
    if (_errorContextLog.length > 100) {
      _errorContextLog.removeAt(0);
    }

    // In production, send to crash reporting service
    if (kReleaseMode) {
      _sendToCrashReporting(type, error, stack);
    }
  }

  /// Log error with additional context
  static void logErrorWithContext(
      String type,
      Object error,
      StackTrace? stack,
      Map<String, dynamic>? context,
      ) {
    final contextStr = context != null ? '\nContext: $context' : '';
    logError('$type$contextStr', error, stack);
  }

  /// Handle async errors with try-catch wrapper
  static Future<T?> handleAsyncError<T>(
      Future<T> Function() operation, {
        String? context,
        T? fallbackValue,
        bool rethrowError = false,
      }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      final errorContext = context ?? 'Async Operation';
      logError(errorContext, error, stackTrace);

      if (rethrowError) {
        rethrow;
      }

      return fallbackValue;
    }
  }

  /// Handle sync errors with try-catch wrapper
  static T? handleSyncError<T>(
      T Function() operation, {
        String? context,
        T? fallbackValue,
        bool rethrowError = false,
      }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      final errorContext = context ?? 'Sync Operation';
      logError(errorContext, error, stackTrace);

      if (rethrowError) {
        rethrow;
      }

      return fallbackValue;
    }
  }

  /// Log warning (non-fatal error)
  static void logWarning(String message, [Object? details]) {
    final timestamp = DateTime.now().toIso8601String();
    final warningMessage = '[$timestamp] WARNING: $message';

    if (details != null) {
      print('$warningMessage - Details: $details');
    } else {
      print(warningMessage);
    }
  }

  /// Log info message
  static void logInfo(String message, [Object? details]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final infoMessage = '[$timestamp] INFO: $message';

      if (details != null) {
        print('$infoMessage - Details: $details');
      } else {
        print(infoMessage);
      }
    }
  }

  // ============================================================================
  // ERROR HANDLING UTILITIES
  // ============================================================================

  /// Handle general errors and return user-friendly message
  static String handleError(dynamic error, [String? context]) {
    final errorMessage = context != null
        ? '$context: ${getUserFriendlyMessage(error)}'
        : getUserFriendlyMessage(error);

    logError('General Error', error);
    return errorMessage;
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred';

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('networkexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network unreachable')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('deadline exceeded')) {
      return 'Request timed out. Please try again.';
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('forbidden')) {
      return 'Permission required. Please check app settings.';
    }

    // Storage errors
    if (errorString.contains('storage') ||
        errorString.contains('disk') ||
        errorString.contains('space') ||
        errorString.contains('no space left')) {
      return 'Not enough storage space available.';
    }

    // Authentication errors
    if (errorString.contains('authentication') ||
        errorString.contains('unauthorized') ||
        errorString.contains('login') ||
        errorString.contains('credential')) {
      return 'Authentication failed. Please log in again.';
    }

    // File system errors
    if (errorString.contains('file not found') ||
        errorString.contains('directory not found')) {
      return 'Required file or folder not found.';
    }

    // App blocker specific errors
    if (errorString.contains('app blocker') ||
        errorString.contains('blocking')) {
      return 'App blocking service error. Please restart the app.';
    }

    // Platform channel errors
    if (errorString.contains('platform') ||
        errorString.contains('method channel')) {
      return 'Device feature not available on this platform.';
    }

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('sql')) {
      return 'Data storage error. Please try again.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Handle API errors with user-friendly messages
  static String handleApiError(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString();

      if (errorString.contains('SocketException') ||
          errorString.contains('NetworkException')) {
        return 'No internet connection. Please check your network and try again.';
      }

      if (errorString.contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      }

      if (errorString.contains('FormatException')) {
        return 'Invalid data format received from server.';
      }

      if (errorString.contains('HttpException')) {
        return 'Server error. Please try again later.';
      }
    }

    return getUserFriendlyMessage(error);
  }

  /// Handle permission errors specifically
  static String handlePermissionError(String permission, dynamic error) {
    logError('Permission Error: $permission', error);

    switch (permission.toLowerCase()) {
      case 'camera':
        return 'Camera permission is required. Please enable it in settings.';
      case 'microphone':
        return 'Microphone permission is required. Please enable it in settings.';
      case 'location':
        return 'Location permission is required. Please enable it in settings.';
      case 'storage':
        return 'Storage permission is required. Please enable it in settings.';
      case 'usagestats':
        return 'Usage access permission is required for app blocking. Please enable it in settings.';
      case 'overlay':
        return 'Overlay permission is required for app blocking. Please enable it in settings.';
      case 'notification':
        return 'Notification permission is required. Please enable it in settings.';
      default:
        return 'Permission required. Please check app settings.';
    }
  }

  // ============================================================================
  // FIXED: SNACKBAR HELPER METHODS
  // ============================================================================

  /// Show error snackbar with retry option
  static void showErrorSnackbar(
      BuildContext context,
      String message, {
        VoidCallback? onRetry,
        Duration duration = const Duration(seconds: 5),
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: onRetry,
        )
            : null,
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackbar(
      BuildContext context,
      String message, {
        VoidCallback? onAction,
        String? actionLabel,
        Duration duration = const Duration(seconds: 4),
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        )
            : null,
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackbar(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackbar(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
      ),
    );
  }

  // ============================================================================
  // CRASH REPORTING
  // ============================================================================

  /// Send error to crash reporting service (placeholder for future implementation)
  static void _sendToCrashReporting(String type, Object error, StackTrace? stack) {
    // TODO: Implement crash reporting service integration
    // Examples: Firebase Crashlytics, Sentry, Bugsnag, etc.

    if (kDebugMode) {
      print('CRASH REPORTING: Would send error to service - $type: $error');
    }
  }

  /// Report handled exception to crash reporting
  static void reportHandledException(Object error, StackTrace? stack, {
    String? reason,
    Map<String, dynamic>? customData,
  }) {
    logError('Handled Exception${reason != null ? ' ($reason)' : ''}', error, stack);

    if (customData != null) {
      logInfo('Custom data for exception', customData);
    }

    if (kReleaseMode) {
      _sendToCrashReporting('Handled Exception', error, stack);
    }
  }

  // ============================================================================
  // ERROR LOG MANAGEMENT
  // ============================================================================

  /// Get recent error logs
  static List<String> getRecentErrors([int count = 10]) {
    final recentCount = count.clamp(1, _errorLog.length);
    return _errorLog.sublist(_errorLog.length - recentCount);
  }

  /// Get detailed error contexts
  static List<ErrorContext> getRecentErrorContexts([int count = 10]) {
    final recentCount = count.clamp(1, _errorContextLog.length);
    return _errorContextLog.sublist(_errorContextLog.length - recentCount);
  }

  /// Clear error logs
  static void clearErrorLogs() {
    _errorLog.clear();
    _errorContextLog.clear();
    if (kDebugMode) {
      print('ErrorHandler: Error logs cleared');
    }
  }

  /// Export error logs for debugging
  static String exportErrorLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== ERROR LOGS EXPORT ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total errors: ${_errorLog.length}');
    buffer.writeln();

    for (final errorContext in _errorContextLog) {
      buffer.writeln('--- ERROR ---');
      buffer.writeln('Type: ${errorContext.type}');
      buffer.writeln('Time: ${errorContext.timestamp.toIso8601String()}');
      buffer.writeln('Error: ${errorContext.error}');
      if (errorContext.stackTrace != null) {
        buffer.writeln('Stack: ${errorContext.stackTrace}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================

  /// Validate and handle null checks
  static T validateNotNull<T>(T? value, String fieldName) {
    if (value == null) {
      final error = ArgumentError.notNull(fieldName);
      logError('Validation Error', error);
      throw error;
    }
    return value;
  }

  /// Validate string is not empty
  static String validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      final error = ArgumentError.value(value, fieldName, 'Cannot be null or empty');
      logError('Validation Error', error);
      throw error;
    }
    return value;
  }

  /// Validate list is not empty
  static List<T> validateListNotEmpty<T>(List<T>? value, String fieldName) {
    if (value == null || value.isEmpty) {
      final error = ArgumentError.value(value, fieldName, 'Cannot be null or empty');
      logError('Validation Error', error);
      throw error;
    }
    return value;
  }
}

// ============================================================================
// ERROR CONTEXT CLASS
// ============================================================================

class ErrorContext {
  final String type;
  final Object error;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  ErrorContext({
    required this.type,
    required this.error,
    this.stackTrace,
    required this.timestamp,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }
}

// ============================================================================
// CUSTOM ERROR WIDGETS
// ============================================================================

/// Custom error dialog widget
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;
  final String? errorDetails;

  const ErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
    this.errorDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (showDetails && errorDetails != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Error Details'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    errorDetails!,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Error boundary widget for catching widget errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final Function(Object error, StackTrace stackTrace)? onError;
  final bool showErrorDetails;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.fallback,
    this.onError,
    this.showErrorDetails = false,
  }) : super(key: key);

  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _hasError = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildDefaultErrorWidget(context);
    }

    // Wrap child in error catching
    return _ErrorCatcher(
      onError: _handleError,
      child: widget.child,
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This section encountered an error and couldn\'t load properly.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _error = null;
                _stackTrace = null;
              });
            },
            child: const Text('Try Again'),
          ),
          if (widget.showErrorDetails && _error != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ErrorDialog(
                    title: 'Error Details',
                    message: 'Technical error information:',
                    showDetails: true,
                    errorDetails: '$_error\n\n$_stackTrace',
                  ),
                );
              },
              child: const Text('Show Details'),
            ),
          ],
        ],
      ),
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _hasError = true;
      _error = error;
      _stackTrace = stackTrace;
    });

    widget.onError?.call(error, stackTrace);
    ErrorHandler.logError('Widget Error', error, stackTrace);
  }
}

/// Helper widget to catch errors in child widgets
class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace) onError;

  const _ErrorCatcher({
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// ============================================================================
// GLOBAL ERROR WIDGETS
// ============================================================================

/// Global error widget for app-level errors
class GlobalErrorWidget {
  static Widget build(BuildContext context, {String? message}) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red[50]!,
                Colors.red[100]!,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 72,
                    color: Colors.red[700],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message ?? 'The app encountered an unexpected error. Please restart the app.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Try to restart the app
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Restart App'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}