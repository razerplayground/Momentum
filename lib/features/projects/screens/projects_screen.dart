import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/providers/employee_provider.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(workspaceProjectsProvider);
    final expenses = ref.watch(expensesProvider);
    final workspace = ref.watch(activeWorkspaceProvider);
    final isGlobalView = ref.watch(globalViewEnabledProvider);
    final filteredProjects = projects.where((project) {
      switch (_selectedFilter) {
        case 'Active':
          return project.statusStr == 'active';
        case 'Pending':
          return project.statusStr == 'paused';
        case 'Completed':
          return project.statusStr == 'completed';
        default:
          return true;
      }
    }).toList();

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
                        // Back button shown only when navigated as a sub-route
                        if (context.canPop()) ...[
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: const Icon(Icons.arrow_back_ios_rounded,
                                size: 20, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text('Projects', style: AppTextStyles.displaySmall),
                        const Spacer(),
                        _FilterChips(
                          selected: _selectedFilter,
                          onSelected: (filter) =>
                              setState(() => _selectedFilter = filter),
                        ),
                      ],
                    ),
                    if (workspace != null || isGlobalView)
                      Text(
                          isGlobalView
                              ? 'All Workspaces • ${filteredProjects.length} projects'
                              : '${workspace!.name} • ${filteredProjects.length} projects',
                          style: AppTextStyles.bodySmall),
                    const SizedBox(height: 16),
                    // Stats strip
                    _ProjectStatsStrip(
                      projects: filteredProjects,
                      expenses: expenses,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          if (filteredProjects.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.folder_open_rounded,
                title: 'No Projects Yet',
                subtitle:
                    'Start by creating your first project for this workspace.',
                actionLabel: 'New Project',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _ProjectListCard(
                    project: filteredProjects[i],
                    expenses: expenses
                        .where((expense) =>
                            expense.projectId == filteredProjects[i].id)
                        .toList(),
                    onTap: () =>
                        context.go('/home/projects/${filteredProjects[i].id}'),
                  ),
                ),
                childCount: filteredProjects.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProject(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddProject(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddProjectSheet(ref: ref),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['All', 'Active', 'Pending', 'Completed'].map((f) {
          final isSelected = selected == f;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => onSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProjectStatsStrip extends StatelessWidget {
  final List<ProjectModel> projects;
  final List<ExpenseModel> expenses;

  const _ProjectStatsStrip({required this.projects, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final active = projects.where((p) => p.statusStr == 'active').length;
    final completed = projects.where((p) => p.statusStr == 'completed').length;
    final projectIds = projects.map((project) => project.id).toSet();
    final totalIncome = expenses
        .where((expense) =>
            expense.isIncome && projectIds.contains(expense.projectId))
        .fold(0.0, (sum, expense) => sum + expense.amount);
    final totalExpense = expenses
        .where((expense) =>
            !expense.isIncome && projectIds.contains(expense.projectId))
        .fold(0.0, (sum, expense) => sum + expense.amount);

    return Row(
      children: [
        _StripStat(
            label: 'Active', value: '$active', color: AppColors.statusActive),
        const SizedBox(width: 12),
        _StripStat(
            label: 'Done', value: '$completed', color: AppColors.statusDone),
        const SizedBox(width: 12),
        _StripStat(
          label: 'Net Profit',
          value: '₹${(totalIncome - totalExpense).toStringAsFixed(0)}',
          color: (totalIncome - totalExpense) >= 0
              ? AppColors.statusActive
              : AppColors.statusOverdue,
        ),
      ],
    );
  }
}

class _StripStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StripStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.titleMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _ProjectListCard extends StatelessWidget {
  final ProjectModel project;
  final List<ExpenseModel> expenses;
  final VoidCallback onTap;

  const _ProjectListCard(
      {required this.project, required this.expenses, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final income = expenses
        .where((expense) => expense.isIncome)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    final expense = expenses
        .where((expense) => !expense.isIncome)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    final profitPercentage = income == 0
        ? 0.0
        : ((income - expense) / income * 100).clamp(-999.0, 999.0);

    return AnimatedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(project.colorValue),
                      Color(project.colorValue).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(project.emoji,
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: AppTextStyles.titleLarge),
                    if (project.description.isNotEmpty)
                      Text(project.description,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              StatusChip(status: project.statusStr),
              const SizedBox(width: 8),
              PriorityChip(priority: project.priorityStr, compact: true),
              const Spacer(),
              if (project.dueDate != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM').format(project.dueDate!),
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.progress,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(project.colorValue)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(project.progress * 100).toInt()}%',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: Color(project.colorValue),
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FinanceStat(
                icon: Icons.trending_up_rounded,
                label: 'Income',
                value: '₹${income.toStringAsFixed(0)}',
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 16),
              _FinanceStat(
                icon: Icons.trending_down_rounded,
                label: 'Expense',
                value: '₹${expense.toStringAsFixed(0)}',
                color: AppColors.accentRed,
              ),
              const SizedBox(width: 16),
              _FinanceStat(
                icon: Icons.percent_rounded,
                label: 'Margin',
                value: '${profitPercentage.toStringAsFixed(1)}%',
                color: profitPercentage >= 0
                    ? AppColors.accentGreen
                    : AppColors.accentRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _FinanceStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text('$label: ', style: AppTextStyles.labelSmall),
        Text(value,
            style: AppTextStyles.labelSmall
                .copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _AddProjectSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddProjectSheet({required this.ref});

  @override
  State<_AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends State<_AddProjectSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedEmoji = '📁';
  int _selectedColorIndex = 0;
  final Set<String> _selectedMemberIds = {};
  DateTime _dueDate = DateTime.now();
  String? _nameError;
  String? _budgetError;

  bool get _isPastDueDate {
    final today = DateTime.now();
    final date = DateTime(_dueDate.year, _dueDate.month, _dueDate.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    return date.isBefore(todayOnly);
  }

  final List<String> _emojis = ['📁', '🏗️', '💼', '🚀', '🎯', '⚡', '🔧', '🌟'];

  @override
  Widget build(BuildContext context) {
    final employees = widget.ref.watch(workspaceEmployeesProvider);

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
              Text('New Project', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              Row(
                children: _emojis
                    .map((e) => GestureDetector(
                          onTap: () => setState(() => _selectedEmoji = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _selectedEmoji == e
                                  ? AppColors.primary.withOpacity(0.12)
                                  : AppColors.surfaceVariant,
                              border: _selectedEmoji == e
                                  ? Border.all(
                                      color: AppColors.primary, width: 2)
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                                child: Text(e,
                                    style: const TextStyle(fontSize: 20))),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              Row(
                  children:
                      List.generate(AppColors.workspaceColors.length, (i) {
                final c = AppColors.workspaceColors[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _selectedColorIndex == i
                            ? Border.all(
                                color: AppColors.textPrimary, width: 2.5)
                            : null,
                      ),
                    ),
                  ),
                );
              })),
              const SizedBox(height: 14),
              TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      hintText: 'Project Name',
                      errorText: _nameError,
                      prefixIcon: const Icon(Icons.folder_rounded,
                          color: AppColors.primary))),
              const SizedBox(height: 12),
              TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                      prefixIcon:
                          Icon(Icons.notes_rounded, color: AppColors.primary))),
              const SizedBox(height: 12),
              TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      hintText: 'Budget (₹)',
                      errorText: _budgetError,
                      prefixIcon: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.primary))),
              const SizedBox(height: 12),
              Text('Due Date', style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked == null || !context.mounted) return;
                  setState(() => _dueDate = picked);
                  if (_isPastDueDate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Warning: this project due date is in the past.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isPastDueDate
                          ? AppColors.accentOrange
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: _isPastDueDate
                            ? AppColors.accentOrange
                            : AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd MMM yyyy').format(_dueDate),
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isPastDueDate) ...[
                const SizedBox(height: 6),
                Text(
                  'Warning: the selected date is earlier than today.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text('Team Members', style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
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
              const SizedBox(height: 24),
              GradientButton(
                  label: 'Create Project',
                  onTap: () {
                    final name = _nameController.text.trim();
                    final budgetText = _budgetController.text.trim();
                    final budget =
                        budgetText.isEmpty ? 0.0 : double.tryParse(budgetText);
                    setState(() {
                      _nameError =
                          name.isEmpty ? 'Project name is required' : null;
                      _budgetError = budget == null || budget < 0
                          ? 'Enter a valid non-negative budget'
                          : null;
                    });
                    if (_nameError != null || _budgetError != null) return;
                    final workspaceId =
                        widget.ref.read(activeWorkspaceIdProvider);
                    if (workspaceId == null) return;
                    final project = ProjectModel.create(
                      workspaceId: workspaceId,
                      name: name,
                      description: _descController.text.trim(),
                      dueDate: _dueDate,
                      emoji: _selectedEmoji,
                      colorValue:
                          AppColors.workspaceColors[_selectedColorIndex].value,
                      budget: budget!,
                    );
                    project.memberIds = _selectedMemberIds.toList();
                    widget.ref
                        .read(projectsProvider.notifier)
                        .addProject(project);
                    Navigator.pop(context);
                  }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
