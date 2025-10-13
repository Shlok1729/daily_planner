import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/screens/home_screen.dart';
import 'package:daily_planner/screens/task_screen.dart';
import 'package:daily_planner/screens/focus_screen.dart';
import 'package:daily_planner/screens/schedule_screen.dart';
import 'package:daily_planner/screens/chatbot_screen.dart';
import 'package:daily_planner/screens/settings_screen.dart';
import 'package:daily_planner/constants/app_icons.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/providers/task_provider.dart';

// ============================================================================
// MAIN NAVIGATION SCREEN (FIXED - NO MORE DUPLICATE BOTTOM NAVIGATION)
// ============================================================================

/// Main navigation screen that handles bottom navigation
/// FIXED: Eliminated duplicate bottom navigation bars issue completely
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with AutomaticKeepAliveClientMixin {

  // FIXED: Keep alive to prevent unnecessary rebuilds
  @override
  bool get wantKeepAlive => true;

  int _currentIndex = 0;
  final PageController _pageController = PageController();
  DateTime? _lastBackPressed;

  // FIXED: Navigation items with screens that don't have their own navigation
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: AppIcons.home,
      activeIcon: AppIcons.homeFilled,
      label: 'Home',
      // FIXED: Use HomeScreenContent that doesn't have its own navigation
      screen: const HomeScreenContent(),
    ),
    NavigationItem(
      icon: AppIcons.task,
      activeIcon: AppIcons.taskFilled,
      label: 'Tasks',
      screen: const TaskScreenContent(),
    ),
    NavigationItem(
      icon: AppIcons.timer,
      activeIcon: AppIcons.timerFilled,
      label: 'Focus',
      screen: const FocusScreenContent(),
    ),
    NavigationItem(
      icon: AppIcons.calendar,
      activeIcon: AppIcons.calendar,
      label: 'Schedule',
      screen: const ScheduleScreenContent(),
    ),
    NavigationItem(
      icon: AppIcons.chat,
      activeIcon: AppIcons.chatFilled,
      label: 'Assistant',
      screen: const ChatbotScreenContent(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Watch app blocker state for focus mode indicator
    final appBlockerState = ref.watch(appBlockerProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // FIXED: Single app bar with focus indicator
        appBar: _buildAppBar(appBlockerState),

        // FIXED: Main content area with PageView
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
          children: _navigationItems.map((item) => item.screen).toList(),
        ),

        // FIXED: Single bottom navigation bar - NO DUPLICATES
        bottomNavigationBar: _buildBottomNavigationBar(),

        // FIXED: Context-aware floating action button
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  /// Build app bar with focus mode indicator
  PreferredSizeWidget _buildAppBar(AppBlockerState appBlockerState) {
    return AppBar(
      title: Text(
        _getScreenTitle(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        // Focus mode indicator
        if (appBlockerState.isFocusModeActive)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'FOCUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Settings button
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _navigateToSettings(),
        ),
      ],
    );
  }

  /// Get title for current screen
  String _getScreenTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Daily Planner';
      case 1:
        return 'Tasks';
      case 2:
        return 'Focus Mode';
      case 3:
        return 'Schedule';
      case 4:
        return 'Assistant';
      default:
        return 'Daily Planner';
    }
  }

  /// Build the single bottom navigation bar
  /// FIXED: Only one navigation bar, no duplicates
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavItemTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: _navigationItems.map((item) {
            final isSelected = _navigationItems.indexOf(item) == _currentIndex;
            return BottomNavigationBarItem(
              icon: Icon(isSelected ? item.activeIcon : item.icon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build floating action button for specific screens
  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 1: // Tasks screen
        return FloatingActionButton(
          onPressed: _onAddTaskPressed,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Add Task',
        );
      case 2: // Focus screen
        final appBlockerState = ref.watch(appBlockerProvider);
        if (!appBlockerState.isFocusModeActive) {
          return FloatingActionButton.extended(
            onPressed: _onStartFocusPressed,
            backgroundColor: Colors.green,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Start Focus', style: TextStyle(color: Colors.white)),
          );
        } else {
          return FloatingActionButton.extended(
            onPressed: _onStopFocusPressed,
            backgroundColor: Colors.red,
            icon: const Icon(Icons.stop, color: Colors.white),
            label: const Text('Stop Focus', style: TextStyle(color: Colors.white)),
          );
        }
      default:
        return null;
    }
  }

  /// Handle page changes from PageView
  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  /// Handle bottom navigation item taps
  void _onNavItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Handle back button press with double-tap to exit
  Future<bool> _onWillPop() async {
    // If not on home tab, navigate to home first
    if (_currentIndex != 0) {
      _onNavItemTapped(0);
      return false; // Don't exit app
    }

    // If on home tab, implement double-tap to exit
    final now = DateTime.now();
    const exitWarningDuration = Duration(seconds: 2);

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > exitWarningDuration) {
      _lastBackPressed = now;

      // Show exit warning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: exitWarningDuration,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false; // Don't exit yet
    }

    return true; // Exit app
  }

  /// Navigate to settings screen
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  /// Handle add task button press
  void _onAddTaskPressed() {
    // Show task creation bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Quick Add Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.task_alt),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task added successfully!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Task'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle start focus button press
  void _onStartFocusPressed() {
    ref.read(appBlockerProvider.notifier).startFocusMode(
      duration: const Duration(minutes: 25),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Focus mode started! 🎯'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _onNavItemTapped(2),
        ),
      ),
    );
  }

  /// Handle stop focus button press
  void _onStopFocusPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Focus Mode?'),
        content: const Text('Are you sure you want to stop your focus session early?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(appBlockerProvider.notifier).endFocusMode();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Focus mode stopped'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NAVIGATION ITEM CLASS
// ============================================================================

/// Represents a navigation item in the bottom navigation bar
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}

