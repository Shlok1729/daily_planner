import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daily_planner/models/focus_session.dart';
import 'package:daily_planner/services/focus_history_service.dart';
import 'package:daily_planner/utils/error_handler.dart';
import 'package:daily_planner/widgets/common/loading_widget.dart';
import 'package:daily_planner/widgets/focus/focus_stats_widget.dart';

class FocusHistoryScreen extends ConsumerStatefulWidget {
  const FocusHistoryScreen({Key? key}) : super(key: key);

  @override
  _FocusHistoryScreenState createState() => _FocusHistoryScreenState();
}

class _FocusHistoryScreenState extends ConsumerState<FocusHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FocusHistoryService _historyService = FocusHistoryService();

  bool _isLoading = true;
  List<FocusSession> _recentSessions = [];
  FocusStats? _stats;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _historyService.getRecentSessions(limit: 50);
      final stats = await _historyService.getStats(period: _selectedPeriod);

      setState(() {
        _recentSessions = sessions;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ErrorHandler.showErrorSnackbar(
        context,
        'Failed to load focus history: ${ErrorHandler.getUserFriendlyMessage(e)}',
        onRetry: _loadData,
      );
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Focus History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportData();
                  break;
                case 'clear':
                  _clearHistory();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear History', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview', icon: Icon(Icons.analytics)),
            Tab(text: 'Sessions', icon: Icon(Icons.history)),
            Tab(text: 'Insights', icon: Icon(Icons.psychology)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: LoadingWidget())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildSessionsTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_stats == null) {
      return _buildErrorState('No statistics available');
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          SizedBox(height: 20),
          FocusStatsWidget(stats: _stats!),
          SizedBox(height: 24),
          _buildQuickStats(),
          SizedBox(height: 24),
          _buildWeeklyChart(),
          SizedBox(height: 24),
          _buildProductivityTrends(),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    if (_recentSessions.isEmpty) {
      return _buildEmptyState(
        'No focus sessions yet',
        'Start your first focus session to see your history here',
        Icons.timer,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _recentSessions.length,
      itemBuilder: (context, index) {
        final session = _recentSessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightsHeader(),
          SizedBox(height: 20),
          _buildProductivityInsights(),
          SizedBox(height: 20),
          _buildTimePatterns(),
          SizedBox(height: 20),
          _buildAppBlockingInsights(),
          SizedBox(height: 20),
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: ['week', 'month', 'year'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadData();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard(
          'Total Sessions',
          '${_stats!.totalSessions}',
          Icons.play_circle_outline,
          Colors.blue,
        ),
        SizedBox(width: 12),
        _buildStatCard(
          'Avg Duration',
          '${(_stats!.averageDuration ~/ 60)}m',
          Icons.timer,
          Colors.green,
        ),
        SizedBox(width: 12),
        _buildStatCard(
          'Success Rate',
          '${(_stats!.completionRate * 100).toInt()}%',
          Icons.check_circle,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Focus Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildWeeklyBars(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeeklyBars() {
    final weekData = _stats?.weeklyData ?? {};
    final maxMinutes = weekData.values.isNotEmpty
        ? weekData.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return List.generate(7, (index) {
      final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
      final minutes = weekData[index] ?? 0;
      final height = maxMinutes > 0 ? (minutes / maxMinutes) * 80 : 0.0;

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${(minutes ~/ 60)}h',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 4),
          Container(
            width: 24,
            height: height + 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 8),
          Text(
            dayName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    });
  }

  Widget _buildProductivityTrends() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productivity Trends',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          _buildTrendItem(
            'Best Focus Time',
            _stats?.bestFocusTime ?? 'Morning',
            Icons.wb_sunny,
            Colors.orange,
          ),
          _buildTrendItem(
            'Avg Session Length',
            '${(_stats?.averageDuration ?? 0) ~/ 60} minutes',
            Icons.schedule,
            Colors.blue,
          ),
          _buildTrendItem(
            'Current Streak',
            '${_stats?.currentStreak ?? 0} days',
            Icons.local_fire_department,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(FocusSession session) {
    final isCompleted = session.completedDuration >= session.plannedDuration;
    final completionPercentage = session.plannedDuration > 0
        ? (session.completedDuration / session.plannedDuration * 100).clamp(0, 100)
        : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.schedule,
                      color: isCompleted ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title ?? 'Focus Session',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy • HH:mm').format(session.startTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${completionPercentage.toInt()}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isCompleted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildSessionStat(
                    'Planned',
                    '${session.plannedDuration ~/ 60}m',
                    Icons.schedule,
                  ),
                  SizedBox(width: 16),
                  _buildSessionStat(
                    'Completed',
                    '${session.completedDuration ~/ 60}m',
                    Icons.check,
                  ),
                  SizedBox(width: 16),
                  _buildSessionStat(
                    'Apps Blocked',
                    '${session.blockedApps?.length ?? 0}',
                    Icons.block,
                  ),
                ],
              ),
              if (session.completedDuration < session.plannedDuration) ...[
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: completionPercentage / 100,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: Colors.white, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Personalized analysis of your focus patterns',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityInsights() {
    return _buildInsightCard(
      'Productivity Analysis',
      Icons.trending_up,
      Colors.green,
      [
        'You focus best in the morning hours',
        'Average session completion: ${(_stats?.completionRate ?? 0 * 100).toInt()}%',
        'Most productive day: ${_stats?.mostProductiveDay ?? 'Monday'}',
      ],
    );
  }

  Widget _buildTimePatterns() {
    return _buildInsightCard(
      'Time Patterns',
      Icons.access_time,
      Colors.blue,
      [
        'Peak focus time: ${_stats?.bestFocusTime ?? '9:00 AM'}',
        'Typical session length: ${(_stats?.averageDuration ?? 0) ~/ 60} minutes',
        'Most consistent: Weekdays',
      ],
    );
  }

  Widget _buildAppBlockingInsights() {
    return _buildInsightCard(
      'App Blocking Effectiveness',
      Icons.block,
      Colors.red,
      [
        'Apps blocked this week: ${_stats?.appsBlockedCount ?? 0}',
        'Distraction attempts prevented: ${_stats?.distractionsBlocked ?? 0}',
        'Most blocked app: Social Media',
      ],
    );
  }

  Widget _buildRecommendations() {
    return _buildInsightCard(
      'Recommendations',
      Icons.lightbulb,
      Colors.orange,
      [
        'Try 25-minute Pomodoro sessions',
        'Schedule focus time in the morning',
        'Take breaks every 45 minutes',
        'Block social media during work hours',
      ],
    );
  }

  Widget _buildInsightCard(
      String title,
      IconData icon,
      Color color,
      List<String> insights,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...insights.map((insight) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    insight,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 24),
            Text(
              'Error Loading Data',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      await _historyService.exportData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Focus data exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ErrorHandler.showErrorSnackbar(
        context,
        'Failed to export data: ${ErrorHandler.getUserFriendlyMessage(e)}',
      );
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Focus History?'),
        content: Text(
          'This will permanently delete all your focus session data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _historyService.clearHistory();
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Focus history cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ErrorHandler.showErrorSnackbar(
          context,
          'Failed to clear history: ${ErrorHandler.getUserFriendlyMessage(e)}',
        );
      }
    }
  }
}