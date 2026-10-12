import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/task_model.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../dashboard/dashboard_navigation_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';
import 'task_form_sheet.dart';
import '../../../data/providers/project_provider.dart';

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
    final isGlobalView = ref.watch(globalViewEnabledProvider);
    final workspaces = ref.watch(workspacesProvider);
    final projects = ref.watch(projectsProvider);
    final today = ref.watch(todayTasksProvider);
    final overdue = ref.watch(overdueTasksProvider);

    final filtered = _filterStatus == 'all'
        ? allTasks
        : _filterStatus == 'today'
            ? today
            : _filterStatus == 'overdue'
                ? overdue
                : allTasks.where((t) => t.isCompleted).toList();

    final sortedTasks = [...filtered];

    sortedTasks.sort((a, b) {
      const priorityOrder = {
        'high': 0,
        'medium': 1,
        'low': 2,
      };

      return (priorityOrder[a.priorityStr] ?? 3)
          .compareTo(priorityOrder[b.priorityStr] ?? 3);
    });
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
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.read(dashboardTabIndexProvider.notifier).state =
                                0;
                            context.go('/home');
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Tasks', style: AppTextStyles.displaySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        isGlobalView
                            ? '${allTasks.length} total across all workspaces • ${today.length} today'
                            : '${allTasks.length} total • ${today.length} today',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 16),
                    // Stat Cards
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _TaskStatCard(
                            label: 'All',
                            count: allTasks.length,
                            color: AppColors.primary,
                            isSelected: _filterStatus == 'all',
                            onTap: () => setState(() => _filterStatus = 'all'),
                          ),
                          _TaskStatCard(
                            label: 'Today',
                            count: today.length,
                            color: AppColors.accentBlue,
                            isSelected: _filterStatus == 'today',
                            onTap: () =>
                                setState(() => _filterStatus = 'today'),
                          ),
                          _TaskStatCard(
                            label: 'Overdue',
                            count: overdue.length,
                            color: AppColors.accentRed,
                            isSelected: _filterStatus == 'overdue',
                            onTap: () =>
                                setState(() => _filterStatus = 'overdue'),
                          ),
                          _TaskStatCard(
                            label: 'Done',
                            count: allTasks.where((t) => t.isCompleted).length,
                            color: AppColors.accentGreen,
                            isSelected: _filterStatus == 'done',
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
          if (sortedTasks.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.task_alt_outlined,
                title: 'No Tasks Here',
                subtitle: 'Create tasks to track your work.',
                actionLabel: 'New Task',
                onAction: () => _showAddTask(context),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _TaskCard(
                    task: sortedTasks[i],
                    isGlobalView: isGlobalView,
                    workspaceName: workspaces
                        .where((workspace) =>
                            workspace.id == sortedTasks[i].workspaceId)
                        .map((workspace) => workspace.name)
                        .firstOrNull,
                    projectName: projects
                        .where((p) => p.id == sortedTasks[i].projectId)
                        .map((p) => p.name)
                        .firstOrNull,
                    onToggle: () => ref
                        .read(tasksProvider.notifier)
                        .toggleComplete(sortedTasks[i].id),
                    onTap: () => context.go('/home/tasks/${sortedTasks[i].id}'),
                  ),
                ),
                childCount: sortedTasks.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasksScreenFab',
        onPressed: () => _showAddTask(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showTaskFormSheet(context, ref);
  }
}

class _TaskStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskStatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
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
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
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
                    color:
                        isSelected ? Colors.white70 : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isGlobalView;
  final String? workspaceName;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final String? projectName;

  const _TaskCard(
      {required this.task,
      required this.isGlobalView,
      required this.workspaceName,
      required this.projectName,
      required this.onToggle,
      required this.onTap});

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
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color:
                      task.isCompleted ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        task.isCompleted ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
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
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                if (projectName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          projectName!,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(task.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    PriorityChip(priority: task.priorityStr, compact: true),
                    const SizedBox(width: 8),
                    if (task.dueDate != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 12,
                              color: task.dueDate!.isBefore(DateTime.now())
                                  ? AppColors.accentRed
                                  : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM').format(task.dueDate!),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: task.dueDate!.isBefore(DateTime.now())
                                  ? AppColors.accentRed
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    if (isGlobalView)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withAlpha((0.12 * 255).round()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            workspaceName ?? 'Unknown Workspace',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (task.tags.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
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
