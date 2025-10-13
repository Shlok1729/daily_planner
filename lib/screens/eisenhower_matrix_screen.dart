import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/constants/app_colors.dart';
import 'package:daily_planner/models/task_model.dart';
import 'package:daily_planner/screens/chatbot_screen.dart';
import 'package:daily_planner/widgets/task/task_form.dart';

class EisenhowerMatrixScreen extends ConsumerStatefulWidget {
  const EisenhowerMatrixScreen({Key? key}) : super(key: key);

  @override
  _EisenhowerMatrixScreenState createState() => _EisenhowerMatrixScreenState();
}

class _EisenhowerMatrixScreenState extends ConsumerState<EisenhowerMatrixScreen> {
  // Mock data - in real app, this would come from providers
  List<Task> _urgentImportantTasks = [];
  List<Task> _urgentNotImportantTasks = [];
  List<Task> _notUrgentImportantTasks = [];
  List<Task> _notUrgentNotImportantTasks = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // Add some sample tasks
    _urgentImportantTasks = [
      Task(
        title: 'Emergency meeting',
        description: 'Client crisis call',
        dueDate: DateTime.now(),
        dueTime: TimeOfDay.now(),
        priority: TaskPriority.high,
        isUrgent: true,
        isImportant: true,
      ),
    ];

    _notUrgentImportantTasks = [
      Task(
        title: 'Plan quarterly goals',
        description: 'Strategic planning session',
        dueDate: DateTime.now().add(Duration(days: 3)),
        dueTime: TimeOfDay(hour: 14, minute: 0),
        priority: TaskPriority.medium,
        isUrgent: false,
        isImportant: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eisenhower Matrix'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Check if we have enough space for the full matrix
          if (constraints.maxHeight < 400) {
            return SingleChildScrollView(
              child: _buildMatrixContent(constraints),
            );
          }
          return _buildMatrixContent(constraints);
        },
      ),
    );
  }

  Widget _buildMatrixContent(BoxConstraints constraints) {
    return Column(
      children: [
        // Header explanation
        Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.grid_view,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Organize your tasks by urgency and importance',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Matrix Grid - FIXED: Wrapped in Flexible
        Flexible(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Header labels
                Container(
                  height: 30,
                  child: Row(
                    children: [
                      SizedBox(width: 60), // Space for side labels
                      Expanded(
                        child: Center(
                          child: Text(
                            'URGENT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'NOT URGENT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),

                // Matrix rows
                Expanded(
                  child: Row(
                    children: [
                      // Side label for Important
                      Container(
                        width: 60,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Center(
                            child: Text(
                              'IMPORTANT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Urgent + Important
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: 4),
                          child: _buildQuadrant(
                            'DO',
                            'Do it now',
                            AppColors.urgentImportant,
                            Icons.priority_high,
                            _urgentImportantTasks,
                            true,
                            true,
                          ),
                        ),
                      ),

                      // Not Urgent + Important
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 4),
                          child: _buildQuadrant(
                            'DECIDE',
                            'Schedule a time',
                            AppColors.notUrgentImportant,
                            Icons.calendar_today,
                            _notUrgentImportantTasks,
                            false,
                            true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                Expanded(
                  child: Row(
                    children: [
                      // Side label for Not Important
                      Container(
                        width: 60,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Center(
                            child: Text(
                              'NOT IMPORTANT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Urgent + Not Important
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: 4),
                          child: _buildQuadrant(
                            'DELEGATE',
                            'Who can do it?',
                            AppColors.urgentNotImportant,
                            Icons.person_outline,
                            _urgentNotImportantTasks,
                            true,
                            false,
                          ),
                        ),
                      ),

                      // Not Urgent + Not Important
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 4),
                          child: _buildQuadrant(
                            'DELETE',
                            'Eliminate it',
                            AppColors.notUrgentNotImportant,
                            Icons.delete_outline,
                            _notUrgentNotImportantTasks,
                            false,
                            false,
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

        // How to use button
        Container(
          padding: EdgeInsets.all(16),
          child: InkWell(
            onTap: _navigateToHelp,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'How to use Eisenhower Matrix',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrant(
      String title,
      String subtitle,
      Color color,
      IconData icon,
      List<Task> tasks,
      bool isUrgent,
      bool isImportant,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Tasks list - FIXED: Better layout
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  // Existing tasks
                  Expanded(
                    child: tasks.isNotEmpty
                        ? ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) => _buildTaskItem(tasks[index], color),
                    )
                        : Center(
                      child: Text(
                        'No tasks',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // Add task button
                  SizedBox(height: 4),
                  InkWell(
                    onTap: () => _showAddTaskDialog(isUrgent, isImportant),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: color, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Add Task',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.description.isNotEmpty) ...[
            SizedBox(height: 2),
            Text(
              task.description,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _showAddTaskDialog(bool isUrgent, bool isImportant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskForm(
        onSave: (task) {
          final newTask = task.copyWith(
            isUrgent: isUrgent,
            isImportant: isImportant,
          );

          setState(() {
            if (isUrgent && isImportant) {
              _urgentImportantTasks.add(newTask);
            } else if (isUrgent && !isImportant) {
              _urgentNotImportantTasks.add(newTask);
            } else if (!isUrgent && isImportant) {
              _notUrgentImportantTasks.add(newTask);
            } else {
              _notUrgentNotImportantTasks.add(newTask);
            }
          });

          Navigator.pop(context);
        },
      ),
    );
  }

  void _navigateToHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatbotScreen(
          initialMessage: "How to use Eisenhower Matrix? Please explain the different quadrants and how to prioritize tasks effectively.",
        ),
      ),
    );
  }
}