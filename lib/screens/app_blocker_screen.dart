import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:daily_planner/services/app_blocker_service.dart';

class AppBlockerScreen extends StatefulWidget {
  final String appName;
  final String appIcon;

  const AppBlockerScreen({
    Key? key,
    required this.appName,
    required this.appIcon,
  }) : super(key: key);

  @override
  _AppBlockerScreenState createState() => _AppBlockerScreenState();
}

class _AppBlockerScreenState extends State<AppBlockerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  late BlockMessage message; // FIXED: Now BlockMessage is defined in app_blocker_service.dart
  final AppBlockerService _blockerService = AppBlockerService();

  @override
  void initState() {
    super.initState();

    // Get random message for the app - FIXED: Now calls the correct method
    message = _blockerService.getRandomMessage();

    // Record the blocked attempt - FIXED: Now calls the correct method
    _blockerService.recordBlockedAttempt(widget.appName);

    // Setup animations
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticInOut,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _shakeController.repeat(reverse: true);

    // Haptic feedback
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              message.backgroundColor,
              message.backgroundColor.withOpacity(0.8),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),

                // Animated skull/emoji
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  message.emoji,
                                  style: TextStyle(fontSize: 60),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                SizedBox(height: 40),

                // Main message
                Text(
                  message.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 20),

                // Subtitle message
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    message.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 30),

                // Footer message
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    message.footer,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 40),

                // App blocked indicator - FIXED: Now calls the correct method
                FutureBuilder<Map<String, int>>(
                  future: _blockerService.getBlockedAttempts(),
                  builder: (context, snapshot) {
                    final attempts = snapshot.data?[widget.appName] ?? 0;

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '${widget.appName} Blocked: ${attempts}x Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                Spacer(),

                // Stats row
                _buildStatsRow(),

                SizedBox(height: 30),

                // OK Button
                Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Alternative actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      'Take Break',
                      Icons.coffee,
                          () => _takeBreak(),
                    ),
                    _buildActionButton(
                      'Focus Mode',
                      Icons.timer,
                          () => _startFocus(),
                    ),
                    _buildActionButton(
                      'Settings',
                      Icons.settings,
                          () => _openSettings(),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Additional action buttons for comprehensive functionality
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      'Emergency',
                      Icons.emergency,
                          () => _activateEmergencyOverride(),
                    ),
                    _buildActionButton(
                      'Stats',
                      Icons.analytics,
                          () => _showDetailedStats(),
                    ),
                    _buildActionButton(
                      'Schedule',
                      Icons.schedule,
                          () => _scheduleFocus(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    // FIXED: Now calls the correct method
    return FutureBuilder<Map<String, int>>(
      future: _blockerService.getAllBlockedAttempts(),
      builder: (context, snapshot) {
        final totalBlocked = snapshot.data?.values.fold(0, (sum, count) => sum + count) ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('🚫', totalBlocked.toString(), 'Blocked Today'),
            FutureBuilder<Map<String, dynamic>>(
              future: _blockerService.getTodayStatistics(),
              builder: (context, snapshot) {
                final timeSaved = snapshot.data?['timeSaved'] ?? 0;
                final timeSavedStr = _formatTime(Duration(seconds: timeSaved));
                return _buildStatItem('⏰', timeSavedStr, 'Time Saved');
              },
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _blockerService.getSettings(),
              builder: (context, snapshot) {
                final streak = snapshot.data?['currentStreak'] ?? 0;
                return _buildStatItem('🔥', streak.toString(), 'Focus Streak');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _takeBreak() {
    HapticFeedback.lightImpact();
    // Show break options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBreakOptionsSheet(),
    );
  }

  void _startFocus() {
    HapticFeedback.lightImpact();
    // Show focus duration options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFocusOptionsSheet(),
    );
  }

  void _openSettings() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    // This would navigate to app blocker settings
  }

  void _activateEmergencyOverride() async {
    HapticFeedback.heavyImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency Override'),
        content: Text(
          'This will temporarily disable app blocking for 15 minutes. '
              'Use this feature only in emergencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Activate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _blockerService.activateEmergencyOverride();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency override activated for 15 minutes'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate emergency override'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetailedStats() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDetailedStatsSheet(),
    );
  }

  void _scheduleFocus() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScheduleSheet(),
    );
  }

  Widget _buildBreakOptionsSheet() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Take a Break',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.water_drop),
            title: Text('Hydrate'),
            subtitle: Text('Drink some water'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Rest Eyes'),
            subtitle: Text('Look away from screen'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.directions_walk),
            title: Text('Stretch'),
            subtitle: Text('Take a quick walk'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusOptionsSheet() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Start Focus Session',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.timer),
            title: Text('Quick Focus'),
            subtitle: Text('15 minutes'),
            onTap: () {
              Navigator.pop(context);
              _startFocusSession(Duration(minutes: 15));
            },
          ),
          ListTile(
            leading: Icon(Icons.timer),
            title: Text('Pomodoro'),
            subtitle: Text('25 minutes'),
            onTap: () {
              Navigator.pop(context);
              _startFocusSession(Duration(minutes: 25));
            },
          ),
          ListTile(
            leading: Icon(Icons.timer),
            title: Text('Deep Focus'),
            subtitle: Text('50 minutes'),
            onTap: () {
              Navigator.pop(context);
              _startFocusSession(Duration(minutes: 50));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(
            'Detailed Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _blockerService.getWeeklyStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {};
                return ListView(
                  children: [
                    _buildStatCard('Total Blocks This Week', '${stats['totalBlocks'] ?? 0}'),
                    _buildStatCard('Time Saved This Week', _formatTime(Duration(seconds: stats['totalTimeSaved'] ?? 0))),
                    _buildStatCard('Current Streak', '${stats['streak'] ?? 0} days'),
                    _buildStatCard('Average Focus Time', '${stats['averageFocusTime'] ?? 0} minutes'),
                    SizedBox(height: 20),
                    Text(
                      'Top Blocked Apps',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 10),
                    ...((stats['topBlockedApps'] as Map<String, dynamic>?)?.entries.take(5) ?? [])
                        .map((entry) => ListTile(
                      title: Text(entry.key),
                      trailing: Text('${entry.value} blocks'),
                    )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSheet() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Schedule Focus Session',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Schedule for Later'),
            subtitle: Text('Set a specific time'),
            onTap: () {
              Navigator.pop(context);
              _showTimePicker();
            },
          ),
          ListTile(
            leading: Icon(Icons.repeat),
            title: Text('Daily Routine'),
            subtitle: Text('Set recurring focus times'),
            onTap: () {
              Navigator.pop(context);
              _showRoutineDialog();
            },
          ),
          ListTile(
            leading: Icon(Icons.event),
            title: Text('Focus Calendar'),
            subtitle: Text('View scheduled sessions'),
            onTap: () {
              Navigator.pop(context);
              _showFocusCalendar();
            },
          ),
        ],
      ),
    );
  }

  void _startFocusSession(Duration duration) async {
    try {
      await _blockerService.startFocusMode(duration: duration);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Focus session started for ${_formatTime(duration)}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start focus session'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledTime.isBefore(now)) {
        // Schedule for tomorrow if time has passed today
        scheduledTime.add(Duration(days: 1));
      }

      _showDurationPicker(scheduledTime);
    }
  }

  void _showDurationPicker(DateTime scheduledTime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Focus Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('15 minutes'),
              onTap: () {
                Navigator.pop(context);
                _scheduleSession(scheduledTime, Duration(minutes: 15));
              },
            ),
            ListTile(
              title: Text('25 minutes'),
              onTap: () {
                Navigator.pop(context);
                _scheduleSession(scheduledTime, Duration(minutes: 25));
              },
            ),
            ListTile(
              title: Text('50 minutes'),
              onTap: () {
                Navigator.pop(context);
                _scheduleSession(scheduledTime, Duration(minutes: 50));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleSession(DateTime scheduledTime, Duration duration) async {
    try {
      // This would integrate with the provider to schedule the session
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Focus session scheduled for ${TimeOfDay.fromDateTime(scheduledTime).format(context)} '
                '(${_formatTime(duration)})',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule focus session'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRoutineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Daily Focus Routine'),
        content: Text('Set up recurring focus sessions at specific times each day.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // This would open a detailed routine setup screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Routine feature coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text('Set Up'),
          ),
        ],
      ),
    );
  }

  void _showFocusCalendar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Focus Calendar'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Text('Upcoming Focus Sessions:'),
              SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('Today, 2:00 PM'),
                      subtitle: Text('25 min Pomodoro Session'),
                      trailing: Icon(Icons.check_circle, color: Colors.green),
                    ),
                    ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('Today, 4:00 PM'),
                      subtitle: Text('50 min Deep Focus'),
                      trailing: Icon(Icons.pending, color: Colors.orange),
                    ),
                    ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('Tomorrow, 9:00 AM'),
                      subtitle: Text('25 min Morning Focus'),
                      trailing: Icon(Icons.schedule, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}