import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/employee_provider.dart';
import '../../../shared/widgets/avatar_stack.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(workspaceEmployeesProvider)
        .where((e) => e.id == employeeId)
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
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () {}),
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
                      style: AppTextStyles.displaySmall.copyWith(color: Colors.white)),
                  Text(employee.roleStr.toUpperCase(),
                      style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white70, fontWeight: FontWeight.w600)),
                  Text(employee.department,
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(items: [
                    _InfoItem(icon: Icons.email_rounded, label: 'Email', value: employee.email),
                    _InfoItem(icon: Icons.phone_rounded, label: 'Phone', value: employee.phone),
                    _InfoItem(icon: Icons.business_rounded, label: 'Department', value: employee.department),
                    _InfoItem(icon: Icons.badge_rounded, label: 'Status',
                        value: employee.statusStr == 'onLeave' ? 'On Leave' : employee.statusStr),
                  ]),
                ],
              ),
            ),
          ],
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
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 12, offset: const Offset(0, 4)),
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
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 18, color: AppColors.primary),
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

  const _InfoItem({required this.icon, required this.label, required this.value});
}
