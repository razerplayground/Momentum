import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/providers/employee_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';

class DashboardScreen extends ConsumerWidget {
  /// Callback to switch the bottom-nav tab from within the dashboard.
  /// Index mapping: 0=Home, 1=Projects, 2=Tasks, 3=Notes, 4=Calendar
  final void Function(int index) onTabSwitch;

  const DashboardScreen({super.key, required this.onTabSwitch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(activeWorkspaceProvider);
    final projects = ref.watch(workspaceProjectsProvider);
    final tasks = ref.watch(workspaceTasksProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final employees = ref.watch(workspaceEmployeesProvider);

    if (workspace == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeProjects = projects.where((p) => p.statusStr == 'active').toList();
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/workspaces'),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Color(workspace.colorValue),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(workspace.emoji,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$greeting 👋', style: AppTextStyles.bodySmall),
                              Text(workspace.name, style: AppTextStyles.titleLarge),
                            ],
                          ),
                        ),
                        _IconButton(
                          icon: Icons.search_rounded,
                          onTap: () => _showSearchSheet(context),
                        ),
                        const SizedBox(width: 8),
                        _IconButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () => _showNotificationsSheet(context, todayTasks),
                          badge: todayTasks.isNotEmpty,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(now),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Quick Action Cards ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      label: 'Create\nNew Note',
                      icon: Icons.sticky_note_2_rounded,
                      gradient: AppColors.purpleGradient,
                      // Opens an inline add-note sheet right from the dashboard
                      onTap: () => _showAddNoteSheet(context, ref),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _QuickActionCard(
                      label: 'Create\nNew Task',
                      icon: Icons.task_alt_rounded,
                      gradient: AppColors.goldenGradient,
                      // Opens an inline add-task sheet right from the dashboard
                      onTap: () => _showAddTaskSheet(context, ref),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Workspace Overview ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AnimatedCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Workspace Overview',
                            style: AppTextStyles.titleMedium),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusActive.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Active',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.statusActive,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatItem(
                          value: '${activeProjects.length}',
                          label: 'Projects',
                          color: AppColors.primary,
                          icon: Icons.folder_rounded,
                          onTap: () => onTabSwitch(1),
                        ),
                        _StatItem(
                          value: '${tasks.length}',
                          label: 'Tasks',
                          color: AppColors.accentBlue,
                          icon: Icons.task_alt_rounded,
                          onTap: () => onTabSwitch(2),
                        ),
                        _StatItem(
                          value: '${employees.length}',
                          label: 'Team',
                          color: AppColors.accentGreen,
                          icon: Icons.people_rounded,
                          onTap: () => context.go('/home/employees'),
                        ),
                        _StatItem(
                          value: '$completedTasks',
                          label: 'Done',
                          color: AppColors.accentOrange,
                          icon: Icons.check_circle_rounded,
                          onTap: () => onTabSwitch(2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Quick Access (all wired) ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Access', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _QuickNav(
                        icon: Icons.task_alt_rounded,
                        label: 'Tasks',
                        color: AppColors.accentBlue,
                        bg: AppColors.cardBlue,
                        onTap: () => onTabSwitch(2),
                      ),
                      _QuickNav(
                        icon: Icons.sticky_note_2_rounded,
                        label: 'Notes',
                        color: AppColors.primary,
                        bg: AppColors.cardPurple,
                        onTap: () => onTabSwitch(3),
                      ),
                      _QuickNav(
                        icon: Icons.people_rounded,
                        label: 'Team',
                        color: AppColors.accentPink,
                        bg: AppColors.cardPink,
                        onTap: () => context.go('/home/employees'),
                      ),
                      _QuickNav(
                        icon: Icons.track_changes_rounded,
                        label: 'Follow-ups',
                        color: AppColors.accentOrange,
                        bg: AppColors.cardOrange,
                        onTap: () => context.go('/home/followups'),
                      ),
                      _QuickNav(
                        icon: Icons.checklist_rounded,
                        label: 'To-Do',
                        color: AppColors.accentTeal,
                        bg: AppColors.cardTeal,
                        onTap: () => context.go('/home/todo'),
                      ),
                      _QuickNav(
                        icon: Icons.calendar_month_rounded,
                        label: 'Calendar',
                        color: AppColors.accentGreen,
                        bg: AppColors.cardGreen,
                        onTap: () => onTabSwitch(4),
                      ),
                      _QuickNav(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Finance',
                        color: AppColors.accentGreen,
                        bg: AppColors.cardGreen,
                        // Finance lives inside each project — go to projects list
                        onTap: () => onTabSwitch(1),
                      ),
                      _QuickNav(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        color: AppColors.textSecondary,
                        bg: AppColors.surfaceVariant,
                        onTap: () => _showWorkspaceSettings(context, workspace, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Active Projects ─────────────────────────────────────
          if (activeProjects.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: SectionHeader(
                  title: 'Active Projects',
                  subtitle: '${activeProjects.length} active',
                  actionLabel: 'See All',
                  // "See All" switches to the Projects tab
                  onAction: () => onTabSwitch(1),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _ProjectCard(
                    project: activeProjects[i],
                    // Tapping a project card navigates to its detail screen
                    onTap: () => context.go('/home/projects/${activeProjects[i].id}'),
                  ),
                ),
                childCount: activeProjects.take(3).length,
              ),
            ),
          ],

          // ─── Today's Tasks ────────────────────────────────────────
          if (todayTasks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: SectionHeader(
                  title: "Today's Tasks",
                  subtitle: '${todayTasks.length} due today',
                  actionLabel: 'See All',
                  // "See All" switches to the Tasks tab
                  onAction: () => onTabSwitch(2),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: _TodayTaskTile(
                    task: todayTasks[i],
                    onToggle: () => ref
                        .read(tasksProvider.notifier)
                        .toggleComplete(todayTasks[i].id),
                    onTap: () =>
                        context.go('/home/tasks/${todayTasks[i].id}'),
                  ),
                ),
                childCount: todayTasks.take(3).length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─── Quick Add Sheets (inlined for dashboard use) ──────────────

  void _showAddNoteSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DashboardAddNoteSheet(parentRef: ref),
    );
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DashboardAddTaskSheet(parentRef: ref),
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SearchSheet(),
    );
  }

  void _showNotificationsSheet(BuildContext context, List<TaskModel> todayTasks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NotificationsSheet(todayTasks: todayTasks),
    );
  }

  void _showWorkspaceSettings(BuildContext context, dynamic workspace, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WorkspaceSettingsSheet(workspace: workspace, parentRef: ref),
    );
  }
}

