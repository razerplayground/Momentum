import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(workspaceProjectsProvider);
    final workspace = ref.watch(activeWorkspaceProvider);

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
                        _FilterChips(),
                      ],
                    ),
                    if (workspace != null)
                      Text('${workspace.name} • ${projects.length} projects',
                          style: AppTextStyles.bodySmall),
                    const SizedBox(height: 16),
                    // Stats strip
                    _ProjectStatsStrip(projects: projects),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          if (projects.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.folder_open_rounded,
                title: 'No Projects Yet',
                subtitle: 'Start by creating your first project for this workspace.',
                actionLabel: 'New Project',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _ProjectListCard(
                    project: projects[i],
                    onTap: () => context.go('/home/projects/${projects[i].id}'),
                  ),
                ),
                childCount: projects.length,
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

class _FilterChips extends StatefulWidget {
  @override
  State<_FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<_FilterChips> {
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['All', 'Active', 'Done'].map((f) {
        final isSelected = _selected == f;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: GestureDetector(
            onTap: () => setState(() => _selected = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
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
    );
  }
}

class _ProjectStatsStrip extends StatelessWidget {
  final List<ProjectModel> projects;

  const _ProjectStatsStrip({required this.projects});

  @override
  Widget build(BuildContext context) {
    final active = projects.where((p) => p.statusStr == 'active').length;
    final completed = projects.where((p) => p.statusStr == 'completed').length;
    final totalIncome = projects.fold(0.0, (sum, p) => sum + p.totalIncome);
    final totalExpense = projects.fold(0.0, (sum, p) => sum + p.totalExpense);

    return Row(
      children: [
        _StripStat(label: 'Active', value: '$active', color: AppColors.statusActive),
        const SizedBox(width: 12),
        _StripStat(label: 'Done', value: '$completed', color: AppColors.statusDone),
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

  const _StripStat({required this.label, required this.value, required this.color});

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
  final VoidCallback onTap;

  const _ProjectListCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
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
                child: Center(child: Text(project.emoji,
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
                          maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(project.colorValue)),
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
                value: '₹${project.totalIncome.toStringAsFixed(0)}',
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 16),
              _FinanceStat(
                icon: Icons.trending_down_rounded,
                label: 'Expense',
                value: '₹${project.totalExpense.toStringAsFixed(0)}',
                color: AppColors.accentRed,
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
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text('$label: ', style: AppTextStyles.labelSmall),
        Text(value,
            style: AppTextStyles.labelSmall.copyWith(
                color: color, fontWeight: FontWeight.w700)),
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

  final List<String> _emojis = ['📁', '🏗️', '💼', '🚀', '🎯', '⚡', '🔧', '🌟'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('New Project', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              Row(
                children: _emojis.map((e) => GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _selectedEmoji == e
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.surfaceVariant,
                      border: _selectedEmoji == e
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(e,
                        style: const TextStyle(fontSize: 20))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 14),
              Row(children: List.generate(AppColors.workspaceColors.length, (i) {
                final c = AppColors.workspaceColors[i];
                return Padding(padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle,
                        border: _selectedColorIndex == i
                            ? Border.all(color: AppColors.textPrimary, width: 2.5)
                            : null,
                      ),
                    ),
                  ),
                );
              })),
              const SizedBox(height: 14),
              TextField(controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Project Name',
                      prefixIcon: Icon(Icons.folder_rounded, color: AppColors.primary))),
              const SizedBox(height: 12),
              TextField(controller: _descController, maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Description (optional)',
                      prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary))),
              const SizedBox(height: 12),
              TextField(controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Budget (₹)',
                      prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary))),
              const SizedBox(height: 24),
              GradientButton(label: 'Create Project', onTap: () {
                if (_nameController.text.trim().isEmpty) return;
                final workspaceId = widget.ref.read(activeWorkspaceIdProvider);
                if (workspaceId == null) return;
                final project = ProjectModel.create(
                  workspaceId: workspaceId,
                  name: _nameController.text.trim(),
                  description: _descController.text.trim(),
                  emoji: _selectedEmoji,
                  colorValue: AppColors.workspaceColors[_selectedColorIndex].value,
                  budget: double.tryParse(_budgetController.text) ?? 0,
                );
                widget.ref.read(projectsProvider.notifier).addProject(project);
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
