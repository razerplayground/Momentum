import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/providers/task_provider.dart';
import '../../../../data/providers/workspace_provider.dart';

void showTaskFormSheet(BuildContext context, WidgetRef ref, {TaskModel? task}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => TaskFormSheet(parentRef: ref, task: task),
  );
}

class TaskFormSheet extends StatefulWidget {
  final WidgetRef parentRef;
  final TaskModel? task;

  const TaskFormSheet({
    super.key,
    required this.parentRef,
    this.task,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagController;
  late TextEditingController _subtaskController;

  String _selectedStatus = 'todo';
  String _selectedPriority = 'medium';
  DateTime? _dueDate;
  List<String> _tags = [];
  List<SubtaskModel> _subtasks = [];

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _tagController = TextEditingController();
    _subtaskController = TextEditingController();

    if (_isEdit) {
      _selectedStatus = widget.task!.statusStr;
      _selectedPriority = widget.task!.priorityStr;
      _dueDate = widget.task!.dueDate;
      _tags = List.from(widget.task!.tags);
      _subtasks = List.from(widget.task!.subtasks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) return;

    final activeWorkspaceId =
        widget.parentRef.read(activeWorkspaceIdProvider);

    if (activeWorkspaceId == null && !_isEdit) return;

    final taskNotifier = widget.parentRef.read(tasksProvider.notifier);

    if (_isEdit) {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        statusStr: _selectedStatus,
        priorityStr: _selectedPriority,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        tags: _tags,
        subtasks: _subtasks,
        isCompleted: _selectedStatus == 'done',
        completedAt: _selectedStatus == 'done' ? (_selectedStatus != widget.task!.statusStr ? DateTime.now() : widget.task!.completedAt) : null,
        clearCompletedAt: _selectedStatus != 'done',
      );
      taskNotifier.updateTask(updatedTask);
    } else {
      final newTask = TaskModel.create(
        workspaceId: activeWorkspaceId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        dueDate: _dueDate,
        tags: _tags,
        subtasks: _subtasks,
      );
      if (_selectedStatus == 'done') {
        newTask.isCompleted = true;
        newTask.completedAt = DateTime.now();
      }
      taskNotifier.addTask(newTask);
    }

    Navigator.pop(context);
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.parentRef
                  .read(tasksProvider.notifier)
                  .deleteTask(widget.task!.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagController.clear();
      });
    }
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(SubtaskModel.create(title: text));
        _subtaskController.clear();
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectDueDate() async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: _dueDate ?? DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );

  if (pickedDate != null) {
    setState(() {
      _dueDate = pickedDate;
    });
  }
}

  Widget _buildStatusChip(String value, String label, Color color) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color) {
    final isSelected = _selectedPriority == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16,),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEdit ? 'Edit Task' : 'New Task',
                      style: AppTextStyles.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    style: AppTextStyles.titleLarge,
                    decoration: InputDecoration(
                      hintText: 'Task Title',
                      hintStyle: AppTextStyles.titleLarge.copyWith(color: AppColors.textTertiary),
                      prefixIcon: const Icon(Icons.task_alt_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextField(
                    controller: _descController,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Description (optional)',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status
                  Text('Status', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip('todo', 'To Do', AppColors.primary),
                        const SizedBox(width: 8),
                        _buildStatusChip('inProgress', 'In Progress', AppColors.accentBlue),
                        const SizedBox(width: 8),
                        _buildStatusChip('review', 'Review', AppColors.accentOrange),
                        const SizedBox(width: 8),
                        _buildStatusChip('done', 'Done', AppColors.accentGreen),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Priority
                  Text('Priority', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPriorityChip('low', 'Low', AppColors.priorityLow),
                        const SizedBox(width: 8),
                        _buildPriorityChip('medium', 'Medium', AppColors.priorityMedium),
                        const SizedBox(width: 8),
                        _buildPriorityChip('high', 'High', AppColors.priorityHigh),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Due Date
                  Text('Due Date', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickDueDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dueDate == null
                                  ? 'No due date'
                                  : DateFormat('MMM d, yyyy').format(_dueDate!),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _dueDate == null ? AppColors.textTertiary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_dueDate != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _dueDate = null;
                                });
                              },
                              child: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tags
                  Text('Tags', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  if (_tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag, style: AppTextStyles.labelMedium),
                        backgroundColor: AppColors.surfaceVariant,
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                          });
                        },
                        side: BorderSide.none,
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _tagController,
                    onSubmitted: (_) => _addTag(),
                    decoration: InputDecoration(
                      hintText: 'Add tag',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        onPressed: _addTag,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Subtasks
                  Text('Subtasks', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  if (_subtasks.isNotEmpty) ...[
                    Column(
                      children: _subtasks.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final subtask = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                subtask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: subtask.isCompleted ? AppColors.accentGreen : AppColors.textTertiary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  subtask.title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _subtasks.removeAt(idx);
                                  });
                                },
                                child: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _subtaskController,
                    onSubmitted: (_) => _addSubtask(),
                    decoration: InputDecoration(
                      hintText: 'Add subtask...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        onPressed: _addSubtask,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  GradientButton(
                    label: _isEdit ? 'Update Task' : 'Create Task',
                    onTap: _saveTask,
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _deleteTask,
                        child: Text(
                          'Delete Task',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.accentRed),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
