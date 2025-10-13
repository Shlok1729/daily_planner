import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daily_planner/constants/app_colors.dart';
import 'package:daily_planner/constants/app_icons.dart';
import 'package:daily_planner/models/task_model.dart';
import 'package:daily_planner/providers/task_provider.dart';
import 'package:daily_planner/widgets/common/loading_widget.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final bool isCreating;
  final bool showBottomNav; // FIXED: Add parameter to control bottom navigation

  const TasksScreen({
    Key? key,
    this.isCreating = false,
    this.showBottomNav = true, // Default to showing bottom nav
  }) : super(key: key);

  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.isCreating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTaskForm();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showTaskForm({Task? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: _TaskForm(task: task),
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Congratulations!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Task completed successfully!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Great job! Keep up the momentum!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // FIXED: The content part of the screen, shared between both layouts
    final content = Column(
        children: [
        _buildDateSelector(isDark),
        _buildFilterChips(isDark),
    Expanded(
    child: taskState.isLoading
    ? LoadingWidget(message: 'Loading tasks...')
        : TabBarView(
    controller: _tabController,
    children: [
    _buildTaskList(
    taskState.tasks.where((task) => !task.isCompleted).toList(),
    false,
    isDark,
    ),
      _buildTaskList(
        taskState.tasks.where((task) => !task.isCompleted).toList(),
        false,
        isDark,
      ),
      _buildTaskList(
        taskState.tasks.where((task) => task.isCompleted).toList(),
        true,
        isDark,
      ),
    ],
    ),
    ),
        ],
    );

    // FIXED: Only use Scaffold if this is the standalone screen (not in bottom nav)
    if (widget.showBottomNav) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(isDark),
        body: content,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: "tasks_screen_fab",
          onPressed: () => _showTaskForm(),
          icon: Icon(AppIcons.add),
          label: Text('Add Task'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
        ),
      );
    } else {
      // FIXED: Return content with appbar but without Scaffold wrapper for use in navigation
      return SafeArea(
        child: Column(
          children: [
            PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight + 48), // For tab bar
              child: _buildAppBar(isDark),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: _isSearching
          ? TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        autofocus: true,
        onChanged: (value) => setState(() {}),
      )
          : Text(
        'Tasks',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      iconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
              }
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => _showOptionsMenu(),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pending'),
                SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final taskState = ref.watch(taskProvider);
                    final pendingCount = taskState.tasks.where((task) => !task.isCompleted).length;
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Completed'),
                SizedBox(width: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final taskState = ref.watch(taskProvider);
                    final completedCount = taskState.tasks.where((task) => task.isCompleted).length;
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$completedCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(Duration(days: 1));
              });
            },
            icon: Icon(
              Icons.chevron_left,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.grey[800]
                  : Colors.grey[100],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMMM d').format(_selectedDate),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(Duration(days: 1));
              });
            },
            icon: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.grey[800]
                  : Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = ['All', 'High Priority', 'Medium Priority', 'Low Priority'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, bool isCompleted, bool isDark) {
    final filteredTasks = _getFilteredTasks(tasks);

    if (filteredTasks.isEmpty) {
      return _buildEmptyState(isCompleted, isDark);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return _buildTaskCard(task, isDark);
      },
    );
  }

  Widget _buildTaskCard(Task task, bool isDark) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: isDark ? 6 : 3,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.grey[700]!.withOpacity(0.5)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showTaskForm(task: task),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _toggleTaskCompletion(task),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: task.isCompleted ? Colors.green : Colors.transparent,
                        border: Border.all(
                          color: task.isCompleted
                              ? Colors.green
                              : (isDark ? Colors.grey[400]! : Colors.grey[500]!),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: task.isCompleted
                          ? Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted
                                ? (isDark ? Colors.grey[500] : Colors.grey[600])
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          SizedBox(height: 6),
                          Text(
                            task.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: task.isCompleted
                                  ? (isDark ? Colors.grey[600] : Colors.grey[500])
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  _buildPriorityChip(task.priority, isDark),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]?.withOpacity(0.5)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${task.dueTime.format(context)}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    if (task.isUrgent) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(isDark ? 0.3 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'Urgent',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    if (task.isImportant && !task.isUrgent)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(isDark ? 0.3 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'Important',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority, bool isDark) {
    Color color;
    String label;

    switch (priority) {
      case TaskPriority.high:
        color = Colors.red;
        label = 'High';
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        label = 'Medium';
        break;
      case TaskPriority.low:
        color = Colors.green;
        label = 'Low';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isCompleted, bool isDark) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]?.withOpacity(0.5)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.celebration : Icons.task_alt,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            Text(
              isCompleted
                  ? 'No completed tasks yet'
                  : 'No pending tasks for this day',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              isCompleted
                  ? 'Complete some tasks to see them here'
                  : 'Add a new task to get started',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isCompleted) ...[
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showTaskForm(),
                icon: Icon(Icons.add),
                label: Text('Add Your First Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    var filtered = tasks.where((task) {
      final matchesDate = task.dueDate.day == _selectedDate.day &&
          task.dueDate.month == _selectedDate.month &&
          task.dueDate.year == _selectedDate.year;

      final matchesSearch = _searchController.text.isEmpty ||
          task.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'High Priority' && task.priority == TaskPriority.high) ||
          (_selectedFilter == 'Medium Priority' && task.priority == TaskPriority.medium) ||
          (_selectedFilter == 'Low Priority' && task.priority == TaskPriority.low);

      return matchesDate && matchesSearch && matchesFilter;
    }).toList();

    // Sort by priority and time
    filtered.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index);
      }
      return a.dueTime.hour.compareTo(b.dueTime.hour);
    });

    return filtered;
  }

  void _showOptionsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sort,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                'Sort Tasks',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Change task ordering',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add sort logic here
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: Colors.blue,
                ),
              ),
              title: Text(
                'Filter Options',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Advanced filtering',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Add filter logic here
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_sweep,
                  color: Colors.red,
                ),
              ),
              title: Text(
                'Clear Completed',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Remove all completed tasks',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _clearCompletedTasks();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTaskCompletion(Task task) {
    final taskNotifier = ref.read(taskProvider.notifier);
    taskNotifier.toggleTask(task.id);

    if (!task.isCompleted) {
      _showCompletionDialog();
    }
  }

  void _clearCompletedTasks() {
    final taskNotifier = ref.read(taskProvider.notifier);
    taskNotifier.clearCompleted();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Completed tasks cleared'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Enhanced Task Form Widget - FIXED: Complete dark theme support
class _TaskForm extends ConsumerStatefulWidget {
  final Task? task;

  const _TaskForm({Key? key, this.task}) : super(key: key);

  @override
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _isUrgent = false;
  bool _isImportant = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.dueDate;
      _selectedTime = widget.task!.dueTime;
      _selectedPriority = widget.task!.priority;
      _isUrgent = widget.task!.isUrgent;
      _isImportant = widget.task!.isImportant;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
        dueTime: _selectedTime,
        priority: _selectedPriority,
        isUrgent: _isUrgent,
        isImportant: _isImportant,
        isCompleted: widget.task?.isCompleted ?? false,
      );

      final taskNotifier = ref.read(taskProvider.notifier);
      if (widget.task == null) {
        taskNotifier.addTask(task);
      } else {
        taskNotifier.updateTask(task);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                widget.task == null ? Icons.add_circle : Icons.edit,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(widget.task == null ? 'Task added' : 'Task updated'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
        key: _formKey,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Handle
        Container(
        width: 40,
        height: 4,
        margin: EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
    color: isDark ? Colors.grey[600] : Colors.grey[300],
    borderRadius: BorderRadius.circular(2),
    ),
    ),

    Text(
    widget.task == null ? 'Add Task' : 'Edit Task',
    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
    ),
    ),

    SizedBox(height: 20),

    // Title
    TextFormField(
    controller: _titleController,
    decoration: InputDecoration(
    labelText: 'Task Title',
    labelStyle: TextStyle(
    color: isDark ? Colors.grey[400] : Colors.grey[600],
    ),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
    color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
    ),
    ),
    focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
    color: Theme.of(context).colorScheme.primary,
    width: 2,
    ),
    ),
    filled: true,
    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      prefixIcon: Icon(
        Icons.title,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
    ),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a task title';
        }
        return null;
      },
    ),

          SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
              prefixIcon: Icon(
                Icons.description,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 3,
          ),

          SizedBox(height: 16),

          // Date and Time
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  icon: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    DateFormat('MMM dd').format(_selectedDate),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[50],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
                  icon: Icon(
                    Icons.access_time,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    _selectedTime.format(context),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[50],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Priority
          DropdownButtonFormField<TaskPriority>(
            value: _selectedPriority,
            decoration: InputDecoration(
              labelText: 'Priority',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
              prefixIcon: Icon(
                Icons.flag,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            dropdownColor: isDark ? Colors.grey[800] : Colors.white,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            items: TaskPriority.values.map((priority) {
              Color priorityColor;
              switch (priority) {
                case TaskPriority.high:
                  priorityColor = Colors.red;
                  break;
                case TaskPriority.medium:
                  priorityColor = Colors.orange;
                  break;
                case TaskPriority.low:
                  priorityColor = Colors.green;
                  break;
              }

              return DropdownMenuItem(
                value: priority,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      priority.name.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPriority = value!;
              });
            },
          ),

          SizedBox(height: 16),

          // Urgent and Important switches
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eisenhower Matrix',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: Text(
                          'Urgent',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Needs immediate attention',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        value: _isUrgent,
                        onChanged: (value) {
                          setState(() {
                            _isUrgent = value;
                          });
                        },
                        activeColor: Colors.red,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        title: Text(
                          'Important',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Contributes to goals',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        value: _isImportant,
                        onChanged: (value) {
                          setState(() {
                            _isImportant = value;
                          });
                        },
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Save button
          ElevatedButton.icon(
            onPressed: _saveTask,
            icon: Icon(widget.task == null ? Icons.add : Icons.save),
            label: Text(widget.task == null ? 'Add Task' : 'Update Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          SizedBox(height: 16),
        ],
        ),
    );
  }
}