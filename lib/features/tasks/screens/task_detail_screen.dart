import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/task_provider.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(workspaceTasksProvider)
        .where((t) => t.id == taskId)
        .firstOrNull;

    if (task == null) {
      return const Scaffold(body: Center(child: Text('Task not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.accentRed), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(tasksProvider.notifier).toggleComplete(taskId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    task.title,
                    style: AppTextStyles.displaySmall.copyWith(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (task.description.isNotEmpty) ...[
              Text(task.description, style: AppTextStyles.bodyLarge),
              const SizedBox(height: 16),
            ],
            _InfoRow(icon: Icons.flag_rounded, label: 'Priority',
                value: task.priorityStr.toUpperCase()),
            _InfoRow(icon: Icons.sync_rounded, label: 'Status',
                value: task.statusStr.toUpperCase()),
            if (task.dueDate != null)
              _InfoRow(icon: Icons.calendar_today_rounded, label: 'Due Date',
                  value: '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'),
            if (task.tags.isNotEmpty)
              _InfoRow(icon: Icons.label_rounded, label: 'Tags',
                  value: task.tags.join(', ')),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text('$label: ', style: AppTextStyles.labelLarge),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
