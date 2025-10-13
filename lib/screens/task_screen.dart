import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daily_planner/constants/app_colors.dart';
import 'package:daily_planner/models/task_model.dart';
import 'package:daily_planner/widgets/task/task_form.dart';
import 'package:daily_planner/widgets/task/task_item.dart';

class TaskScreen extends ConsumerStatefulWidget {
  final bool isCreating;

  const TaskScreen({
    Key? key,
    this.isCreating = false,
  }) : super(key: key);

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All';

  // Mock data for demonstration
  final List<Task> _pendingTasks = [
    Task(
      title: 'Complete project proposal',
      description: 'Finish the draft and send for review',
      dueDate: DateTime.now().add(Duration(days: 1)),
      dueTime: TimeOfDay(hour: 17, minute: 0),
      priority: TaskPriority.high,
      isUrgent: true,
      isImportant: true,
    ),
    Task(
      title: 'Team meeting',
      description: 'Weekly sync with the development team',
      dueDate: DateTime.now(),
      dueTime: TimeOfDay(hour: 14, minute: 30),
      priority: TaskPriority.medium,
      isUrgent: true,
      isImportant: true,
    ),
    Task(
      title: 'Buy groceries',
      description: 'Get milk, eggs, and bread',
      dueDate: DateTime.now().add(Duration(days: 2)),
      dueTime: TimeOfDay(hour: 18, minute: 0),
      priority: TaskPriority.low,
      isUrgent: false,
      isImportant: true,
    ),
  ];

  final List<Task> _completedTasks = [
    Task(
      title: 'Morning exercise',
      description: '30 minutes of cardio',
      dueDate: DateTime.now(),
      dueTime: TimeOfDay(hour: 7, minute: 0),
      priority: TaskPriority.medium,
      isCompleted: true,
      isUrgent: false,
      isImportant: true,
    ),
    Task(
      title: 'Reply to emails',
      description: 'Check inbox and respond to important messages',
      dueDate: DateTime.now().subtract(Duration(days: 1)),
      dueTime: TimeOfDay(hour: 10, minute: 0),
      priority: TaskPriority.medium,
      isCompleted: true,
      isUrgent: true,
      isImportant: false,
    ),
  ];

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
      builder: (context) => TaskForm(
        task: task,
        onSave: (newTask) {
          setState(() {
            if (task != null) {
              final index = _pendingTasks.indexWhere((t) => t.id == task.id);
              if (index != -1) {
                _pendingTasks[index] = newTask;
              }
            } else {
              _pendingTasks.add(newTask);
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      if (task.isCompleted) {
        _completedTasks.removeWhere((t) => t.id == task.id);
        _pendingTasks.add(task.copyWith(isCompleted: false));
      } else {
        _pendingTasks.removeWhere((t) => t.id == task.id);
        _completedTasks.add(task.copyWith(isCompleted: true));
      }
    });

    // Show completion animation
    if (!task.isCompleted) {
      _showCompletionAnimation();
    }
  }

  void _deleteTask(Task task) {
    setState(() {
      if (task.isCompleted) {
        _completedTasks.removeWhere((t) => t.id == task.id);
      } else {
        _pendingTasks.removeWhere((t) => t.id == task.id);
      }
    });

    // Show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              if (task.isCompleted) {
                _completedTasks.add(task);
              } else {
                _pendingTasks.add(task);
              }
            });
          },
        ),
      ),
    );
  }

  void _showCompletionAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Task Completed!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Great job! Keep it up!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue'),
          ),
        ],
      ),
    );

    // Auto dismiss after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildFilterChips(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(_pendingTasks, false),
                _buildTaskList(_completedTasks, true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(),
        icon: Icon(Icons.add),
        label: Text('Add Task'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isSearching
          ? TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        style: TextStyle(color: Colors.black87),
        autofocus: true,
        onChanged: (value) => setState(() {}),
      )
          : Text(
        'Tasks',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black87,
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
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
          icon: Icon(Icons.more_vert),
          onPressed: () => _showOptionsMenu(),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pending'),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_getFilteredTasks(_pendingTasks).length}',
                    style: TextStyle(fontSize: 12),
                  ),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_getFilteredTasks(_completedTasks).length}',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 80,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _selectedDate.day == date.day &&
              _selectedDate.month == date.month &&
              _selectedDate.year == date.year;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 70,
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300]!,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 3),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'High Priority', 'Medium Priority', 'Low Priority'];

    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter : 'All';
                });
              },
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, bool isCompleted) {
    final filteredTasks = _getFilteredTasks(tasks);

    if (filteredTasks.isEmpty) {
      return _buildEmptyState(isCompleted);
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return TaskItem(
          task: task,
          onToggle: () => _toggleTaskCompletion(task),
          onEdit: () => _showTaskForm(task: task),
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isCompleted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompleted ? Icons.celebration : Icons.task_alt,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            isCompleted
                ? 'No completed tasks yet'
                : 'No pending tasks for this day',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isCompleted
                ? 'Complete some tasks to see them here'
                : 'Add a new task to get started',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          if (!isCompleted) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showTaskForm(),
              icon: Icon(Icons.add),
              label: Text('Add Your First Task'),
            ),
          ],
        ],
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.sort),
              title: Text('Sort Tasks'),
              onTap: () {
                Navigator.pop(context);
                _showSortOptions();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_sweep),
              title: Text('Clear Completed'),
              onTap: () {
                Navigator.pop(context);
                _clearCompleted();
              },
            ),
            ListTile(
              leading: Icon(Icons.file_download),
              title: Text('Export Tasks'),
              onTap: () {
                Navigator.pop(context);
                // Export functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    // Implementation for sort options
  }

  void _clearCompleted() {
    setState(() {
      _completedTasks.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Completed tasks cleared')),
    );
  }
}