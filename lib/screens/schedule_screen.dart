import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/services/schedule_service.dart';
import 'package:daily_planner/models/task_model.dart';
import 'package:daily_planner/providers/task_provider.dart';
import 'package:daily_planner/constants/app_icons.dart';
import 'package:daily_planner/widgets/common/loading_widget.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  DateTime _selectedDate = DateTime.now();
  List<ScheduleItem> _scheduleItems = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() => _isLoading = true);
    try {
      await _scheduleService.initialize();
      await _loadSchedule();
    } catch (e) {
      setState(() => _error = 'Failed to initialize schedule service: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final items = await _scheduleService.getTimeBlocks(_selectedDate);
      setState(() {
        _scheduleItems = items;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to load schedule: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSchedule() async {
    setState(() => _isLoading = true);
    try {
      final taskState = ref.read(taskProvider);
      final tasks = taskState.getTasksForDate(_selectedDate);

      final preferences = {
        'work_start_hour': 9,
        'work_end_hour': 17,
        'break_duration': 15,
        'lunch_duration': 60,
        'focus_session_duration': 45,
      };

      final generatedItems = await _scheduleService.generateSchedule(
        date: _selectedDate,
        tasks: tasks,
        preferences: preferences,
      );

      await _scheduleService.saveSchedule(_selectedDate, generatedItems);

      setState(() {
        _scheduleItems = generatedItems;
        _error = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schedule generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _error = 'Failed to generate schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate schedule'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Schedule',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
            onPressed: _loadSchedule,
          ),
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
            onPressed: _showAddScheduleItem,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(isDark),
          _buildScheduleInfo(),
          Expanded(
            child: _isLoading
                ? LoadingWidget()
                : _error != null
                ? _buildErrorState(isDark)
                : _scheduleItems.isEmpty
                ? _buildEmptyState(isDark)
                : _buildScheduleList(isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateSchedule,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.auto_awesome, color: Colors.white),
        tooltip: 'Generate Schedule',
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousDate,
            icon: Icon(AppIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              child: Text(
                _formatSelectedDate(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          IconButton(
            onPressed: _nextDate,
            icon: Icon(AppIcons.arrowRight, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo() {
    if (_scheduleItems.isEmpty) return SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalDuration = _scheduleItems.fold<Duration>(
      Duration.zero,
          (total, item) => total + item.duration,
    );

    final taskCount = _scheduleItems
        .where((item) => item.type == ScheduleItemType.task)
        .length;
    final breakCount = _scheduleItems.where((item) =>
    item.type == ScheduleItemType.break_time ||
        item.type == ScheduleItemType.break_
    ).length;

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Total Items', _scheduleItems.length.toString(), Icons.list, isDark),
          _buildInfoItem('Tasks', taskCount.toString(), Icons.task, isDark),
          _buildInfoItem('Breaks', breakCount.toString(), Icons.coffee, isDark),
          _buildInfoItem('Duration',
              '${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m',
              Icons.schedule, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          color: isDark ? Colors.blue[400] : Colors.blue[600],
          size: 20,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.blue[300] : Colors.blue[800],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.blue[400] : Colors.blue[600],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _scheduleItems.length,
      itemBuilder: (context, index) {
        final item = _scheduleItems[index];
        return _buildScheduleItemCard(item, index, isDark);
      },
    );
  }

  Widget _buildScheduleItemCard(ScheduleItem item, int index, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => _showScheduleItemDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Time indicator
              Container(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(TimeOfDay.fromDateTime(item.startTime)),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatTime(TimeOfDay.fromDateTime(item.endTime)),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Colored line indicator
              Container(
                width: 4,
                height: 50,
                margin: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: item.type.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.type.icon,
                          size: 16,
                          color: item.type.color,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.type.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.type.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: item.type.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${item.durationInMinutes} min',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                        Spacer(),
                        if (item.isCompleted)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.isCompleted ? Icons.check : Icons.play_arrow,
                  size: 16,
                  color: item.isCompleted
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No schedule for this day',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Generate a schedule to organize your day',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateSchedule,
            icon: Icon(AppIcons.add),
            label: Text('Generate Schedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          SizedBox(height: 16),
          Text(
            'Error loading schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSchedule,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _previousDate() {
    setState(() {
      _selectedDate = _selectedDate.subtract(Duration(days: 1));
    });
    _loadSchedule();
  }

  void _nextDate() {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: 1));
    });
    _loadSchedule();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSchedule();
    }
  }

  String _formatSelectedDate() {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return 'Today';
    } else if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day + 1) {
      return 'Tomorrow';
    } else if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showScheduleItemDetails(ScheduleItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Row(
          children: [
            Icon(
              item.type.icon,
              color: item.type.color,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null && item.description!.isNotEmpty) ...[
              Text(
                'Description:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                item.description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 16),
            ],

            Text(
              'Type:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.type.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.type.displayName,
                style: TextStyle(
                  color: item.type.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 16),

            Text(
              'Time:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${_formatTime(TimeOfDay.fromDateTime(item.startTime))} - ${_formatTime(TimeOfDay.fromDateTime(item.endTime))}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Duration:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${item.durationInMinutes} minutes',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),

            if (item.priority != null) ...[
              SizedBox(height: 16),
              Text(
                'Priority:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(item.priority!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.priority!.name.toUpperCase(),
                  style: TextStyle(
                    color: _getPriorityColor(item.priority!),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            if (item.taskId != null) ...[
              SizedBox(height: 16),
              Text(
                'Linked Task:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                item.taskId!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          if (item.type == ScheduleItemType.task)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markTaskComplete(item);
              },
              child: Text('Mark Complete'),
            ),
        ],
      ),
    );
  }

  void _markTaskComplete(ScheduleItem item) async {
    if (item.taskId == null) return;

    try {
      final taskNotifier = ref.read(taskProvider.notifier);
      await taskNotifier.completeTask(item.taskId!);

      // Update the schedule item as completed
      final updatedItems = _scheduleItems.map((scheduleItem) {
        if (scheduleItem.id == item.id) {
          return scheduleItem.copyWith(isCompleted: true);
        }
        return scheduleItem;
      }).toList();

      await _scheduleService.saveSchedule(_selectedDate, updatedItems);

      setState(() {
        _scheduleItems = updatedItems;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task marked as complete!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark task as complete'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  void _showAddScheduleItem() {
    // Implementation for adding new schedule items
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Add Schedule Item',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'This feature will allow you to manually add items to your schedule.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Manual schedule item creation coming soon!')),
              );
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}