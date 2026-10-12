import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/followup_model.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../dashboard/dashboard_navigation_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';

class FollowupsScreen extends ConsumerWidget {
  final String? projectId;

  const FollowupsScreen({super.key, this.projectId});

  void _openAddFollowup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFollowupScreen(projectId: projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followups = projectId != null
        ? ref.watch(projectFollowupsProvider(projectId!))
        : ref.watch(workspaceFollowupsProvider);

    final pending = followups.where((f) => f.statusStr == 'pending').length;
    final done = followups.where((f) => f.statusStr == 'done').length;
    final overdue = followups.where((f) => f.statusStr == 'overdue').length;
    final showProjectBackButton = projectId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: projectId != null
          ? null
          : AppBar(
              title: const Text('Follow-ups'),
              leading: IconButton(
                onPressed: () {
                  ref.read(dashboardTabIndexProvider.notifier).state = 0;
                  context.go('/home');
                },
                icon: const Icon(Icons.arrow_back_ios_rounded),
              ),
            ),
      body: CustomScrollView(
        slivers: [
          if (showProjectBackButton)
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(dashboardTabIndexProvider.notifier).state =
                              0;
                          context.go('/home');
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Follow-ups', style: AppTextStyles.displaySmall),
                    ],
                  ),
                ),
              ),
            ),
          if (projectId == null)
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Follow-ups', style: AppTextStyles.displaySmall),
                      Text('$pending pending • $done done • $overdue overdue',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 16),
                      // Filter strip
                      _FollowupStats(
                          pending: pending, done: done, overdue: overdue),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          if (followups.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.track_changes_outlined,
                title: 'No Follow-ups',
                subtitle: 'Add follow-up reminders for your projects and tasks.',
                actionLabel: 'Add Follow-up',
                onAction: () => _openAddFollowup(context),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _FollowupCard(followup: followups[i], ref: ref),
                ),
                childCount: followups.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddFollowup(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _FollowupStats extends StatelessWidget {
  final int pending;
  final int done;
  final int overdue;

  const _FollowupStats(
      {required this.pending, required this.done, required this.overdue});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBadge(
            label: 'Pending', count: pending, color: AppColors.statusPending),
        const SizedBox(width: 10),
        _StatBadge(label: 'Done', count: done, color: AppColors.statusDone),
        const SizedBox(width: 10),
        _StatBadge(
            label: 'Overdue', count: overdue, color: AppColors.statusOverdue),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count $label',
              style: AppTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _FollowupCard extends StatelessWidget {
  final FollowupModel followup;
  final WidgetRef ref;

  const _FollowupCard({required this.followup, required this.ref});

  IconData get _typeIcon {
    switch (followup.typeStr) {
      case 'call':
        return Icons.phone_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'meeting':
        return Icons.people_rounded;
      case 'visit':
        return Icons.location_on_rounded;
      case 'message':
        return Icons.message_rounded;
      default:
        return Icons.track_changes_rounded;
    }
  }

  bool get _isOverdue {
    return followup.statusStr != 'done' &&
        followup.dueDate.isBefore(DateTime.now());
  }

  Color get _statusColor {
    if (_isOverdue) {
      return AppColors.statusOverdue;
    }

    switch (followup.statusStr) {
      case 'done':
        return AppColors.statusDone;
      default:
        return AppColors.statusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(followup.title, style: AppTextStyles.titleMedium),
                if (followup.description.isNotEmpty)
                  Text(followup.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM yyyy').format(followup.dueDate),
                        style: AppTextStyles.labelSmall),
                    const Spacer(),
                    StatusChip(status: followup.statusStr),
                  ],
                ),
              ],
            ),
          ),
          if (followup.statusStr == 'pending')
            GestureDetector(
              onTap: () => ref
                  .read(followupsProvider.notifier)
                  .markDone(followup.id, null),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-screen "Add Follow-up" page.
/// Opened from the FAB and from the "Add Follow-up" button in the empty state.
class AddFollowupScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const AddFollowupScreen({super.key, this.projectId});

  @override
  ConsumerState<AddFollowupScreen> createState() => _AddFollowupScreenState();
}

class _AddFollowupScreenState extends ConsumerState<AddFollowupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'call';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  final List<String> _types = [
    'call',
    'email',
    'meeting',
    'visit',
    'message',
    'other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _dueDate = d);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a workspace before saving.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final followup = FollowupModel.create(
        workspaceId: workspaceId,
        title: _titleController.text.trim(),
        dueDate: _dueDate,
        description: _descController.text.trim(),
        type: _type,
        projectId: widget.projectId,
      );
      await ref.read(followupsProvider.notifier).add(followup);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Follow-up created successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Unable to create follow-up: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppColors.textPrimary),
        ),
        title: Text('New Follow-up', style: AppTextStyles.headlineSmall),
        centerTitle: false,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Follow-up Title',
                      prefixIcon: Icon(Icons.track_changes_rounded,
                          color: AppColors.primary),
                    ),
                    validator: (value) {
                      final title = (value ?? '').trim();
                      if (title.isEmpty) {
                        return 'Follow-up title is required.';
                      }
                      if (title.length > 20) {
                        return 'Follow-up title must be 20 characters or less.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Notes (optional)',
                      prefixIcon:
                          Icon(Icons.notes_rounded, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(
                      hintText: 'Type',
                      prefixIcon: Icon(Icons.category_rounded,
                          color: AppColors.primary),
                    ),
                    items: _types
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.toUpperCase())))
                        .toList(),
                    onChanged: (val) => setState(() => _type = val ?? 'call'),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
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
                          Text(DateFormat('dd MMM yyyy').format(_dueDate),
                              style: AppTextStyles.titleMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: _isSaving ? 'Saving...' : 'Add Follow-up',
                    onTap: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}