// ─── Icon Button ─────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _IconButton({
    required this.icon, required this.onTap, this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          if (badge)
            Positioned(
              right: 2, top: 2,
              child: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accentRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label, required this.icon,
    required this.gradient, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10, bottom: -10,
              child: Icon(Icons.auto_awesome_rounded,
                  size: 70, color: Colors.white.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  Text(label,
                      style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Item (now tappable) ─────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatItem({
    required this.value, required this.label,
    required this.color, required this.icon, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: AppTextStyles.headlineSmall.copyWith(color: color)),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Nav Grid Item ─────────────────────────────────────────────────────

class _QuickNav extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _QuickNav({
    required this.icon, required this.label,
    required this.color, required this.bg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Active Project Card (now tappable) ──────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final dynamic project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

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
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Color(project.colorValue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(project.emoji,
                    style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: AppTextStyles.titleMedium),
                    Text('${project.completedTasks}/${project.totalTasks} tasks',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              StatusChip(status: project.statusStr),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.progress,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(Color(project.colorValue)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(project.progress * 100).toInt()}% complete',
                  style: AppTextStyles.labelSmall),
              if (project.dueDate != null)
                Text(
                  'Due ${DateFormat('dd MMM').format(project.dueDate!)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: project.dueDate!.isBefore(DateTime.now())
                        ? AppColors.accentRed
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Today Task Tile (now tappable + checkbox working) ───────────────────────

class _TodayTaskTile extends StatelessWidget {
  final dynamic task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TodayTaskTile({
    required this.task, required this.onToggle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Wired checkbox
          GestureDetector(
            onTap: onToggle,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                if (task.description.isNotEmpty)
                  Text(task.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          PriorityChip(priority: task.priorityStr, compact: true),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }
}

// ─── Dashboard Quick-Add Note Sheet ─────────────────────────────────────────

class _DashboardAddNoteSheet extends StatefulWidget {
  final WidgetRef parentRef;
  const _DashboardAddNoteSheet({required this.parentRef});

  @override
  State<_DashboardAddNoteSheet> createState() => _DashboardAddNoteSheetState();
}

class _DashboardAddNoteSheetState extends State<_DashboardAddNoteSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  int _colorIndex = 0;

  final List<Color> _colors = [
    AppColors.cardPurple, AppColors.cardBlue, AppColors.cardOrange,
    AppColors.cardPink, AppColors.cardGreen, AppColors.cardTeal,
  ];

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
            Text('New Note', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 14),
            Row(children: _colors.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: entry.value, shape: BoxShape.circle,
                    border: _colorIndex == entry.key
                        ? Border.all(color: AppColors.primary, width: 2.5)
                        : null,
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            TextField(controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'Title',
                    prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            TextField(controller: _contentCtrl, maxLines: 3,
                decoration: const InputDecoration(hintText: 'Write your note...',
                    prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary))),
            const SizedBox(height: 24),
            GradientButton(label: 'Save Note', onTap: () {
              if (_titleCtrl.text.trim().isEmpty) return;
              final wsId = widget.parentRef.read(activeWorkspaceIdProvider);
              if (wsId == null) return;
              final note = NoteModel.create(
                workspaceId: wsId,
                title: _titleCtrl.text.trim(),
                content: _contentCtrl.text.trim(),
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

// ─── Dashboard Quick-Add Task Sheet ─────────────────────────────────────────

class _DashboardAddTaskSheet extends StatefulWidget {
  final WidgetRef parentRef;
  const _DashboardAddTaskSheet({required this.parentRef});

  @override
  State<_DashboardAddTaskSheet> createState() => _DashboardAddTaskSheetState();
}

class _DashboardAddTaskSheetState extends State<_DashboardAddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';

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
            TextField(controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'Task Title',
                    prefixIcon: Icon(Icons.task_alt_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, maxLines: 2,
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
              if (_titleCtrl.text.trim().isEmpty) return;
              final wsId = widget.parentRef.read(activeWorkspaceIdProvider);
              if (wsId == null) return;
              final task = TaskModel.create(
                workspaceId: wsId,
                title: _titleCtrl.text.trim(),
                description: _descCtrl.text.trim(),
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

// ─── Search Sheet ─────────────────────────────────────────────────────────────

class _SearchSheet extends StatelessWidget {
  const _SearchSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search tasks, projects, notes...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.manage_search_rounded,
                    size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Start typing to search',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ─── Notifications Sheet ──────────────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  final List<TaskModel> todayTasks;

  const _NotificationsSheet({required this.todayTasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Notifications', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 20),
          Expanded(
            child: todayTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: AppColors.textTertiary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('All caught up!',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: todayTasks.length,
                    itemBuilder: (context, i) {
                      final task = todayTasks[i];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.task_alt_rounded,
                              color: AppColors.accentBlue, size: 20),
                        ),
                        title: Text('Task due today', style: AppTextStyles.labelSmall),
                        subtitle: Text(task.title, style: AppTextStyles.bodyMedium),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/home/tasks/${task.id}');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Workspace Settings Sheet ─────────────────────────────────────────────────

class _WorkspaceSettingsSheet extends StatefulWidget {
  final dynamic workspace;
  final WidgetRef parentRef;

  const _WorkspaceSettingsSheet({required this.workspace, required this.parentRef});

  @override
  State<_WorkspaceSettingsSheet> createState() => _WorkspaceSettingsSheetState();
}

class _WorkspaceSettingsSheetState extends State<_WorkspaceSettingsSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late String _selectedEmoji;
  late int _selectedColorIndex;
  late String _selectedIndustry;

  final List<String> _emojis = ['🏢', '🏗️', '🛒', '💻', '🏥', '🍕', '🎓', '✈️', '🏦', '🎨'];
  final List<String> _industries = [
    'General', 'Construction', 'Technology', 'Retail',
    'Healthcare', 'Food & Beverage', 'Education', 'Finance', 'Real Estate',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.workspace.name);
    _descCtrl = TextEditingController(text: widget.workspace.description);
    _selectedEmoji = widget.workspace.emoji;
    _selectedIndustry = widget.workspace.industry;
    _selectedColorIndex = AppColors.workspaceColors.indexWhere(
      (c) => c.value == widget.workspace.colorValue,
    );
    if (_selectedColorIndex == -1) _selectedColorIndex = 0;
  }

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
              Text('Workspace Settings', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 20),
              
              Text('Icon', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojis.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = _emojis[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: _selectedEmoji == _emojis[i]
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.surfaceVariant,
                        border: _selectedEmoji == _emojis[i]
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(_emojis[i],
                          style: const TextStyle(fontSize: 24))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text('Color Theme', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              Row(
                children: List.generate(AppColors.workspaceColors.length, (i) {
                  final c = AppColors.workspaceColors[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: c, shape: BoxShape.circle,
                          border: _selectedColorIndex == i
                              ? Border.all(color: AppColors.textPrimary, width: 2.5)
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Workspace Name',
                  prefixIcon: Icon(Icons.business_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedIndustry,
                decoration: const InputDecoration(
                  hintText: 'Industry',
                  prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary),
                ),
                items: _industries
                    .map((ind) => DropdownMenuItem(value: ind, child: Text(ind)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedIndustry = val ?? 'General'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Description',
                  prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              
              GradientButton(
                label: 'Save Settings',
                onTap: () {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  final updated = widget.workspace.copyWith(
                    name: _nameCtrl.text.trim(),
                    description: _descCtrl.text.trim(),
                    emoji: _selectedEmoji,
                    colorValue: AppColors.workspaceColors[_selectedColorIndex].value,
                    industry: _selectedIndustry,
                    updatedAt: DateTime.now(),
                  );
                  widget.parentRef.read(workspacesProvider.notifier).updateWorkspace(updated);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
