import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/task_model.dart';
import '../../../data/providers/task_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';
import 'task_form_sheet.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(singleTaskProvider(taskId));

    if (task == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Task not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Task Details', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () {
              showTaskFormSheet(context, ref, task: task);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.accentRed),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context, ref, task),
            const SizedBox(height: 24),
            _buildStatusStepper(ref, task),
            const SizedBox(height: 24),
            _buildInfoSection(task),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: 'Description'),
              const SizedBox(height: 12),
              AnimatedCard(
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    task.description,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildSubtasksSection(ref, task),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Task', style: AppTextStyles.headlineMedium),
        content: Text('Are you sure you want to delete this task?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: Text('Cancel', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(tasksProvider.notifier).deleteTask(taskId);
              ctx.pop();
              context.pop();
            },
            child: Text('Delete', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, WidgetRef ref, TaskModel task) {
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => ref.read(tasksProvider.notifier).toggleComplete(task.id),
                child: Container(
                  margin: const EdgeInsets.only(top: 4, right: 12),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                    color: task.isCompleted ? AppColors.primary : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              Expanded(
                child: Text(
                  task.title,
                  style: AppTextStyles.displaySmall.copyWith(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              PriorityChip(priority: task.priorityStr),
              const SizedBox(width: 8),
              StatusChip(status: task.statusStr),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(WidgetRef ref, TaskModel task) {
    const statuses = [
      {'val': 'todo', 'label': 'To Do', 'color': AppColors.textSecondary, 'icon': Icons.radio_button_unchecked},
      {'val': 'inProgress', 'label': 'In Progress', 'color': AppColors.accentBlue, 'icon': Icons.play_arrow},
      {'val': 'review', 'label': 'Under Review', 'color': AppColors.accentOrange, 'icon': Icons.search},
      {'val': 'done', 'label': 'Completed', 'color': AppColors.statusDone, 'icon': Icons.check},
    ];

    final currentIdx = statuses.indexWhere((s) => s['val'] == task.statusStr);
    
    return AnimatedCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(statuses.length, (index) {
          final isCompleted = currentIdx != -1 && index < currentIdx;
          final isCurrent = index == currentIdx;
          final isFuture = currentIdx != -1 && index > currentIdx;
          
          final status = statuses[index];
          final color = status['color'] as Color;
          final val = status['val'] as String;

          Widget circle;
          if (isCompleted) {
            circle = Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            );
          } else if (isCurrent) {
            circle = Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(status['icon'] as IconData, color: Colors.white, size: 16),
            );
          } else {
            circle = Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Icon(status['icon'] as IconData, color: AppColors.border, size: 16),
            );
          }

          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(tasksProvider.notifier).updateTaskStatus(taskId, val);
              },
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index == 0 ? Colors.transparent : (isCompleted || isCurrent ? AppColors.primary : AppColors.border),
                        ),
                      ),
                      circle,
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index == statuses.length - 1 ? Colors.transparent : (isCompleted ? AppColors.primary : AppColors.border),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status['label'] as String,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isFuture ? AppColors.textTertiary : AppColors.textPrimary,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInfoSection(TaskModel task) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isOverdue = task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted;

    return AnimatedCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Due Date',
            value: task.dueDate != null ? dateFormat.format(task.dueDate!) : 'No due date',
            valueColor: isOverdue ? AppColors.accentRed : null,
          ),
          const AppDivider(),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Priority',
            value: task.priorityStr[0].toUpperCase() + task.priorityStr.substring(1),
          ),
          const AppDivider(),
          _InfoRow(
            icon: Icons.label_outline,
            label: 'Tags',
            value: task.tags.isNotEmpty ? task.tags.join(', ') : 'None',
          ),
          const AppDivider(),
          _InfoRow(
            icon: Icons.access_time,
            label: 'Created',
            value: dateFormat.format(task.createdAt),
          ),
          const AppDivider(),
          _InfoRow(
            icon: Icons.update,
            label: 'Last Updated',
            value: dateFormat.format(task.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksSection(WidgetRef ref, TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Subtasks',
          subtitle: '${task.completedSubtaskCount} of ${task.subtasks.length} completed',
        ),
        if (task.subtasks.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: AppColors.borderLight,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: task.subtaskProgress,
                child: ShaderMask(
                  shaderCallback: (bounds) => AppColors.progressGradient.createShader(bounds),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...task.subtasks.map((subtask) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: AnimatedCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => ref.read(tasksProvider.notifier).toggleSubtask(task.id, subtask.id),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: subtask.isCompleted ? AppColors.primary : AppColors.border,
                              width: 2,
                            ),
                            color: subtask.isCompleted ? AppColors.primary : Colors.transparent,
                          ),
                          child: subtask.isCompleted
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subtask.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                            color: subtask.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textTertiary),
                        onPressed: () => ref.read(tasksProvider.notifier).deleteSubtask(task.id, subtask.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              )),
        ],
        const SizedBox(height: 12),
        _SubtaskInput(taskId: task.id, ref: ref),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskInput extends StatefulWidget {
  final String taskId;
  final WidgetRef ref;
  const _SubtaskInput({required this.taskId, required this.ref});

  @override
  State<_SubtaskInput> createState() => _SubtaskInputState();
}

class _SubtaskInputState extends State<_SubtaskInput> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.ref.read(tasksProvider.notifier).addSubtask(
        widget.taskId, 
        SubtaskModel.create(title: text),
      );
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Add a subtask...',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          border: InputBorder.none,
          icon: Icon(Icons.add, color: AppColors.textTertiary),
        ),
        onSubmitted: (_) => _submit(),
        textInputAction: TextInputAction.done,
      ),
    );
  }
}
