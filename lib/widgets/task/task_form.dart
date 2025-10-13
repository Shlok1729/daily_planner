import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daily_planner/constants/app_colors.dart';
import 'package:daily_planner/models/task_model.dart';

class TaskForm extends StatefulWidget {
  final Task? task;
  final Function(Task) onSave;

  const TaskForm({
    Key? key,
    this.task,
    required this.onSave,
  }) : super(key: key);

  @override
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late TaskPriority _priority;
  late TaskCategory _category;
  late bool _isUrgent;
  late bool _isImportant;

  @override
  void initState() {
    super.initState();

    // Initialize with existing task data or defaults
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate ?? DateTime.now();
    _dueTime = widget.task?.dueTime ?? TimeOfDay(hour: 12, minute: 0);
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _category = widget.task?.category ?? TaskCategory.personal;
    _isUrgent = widget.task?.isUrgent ?? false;
    _isImportant = widget.task?.isImportant ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate,
        dueTime: _dueTime,
        priority: _priority,
        category: _category,
        isCompleted: widget.task?.isCompleted ?? false,
        isUrgent: _isUrgent,
        isImportant: _isImportant,
      );

      widget.onSave(task);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );

    if (picked != null && picked != _dueTime) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                widget.task == null ? 'Create Task' : 'Edit Task',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 24),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Due date and time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_dueDate),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Time',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _dueTime.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Priority selection
              Text(
                'Priority',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityOption(
                    context,
                    'High',
                    TaskPriority.high,
                    AppColors.highPriority,
                  ),
                  SizedBox(width: 12),
                  _buildPriorityOption(
                    context,
                    'Medium',
                    TaskPriority.medium,
                    AppColors.mediumPriority,
                  ),
                  SizedBox(width: 12),
                  _buildPriorityOption(
                    context,
                    'Low',
                    TaskPriority.low,
                    AppColors.lowPriority,
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Eisenhower Matrix
              Text(
                'Eisenhower Matrix',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text('Urgent'),
                      value: _isUrgent,
                      onChanged: (value) {
                        setState(() {
                          _isUrgent = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: Text('Important'),
                      value: _isImportant,
                      onChanged: (value) {
                        setState(() {
                          _isImportant = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Category selection
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<TaskCategory>(
                value: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: TaskCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(
                    widget.task == null ? 'Create Task' : 'Save Changes',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityOption(
      BuildContext context,
      String label,
      TaskPriority priority,
      Color color,
      ) {
    final isSelected = _priority == priority;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _priority = priority;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(TaskCategory category) {
    switch (category) {
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.other:
        return 'Other';
      default:
        return 'Other';
    }
  }
}