import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:daily_planner/utils/error_handler.dart';

// ============================================================================
// TIMER WIDGET (FIXED - CREATED MISSING WIDGET)
// ============================================================================

/// Timer widget for focus sessions and pomodoro
/// FIXED: Created missing TimerWidget that was being used in pomodoro_screen.dart
class TimerWidget extends StatefulWidget {
  final int initialMinutes;
  final VoidCallback? onTimerComplete;
  final bool autoStart;
  final Color? primaryColor;
  final Color? backgroundColor;
  final double size;
  final String? taskName;
  final bool showControls;
  final bool showTaskName;

  const TimerWidget({
    Key? key,
    required this.initialMinutes,
    this.onTimerComplete,
    this.autoStart = false,
    this.primaryColor,
    this.backgroundColor,
    this.size = 200.0,
    this.taskName,
    this.showControls = true,
    this.showTaskName = true,
  }) : super(key: key);

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    _setupAnimations();

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMinutes != widget.initialMinutes) {
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    _totalSeconds = widget.initialMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _isCompleted = false;
    _updateProgressAnimation();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  void _updateProgressAnimation() {
    if (_totalSeconds > 0) {
      final progress = (_totalSeconds - _remainingSeconds) / _totalSeconds;
      _progressController.animateTo(progress);
    }
  }

  void _startTimer() {
    if (_isRunning || _isCompleted) return;

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _pulseController.repeat(reverse: true);
    _startCountdown();

    HapticFeedback.lightImpact();
  }

  void _pauseTimer() {
    if (!_isRunning || _isPaused) return;

    setState(() {
      _isPaused = true;
    });

    _timer?.cancel();
    _pulseController.stop();

    HapticFeedback.mediumImpact();
  }

  void _resumeTimer() {
    if (!_isRunning || !_isPaused) return;

    setState(() {
      _isPaused = false;
    });

    _pulseController.repeat(reverse: true);
    _startCountdown();

    HapticFeedback.lightImpact();
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    HapticFeedback.heavyImpact();
  }

  void _resetTimer() {
    _stopTimer();
    _initializeTimer();
    setState(() {});

    HapticFeedback.mediumImpact();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        _updateProgressAnimation();
      } else {
        _onTimerComplete();
        timer.cancel();
      }
    });
  }

  void _onTimerComplete() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isCompleted = true;
      _remainingSeconds = 0;
    });

    _pulseController.stop();
    _pulseController.reset();
    _progressController.animateTo(1.0);

    // Haptic feedback for completion
    HapticFeedback.heavyImpact();

    // Call completion callback
    widget.onTimerComplete?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getStatusText() {
    if (_isCompleted) {
      return 'COMPLETED';
    } else if (_isPaused) {
      return 'PAUSED';
    } else if (_isRunning) {
      return 'RUNNING';
    } else {
      return 'READY';
    }
  }

  Color _getStatusColor() {
    if (_isCompleted) {
      return Colors.green;
    } else if (_isPaused) {
      return Colors.orange;
    } else if (_isRunning) {
      return widget.primaryColor ?? Theme.of(context).colorScheme.primary;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = widget.primaryColor ?? theme.colorScheme.primary;
    final effectiveBackgroundColor = widget.backgroundColor ??
        (theme.brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100]);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main timer display
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _progressAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _isRunning && !_isPaused ? _pulseAnimation.value : 1.0,
              child: Container(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: effectiveBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),

                    // Progress circle
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: TimerProgressPainter(
                        progress: _progressAnimation.value,
                        color: effectivePrimaryColor,
                        backgroundColor: effectivePrimaryColor.withOpacity(0.1),
                        strokeWidth: 8.0,
                      ),
                    ),

                    // Timer content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Task name
                        if (widget.showTaskName && widget.taskName != null) ...[
                          Container(
                            width: widget.size * 0.7,
                            child: Text(
                              widget.taskName!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Time display
                        Text(
                          _formatTime(_remainingSeconds),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: effectivePrimaryColor,
                            fontSize: widget.size * 0.15,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Status text
                        Text(
                          _getStatusText(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Play/pause button overlay
                    if (widget.showControls && (!_isRunning || _isPaused))
                      Positioned(
                        bottom: widget.size * 0.15,
                        child: GestureDetector(
                          onTap: _isRunning ? _resumeTimer : _startTimer,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: effectivePrimaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: effectivePrimaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Timer controls
        if (widget.showControls) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pause/Resume button
              if (_isRunning)
                _buildControlButton(
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  label: _isPaused ? 'Resume' : 'Pause',
                  onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                  color: Colors.orange,
                ),

              // Stop button
              if (_isRunning)
                _buildControlButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  onPressed: _stopTimer,
                  color: Colors.red,
                ),

              // Reset button
              if (!_isRunning)
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Reset',
                  onPressed: _resetTimer,
                  color: Colors.grey,
                ),

              // Start button
              if (!_isRunning && !_isCompleted)
                _buildControlButton(
                  icon: Icons.play_arrow,
                  label: 'Start',
                  onPressed: _startTimer,
                  color: Colors.green,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            elevation: 4,
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TIMER PROGRESS PAINTER
// ============================================================================

/// Custom painter for timer progress circle
class TimerProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  TimerProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final startAngle = -math.pi / 2; // Start from top
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Progress indicator dot
    if (progress > 0 && progress < 1) {
      final dotAngle = -math.pi / 2 + (2 * math.pi * progress);
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth / 2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ============================================================================
// TIMER UTILS
// ============================================================================

/// Utility class for timer-related operations
class TimerUtils {
  /// Format seconds to MM:SS format
  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Format seconds to HH:MM:SS format
  static String formatTimeWithHours(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return formatTime(seconds);
    }
  }

  /// Parse time string to seconds
  static int parseTimeToSeconds(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return (minutes * 60) + seconds;
      } else if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);
        return (hours * 3600) + (minutes * 60) + seconds;
      }
    } catch (e) {
      ErrorHandler.logError('Failed to parse time string', e);
    }
    return 0;
  }

  /// Get timer completion message
  static String getCompletionMessage(int totalMinutes) {
    if (totalMinutes < 10) {
      return 'Great job! You completed a $totalMinutes-minute session!';
    } else if (totalMinutes < 30) {
      return 'Well done! You stayed focused for $totalMinutes minutes!';
    } else if (totalMinutes < 60) {
      return 'Excellent! You completed a $totalMinutes-minute deep work session!';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return 'Amazing! You focused for ${hours}h ${minutes}m - that\'s dedication!';
    }
  }

  /// Calculate productivity score based on session duration
  static double calculateProductivityScore(int totalMinutes, int completedMinutes) {
    if (totalMinutes <= 0) return 0.0;
    final completion = completedMinutes / totalMinutes;

    // Bonus for completing the full session
    if (completion >= 1.0) {
      return 1.0;
    }

    // Partial credit for partial completion
    return completion * 0.8;
  }

  /// Get recommended break duration based on work duration
  static int getRecommendedBreakDuration(int workMinutes) {
    if (workMinutes <= 25) {
      return 5; // Short break for Pomodoro
    } else if (workMinutes <= 45) {
      return 10; // Medium break
    } else if (workMinutes <= 90) {
      return 15; // Long break for deep work
    } else {
      return 20; // Extended break for marathon sessions
    }
  }

  /// Get motivational message based on remaining time
  static String getMotivationalMessage(int remainingMinutes) {
    if (remainingMinutes <= 2) {
      return 'Almost there! You\'ve got this! 💪';
    } else if (remainingMinutes <= 5) {
      return 'Final stretch! Stay focused! 🎯';
    } else if (remainingMinutes <= 10) {
      return 'You\'re doing great! Keep going! 🔥';
    } else if (remainingMinutes <= 20) {
      return 'Halfway there! Maintain your momentum! ⚡';
    } else {
      return 'You\'ve got this! One step at a time! 🚀';
    }
  }
}