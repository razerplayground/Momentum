import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/other_providers.dart';

class ExpensesScreen extends ConsumerWidget {
  final String projectId;

  const ExpensesScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(projectExpensesProvider(projectId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Project Finance')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: expenses.length,
        itemBuilder: (context, i) {
          final e = expenses[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                leading: Icon(
                  e.isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: e.isIncome ? AppColors.accentGreen : AppColors.accentRed,
                ),
                title: Text(e.title, style: AppTextStyles.titleMedium),
                subtitle: Text(e.date.toIso8601String().substring(0, 10)),
                trailing: Text(
                  '${e.isIncome ? '+' : '-'}₹${e.amount.toStringAsFixed(0)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: e.isIncome ? AppColors.accentGreen : AppColors.accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
