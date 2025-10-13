import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/widgets/focus/timer_widget.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/screens/focus_lock_screen.dart';
import 'package:daily_planner/utils/icon_renderer.dart';

// ============================================================================
// POMODORO SCREEN (FIXED - VOID RETURN TYPE ISSUE)
// ============================================================================

enum PomodoroPhase { ready, work, shortBreak, longBreak }

class PomodoroSession {
  final int sessionNumber;
  final PomodoroPhase phase;
  final Duration duration;
  final DateTime startTime;
  final bool completed;

  PomodoroSession({
    required this.sessionNumber,
    required this.phase,
    required this.duration,
    required this.startTime,
    this.completed = false,
  });

  PomodoroSession copyWith({
    int? sessionNumber,
    PomodoroPhase? phase,
    Duration? duration,
    DateTime? startTime,
    bool? completed,
  }) {
    return PomodoroSession(
      sessionNumber: sessionNumber ?? this.sessionNumber,
      phase: phase ?? this.phase,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      completed: completed ?? this.completed,
    );
  }
}

/// FIXED: Pomodoro screen with void return type issue resolved
class PomodoroScreen extends ConsumerStatefulWidget {
  final String? taskName;
  final bool autoStartFirstSession;

  const PomodoroScreen({
    Key? key,
    this.taskName,
    this.autoStartFirstSession = false,
  }) : super(key: key);

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with TickerProviderStateMixin {
  PomodoroPhase _currentPhase = PomodoroPhase.ready;
  int _currentSession = 1;
  bool _isActive = false;
  List<PomodoroSession> _sessionHistory = [];

  // Pomodoro settings
  final int _workDuration = 25; // minutes
  final int _shortBreakDuration = 5; // minutes
  final int _longBreakDuration = 15; // minutes
  final int _sessionsUntilLongBreak = 4;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    if (widget.autoStartFirstSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startWorkSession();
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  int get _currentDurationMinutes {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return _workDuration;
      case PomodoroPhase.shortBreak:
        return _shortBreakDuration;
      case PomodoroPhase.longBreak:
        return _longBreakDuration;
      case PomodoroPhase.ready:
        return _workDuration;
    }
  }

  String get _currentPhaseTitle {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return 'Work Session ${_currentSession}';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
      case PomodoroPhase.ready:
        return 'Ready to Start';
    }
  }

