import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/providers/employee_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/avatar_stack.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(workspaceEmployeesProvider);
    final active = employees.where((e) => e.statusStr == 'active').length;

    final query = _searchQuery.trim().toLowerCase();
    final filteredEmployees = query.isEmpty
        ? employees
        : employees.where((e) {
            return e.name.toLowerCase().contains(query) ||
                e.email.toLowerCase().contains(query) ||
                e.roleStr.toLowerCase().contains(query) ||
                e.department.toLowerCase().contains(query);
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
                    Text('Team', style: AppTextStyles.displaySmall),
                    Text('$active active employees',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 16),
                    // Stats
                    Row(
                      children: [
                        _EmpStatCard(
                            label: 'Total',
                            value: '${employees.length}',
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        _EmpStatCard(
                            label: 'Active',
                            value: '$active',
                            color: AppColors.accentGreen),
                        const SizedBox(width: 12),
                        _EmpStatCard(
                          label: 'On Leave',
                          value:
                              '${employees.where((e) => e.statusStr == 'onLeave').length}',
                          color: AppColors.accentOrange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search employees...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.primary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.primary.withOpacity(0.06),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          if (employees.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No Employees',
                subtitle: 'Add your team members to track and assign work.',
                actionLabel: 'Add Employee',
              ),
            )
          else if (filteredEmployees.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No Results',
                subtitle: 'No employees match your search.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _EmployeeCard(
                    employee: filteredEmployees[i],
                    onTap: () => context
                        .go('/home/employees/${filteredEmployees[i].id}'),
                  ),
                ),
                childCount: filteredEmployees.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEmployee(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddEmployee(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddEmployeeSheet(parentRef: ref),
    );
  }
}

class _EmpStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _EmpStatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.headlineSmall
                    .copyWith(color: color, fontWeight: FontWeight.w800)),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = employee.statusStr == 'active'
        ? AppColors.statusActive
        : employee.statusStr == 'onLeave'
            ? AppColors.statusPending
            : AppColors.statusPaused;

    return AnimatedCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          EmployeeAvatar(
            name: employee.name,
            colorValue: employee.avatarColorValue,
            size: 52,
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: AppTextStyles.titleLarge),
                Text(employee.roleStr.toUpperCase(),
                    style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
                Text(employee.department, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                        employee.statusStr == 'onLeave'
                            ? 'On Leave'
                            : employee.statusStr,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(employee.email,
                  style: AppTextStyles.labelSmall,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddEmployeeSheet extends StatefulWidget {
  final WidgetRef parentRef;

  const _AddEmployeeSheet({required this.parentRef});

  @override
  State<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<_AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deptController = TextEditingController(text: 'General');
  String _role = 'other';
  int _colorIndex = 0;

  final List<String> _roles = [
    'manager',
    'developer',
    'designer',
    'sales',
    'hr',
    'accountant',
    'other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                Text('Add Employee', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 14),
                // Color for avatar
                Row(
                    children: AppColors.workspaceColors
                        .take(6)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
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
                            ? Border.all(
                                color: AppColors.textPrimary, width: 2.5)
                            : null,
                      ),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Full name is required'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon:
                        Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(email)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon:
                        Icon(Icons.email_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Phone is required' : null,
                  decoration: const InputDecoration(
                    labelText: 'Phone *',
                    prefixIcon:
                        Icon(Icons.phone_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deptController,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Department is required'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Department *',
                    prefixIcon:
                        Icon(Icons.business_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                      labelText: 'Role *',
                      prefixIcon:
                          Icon(Icons.work_rounded, color: AppColors.primary)),
                  items: _roles
                      .map((r) => DropdownMenuItem(
                          value: r, child: Text(r.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => _role = val ?? 'other'),
                ),
                const SizedBox(height: 24),
                GradientButton(
                    label: 'Add Employee',
                    onTap: () {
                      if (!_formKey.currentState!.validate()) return;
                      final workspaceId =
                          widget.parentRef.read(activeWorkspaceIdProvider);
                      if (workspaceId == null) return;
                      final employee = EmployeeModel.create(
                        workspaceId: workspaceId,
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        phone: _phoneController.text.trim(),
                        role: _role,
                        department: _deptController.text.trim().isEmpty
                            ? 'General'
                            : _deptController.text.trim(),
                        avatarColorValue:
                            AppColors.workspaceColors[_colorIndex].value,
                      );
                      widget.parentRef
                          .read(employeesProvider.notifier)
                          .addEmployee(employee);
                      Navigator.pop(context);
                    }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}