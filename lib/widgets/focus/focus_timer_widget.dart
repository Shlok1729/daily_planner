import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/models/blocked_app.dart';

// ============================================================================
// FOCUS TIMER WIDGET - COMPLETELY FIXED
// ============================================================================

/// Focus timer widget with proper timer controls and display
/// FIXED: Added all missing parameters and methods for focus/pomodoro screens
class FocusTimerWidget extends ConsumerStatefulWidget {
  final int remainingTime; // in seconds
  final int totalDuration; // in seconds
  final String? taskName;
  final VoidCallback? onTimerComplete;
  final VoidCallback? onTimerStart;
  final VoidCallback? onTimerPause;
  final VoidCallback? onTimerStop;
  final bool isRunning;
  final bool isPaused;
  final Color? primaryColor;
  final Color? backgroundColor;
  final double size;
  final bool showControls;
  final bool showTaskName;
  final bool autoStart;

  const FocusTimerWidget({
    Key? key,
    required this.remainingTime,
    required this.totalDuration,
    this.taskName,
    this.onTimerComplete,
    this.onTimerStart,
    this.onTimerPause,
    this.onTimerStop,
    this.isRunning = false,
    this.isPaused = false,
    this.primaryColor,
    this.backgroundColor,
    this.size = 200.0,
    this.showControls = true,
    this.showTaskName = true,
    this.autoStart = false,
  }) : super(key: key);

  @override
  ConsumerState<FocusTimerWidget> createState() => _FocusTimerWidgetState();
}

