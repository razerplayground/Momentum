import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/providers/employee_provider.dart';
import '../../../shared/widgets/avatar_stack.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  bool _isDeleting = false;
  bool _isUpdating = false;
  bool _employeeDeleted = false;

  @override
  Widget build(BuildContext context) {
    if (_employeeDeleted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Employee Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.accentGreen, size: 56),
              SizedBox(height: 16),
              Text('Employee deleted'),
            ],
          ),
        ),
      );
    }

    final employee = ref
        .watch(workspaceEmployeesProvider)
        .where((e) => e.id == widget.employeeId)
        .firstOrNull;

    if (employee == null) {
      return const Scaffold(body: Center(child: Text('Employee not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Employee Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit employee',
            icon: _isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_rounded),
            onPressed: _isUpdating || _isDeleting
                ? null
                : () => _showEditEmployee(employee),
          ),
          IconButton(
            tooltip: 'Delete employee',
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            onPressed: _isDeleting ? null : () => _confirmDelete(employee),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(employee.avatarColorValue),
                    Color(employee.avatarColorValue).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  EmployeeAvatar(
                    name: employee.name,
                    colorValue: employee.avatarColorValue,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(employee.name,
                      style: AppTextStyles.displaySmall
                          .copyWith(color: Colors.white)),
                  Text(employee.roleStr.toUpperCase(),
                      style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white70, fontWeight: FontWeight.w600)),
                  Text(employee.department,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white60)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(items: [
                    _InfoItem(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        value: employee.email),
                    _InfoItem(
                        icon: Icons.business_rounded,
                        label: 'Department',
                        value: employee.department),
                    _InfoItem(
                        icon: Icons.badge_rounded,
                        label: 'Status',
                        value: employee.statusStr == 'onLeave'
                            ? 'On Leave'
                            : employee.statusStr),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditEmployee(EmployeeModel employee) async {
    final updated = await showModalBottomSheet<EmployeeModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditEmployeeSheet(employee: employee),
    );
    if (updated == null || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      await ref.read(employeesProvider.notifier).updateEmployee(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee updated.')),
        );
      }
    } catch (error) {
      _handleEmployeeActionError(error, action: 'update');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _confirmDelete(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete employee?'),
        content: Text('This will permanently delete ${employee.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.statusPaused),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(employeesProvider.notifier).deleteEmployee(employee.id);
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _employeeDeleted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee deleted.')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
      _handleEmployeeActionError(error, action: 'delete');
    }
  }

  void _handleEmployeeActionError(
    Object error, {
    required String action,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not $action employee: $error')),
    );
  }
}

class _EditEmployeeSheet extends StatefulWidget {
  final EmployeeModel employee;

  const _EditEmployeeSheet({required this.employee});

  @override
  State<_EditEmployeeSheet> createState() => _EditEmployeeSheetState();
}

class _EditEmployeeSheetState extends State<_EditEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _departmentController;
  late final TextEditingController _salaryController;
  late String _status;

  final List<String> _statuses = ['active', 'busy', 'onLeave'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.employee.roleStr);
    _departmentController =
        TextEditingController(text: widget.employee.department);
    _salaryController =
        TextEditingController(text: widget.employee.salary.toString());
    _status = _statuses.contains(widget.employee.statusStr)
        ? widget.employee.statusStr
        : 'active';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _departmentController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Employee', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Job title is required'
                    : null,
                decoration: const InputDecoration(labelText: 'Job Title'),
              ),
              TextFormField(
                controller: _departmentController,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Department is required'
                    : null,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              TextFormField(
                controller: _salaryController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    double.tryParse((value ?? '').trim()) == null
                        ? 'Enter a valid salary'
                        : null,
                decoration: const InputDecoration(labelText: 'Salary'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status == 'onLeave'
                              ? 'ON LEAVE'
                              : status.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _status = value ?? 'active'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(
                      context,
                      EmployeeModel(
                        id: widget.employee.id,
                        workspaceId: widget.employee.workspaceId,
                        name: widget.employee.name,
                        email: widget.employee.email,
                        phone: widget.employee.phone,
                        roleStr: _titleController.text.trim(),
                        statusStr: _status,
                        department: _departmentController.text.trim(),
                        joinedAt: widget.employee.joinedAt,
                        createdAt: widget.employee.createdAt,
                        avatarUrl: widget.employee.avatarUrl,
                        salary: double.parse(_salaryController.text.trim()),
                        projectIds: widget.employee.projectIds,
                        notes: widget.employee.notes,
                        avatarColorValue: widget.employee.avatarColorValue,
                      ),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(item.icon, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: AppTextStyles.labelSmall),
                        Text(item.value.isEmpty ? 'Not provided' : item.value,
                            style: AppTextStyles.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, color: AppColors.borderLight),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem(
      {required this.icon, required this.label, required this.value});
}
