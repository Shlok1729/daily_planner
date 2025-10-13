import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:daily_planner/constants/app_colors.dart';
import 'package:daily_planner/models/task_model.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskItem({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  _TaskItemState createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _checkAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.task.isCompleted) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    if (widget.task.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }

    // Add a slight delay to allow animation to start
    Future.delayed(Duration(milliseconds: 100), () {
      widget.onToggle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color priorityColor = _getPriorityColor(widget.task.priority);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => widget.onEdit(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) => _showDeleteConfirmation(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value * -5),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: widget.task.isCompleted
                      ? Border.all(color: Colors.green.withOpacity(0.3), width: 2)
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onEdit,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FIXED: Better row layout to prevent overflow
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Enhanced Checkbox
                              GestureDetector(
                                onTap: _handleToggle,
                                child: AnimatedBuilder(
                                  animation: _checkAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: widget.task.isCompleted
                                            ? Colors.green
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: widget.task.isCompleted
                                              ? Colors.green
                                              : (isDark ? Colors.grey[400]! : Colors.grey),
                                          width: 2,
                                        ),
                                      ),
                                      child: widget.task.isCompleted
                                          ? Transform.scale(
                                        scale: _checkAnimation.value,
                                        child: Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      )
                                          : null,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 16),

                              // Task content - FIXED: Flexible to prevent overflow
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // FIXED: Better title layout with priority indicator
                                    Row(
                                      children: [
                                        // Priority indicator
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: priorityColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        // FIXED: Flexible title to prevent overflow
                                        Expanded(
                                          child: AnimatedDefaultTextStyle(
                                            duration: Duration(milliseconds: 300),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              decoration: widget.task.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: widget.task.isCompleted
                                                  ? (isDark ? Colors.grey[500] : Colors.grey)
                                                  : Theme.of(context).textTheme.bodyLarge?.color,
                                            ),
                                            child: Text(
                                              widget.task.title,
                                              maxLines: 2, // FIXED: Limit lines to prevent overflow
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.task.description.isNotEmpty) ...[
                                      SizedBox(height: 4),
                                      AnimatedDefaultTextStyle(
                                        duration: Duration(milliseconds: 300),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget.task.isCompleted
                                              ? (isDark ? Colors.grey[600] : Colors.grey.withOpacity(0.7))
                                              : (isDark ? Colors.grey[400] : Colors.grey),
                                          decoration: widget.task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                        child: Text(
                                          widget.task.description,
                                          maxLines: 2, // FIXED: Limit lines to prevent overflow
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // FIXED: Better bottom row layout to prevent overflow
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${widget.task.dueTime.format(context)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey,
                                ),
                              ),

                              // FIXED: Spacer to push tags to the right
                              Spacer(),

                              // FIXED: Wrap tags in a flexible widget to handle overflow
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.task.isUrgent && widget.task.isImportant)
                                      _buildTag(context, 'Important & Urgent', AppColors.urgentImportant, isDark),
                                    if (widget.task.isUrgent && !widget.task.isImportant)
                                      _buildTag(context, 'Urgent', AppColors.urgentNotImportant, isDark),
                                    if (!widget.task.isUrgent && widget.task.isImportant)
                                      _buildTag(context, 'Important', AppColors.notUrgentImportant, isDark),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Completion status indicator
                          if (widget.task.isCompleted) ...[
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Done',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // FIXED: Reduced padding
      margin: EdgeInsets.only(left: 4), // FIXED: Add margin for spacing
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8), // FIXED: Smaller border radius
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9, // FIXED: Smaller font size to prevent overflow
          color: color,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.highPriority;
      case TaskPriority.medium:
        return AppColors.mediumPriority;
      case TaskPriority.low:
        return AppColors.lowPriority;
      default:
        return AppColors.lowPriority;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Delete Task',
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.task.title}"?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}