  Color get _currentPhaseColor {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return Colors.red;
      case PomodoroPhase.shortBreak:
        return Colors.green;
      case PomodoroPhase.longBreak:
        return Colors.blue;
      case PomodoroPhase.ready:
        return Colors.grey;
    }
  }

  IconData get _currentPhaseIcon {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return Icons.work;
      case PomodoroPhase.shortBreak:
        return Icons.coffee;
      case PomodoroPhase.longBreak:
        return Icons.spa;
      case PomodoroPhase.ready:
        return Icons.play_arrow;
    }
  }

  void _startWorkSession() async {
    setState(() {
      _currentPhase = PomodoroPhase.work;
      _isActive = true;
    });

    // FIXED: Use the correct parameter name for startFocusMode
    final appBlockerNotifier = ref.read(appBlockerProvider.notifier);

    try {
      // Start app blocking for work session
      await appBlockerNotifier.startFocusMode(
        duration: Duration(minutes: _workDuration),
      );
    } catch (e) {
      // Handle error but continue with timer
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('App blocking failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    _recordSession(PomodoroPhase.work, false);
  }

  void _startBreak() {
    final shouldBeLongBreak = _currentSession % _sessionsUntilLongBreak == 0;
    final breakPhase = shouldBeLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;

    setState(() {
      _currentPhase = breakPhase;
      _isActive = true;
    });

    // FIXED: Handle break start properly
    _handleBreakStart(breakPhase);
  }

  void _handleBreakStart(PomodoroPhase breakPhase) async {
    // Stop app blocking during breaks
    final appBlockerNotifier = ref.read(appBlockerProvider.notifier);

    try {
      // FIXED: Use the appropriate method to stop focus mode
      await appBlockerNotifier.endFocusMode();
    } catch (e) {
      // Handle error silently during breaks
      if (mounted) {
        print('Failed to stop app blocking during break: $e');
      }
    }

    _recordSession(breakPhase, false);
  }

  void _completeSession() {
    // Mark current session as completed
    if (_sessionHistory.isNotEmpty) {
      final lastSession = _sessionHistory.last;
      _sessionHistory[_sessionHistory.length - 1] = lastSession.copyWith(completed: true);
    }

    if (_currentPhase == PomodoroPhase.work) {
      _currentSession++;
      _startBreak();
    } else {
      // Break completed, ready for next work session
      setState(() {
        _currentPhase = PomodoroPhase.ready;
        _isActive = false;
      });
    }
  }

  void _recordSession(PomodoroPhase phase, bool completed) {
    final session = PomodoroSession(
      sessionNumber: phase == PomodoroPhase.work ? _currentSession : 0,
      phase: phase,
      duration: Duration(minutes: _currentDurationMinutes),
      startTime: DateTime.now(),
      completed: completed,
    );

    setState(() {
      _sessionHistory.add(session);
    });
  }

  void _resetPomodoro() async {
    // FIXED: Handle reset properly using the appropriate method
    final appBlockerNotifier = ref.read(appBlockerProvider.notifier);

    try {
      // FIXED: Use endFocusMode instead of stopFocusMode
      await appBlockerNotifier.endFocusMode();
    } catch (e) {
      // Handle error silently
      print('Failed to stop app blocking during reset: $e');
    }

    setState(() {
      _currentPhase = PomodoroPhase.ready;
      _currentSession = 1;
      _isActive = false;
      _sessionHistory.clear();
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final appBlockerState = ref.watch(appBlockerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskName ?? 'Pomodoro Timer'),
        backgroundColor: _currentPhaseColor.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isActive ? null : _resetPomodoro,
            tooltip: 'Reset',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showSessionHistory(),
            tooltip: 'History',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _currentPhaseColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPhaseHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildTimerSection(),
                ),
                const SizedBox(height: 24),
                _buildControlButtons(),
                const SizedBox(height: 16),
                _buildStatsPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: _currentPhaseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _currentPhaseColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _currentPhaseIcon,
                color: _currentPhaseColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                _currentPhaseTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _currentPhaseColor,
                ),
              ),
            ],
          ),
          if (ref.watch(appBlockerProvider).isFocusModeActive) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Focus Mode Active',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isActive ? _pulseAnimation.value : 1.0,
          child: TimerWidget(
            initialMinutes: _currentDurationMinutes,
            onTimerComplete: _completeSession,
            autoStart: false,
            primaryColor: _currentPhaseColor,
            size: 280,
          ),
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (_currentPhase == PomodoroPhase.ready)
          _buildControlButton(
            icon: Icons.play_arrow,
            label: 'Start Work',
            color: Colors.green,
            onPressed: _startWorkSession,
          ),

        if (_isActive)
          _buildControlButton(
            icon: Icons.skip_next,
            label: 'Skip',
            color: Colors.orange,
            onPressed: _completeSession,
          ),

        if (!_isActive && _currentPhase != PomodoroPhase.ready)
          _buildControlButton(
            icon: Icons.play_arrow,
            label: _currentPhase == PomodoroPhase.work ? 'Continue' : 'Start Work',
            color: Colors.green,
            onPressed: _currentPhase == PomodoroPhase.work ? null : _startWorkSession,
          ),

        _buildControlButton(
          icon: Icons.refresh,
          label: 'Reset',
          color: Colors.red,
          onPressed: _isActive ? null : _resetPomodoro,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
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
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onPressed == null ? Colors.grey : color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel() {
    final totalSessions = _sessionHistory.where((s) => s.phase == PomodoroPhase.work && s.completed).length;
    final totalFocusTime = Duration(minutes: totalSessions * 25);
    final todaySessions = _sessionHistory
        .where((s) => s.phase == PomodoroPhase.work &&
        s.completed &&
        _isSameDay(s.startTime, DateTime.now()))
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Today',
                    '$todaySessions',
                    'sessions',
                    Icons.today,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    '$totalSessions',
                    'sessions',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Focus Time',
                    '${totalFocusTime.inHours}h ${totalFocusTime.inMinutes.remainder(60)}m',
                    '',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showSessionHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _sessionHistory.isEmpty
              ? const Center(
            child: Text('No sessions completed yet'),
          )
              : ListView.builder(
            itemCount: _sessionHistory.length,
            itemBuilder: (context, index) {
              final session = _sessionHistory[index];
              return ListTile(
                leading: Icon(
                  session.phase == PomodoroPhase.work
                      ? Icons.work
                      : Icons.coffee,
                  color: session.completed ? Colors.green : Colors.grey,
                ),
                title: Text(
                  session.phase == PomodoroPhase.work
                      ? 'Work Session ${session.sessionNumber}'
                      : session.phase == PomodoroPhase.longBreak
                      ? 'Long Break'
                      : 'Short Break',
                ),
                subtitle: Text(
                  '${session.duration.inMinutes} min - ${session.completed ? 'Completed' : 'Incomplete'}',
                ),
                trailing: Text(
                  '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}