import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/workspace_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _businessId;
  bool _allBusinesses = true;

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider);
    final workspaceNames = {
      for (final workspace in workspaces) workspace.id: workspace.name,
    };
    final activeWorkspaceId = ref.watch(activeWorkspaceProvider)?.id;
    final businessId = workspaces.any((item) => item.id == _businessId)
        ? _businessId!
        : activeWorkspaceId ??
            (workspaces.isNotEmpty ? workspaces.first.id : null);
    final workspaceIds = _allBusinesses
        ? workspaces.map((workspace) => workspace.id).toSet()
        : businessId == null
            ? <String>{}
            : {businessId};
    final projects = ref.watch(projectsProvider);
    final projectWorkspaceIds = {
      for (final project in projects) project.id: project.workspaceId,
    };
    final projectNames = {
      for (final project in projects) project.id: project.name,
    };
    final tasks = ref.watch(tasksProvider).where((task) {
      final taskWorkspaceId = task.projectId == null
          ? task.workspaceId
          : projectWorkspaceIds[task.projectId] ?? task.workspaceId;
      return workspaceIds.contains(taskWorkspaceId);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final expenses = ref
        .watch(expensesProvider)
        .where((expense) => workspaceIds.contains(expense.workspaceId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.business_center_outlined),
                label: Text('All businesses'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.business_outlined),
                label: Text('One business'),
              ),
            ],
            selected: {_allBusinesses},
            onSelectionChanged: (selection) =>
                setState(() => _allBusinesses = selection.first),
          ),
          if (!_allBusinesses) ...[
            const SizedBox(height: 16),
            if (workspaces.isEmpty)
              const Text('Create a business to view its reports.')
            else
              DropdownButtonFormField<String>(
                initialValue: businessId,
                decoration: const InputDecoration(
                  labelText: 'Business',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                items: workspaces
                    .map(
                      (workspace) => DropdownMenuItem(
                        value: workspace.id,
                        child: Text(workspace.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _businessId = value);
                },
              ),
          ],
          const SizedBox(height: 16),
          if (expenses.isNotEmpty)
            _FinanceDetailsSection(
              expenses: expenses,
              workspaceNames: workspaceNames,
              projectNames: projectNames,
              title: _allBusinesses
                  ? 'Finance details · All businesses'
                  : 'Finance details · ${workspaceNames[businessId] ?? 'Business'}',
            ),
          _TaskDetailsSection(
            tasks: tasks,
            workspaceNames: workspaceNames,
            projectWorkspaceIds: projectWorkspaceIds,
            projectNames: projectNames,
            title: _allBusinesses
                ? 'Task details · All businesses'
                : 'Task details · ${workspaceNames[businessId] ?? 'Business'}',
          ),
        ],
      ),
    );
  }
}

class _FinanceDetailsSection extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final Map<String, String> workspaceNames;
  final Map<String, String> projectNames;
  final String title;

  const _FinanceDetailsSection({
    required this.expenses,
    required this.workspaceNames,
    required this.projectNames,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final income = expenses
        .where((expense) => expense.isIncome)
        .fold(0.0, (total, expense) => total + expense.amount);
    final spending = expenses
        .where((expense) => !expense.isIncome)
        .fold(0.0, (total, expense) => total + expense.amount);
    final netProfit = income - spending;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryMetric(
                label: 'Income',
                value: '₹${income.toStringAsFixed(2)}',
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 10),
              _SummaryMetric(
                label: 'Expenses',
                value: '₹${spending.toStringAsFixed(2)}',
                color: AppColors.accentRed,
              ),
              const SizedBox(width: 10),
              _SummaryMetric(
                label: 'Net profit',
                value: '₹${netProfit.toStringAsFixed(2)}',
                color: netProfit >= 0
                    ? AppColors.accentGreen
                    : AppColors.accentRed,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${expenses.length} transactions',
              style: AppTextStyles.bodySmall),
          ...expenses.map(
            (expense) => Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                leading: Icon(
                  expense.isIncome
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: expense.isIncome
                      ? AppColors.accentGreen
                      : AppColors.accentRed,
                ),
                title: Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (workspaceNames[expense.workspaceId] != null)
                      workspaceNames[expense.workspaceId]!,
                    if (projectNames[expense.projectId] != null)
                      projectNames[expense.projectId]!,
                    expense.categoryStr,
                    if (expense.description.trim().isNotEmpty)
                      expense.description.trim(),
                    expense.isCompleted ? 'Completed' : 'Open',
                    expense.date.toLocal().toIso8601String().split('T').first,
                  ].join(' · '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${expense.isIncome ? '+' : '-'}₹${expense.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: expense.isIncome
                        ? AppColors.accentGreen
                        : AppColors.accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailsSection extends StatelessWidget {
  final List<TaskModel> tasks;
  final Map<String, String> workspaceNames;
  final Map<String, String> projectWorkspaceIds;
  final Map<String, String> projectNames;
  final String title;

  const _TaskDetailsSection({
    required this.tasks,
    required this.workspaceNames,
    required this.projectWorkspaceIds,
    required this.projectNames,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final completed = tasks
        .where((task) => task.isCompleted || task.statusStr == 'done')
        .length;
    final pending = tasks.length - completed;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryMetric(
                label: 'Total tasks',
                value: '${tasks.length}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _SummaryMetric(
                label: 'Completed',
                value: '$completed',
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 10),
              _SummaryMetric(
                label: 'Open',
                value: '$pending',
                color: AppColors.accentOrange,
              ),
            ],
          ),
          if (tasks.isEmpty)
            const Card(
              margin: EdgeInsets.only(top: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No tasks for this scope.'),
              ),
            ),
          ...tasks.map((task) {
            final taskWorkspaceId = task.projectId == null
                ? task.workspaceId
                : projectWorkspaceIds[task.projectId] ?? task.workspaceId;
            final details = <String>[
              if (workspaceNames[taskWorkspaceId] != null)
                workspaceNames[taskWorkspaceId]!,
              if (task.projectId != null &&
                  projectNames[task.projectId] != null)
                projectNames[task.projectId]!,
              _humanize(task.statusStr),
              '${_humanize(task.priorityStr)} priority',
              if (task.subtasks.isNotEmpty)
                '${task.completedSubtaskCount}/${task.subtasks.length} subtasks',
              if (task.dueDate != null)
                'Due ${task.dueDate!.toLocal().toIso8601String().split('T').first}',
            ];

            return Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                leading: Icon(
                  task.isCompleted || task.statusStr == 'done'
                      ? Icons.check_circle_rounded
                      : Icons.task_alt_rounded,
                  color: task.isCompleted || task.statusStr == 'done'
                      ? AppColors.accentGreen
                      : AppColors.primary,
                ),
                title: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (task.description.trim().isNotEmpty)
                      task.description.trim(),
                    ...details,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _humanize(String value) {
  final spaced = value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');
  return spaced.isEmpty
      ? spaced
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
