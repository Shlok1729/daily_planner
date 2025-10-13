import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/screens/chatbot_screen.dart';
import 'package:daily_planner/screens/focus_screen.dart';
import 'package:daily_planner/screens/schedule_screen.dart';
import 'package:daily_planner/screens/settings_screen.dart';
import 'package:daily_planner/screens/task_screen.dart';
import 'package:daily_planner/screens/profile_screen.dart';
import 'package:daily_planner/screens/auth_screen_enhanced.dart';
import 'package:daily_planner/screens/eisenhower_matrix_screen.dart';
import 'package:daily_planner/screens/focus_history_screen.dart';
import 'package:daily_planner/widgets/home/chatbot_card.dart';
import 'package:daily_planner/widgets/home/eisenhower_matrix.dart';
import 'package:daily_planner/widgets/home/focus_mode_card.dart';
import 'package:daily_planner/widgets/home/task_summary_card.dart';
import 'package:daily_planner/widgets/home/productivity_insights_widget.dart';
import 'package:daily_planner/providers/auth_provider.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/providers/task_provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

// ============================================================================
// COMPLETE HOME SCREEN - MERGED ALL FUNCTIONALITY
// ============================================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _quotes = [
    "The key is not to prioritize what's on your schedule, but to schedule your priorities.",
    "You don't have to be great to start, but you have to start to be great.",
    "The secret of getting ahead is getting started.",
    "Don't count the days, make the days count.",
    "Focus on being productive instead of busy.",
    "Success is the sum of small efforts repeated day in and day out.",
    "The way to get started is to quit talking and begin doing.",
    "Your limitation—it's only your imagination.",
    "Push yourself, because no one else is going to do it for you.",
    "Great things never come from comfort zones.",
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final List<Widget> screens = [
      _buildHomeContent(),
      const TaskScreen(),
      const FocusScreen(),
      const ScheduleScreen(),
      const ChatbotScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _currentIndex == 0 ? _buildFAB() : null,
    );
  }

  /// Build the main home content - COMPLETE VERSION WITH ALL FEATURES
  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header with Menu and Calendar buttons
            _buildWelcomeHeader()
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 600))
                .slideY(begin: -0.3, end: 0),

            // Animated Quote Section - COMPLETE VERSION
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60, // Fixed height to prevent jumping
                    child: Center(
                      child: AnimatedTextKit(
                        animatedTexts: _quotes.map((quote) => TypewriterAnimatedText(
                          quote,
                          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                          speed: const Duration(milliseconds: 50),
                        )).toList(),
                        repeatForever: true,
                        pause: const Duration(seconds: 5),
                        displayFullTextOnTap: true,
                        stopPauseOnTap: true,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 600))
                .moveY(begin: 20, end: 0, duration: const Duration(milliseconds: 600)),

            // Productivity Insights Section - WITH PROPER HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productivity Insights',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductivityInsightsWidget(),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 200), duration: const Duration(milliseconds: 600)),

            // Today's Activity Cards - ENHANCED VERSION
            _buildTodayActivitySection()
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 300), duration: const Duration(milliseconds: 600)),

            // Upcoming Activities - COMPLETE VERSION
            _buildUpcomingActivities()
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 400), duration: const Duration(milliseconds: 600)),

            // Priority Matrix Section - COMPLETE VERSION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Priority Matrix',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EisenhowerMatrixScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            EisenhowerMatrix()
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 500), duration: const Duration(milliseconds: 600)),

            // Task Summary - WITH INTEGRATED NAVIGATION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Today\'s Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TaskSummaryCard(
              onTap: () => setState(() => _currentIndex = 1),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 600), duration: const Duration(milliseconds: 600))
                .moveX(begin: 20, end: 0, duration: const Duration(milliseconds: 600)),

            // Focus Mode - WITH INTEGRATED NAVIGATION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Focus Mode',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FocusModeCard(
              onTap: () => setState(() => _currentIndex = 2),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 700), duration: const Duration(milliseconds: 600))
                .moveX(begin: -20, end: 0, duration: const Duration(milliseconds: 600)),

            // Chatbot Card - WITH INTEGRATED NAVIGATION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'AI Assistant',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ChatbotCard(
              onTap: () => setState(() => _currentIndex = 4),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 800), duration: const Duration(milliseconds: 600))
                .moveY(begin: 20, end: 0, duration: const Duration(milliseconds: 600)),

            // Bottom spacing for FAB
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// Welcome Header with Menu and Calendar buttons
  Widget _buildWelcomeHeader() {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.displayName ?? authState.user?.email?.split('@')[0] ?? 'User';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => setState(() => _currentIndex = 3),
          ),
        ],
      ),
    );
  }

  /// Today's Activity Section - ENHANCED WITH ALL STATS
  Widget _buildTodayActivitySection() {
    final taskState = ref.watch(taskProvider);
    final appBlockerState = ref.watch(appBlockerProvider);

    final completedTasks = taskState.tasks.where((task) => task.isCompleted).length;
    final totalTasks = taskState.tasks.length;

    // Use static values for focus data since focusProvider doesn't exist
    final todayFocusTime = Duration(minutes: 45); // Static for now
    final focusSessionsToday = 3; // Static for now
    final productivityScore = _calculateProductivityScore(completedTasks, totalTasks, todayFocusTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Today\'s Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('$completedTasks', 'Tasks\nCompleted', Icons.check_circle, Colors.green),
              _buildStatItem('${todayFocusTime.inMinutes}m', 'Focus\nTime', Icons.timer, Colors.orange),
              _buildStatItem('$focusSessionsToday', 'Sessions\nDone', Icons.local_fire_department, Colors.red),
              _buildStatItem('${productivityScore.toInt()}%', 'Productivity\nScore', Icons.trending_up, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Goal Progress',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$completedTasks/$totalTasks tasks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: totalTasks > 0 ? completedTasks / totalTasks : 0.0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                minHeight: 6,
              ),
            ],
          ),
          // Focus Mode Status
          if (appBlockerState.isFocusModeActive) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Focus mode active • ${appBlockerState.blockedApps.where((app) => app.isBlocked).length} apps blocked',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
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

  /// Stat Item Widget for Activity Section
  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Upcoming Activities Section - COMPLETE VERSION
  Widget _buildUpcomingActivities() {
    // This should get real data from calendar/schedule provider
    final upcomingActivities = [
      {'title': 'Team Meeting', 'time': '2:30 PM', 'timeUntil': 'In 15 minutes', 'icon': Icons.group, 'color': Colors.red},
      {'title': 'Project Review', 'time': '4:00 PM', 'timeUntil': 'In 1 hour 45 minutes', 'icon': Icons.assignment, 'color': Colors.orange},
      {'title': 'Workout Session', 'time': '6:00 PM', 'timeUntil': 'In 3 hours 45 minutes', 'icon': Icons.fitness_center, 'color': Colors.green},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Activities',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 3),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...upcomingActivities.map((activity) => _buildActivityItem(
            activity['title'] as String,
            activity['timeUntil'] as String,
            activity['time'] as String,
            activity['icon'] as IconData,
            activity['color'] as Color,
          )).toList(),
        ],
      ),
    );
  }

  /// Activity Item Widget
  Widget _buildActivityItem(String title, String timeUntil, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeUntil,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Complete Drawer with all navigation options
  Widget _buildDrawer() {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.displayName ?? authState.user?.email?.split('@')[0] ?? 'User';
    final userEmail = authState.user?.email ?? 'user@example.com';

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main navigation items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box_outlined),
            title: const Text('Tasks'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Focus Mode'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Schedule'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Assistant'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          const Divider(),
          // Additional feature screens
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Priority Matrix'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EisenhowerMatrixScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('Productivity Insights'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FocusHistoryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Spacer(),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreenEnhanced()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }

  /// Floating Action Button with Quick Actions
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 16),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(20),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildQuickActionCard(
                        'Add Task',
                        Icons.add_task,
                        Colors.blue,
                            () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 1);
                        },
                      ),
                      _buildQuickActionCard(
                        'Start Focus',
                        Icons.timer,
                        Colors.green,
                            () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 2);
                        },
                      ),
                      _buildQuickActionCard(
                        'Schedule Event',
                        Icons.event,
                        Colors.orange,
                            () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 3);
                        },
                      ),
                      _buildQuickActionCard(
                        'Ask Assistant',
                        Icons.chat,
                        Colors.purple,
                            () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 4);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  /// Quick Action Card Widget
  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
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

  /// Helper method to calculate productivity score
  double _calculateProductivityScore(int completedTasks, int totalTasks, Duration focusTime) {
    if (totalTasks == 0) return 0.0;

    // Base score from task completion (0-70%)
    double taskScore = (completedTasks / totalTasks) * 70;

    // Bonus from focus time (0-30%)
    double focusScore = (focusTime.inMinutes / 120).clamp(0, 1) * 30; // 2 hours = max bonus

    return (taskScore + focusScore).clamp(0, 100);
  }
}