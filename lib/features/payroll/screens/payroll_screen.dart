import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/providers/employee_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../data/services/api_service.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  String? _businessId;
  String? _requestedBusinessId;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _entries = [];
  Map<String, dynamic> _summary = {};

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final businessId =
        workspaces.any((workspace) => workspace.id == _businessId)
            ? _businessId!
            : activeWorkspace?.id ??
                (workspaces.isNotEmpty ? workspaces.first.id : null);

    if (businessId != null && _requestedBusinessId != businessId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _requestedBusinessId != businessId) {
          _loadPayroll(businessId);
        }
      });
    }

    final employees = ref
        .watch(employeesProvider)
        .where((employee) =>
            employee.workspaceId == businessId &&
            employee.statusStr.toLowerCase() == 'active')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payroll'),
        actions: [
          IconButton(
            tooltip: 'Refresh payroll',
            onPressed: businessId == null || _loading
                ? null
                : () => _loadPayroll(businessId),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: businessId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _loading || employees.isEmpty
                  ? null
                  : () => _showRunPayrollDialog(
                        businessId,
                        employees,
                      ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Run payroll'),
            ),
      body: workspaces.isEmpty
          ? const Center(child: Text('Create a workspace to manage payroll.'))
          : RefreshIndicator(
              onRefresh: businessId == null
                  ? () async {}
                  : () => _loadPayroll(businessId),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: businessId,
                    decoration: const InputDecoration(
                      labelText: 'Workspace',
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
                    onChanged: _loading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _businessId = value);
                            _loadPayroll(value);
                          },
                  ),
                  const SizedBox(height: 16),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Could not load payroll: $_error'),
                            TextButton(
                              onPressed: () => _loadPayroll(businessId!),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _PayrollSummaryCard(summary: _summary),
                  const SizedBox(height: 24),
                  Text('Payroll entries', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  if (!_loading && _error == null && _entries.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No payroll entries for this workspace.'),
                      ),
                    ),
                  ..._entries.map(
                    (entry) => _PayrollEntryCard(
                      entry: entry,
                      onMarkPaid: () => _updateEntryStatus(
                        businessId!,
                        entry,
                        'paid',
                      ),
                      onDelete: () => _deleteEntry(businessId!, entry),
                    ),
                  ),
                  if (employees.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Add active employees before running payroll.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _loadPayroll(String businessId) async {
    setState(() {
      _businessId = businessId;
      _requestedBusinessId = businessId;
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final results = await Future.wait([
        api.getPayroll(businessId),
        api.getPayrollSummary(businessId),
      ]);
      if (!mounted || _businessId != businessId) return;
      setState(() {
        _entries = results[0] as List<Map<String, dynamic>>;
        _summary = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || _businessId != businessId) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _showRunPayrollDialog(
    String businessId,
    List<EmployeeModel> employees,
  ) async {
    final request = await showDialog<_PayrollRunRequest>(
      context: context,
      builder: (context) => _RunPayrollDialog(employees: employees),
    );
    if (request == null || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(apiServiceProvider).runPayroll(businessId, {
        'period': request.period,
        'employeeIds': request.employeeIds,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payroll run successfully')),
      );
      await _loadPayroll(businessId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not run payroll: $error')),
      );
    }
  }

  Future<void> _updateEntryStatus(
    String businessId,
    Map<String, dynamic> entry,
    String status,
  ) async {
    final id = _entryId(entry);
    if (id == null) {
      _showMessage('This payroll entry has no ID and cannot be updated.');
      return;
    }
    try {
      await ref
          .read(apiServiceProvider)
          .updatePayrollEntry(businessId, id, {'status': status});
      await _loadPayroll(businessId);
    } catch (error) {
      _showMessage('Could not update payroll entry: $error');
    }
  }

  Future<void> _deleteEntry(
    String businessId,
    Map<String, dynamic> entry,
  ) async {
    final id = _entryId(entry);
    if (id == null) {
      _showMessage('This payroll entry has no ID and cannot be deleted.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete payroll entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiServiceProvider).deletePayrollEntry(businessId, id);
      await _loadPayroll(businessId);
    } catch (error) {
      _showMessage('Could not delete payroll entry: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PayrollSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _PayrollSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = _firstValue(summary, [
      'totalPayroll',
      'totalAmount',
      'total',
      'amount',
    ]);
    final employees = _firstValue(summary, [
      'employeeCount',
      'totalEmployees',
      'count',
    ]);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.cardPurple,
              child: Icon(Icons.payments_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payroll summary', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${employees ?? 0} employees',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                  .format(_asNumber(total)),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayrollEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onMarkPaid;
  final VoidCallback onDelete;

  const _PayrollEntryCard({
    required this.entry,
    required this.onMarkPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final person = entry['employee'];
    final employeeName = person is Map
        ? (person['name'] ?? person['fullName'])?.toString()
        : null;
    final name = entry['employeeName']?.toString() ??
        employeeName ??
        entry['name']?.toString() ??
        'Payroll entry';
    final amount = _firstValue(entry, ['amount', 'netPay', 'salary', 'total']);
    final period =
        entry['period'] ?? entry['payPeriod'] ?? entry['month'] ?? '';
    final status = entry['status']?.toString() ?? 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.cardGreen,
          child: Icon(Icons.person_rounded, color: AppColors.accentGreen),
        ),
        title: Text(name, style: AppTextStyles.titleMedium),
        subtitle: Text(
          [
            if (period.toString().isNotEmpty) period.toString(),
            status,
          ].join(' • '),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'paid') onMarkPaid();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            if (status.toLowerCase() != 'paid')
              const PopupMenuItem(
                value: 'paid',
                child: Text('Mark as paid'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete entry'),
            ),
          ],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                    .format(_asNumber(amount)),
                style: AppTextStyles.titleMedium,
              ),
              const Icon(Icons.more_horiz_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunPayrollDialog extends StatefulWidget {
  final List<EmployeeModel> employees;

  const _RunPayrollDialog({required this.employees});

  @override
  State<_RunPayrollDialog> createState() => _RunPayrollDialogState();
}

class _RunPayrollDialogState extends State<_RunPayrollDialog> {
  late final TextEditingController _periodController;
  late final Set<String> _selectedEmployees;

  @override
  void initState() {
    super.initState();
    _periodController = TextEditingController(
        text: DateFormat('yyyy-MM').format(DateTime.now()));
    _selectedEmployees =
        widget.employees.map((employee) => employee.id).toSet();
  }

  @override
  void dispose() {
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Run payroll'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _periodController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Pay period',
                  hintText: 'YYYY-MM',
                ),
              ),
              const SizedBox(height: 12),
              Text('Employees', style: AppTextStyles.titleMedium),
              ...widget.employees.map(
                (employee) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedEmployees.contains(employee.id),
                  title: Text(employee.name),
                  subtitle: Text(
                    NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                        .format(employee.salary),
                  ),
                  onChanged: (selected) {
                    setState(() {
                      if (selected ?? false) {
                        _selectedEmployees.add(employee.id);
                      } else {
                        _selectedEmployees.remove(employee.id);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit
              ? () => Navigator.pop(
                    context,
                    _PayrollRunRequest(
                      period: _periodController.text.trim(),
                      employeeIds: _selectedEmployees.toList(),
                    ),
                  )
              : null,
          child: const Text('Run payroll'),
        ),
      ],
    );
  }

  bool get _canSubmit =>
      RegExp(r'^\d{4}-(0[1-9]|1[0-2])$')
          .hasMatch(_periodController.text.trim()) &&
      _selectedEmployees.isNotEmpty;
}

class _PayrollRunRequest {
  final String period;
  final List<String> employeeIds;

  const _PayrollRunRequest({
    required this.period,
    required this.employeeIds,
  });
}

String? _entryId(Map<String, dynamic> entry) {
  final value = entry['id'] ?? entry['_id'] ?? entry['entryId'];
  if (value == null || value.toString().isEmpty) return null;
  return value.toString();
}

dynamic _firstValue(Map<String, dynamic> values, List<String> keys) {
  for (final key in keys) {
    if (values[key] != null) return values[key];
  }
  return null;
}

num _asNumber(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
