import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/workspace_model.dart';
import '../../../data/providers/job_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsValue = ref.watch(jobsProvider);
    final workspaces = ref.watch(workspacesProvider);
    final activeWorkspaceId = ref.watch(activeWorkspaceProvider)?.id;
    final globalView = ref.watch(globalViewEnabledProvider);
    final visibleJobs = jobsValue.valueOrNull?.where((job) {
      return globalView ||
          activeWorkspaceId == null ||
          job.businessId == activeWorkspaceId;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jobs'),
        actions: [
          IconButton(
            tooltip: 'Refresh jobs',
            onPressed: jobsValue.isLoading
                ? null
                : () => ref.read(jobsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: jobsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load jobs: $error',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.read(jobsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (_) {
          if (visibleJobs!.isEmpty) {
            return EmptyState(
              icon: Icons.work_outline_rounded,
              title: 'No Jobs Yet',
              subtitle: 'Add a job to this business to get started.',
              actionLabel: workspaces.isEmpty ? null : 'Add Job',
              onAction: workspaces.isEmpty
                  ? null
                  : () => _showJobEditor(
                        context,
                        ref,
                        workspaces: workspaces,
                        initialBusinessId: _initialBusinessId(
                          workspaces,
                          activeWorkspaceId,
                        ),
                      ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${visibleJobs.length} ${visibleJobs.length == 1 ? 'job' : 'jobs'}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              ...visibleJobs.map(
                (job) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _JobCard(
                    job: job,
                    businessName: workspaces
                        .where((workspace) => workspace.id == job.businessId)
                        .map((workspace) => workspace.name)
                        .firstOrNull,
                    onEdit: () => _showJobEditor(
                      context,
                      ref,
                      workspaces: workspaces,
                      job: job,
                    ),
                    onDelete: () => _confirmDelete(context, ref, job),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: workspaces.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _showJobEditor(
                context,
                ref,
                workspaces: workspaces,
                initialBusinessId: _initialBusinessId(
                  workspaces,
                  activeWorkspaceId,
                ),
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
    );
  }

  String _initialBusinessId(
    List<WorkspaceModel> workspaces,
    String? activeWorkspaceId,
  ) {
    if (activeWorkspaceId != null &&
        workspaces.any((workspace) => workspace.id == activeWorkspaceId)) {
      return activeWorkspaceId;
    }
    return workspaces.first.id;
  }

  Future<void> _showJobEditor(
    BuildContext context,
    WidgetRef ref, {
    required List<WorkspaceModel> workspaces,
    String? initialBusinessId,
    JobModel? job,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _JobEditorSheet(
        workspaces: workspaces,
        initialBusinessId:
            job?.businessId ?? initialBusinessId ?? workspaces.first.id,
        job: job,
        onSave: (businessId, title, department, status) async {
          if (job == null) {
            await ref.read(jobsProvider.notifier).addJob(
                  businessId: businessId,
                  title: title,
                  department: department,
                  status: status,
                );
          } else {
            await ref.read(jobsProvider.notifier).updateJob(
                  job,
                  title: title,
                  department: department,
                  status: status,
                );
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, JobModel job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text('Delete "${job.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(jobsProvider.notifier).deleteJob(job);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job deleted')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete job: $error')),
        );
      }
    }
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final String? businessName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JobCard({
    required this.job,
    required this.businessName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.work_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: AppTextStyles.titleMedium),
                if (job.department.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(job.department, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 6),
                Text(
                  '${job.status.replaceAll('_', ' ')}${businessName == null ? '' : ' · $businessName'}',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit job',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete job',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.accentRed),
          ),
        ],
      ),
    );
  }
}

class _JobEditorSheet extends StatefulWidget {
  final List<WorkspaceModel> workspaces;
  final String initialBusinessId;
  final JobModel? job;
  final Future<void> Function(
    String businessId,
    String title,
    String department,
    String status,
  ) onSave;

  const _JobEditorSheet({
    required this.workspaces,
    required this.initialBusinessId,
    required this.job,
    required this.onSave,
  });

  @override
  State<_JobEditorSheet> createState() => _JobEditorSheetState();
}

class _JobEditorSheetState extends State<_JobEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _departmentController;
  late String _businessId;
  late String _status;
  bool _saving = false;

  static const _statuses = ['open', 'closed'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.job?.title ?? '');
    _departmentController =
        TextEditingController(text: widget.job?.department ?? '');
    _businessId = widget.initialBusinessId;
    final existingStatus = widget.job?.status ?? 'open';
    _status = _statuses.contains(existingStatus) ? existingStatus : 'open';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.job == null ? 'Add Job' : 'Edit Job',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _businessId,
                decoration: const InputDecoration(labelText: 'Business'),
                items: widget.workspaces
                    .map((workspace) => DropdownMenuItem(
                          value: workspace.id,
                          child: Text(workspace.name),
                        ))
                    .toList(),
                onChanged: widget.job == null
                    ? (value) {
                        if (value != null) setState(() => _businessId = value);
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Job title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.replaceAll('_', ' ')),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save Job'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job title is required')),
      );
      return;
    }
    final department = _departmentController.text.trim();
    if (department.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department is required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        _businessId,
        title,
        department,
        _status,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save job: $error')),
        );
      }
    }
  }
}