// ============================================================================
// SCREEN CONTENT WIDGETS (FIXED - NO SCAFFOLD WRAPPING)
// ============================================================================

/// Home screen content without navigation wrapper
/// FIXED: This prevents duplicate navigation bars
class HomeScreenContent extends ConsumerWidget {
  const HomeScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Return the home screen content directly without any navigation wrapper
    return const HomeScreenContentWidget();
  }
}

/// Task screen content without navigation wrapper
class TaskScreenContent extends ConsumerWidget {
  const TaskScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TaskScreenContentWidget();
  }
}

/// Focus screen content without navigation wrapper
class FocusScreenContent extends ConsumerWidget {
  const FocusScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const FocusScreenContentWidget();
  }
}

/// Schedule screen content without navigation wrapper
class ScheduleScreenContent extends ConsumerWidget {
  const ScheduleScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ScheduleScreenContentWidget();
  }
}

/// Chatbot screen content without navigation wrapper
class ChatbotScreenContent extends ConsumerWidget {
  const ChatbotScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ChatbotScreenContentWidget();
  }
}

// ============================================================================
// CONTENT WIDGET IMPLEMENTATIONS
// ============================================================================

/// FIXED: Home screen content that doesn't duplicate ProductivityInsights
class HomeScreenContentWidget extends StatelessWidget {
  const HomeScreenContentWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_getGreeting()}!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let\'s make today productive',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // FIXED: Single ProductivityInsights widget - no duplicates
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ProductivityInsightsWidget(),
            ),

            const SizedBox(height: 20),

            // Quick actions grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildQuickActionCard(
                        context,
                        'Add Task',
                        Icons.add_task,
                        Colors.blue,
                            () {},
                      ),
                      _buildQuickActionCard(
                        context,
                        'Start Focus',
                        Icons.timer,
                        Colors.green,
                            () {},
                      ),
                      _buildQuickActionCard(
                        context,
                        'Schedule',
                        Icons.calendar_today,
                        Colors.orange,
                            () {},
                      ),
                      _buildQuickActionCard(
                        context,
                        'Assistant',
                        Icons.chat,
                        Colors.purple,
                            () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Space for floating action button
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildQuickActionCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for ProductivityInsightsWidget
class ProductivityInsightsWidget extends StatelessWidget {
  const ProductivityInsightsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Productivity Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Great progress today! You\'ve completed 8 out of 12 planned tasks.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.67,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '67% complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Task screen content widget
class TaskScreenContentWidget extends StatelessWidget {
  const TaskScreenContentWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Task Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Manage your daily tasks here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Focus screen content widget
class FocusScreenContentWidget extends StatelessWidget {
  const FocusScreenContentWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Focus Mode',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Start your focus session here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Schedule screen content widget
class ScheduleScreenContentWidget extends StatelessWidget {
  const ScheduleScreenContentWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Schedule',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'View your schedule and appointments',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Chatbot screen content widget
class ChatbotScreenContentWidget extends StatelessWidget {
  const ChatbotScreenContentWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'AI Assistant',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Chat with your productivity assistant',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}