class _FocusTimerWidgetState extends ConsumerState<FocusTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  // FIXED: Added state management for the timer
  late int _remainingTime;
  late int _totalTime;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.remainingTime;
    _totalTime = widget.totalDuration;
    _isRunning = widget.isRunning;
    _isPaused = widget.isPaused;

    _setupAnimations();

    if (widget.autoStart && !_isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }
  }

  @override
  void didUpdateWidget(FocusTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.remainingTime != widget.remainingTime) {
      setState(() {
        _remainingTime = widget.remainingTime;
      });
    }

    if (oldWidget.totalDuration != widget.totalDuration) {
      setState(() {
        _totalTime = widget.totalDuration;
      });
    }

    if (oldWidget.isRunning != widget.isRunning) {
      setState(() {
        _isRunning = widget.isRunning;
      });

      if (widget.isRunning && !_isRunning) {
        _startTimer();
      } else if (!widget.isRunning && _isRunning) {
        _stopTimer();
      }
    }

    if (oldWidget.isPaused != widget.isPaused) {
      setState(() {
        _isPaused = widget.isPaused;
      });
    }
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

    // Start pulse animation when running
    if (_isRunning && !_isPaused) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _updateProgressAnimation() {
    final progress = _totalTime > 0 ? (_totalTime - _remainingTime) / _totalTime : 0.0;
    _progressController.animateTo(progress);
  }

  void _startTimer() {
    if (_remainingTime <= 0) return;

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _isCompleted = false;
    });

    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          _updateProgressAnimation();
        } else {
          _onTimerComplete();
        }
      });
    });

    widget.onTimerStart?.call();
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _pulseController.stop();
    } else {
      _pulseController.repeat(reverse: true);
    }

    widget.onTimerPause?.call();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;

    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    _pulseController.stop();
    _pulseController.reset();

    widget.onTimerStop?.call();
  }

  void _resetTimer() {
    _stopTimer();

    setState(() {
      _remainingTime = _totalTime;
      _isCompleted = false;
    });

    _progressController.reset();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _timer = null;

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isCompleted = true;
      _remainingTime = 0;
    });

    _pulseController.stop();

    // Completion animation
    _progressController.animateTo(1.0);

    widget.onTimerComplete?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBlockerState = ref.watch(appBlockerProvider);
    final theme = Theme.of(context);
    final effectivePrimaryColor = widget.primaryColor ?? theme.primaryColor;
    final effectiveBackgroundColor = widget.backgroundColor ?? theme.scaffoldBackgroundColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _progressAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isRunning && !_isPaused ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectiveBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: effectivePrimaryColor.withOpacity(0.3),
                  blurRadius: _isRunning ? 20 : 10,
                  spreadRadius: _isRunning ? 5 : 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: CircularProgressPainter(
                    progress: 1.0,
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 8,
                  ),
                ),

                // Progress circle
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: CircularProgressPainter(
                    progress: _progressAnimation.value,
                    color: _isCompleted
                        ? Colors.green
                        : _isPaused
                        ? Colors.orange
                        : effectivePrimaryColor,
                    strokeWidth: 8,
                  ),
                ),

                // Timer content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Task name (if provided and should be shown)
                    if (widget.showTaskName && widget.taskName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: effectivePrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.taskName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: effectivePrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Time display
                    Text(
                      _formatTime(_remainingTime),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: _isCompleted
                            ? Colors.green
                            : effectivePrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.size * 0.15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Status text
                    Text(
                      _getStatusText(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        fontSize: widget.size * 0.05,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Control buttons (if enabled)
                    if (widget.showControls) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Start/Pause button
                          if (!_isCompleted) ...[
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: effectivePrimaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: effectivePrimaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _isRunning ? _pauseTimer : _startTimer,
                                icon: Icon(
                                  _isRunning && !_isPaused
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Stop/Reset button
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _isRunning ? _stopTimer : _resetTimer,
                                icon: Icon(
                                  _isRunning ? Icons.stop : Icons.refresh,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ] else ...[
                            // Reset button when completed
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _resetTimer,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),

                // Blocked apps indicator
                if (appBlockerState.isFocusModeActive && appBlockerState.activelyBlockedApps.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${appBlockerState.activelyBlockedApps.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  String _getStatusText() {
    if (_isCompleted) {
      return 'COMPLETED';
    } else if (_isPaused) {
      return 'PAUSED';
    } else if (_isRunning) {
      return 'FOCUS TIME';
    } else {
      return 'READY';
    }
  }
}

/// Custom painter for circular progress indicator
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
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
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ============================================================================
// TIMER WIDGET (ALTERNATIVE IMPLEMENTATION)
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
    final progress = _totalSeconds > 0 ? (_totalSeconds - _remainingSeconds) / _totalSeconds : 0.0;
    _progressController.animateTo(progress);
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _isCompleted = false;
    });

    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _updateProgressAnimation();
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _pulseController.stop();
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;

    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    _pulseController.stop();
    _pulseController.reset();
  }

  void _resetTimer() {
    _stopTimer();

    setState(() {
      _remainingSeconds = _totalSeconds;
      _isCompleted = false;
    });

    _progressController.reset();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _timer = null;

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isCompleted = true;
      _remainingSeconds = 0;
    });

    _pulseController.stop();
    _progressController.animateTo(1.0);

    widget.onTimerComplete?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = widget.primaryColor ?? theme.primaryColor;
    final effectiveBackgroundColor = widget.backgroundColor ?? theme.scaffoldBackgroundColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _progressAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isRunning && !_isPaused ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectiveBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: effectivePrimaryColor.withOpacity(0.3),
                  blurRadius: _isRunning ? 20 : 10,
                  spreadRadius: _isRunning ? 5 : 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: CircularProgressPainter(
                    progress: 1.0,
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 8,
                  ),
                ),

                // Progress circle
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: CircularProgressPainter(
                    progress: _progressAnimation.value,
                    color: _isCompleted
                        ? Colors.green
                        : _isPaused
                        ? Colors.orange
                        : effectivePrimaryColor,
                    strokeWidth: 8,
                  ),
                ),

                // Timer content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Task name (if provided and should be shown)
                    if (widget.showTaskName && widget.taskName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: effectivePrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.taskName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: effectivePrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Time display
                    Text(
                      _formatTime(_remainingSeconds),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: _isCompleted
                            ? Colors.green
                            : effectivePrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.size * 0.12,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Status text
                    Text(
                      _getStatusText(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        fontSize: widget.size * 0.04,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Control buttons (if enabled)
                    if (widget.showControls) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Start/Pause button
                          if (!_isCompleted) ...[
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: effectivePrimaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: effectivePrimaryColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _isRunning ? _pauseTimer : _startTimer,
                                icon: Icon(
                                  _isRunning && !_isPaused
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Stop/Reset button
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _isRunning ? _stopTimer : _resetTimer,
                                icon: Icon(
                                  _isRunning ? Icons.stop : Icons.refresh,
                                  color: Colors.grey[600],
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ] else ...[
                            // Reset button when completed
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _resetTimer,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  String _getStatusText() {
    if (_isCompleted) {
      return 'COMPLETED';
    } else if (_isPaused) {
      return 'PAUSED';
    } else if (_isRunning) {
      return 'FOCUS TIME';
    } else {
      return 'READY';
    }
  }
}

// ============================================================================
// ADVANCED FOCUS TIMER WITH RIVERPOD INTEGRATION
// ============================================================================

/// Advanced focus timer widget that integrates with app blocker provider
class AdvancedFocusTimer extends ConsumerStatefulWidget {
  final Duration initialDuration;
  final String? taskName;
  final List<String>? blockedApps;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onStop;
  final bool autoStartBlocking;
  final Color? primaryColor;
  final double size;

  const AdvancedFocusTimer({
    Key? key,
    required this.initialDuration,
    this.taskName,
    this.blockedApps,
    this.onComplete,
    this.onStart,
    this.onPause,
    this.onStop,
    this.autoStartBlocking = true,
    this.primaryColor,
    this.size = 250.0,
  }) : super(key: key);

  @override
  ConsumerState<AdvancedFocusTimer> createState() => _AdvancedFocusTimerState();
}

class _AdvancedFocusTimerState extends ConsumerState<AdvancedFocusTimer>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _focusTimer;
  Duration _remainingTime = Duration.zero;
  bool _isActive = false;
  bool _isPaused = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.initialDuration;
    _setupAnimations();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: widget.initialDuration,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startFocusSession() async {
    try {
      final appBlockerNotifier = ref.read(appBlockerProvider.notifier);

      // Start app blocking if enabled and apps are specified
      if (widget.autoStartBlocking && widget.blockedApps != null) {
        await appBlockerNotifier.startFocusMode(duration: widget.initialDuration);
      }

      setState(() {
        _isActive = true;
        _isPaused = false;
        _isCompleted = false;
      });

      _progressController.forward();
      _pulseController.repeat(reverse: true);

      _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPaused) return;

        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
          } else {
            _completeFocusSession();
          }
        });
      });

      widget.onStart?.call();
    } catch (e) {
      _showErrorSnackbar('Failed to start focus session: $e');
    }
  }

  void _pauseFocusSession() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _progressController.stop();
      _pulseController.stop();
    } else {
      _progressController.forward();
      _pulseController.repeat(reverse: true);
    }

    widget.onPause?.call();
  }

  void _stopFocusSession() async {
    try {
      final appBlockerNotifier = ref.read(appBlockerProvider.notifier);

      // End app blocking
      if (widget.autoStartBlocking) {
        await appBlockerNotifier.endFocusMode();
      }

      _focusTimer?.cancel();
      _focusTimer = null;

      setState(() {
        _isActive = false;
        _isPaused = false;
        _remainingTime = widget.initialDuration;
      });

      _progressController.reset();
      _pulseController.stop();

      widget.onStop?.call();
    } catch (e) {
      _showErrorSnackbar('Failed to stop focus session: $e');
    }
  }

  void _completeFocusSession() async {
    try {
      final appBlockerNotifier = ref.read(appBlockerProvider.notifier);

      // End app blocking
      if (widget.autoStartBlocking) {
        await appBlockerNotifier.endFocusMode();
      }

      _focusTimer?.cancel();
      _focusTimer = null;

      setState(() {
        _isActive = false;
        _isPaused = false;
        _isCompleted = true;
        _remainingTime = Duration.zero;
      });

      _pulseController.stop();

      widget.onComplete?.call();

      _showCompletionDialog();
    } catch (e) {
      _showErrorSnackbar('Focus session ended with error: $e');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🎉'),
            SizedBox(width: 8),
            Text('Focus Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Congratulations! You completed a ${widget.initialDuration.inMinutes}-minute focus session.'),
            if (widget.taskName != null) ...[
              const SizedBox(height: 8),
              Text('Task: ${widget.taskName}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
            child: const Text('Start Another'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _resetTimer() {
    setState(() {
      _remainingTime = widget.initialDuration;
      _isCompleted = false;
    });
    _progressController.reset();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBlockerState = ref.watch(appBlockerProvider);
    final theme = Theme.of(context);
    final effectivePrimaryColor = widget.primaryColor ?? theme.primaryColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isActive && !_isPaused ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: effectivePrimaryColor.withOpacity(_isActive ? 0.4 : 0.2),
                  blurRadius: _isActive ? 25 : 15,
                  spreadRadius: _isActive ? 8 : 3,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background progress circle
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: CircularProgressPainter(
                    progress: 1.0,
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 12,
                  ),
                ),

                // Active progress circle
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: CircularProgressPainter(
                    progress: _progressAnimation.value,
                    color: _isCompleted
                        ? Colors.green
                        : _isPaused
                        ? Colors.orange
                        : effectivePrimaryColor,
                    strokeWidth: 12,
                  ),
                ),

                // Central content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Task name
                    if (widget.taskName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: effectivePrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.taskName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: effectivePrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Time remaining
                    Text(
                      _formatDuration(_remainingTime),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: _isCompleted ? Colors.green : effectivePrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.size * 0.15,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Status
                    Text(
                      _getStatusText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isCompleted) ...[
                          // Play/Pause button
                          _buildControlButton(
                            icon: _isActive && !_isPaused ? Icons.pause : Icons.play_arrow,
                            onPressed: _isActive ? _pauseFocusSession : _startFocusSession,
                            color: effectivePrimaryColor,
                            isPrimary: true,
                          ),

                          const SizedBox(width: 12),

                          // Stop button
                          if (_isActive)
                            _buildControlButton(
                              icon: Icons.stop,
                              onPressed: _stopFocusSession,
                              color: Colors.red,
                            ),
                        ] else ...[
                          // Reset button when completed
                          _buildControlButton(
                            icon: Icons.refresh,
                            onPressed: _resetTimer,
                            color: Colors.green,
                            isPrimary: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Blocked apps indicator
                if (appBlockerState.isFocusModeActive && appBlockerState.activelyBlockedApps.isNotEmpty)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${appBlockerState.activelyBlockedApps.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isPrimary ? color : color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: isPrimary ? null : Border.all(color: color, width: 2),
        boxShadow: isPrimary
            ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ]
            : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isPrimary ? Colors.white : color,
          size: 24,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _getStatusText() {
    if (_isCompleted) {
      return 'SESSION COMPLETED';
    } else if (_isPaused) {
      return 'PAUSED';
    } else if (_isActive) {
      return 'FOCUS MODE ACTIVE';
    } else {
      return 'READY TO START';
    }
  }
}