import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/followup_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../data/providers/employee_provider.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/avatar_stack.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Returns the appropriate FAB action based on the active tab index.
  void _onFabTap(BuildContext context) {
    switch (_tabController.index) {
      case 0: // Tasks
        _showAddTask(context);
        break;
      case 1: // Finance
        _showAddExpense(context);
        break;
      case 2: // Follow-ups
        _showAddFollowup(context);
        break;
      case 3: // Notes
        _showAddNote(context);
        break;
    }
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddProjectTaskSheet(
        projectId: widget.projectId,
        parentRef: ref,
      ),
    );
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddExpenseSheet(projectId: widget.projectId, ref: ref),
    );
  }

  void _showAddFollowup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddFollowupSheet(
        projectId: widget.projectId,
        parentRef: ref,
      ),
    );
  }

  void _showAddNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddProjectNoteSheet(
        projectId: widget.projectId,
        parentRef: ref,
      ),
    );
  }

  /// Opens the project settings bottom sheet.
  void _showProjectSettings(BuildContext context, dynamic project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (ctx) => _ProjectSettingsSheet(
        project: project,
        parentRef: ref,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectByIdProvider(widget.projectId));
    final employees = ref.watch(workspaceEmployeesProvider);

    if (project == null) {
      return const Scaffold(body: Center(child: Text('Project not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onFabTap(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Color(project.colorValue),
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                // Opens the project settings sheet
                onPressed: () => _showProjectSettings(context, project),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(project.colorValue),
                      Color(project.colorValue).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(project.emoji,
                                style: const TextStyle(
                                    fontSize: 36, color: Colors.white)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(project.name,
                                  style: AppTextStyles.displaySmall
                                      .copyWith(color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusChip(status: project.statusStr),
                            const SizedBox(width: 8),
                            PriorityChip(priority: project.priorityStr),
                            const Spacer(),
                            if (project.dueDate != null)
                              Row(children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 12, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd MMM yyyy')
                                      .format(project.dueDate!),
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: Colors.white70),
                                ),
                              ]),
                          ],
                        ),
                        if (project.memberIds.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          AvatarStack(
                            names: project.memberIds.map((id) {
                              return employees
                                      .where((employee) => employee.id == id)
                                      .map((employee) => employee.name)
                                      .firstOrNull ??
                                  id;
                            }).toList(),
                            size: 28,
                          ),
                        ],
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: project.progress,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.titleSmall,
              tabs: const [
                Tab(text: 'Tasks'),
                Tab(text: 'Finance'),
                Tab(text: 'Follow-ups'),
                Tab(text: 'Notes'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TasksTab(
              projectId: project.id,
              onAddTap: () => _showAddTask(context),
            ),
            _FinanceTab(
              projectId: project.id,
              project: project,
              onAddTap: () => _showAddExpense(context),
            ),
            _FollowupsTab(
              projectId: project.id,
              onAddTap: () => _showAddFollowup(context),
            ),
            _NotesTab(
              projectId: project.id,
              onAddTap: () => _showAddNote(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tasks Tab ──────────────────────────────────────────────────────────────

class _TasksTab extends ConsumerWidget {
  final String projectId;
  final VoidCallback onAddTap;

  const _TasksTab({required this.projectId, required this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(projectTasksProvider(projectId));

    if (tasks.isEmpty) {
      return EmptyState(
        icon: Icons.task_alt_rounded,
        title: 'No Tasks',
        subtitle: 'Add tasks to track progress on this project.',
        actionLabel: 'Add Task',
        onAction: onAddTap,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedCard(
            padding: const EdgeInsets.all(14),
            onTap: () => context.go('/home/tasks/${task.id}'),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      ref.read(tasksProvider.notifier).toggleComplete(task.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? AppColors.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14)
                        : null,
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
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (task.dueDate != null)
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
                ),
                PriorityChip(priority: task.priorityStr, compact: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Finance Tab ─────────────────────────────────────────────────────────────

class _FinanceTab extends ConsumerWidget {
  final String projectId;
  final dynamic project;
  final VoidCallback onAddTap;

  const _FinanceTab({
    required this.projectId,
    required this.project,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(projectExpensesProvider(projectId));
    final income = expenses.where((e) => e.isIncome).toList();
    final expense = expenses.where((e) => !e.isIncome).toList();
    final totalIncome = income.fold(0.0, (s, e) => s + e.amount);
    final totalExpense = expense.fold(0.0, (s, e) => s + e.amount);
    final margin = totalIncome == 0
        ? 0.0
        : ((totalIncome - totalExpense) / totalIncome * 100)
            .clamp(-999.0, 999.0);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
                child: _FinanceSummaryCard(
              label: 'Total Income',
              value: totalIncome,
              color: AppColors.accentGreen,
              icon: Icons.trending_up_rounded,
            )),
            const SizedBox(width: 14),
            Expanded(
                child: _FinanceSummaryCard(
              label: 'Total Expense',
              value: totalExpense,
              color: AppColors.accentRed,
              icon: Icons.trending_down_rounded,
            )),
          ],
        ),
        const SizedBox(height: 14),
        _FinanceSummaryCard(
          label: 'Net Profit',
          value: totalIncome - totalExpense,
          color: (totalIncome - totalExpense) >= 0
              ? AppColors.accentGreen
              : AppColors.accentRed,
          icon: Icons.account_balance_rounded,
          wide: true,
        ),
        const SizedBox(height: 14),
        _FinanceSummaryCard(
          label: 'Profit Margin',
          value: margin,
          suffix: '%',
          color: margin >= 0 ? AppColors.accentGreen : AppColors.accentRed,
          icon: Icons.percent_rounded,
          wide: true,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Transactions', style: AppTextStyles.titleLarge),
            const Spacer(),
            GestureDetector(
              onTap: onAddTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Add',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (expenses.isEmpty)
          EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No Transactions',
            subtitle: 'Add income and expenses to track project financials.',
            actionLabel: 'Add Transaction',
            onAction: onAddTap,
          )
        else
          ...expenses.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnimatedCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (e.isIncome
                                  ? AppColors.accentGreen
                                  : AppColors.accentRed)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          e.isIncome
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: e.isIncome
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: AppTextStyles.titleMedium),
                            Text(DateFormat('dd MMM yyyy').format(e.date),
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Text(
                        '${e.isIncome ? '+' : '-'}₹${e.amount.toStringAsFixed(0)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: e.isIncome
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _FinanceSummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool wide;
  final String suffix;

  const _FinanceSummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.wide = false,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(
                  '${suffix.isEmpty ? '₹' : ''}${value.toStringAsFixed(suffix.isEmpty ? 0 : 1)}$suffix',
                  style: AppTextStyles.headlineSmall.copyWith(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Follow-ups Tab ───────────────────────────────────────────────────────────

class _FollowupsTab extends ConsumerWidget {
  final String projectId;
  final VoidCallback onAddTap;

  const _FollowupsTab({required this.projectId, required this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followups = ref.watch(projectFollowupsProvider(projectId));

    if (followups.isEmpty) {
      return EmptyState(
        icon: Icons.track_changes_rounded,
        title: 'No Follow-ups',
        subtitle: 'Add follow-up reminders for this project.',
        actionLabel: 'Add Follow-up',
        onAction: onAddTap,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: followups.length,
      itemBuilder: (context, i) {
        final f = followups[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(f.statusStr).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon(f.typeStr),
                      color: _statusColor(f.statusStr), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.title, style: AppTextStyles.titleMedium),
                      Text(DateFormat('dd MMM yyyy').format(f.dueDate),
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                StatusChip(status: f.statusStr),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return AppColors.statusDone;
      case 'overdue':
        return AppColors.statusOverdue;
      default:
        return AppColors.statusPending;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'call':
        return Icons.phone_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'meeting':
        return Icons.people_rounded;
      case 'visit':
        return Icons.location_on_rounded;
      default:
        return Icons.track_changes_rounded;
    }
  }
}

// ─── Notes Tab ────────────────────────────────────────────────────────────────

class _NotesTab extends ConsumerWidget {
  final String projectId;
  final VoidCallback onAddTap;

  const _NotesTab({required this.projectId, required this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allNotes = ref.watch(notesProvider);
    final projectNotes = allNotes
        .where((n) => n.projectId == projectId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (projectNotes.isEmpty) {
      return EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'No Notes',
        subtitle: 'Attach notes to this project.',
        actionLabel: 'Add Note',
        onAction: onAddTap,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: projectNotes.length,
      itemBuilder: (context, i) {
        final note = projectNotes[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedCard(
            color: Color(note.colorValue),
            onTap: () => context.go('/home/notes/${note.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.isPinned ? '📌 ${note.title}' : note.title,
                  style: AppTextStyles.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(note.content,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 10),
                Text(
                  DateFormat('dd MMM yyyy').format(note.createdAt),
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Add Task Sheet ──────────────────────────────────────────────────────────

class _AddProjectTaskSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef parentRef;

  const _AddProjectTaskSheet(
      {required this.projectId, required this.parentRef});

  @override
  State<_AddProjectTaskSheet> createState() => _AddProjectTaskSheetState();
}

class _AddProjectTaskSheetState extends State<_AddProjectTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'medium';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Task', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Task Title',
                prefixIcon:
                    Icon(Icons.task_alt_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final isSelected = _priority == p;
                final color = p == 'high'
                    ? AppColors.accentRed
                    : p == 'medium'
                        ? AppColors.accentOrange
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
                          color: isSelected
                              ? color.withOpacity(0.12)
                              : AppColors.surfaceVariant,
                          border: isSelected
                              ? Border.all(color: color, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                            child: Text(p.toUpperCase(),
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: isSelected
                                        ? color
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            GradientButton(
                label: 'Create Task',
                onTap: () {
                  if (_titleController.text.trim().isEmpty) return;
                  final workspaceId =
                      widget.parentRef.read(activeWorkspaceIdProvider);
                  if (workspaceId == null) return;
                  final task = TaskModel.create(
                    workspaceId: workspaceId,
                    projectId: widget.projectId,
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    priority: _priority,
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

// ─── Add Expense Sheet ────────────────────────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef ref;

  const _AddExpenseSheet({required this.projectId, required this.ref});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'expense';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Add Transaction', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: GestureDetector(
                  onTap: () => setState(() => _type = 'income'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'income'
                          ? AppColors.accentGreen.withOpacity(0.12)
                          : AppColors.surfaceVariant,
                      border: _type == 'income'
                          ? Border.all(color: AppColors.accentGreen, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text('Income',
                            style: AppTextStyles.titleMedium.copyWith(
                                color: _type == 'income'
                                    ? AppColors.accentGreen
                                    : AppColors.textSecondary))),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: GestureDetector(
                  onTap: () => setState(() => _type = 'expense'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _type == 'expense'
                          ? AppColors.accentRed.withOpacity(0.12)
                          : AppColors.surfaceVariant,
                      border: _type == 'expense'
                          ? Border.all(color: AppColors.accentRed, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text('Expense',
                            style: AppTextStyles.titleMedium.copyWith(
                                color: _type == 'expense'
                                    ? AppColors.accentRed
                                    : AppColors.textSecondary))),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                    hintText: 'Title',
                    prefixIcon:
                        Icon(Icons.label_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: 'Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded,
                        color: AppColors.primary))),
            const SizedBox(height: 24),
            GradientButton(
                label: 'Add Transaction',
                onTap: () {
                  if (_titleController.text.trim().isEmpty) return;
                  final amount = double.tryParse(_amountController.text) ?? 0;
                  final workspaceId =
                      widget.ref.read(activeWorkspaceIdProvider) ?? '';
                  final expense = ExpenseModel.create(
                    workspaceId: workspaceId,
                    projectId: widget.projectId,
                    title: _titleController.text.trim(),
                    amount: amount,
                    type: _type,
                  );
                  widget.ref.read(expensesProvider.notifier).add(expense);
                  Navigator.pop(context);
                }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Add Follow-up Sheet ──────────────────────────────────────────────────────

class _AddFollowupSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef parentRef;

  const _AddFollowupSheet({required this.projectId, required this.parentRef});

  @override
  State<_AddFollowupSheet> createState() => _AddFollowupSheetState();
}

class _AddFollowupSheetState extends State<_AddFollowupSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'call';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Add Follow-up', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            // Type selector
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final t in [
                    'call',
                    'email',
                    'meeting',
                    'visit',
                    'message'
                  ])
                    GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _type == t
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.surfaceVariant,
                          border: _type == t
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t[0].toUpperCase() + t.substring(1),
                            style: AppTextStyles.labelMedium.copyWith(
                                color: _type == t
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Follow-up Title',
                prefixIcon:
                    Icon(Icons.track_changes_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(DateFormat('dd MMM yyyy').format(_dueDate),
                      style: AppTextStyles.titleMedium),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
                label: 'Add Follow-up',
                onTap: () {
                  if (_titleController.text.trim().isEmpty) return;
                  final workspaceId =
                      widget.parentRef.read(activeWorkspaceIdProvider);
                  if (workspaceId == null) return;
                  final followup = FollowupModel.create(
                    workspaceId: workspaceId,
                    projectId: widget.projectId,
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    dueDate: _dueDate,
                    type: _type,
                  );
                  widget.parentRef
                      .read(followupsProvider.notifier)
                      .add(followup);
                  Navigator.pop(context);
                }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Add Note Sheet ───────────────────────────────────────────────────────────

class _AddProjectNoteSheet extends StatefulWidget {
  final String projectId;
  final WidgetRef parentRef;

  const _AddProjectNoteSheet(
      {required this.projectId, required this.parentRef});

  @override
  State<_AddProjectNoteSheet> createState() => _AddProjectNoteSheetState();
}

class _AddProjectNoteSheetState extends State<_AddProjectNoteSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int _colorIndex = 0;

  final List<Color> _colors = [
    AppColors.cardPurple,
    AppColors.cardBlue,
    AppColors.cardOrange,
    AppColors.cardPink,
    AppColors.cardGreen,
    AppColors.cardTeal,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Note', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 14),
            // Color picker
            Row(
                children: _colors.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: _colorIndex == i
                        ? Border.all(color: AppColors.primary, width: 2.5)
                        : null,
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Note Title',
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your note...',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
                label: 'Save Note',
                onTap: () {
                  if (_titleController.text.trim().isEmpty) return;
                  final workspaceId =
                      widget.parentRef.read(activeWorkspaceIdProvider);
                  if (workspaceId == null) return;
                  final note = NoteModel.create(
                    workspaceId: workspaceId,
                    projectId: widget.projectId,
                    title: _titleController.text.trim(),
                    content: _contentController.text.trim(),
                    colorValue: _colors[_colorIndex].value,
                  );
                  widget.parentRef.read(notesProvider.notifier).addNote(note);
                  Navigator.pop(context);
                }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Project Settings Sheet ───────────────────────────────────────────────────

class _ProjectSettingsSheet extends StatefulWidget {
  final dynamic project;
  final WidgetRef parentRef;

  const _ProjectSettingsSheet({required this.project, required this.parentRef});

  @override
  State<_ProjectSettingsSheet> createState() => _ProjectSettingsSheetState();
}

class _ProjectSettingsSheetState extends State<_ProjectSettingsSheet> {
  late TextEditingController _nameController;
  late String _status;
  late String _priority;
  late DateTime? _dueDate;
  late String _selectedEmoji;
  late int _selectedColorIndex;
  late Set<String> _selectedMemberIds;

  final List<String> _emojis = [
    '📁',
    '🏗️',
    '💼',
    '🚀',
    '🎯',
    '⚡',
    '🔧',
    '🌟',
    '🔥',
    '✅'
  ];
  final List<String> _statuses = ['active', 'paused', 'completed', 'cancelled'];
  final List<String> _priorities = ['low', 'medium', 'high', 'critical'];

  final Map<String, Color> _statusColors = {
    'active': AppColors.statusActive,
    'paused': AppColors.statusPaused,
    'completed': AppColors.statusDone,
    'cancelled': AppColors.accentRed,
  };

  final Map<String, Color> _priorityColors = {
    'low': AppColors.priorityLow,
    'medium': AppColors.priorityMedium,
    'high': AppColors.priorityHigh,
    'critical': AppColors.accentRed,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _status = widget.project.statusStr;
    _priority = widget.project.priorityStr;
    _dueDate = widget.project.dueDate;
    _selectedEmoji = widget.project.emoji;
    _selectedMemberIds = {...widget.project.memberIds};
    // Find nearest color index
    _selectedColorIndex = AppColors.workspaceColors.indexWhere(
      (c) => c.value == widget.project.colorValue,
    );
    if (_selectedColorIndex == -1) _selectedColorIndex = 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    final updated = ProjectModel(
      id: widget.project.id,
      workspaceId: widget.project.workspaceId,
      name: _nameController.text.trim(),
      description: widget.project.description,
      statusStr: _status,
      priorityStr: _priority,
      startDate: widget.project.startDate,
      dueDate: _dueDate,
      createdAt: widget.project.createdAt,
      updatedAt: DateTime.now(),
      memberIds: _selectedMemberIds.toList(),
      budget: widget.project.budget,
      totalIncome: widget.project.totalIncome,
      totalExpense: widget.project.totalExpense,
      colorValue: AppColors.workspaceColors[_selectedColorIndex].value,
      emoji: _selectedEmoji,
      completedTasks: widget.project.completedTasks,
      totalTasks: widget.project.totalTasks,
    );
    widget.parentRef.read(projectsProvider.notifier).updateProject(updated);
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'This will permanently delete "${widget.project.name}" and all its data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.parentRef
                  .read(projectsProvider.notifier)
                  .deleteProject(widget.project.id);
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close sheet
              // Pop the detail screen itself
              if (context.canPop()) context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = widget.parentRef.watch(workspaceEmployeesProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Text('Project Settings', style: AppTextStyles.headlineSmall),
                  const Spacer(),
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.accentRed, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name
              Text('Project Name', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon:
                      Icon(Icons.folder_rounded, color: AppColors.primary),
                  hintText: 'Project name',
                ),
              ),
              const SizedBox(height: 16),

              // Emoji picker
              Text('Icon', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojis.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = _emojis[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _selectedEmoji == _emojis[i]
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.surfaceVariant,
                        border: _selectedEmoji == _emojis[i]
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                          child: Text(_emojis[i],
                              style: const TextStyle(fontSize: 22))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Color picker
              Text('Color', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: List.generate(AppColors.workspaceColors.length, (i) {
                  final c = AppColors.workspaceColors[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: _selectedColorIndex == i
                              ? Border.all(
                                  color: AppColors.textPrimary, width: 3)
                              : null,
                        ),
                        child: _selectedColorIndex == i
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Status selector
              Text('Status', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statuses.map((s) {
                  final isSelected = _status == s;
                  final color = _statusColors[s] ?? AppColors.primary;
                  return GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.12)
                            : AppColors.surfaceVariant,
                        border: isSelected
                            ? Border.all(color: color, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(Icons.check_circle_rounded,
                                color: color, size: 14),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            s[0].toUpperCase() + s.substring(1),
                            style: AppTextStyles.labelMedium.copyWith(
                              color:
                                  isSelected ? color : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Priority selector
              Text('Priority', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _priority == p;
                  final color = _priorityColors[p] ?? AppColors.primary;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.12)
                                : AppColors.surfaceVariant,
                            border: isSelected
                                ? Border.all(color: color, width: 2)
                                : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              p[0].toUpperCase() + p.substring(1),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isSelected
                                    ? color
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Due date picker
              Text('Due Date', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _dueDate != null
                            ? DateFormat('MMMM dd, yyyy').format(_dueDate!)
                            : 'No due date set',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: _dueDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textSecondary, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text('Team Members', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              if (employees.isEmpty)
                Text('No team members available in this workspace.',
                    style: AppTextStyles.bodySmall)
              else
                ...employees.map((employee) => CheckboxListTile(
                      value: _selectedMemberIds.contains(employee.id),
                      onChanged: (selected) => setState(() {
                        if (selected == true) {
                          _selectedMemberIds.add(employee.id);
                        } else {
                          _selectedMemberIds.remove(employee.id);
                        }
                      }),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(employee.name),
                      subtitle: Text(employee.roleStr),
                      activeColor: AppColors.primary,
                    )),
              const SizedBox(height: 20),

              // Save button
              GradientButton(
                label: 'Save Changes',
                icon: Icons.save_rounded,
                onTap: _save,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
