import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/screens/app_blocker_selection_screen.dart';
import 'package:daily_planner/screens/pomodoro_screen.dart';
import 'package:daily_planner/screens/focus_lock_screen.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/models/blocked_app.dart';
import 'package:daily_planner/widgets/focus/timer_widget.dart';
import 'package:daily_planner/utils/icon_renderer.dart';

// ============================================================================
// FOCUS SCREEN (FIXED - ALL COMPILATION ERRORS)
// ============================================================================

enum FocusSessionType { custom, pomodoro, deepWork, quickFocus }

class FocusSessionConfig {
  final FocusSessionType type;
  final String name;
  final String description;
  final Duration duration;
  final IconData icon;
  final Color color;
  final bool includesBreaks;

  const FocusSessionConfig({
    required this.type,
    required this.name,
    required this.description,
    required this.duration,
    required this.icon,
    required this.color,
    this.includesBreaks = false,
  });
}

/// FIXED: Focus screen with all compilation errors resolved
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({Key? key}) : super(key: key);

  @override
  _FocusScreenState createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with TickerProviderStateMixin {
  int _selectedDuration = 25; // Default 25 minutes
  bool _isCustom = false;
  FocusSessionType _selectedSessionType = FocusSessionType.custom;
  String? _taskName;

  final TextEditingController _customDurationController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();

  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  // Predefined focus session configurations
  // FIXED: Removed const keyword as these contain non-const constructors
  static final List<FocusSessionConfig> _sessionConfigs = [
    FocusSessionConfig(
      type: FocusSessionType.pomodoro,
      name: 'Pomodoro',
      description: '25min work + 5min break cycles',
      duration: Duration(minutes: 25),
      icon: Icons.local_fire_department,
      color: Colors.red,
      includesBreaks: true,
    ),
    FocusSessionConfig(
      type: FocusSessionType.deepWork,
      name: 'Deep Work',
      description: 'Extended 90-minute focus session',
      duration: Duration(minutes: 90),
      icon: Icons.psychology,
      color: Colors.purple,
    ),
    FocusSessionConfig(
      type: FocusSessionType.quickFocus,
      name: 'Quick Focus',
      description: 'Short 15-minute burst',
      duration: Duration(minutes: 15),
      icon: Icons.flash_on,
      color: Colors.orange,
    ),
    FocusSessionConfig(
      type: FocusSessionType.custom,
      name: 'Custom',
      description: 'Set your own duration',
      duration: Duration(minutes: 25),
      icon: Icons.tune,
      color: Colors.blue,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _customDurationController.dispose();
    _taskNameController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    );

    _cardController.forward();
  }

  FocusSessionConfig get _selectedConfig {
    return _sessionConfigs.firstWhere(
          (config) => config.type == _selectedSessionType,
      orElse: () => _sessionConfigs.first,
    );
  }

  Duration get _effectiveDuration {
    if (_selectedSessionType == FocusSessionType.custom) {
      return Duration(minutes: _selectedDuration);
    }
    return _selectedConfig.duration;
  }

  void _startFocusSession() async {
    final appBlockerNotifier = ref.read(appBlockerProvider.notifier);

    if (_selectedSessionType == FocusSessionType.pomodoro) {
      // Navigate to dedicated Pomodoro screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PomodoroScreen(
            taskName: _taskName,
            autoStartFirstSession: true,
          ),
        ),
      );
      return;
    }

    // Start focus mode with app blocking
    // FIXED: Only pass duration parameter
    try {
      await appBlockerNotifier.startFocusMode(duration: _effectiveDuration);

      if (!mounted) return;

      // Navigate to focus lock screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FocusLockScreen(
            remainingTime: _effectiveDuration,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error starting focus mode: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBlockerState = ref.watch(appBlockerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showFocusHistory,
            tooltip: 'Focus History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showFocusSettings,
            tooltip: 'Focus Settings',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _cardAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Today',
                      '2',
                      'sessions',
                      Icons.today,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'This Week',
                      '12',
                      'sessions',
                      Icons.date_range,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Streak',
                      '3',
                      'days',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSessionTypeSelector(),
              const SizedBox(height: 20),
              if (_selectedSessionType == FocusSessionType.custom)
                _buildCustomDurationSelector(),
              _buildTaskNameInput(),
              const SizedBox(height: 20),
              _buildBlockedAppsSection(),
              const SizedBox(height: 20),
              _buildStartButton(),
              const SizedBox(height: 20),
              _buildQuickStats(),
            ],
          ),
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

  void _showFocusHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Focus History'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHistoryItem('Today', '2 sessions', '50 minutes', Icons.today),
              // FIXED: Use calendar_today instead of Icons.yesterday which doesn't exist
              _buildHistoryItem('Yesterday', '3 sessions', '75 minutes', Icons.calendar_today),
              _buildHistoryItem('This Week', '12 sessions', '5 hours', Icons.date_range),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'re on a 3-day focus streak! Keep it up!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String period, String sessions, String duration, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(period),
        subtitle: Text(sessions),
        trailing: Text(
          duration,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showFocusSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Focus Settings'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Block notifications'),
                subtitle: const Text('Silence all notifications during focus'),
                value: true,
                onChanged: (value) {
                  // TODO: Implement notification blocking
                },
              ),
              SwitchListTile(
                title: const Text('Auto-start breaks'),
                subtitle: const Text('Automatically start break timers'),
                value: false,
                onChanged: (value) {
                  // TODO: Implement auto-start breaks
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Focus sounds'),
                subtitle: const Text('Nature sounds, white noise'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to sounds settings
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Focus sounds feature coming soon!'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('Do Not Disturb'),
                subtitle: const Text('Configure system-level blocking'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to DND settings
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Do Not Disturb settings coming soon!'),
                    ),
                  );
                },
              ),
            ],
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

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.center_focus_strong,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Time to Focus',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your focus session type and eliminate distractions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: _sessionConfigs.length,
              itemBuilder: (context, index) {
                final config = _sessionConfigs[index];
                final isSelected = config.type == _selectedSessionType;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSessionType = config.type;
                      _isCustom = config.type == FocusSessionType.custom;
                      if (!_isCustom) {
                        _selectedDuration = config.duration.inMinutes;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? config.color.withOpacity(0.15)
                          : Colors.grey[50],
                      border: Border.all(
                        color: isSelected ? config.color : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            config.icon,
                            size: 32,
                            color: isSelected ? config.color : Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            config.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected ? config.color : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config.description,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDurationSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration (minutes)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _selectedDuration.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '$_selectedDuration min',
                    onChanged: (value) {
                      setState(() {
                        _selectedDuration = value.round();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '$_selectedDuration min',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick duration buttons
            Wrap(
              spacing: 8,
              children: [15, 25, 45, 60, 90].map((duration) {
                return ActionChip(
                  label: Text('${duration}m'),
                  onPressed: () {
                    setState(() {
                      _selectedDuration = duration;
                    });
                  },
                  backgroundColor: _selectedDuration == duration
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskNameInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What are you working on? (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(
                hintText: 'e.g., Writing report, Learning Flutter...',
                prefixIcon: const Icon(Icons.work_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                _taskName = value.trim().isEmpty ? null : value.trim();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedAppsSection() {
    final appBlockerState = ref.watch(appBlockerProvider);
    final blockedApps = appBlockerState.blockedApps;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Blocked Apps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AppBlockerSelectionScreen(), // FIXED: Removed const
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (blockedApps.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No apps selected for blocking',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          Text(
                            'Add apps to block distractions during focus sessions',
                            style: TextStyle(color: Colors.orange[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: blockedApps.take(6).map((app) {
                  // FIXED: Use the name property instead of displayName
                  final blockedApp = app as BlockedApp;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          blockedApp.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (blockedApps.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${blockedApps.length - 6} more apps',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _startFocusSession,
        icon: Icon(_selectedConfig.icon),
        label: Text(
          _selectedSessionType == FocusSessionType.pomodoro
              ? 'Start Pomodoro Session'
              : 'Start Focus Session',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedConfig.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStatItem(
                  'Total Time',
                  '24h 30m',
                  Icons.timer,
                  Colors.blue,
                ),
                _buildQuickStatItem(
                  'Best Streak',
                  '7 days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildQuickStatItem(
                  'This Month',
                  '45 sessions',
                  Icons.calendar_month,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}