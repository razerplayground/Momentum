import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/followup_model.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';

class FollowupsScreen extends ConsumerWidget {
  final String? projectId;

  const FollowupsScreen({super.key, this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followups = projectId != null
        ? ref.watch(projectFollowupsProvider(projectId!))
        : ref.watch(workspaceFollowupsProvider);

    final pending = followups.where((f) => f.statusStr == 'pending').length;
    final done = followups.where((f) => f.statusStr == 'done').length;
    final overdue = followups.where((f) => f.statusStr == 'overdue').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: projectId != null
          ? null
          : AppBar(title: const Text('Follow-ups')),
      body: CustomScrollView(
        slivers: [
          if (projectId == null) SliverToBoxAdapter(
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
                    _FollowupStats(pending: pending, done: done, overdue: overdue),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          if (followups.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.track_changes_outlined,
                title: 'No Follow-ups',
                subtitle: 'Add follow-up reminders for your projects and tasks.',
                actionLabel: 'Add Follow-up',
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
        onPressed: () => _showAddFollowup(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddFollowup(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddFollowupSheet(parentRef: ref, projectId: projectId),
    );
  }
}

class _FollowupStats extends StatelessWidget {
  final int pending;
  final int done;
  final int overdue;

  const _FollowupStats({required this.pending, required this.done, required this.overdue});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBadge(label: 'Pending', count: pending, color: AppColors.statusPending),
        const SizedBox(width: 10),
        _StatBadge(label: 'Done', count: done, color: AppColors.statusDone),
        const SizedBox(width: 10),
        _StatBadge(label: 'Overdue', count: overdue, color: AppColors.statusOverdue),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({required this.label, required this.count, required this.color});

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
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count $label', style: AppTextStyles.labelMedium.copyWith(color: color)),
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
      case 'call': return Icons.phone_rounded;
      case 'email': return Icons.email_rounded;
      case 'meeting': return Icons.people_rounded;
      case 'visit': return Icons.location_on_rounded;
      case 'message': return Icons.message_rounded;
      default: return Icons.track_changes_rounded;
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
            width: 42, height: 42,
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
                  Text(followup.description, style: AppTextStyles.bodySmall,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12,
                        color: AppColors.textSecondary),
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
              onTap: () => ref.read(followupsProvider.notifier).markDone(followup.id, null),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Done',
                    style: TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      
    );
  }
}

class _AddFollowupSheet extends StatefulWidget {
  final WidgetRef parentRef;
  final String? projectId;

  const _AddFollowupSheet({required this.parentRef, this.projectId});

  @override
  State<_AddFollowupSheet> createState() => _AddFollowupSheetState();
}

class _AddFollowupSheetState extends State<_AddFollowupSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'call';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

  final List<String> _types = ['call', 'email', 'meeting', 'visit', 'message', 'other'];

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
            Text('New Follow-up', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: _titleController,
                decoration: const InputDecoration(hintText: 'Follow-up Title',
                    prefixIcon: Icon(Icons.track_changes_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            TextField(controller: _descController, maxLines: 2,
                decoration: const InputDecoration(hintText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(hintText: 'Type',
                  prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary)),
              items: _types.map((t) =>
                  DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => _type = val ?? 'call'),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _dueDate = d);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd MMM yyyy').format(_dueDate),
                        style: AppTextStyles.titleMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(label: 'Add Follow-up', onTap: () {
              if (_titleController.text.trim().isEmpty) return;
              final workspaceId = widget.parentRef.read(activeWorkspaceIdProvider);
              if (workspaceId == null) return;
              final followup = FollowupModel.create(
                workspaceId: workspaceId,
                title: _titleController.text.trim(),
                dueDate: _dueDate,
                description: _descController.text.trim(),
                type: _type,
                projectId: widget.projectId,
              );
              widget.parentRef.read(followupsProvider.notifier).add(followup);
              Navigator.pop(context);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
