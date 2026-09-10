import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/task_model.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(workspaceTasksProvider);
    final today = ref.watch(todayTasksProvider);
    final overdue = ref.watch(overdueTasksProvider);

    final filtered = _filterStatus == 'all'
        ? allTasks
        : _filterStatus == 'today'
            ? today
            : _filterStatus == 'overdue'
                ? overdue
                : allTasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show back button when navigated as a sub-route (not as a bottom-nav tab)
                    if (context.canPop())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: const Icon(Icons.arrow_back_ios_rounded,
                                  size: 20, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            Text('Back', style: AppTextStyles.titleMedium
                                .copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    Text('Tasks', style: AppTextStyles.displaySmall),
                    const SizedBox(height: 4),
                    Text('${allTasks.length} total • ${today.length} today',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 16),
                    // Stat Cards
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _TaskStatCard(
                            label: 'All', count: allTasks.length,
                            color: AppColors.primary, isSelected: _filterStatus == 'all',
                            onTap: () => setState(() => _filterStatus = 'all'),
                          ),
                          _TaskStatCard(
                            label: 'Today', count: today.length,
                            color: AppColors.accentBlue, isSelected: _filterStatus == 'today',
                            onTap: () => setState(() => _filterStatus = 'today'),
                          ),
                          _TaskStatCard(
                            label: 'Overdue', count: overdue.length,
                            color: AppColors.accentRed, isSelected: _filterStatus == 'overdue',
                            onTap: () => setState(() => _filterStatus = 'overdue'),
                          ),
                          _TaskStatCard(
                            label: 'Done', count: allTasks.where((t) => t.isCompleted).length,
                            color: AppColors.accentGreen, isSelected: _filterStatus == 'done',
                            onTap: () => setState(() => _filterStatus = 'done'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.task_alt_outlined,
                title: 'No Tasks Here',
                subtitle: 'Create tasks to track your work.',
                actionLabel: 'New Task',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _TaskCard(
                    task: filtered[i],
                    onToggle: () => ref.read(tasksProvider.notifier)
                        .toggleComplete(filtered[i].id),
                    onTap: () => context.go('/home/tasks/${filtered[i].id}'),
                  ),
                ),
                childCount: filtered.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTask(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddTaskSheet(parentRef: ref),
    );
  }
}

class _TaskStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskStatCard({
    required this.label, required this.count,
    required this.color, required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? null : Border.all(color: AppColors.border),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count',
                style: AppTextStyles.headlineSmall.copyWith(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? Colors.white70 : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: task.isCompleted ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(task.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    PriorityChip(priority: task.priorityStr, compact: true),
                    const SizedBox(width: 8),
                    if (task.dueDate != null) Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12,
                            color: task.dueDate!.isBefore(DateTime.now())
                                ? AppColors.accentRed : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM').format(task.dueDate!),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: task.dueDate!.isBefore(DateTime.now())
                                ? AppColors.accentRed : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (task.tags.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(task.tags.first,
                            style: AppTextStyles.labelSmall),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final WidgetRef parentRef;

  const _AddTaskSheet({required this.parentRef});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Task', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: _titleController,
                decoration: const InputDecoration(hintText: 'Task Title',
                    prefixIcon: Icon(Icons.task_alt_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            TextField(controller: _descController, maxLines: 2,
                decoration: const InputDecoration(hintText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final isSelected = _priority == p;
                final color = p == 'high' ? AppColors.accentRed
                    : p == 'medium' ? AppColors.accentOrange
                    : AppColors.accentGreen;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.12) : AppColors.surfaceVariant,
                          border: isSelected ? Border.all(color: color, width: 2) : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(p.toUpperCase(),
                            style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected ? color : AppColors.textSecondary,
                                fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            GradientButton(label: 'Create Task', onTap: () {
              if (_titleController.text.trim().isEmpty) return;
              final workspaceId = widget.parentRef.read(activeWorkspaceIdProvider);
              if (workspaceId == null) return;
              final task = TaskModel.create(
                workspaceId: workspaceId,
                title: _titleController.text.trim(),
                description: _descController.text.trim(),
                priority: _priority,
                dueDate: _dueDate,
              );
              widget.parentRef.read(tasksProvider.notifier).addTask(task);
              Navigator.pop(context);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
