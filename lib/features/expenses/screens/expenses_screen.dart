import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/models/expense_model.dart';

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
            child: Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              confirmDismiss: (_) => _confirmDelete(context),
              onDismissed: (_) async {
                await e.delete();
                ref.invalidate(projectExpensesProvider(projectId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                }
              },
              child: Card(
                child: ListTile(
                  onTap: () => _showEditSheet(context, ref, e),
                  leading: Icon(
                    e.isIncome
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: e.isIncome
                        ? AppColors.accentGreen
                        : AppColors.accentRed,
                  ),
                  title: Text(e.title, style: AppTextStyles.titleMedium),
                  subtitle: Text(e.date.toIso8601String().substring(0, 10)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${e.isIncome ? '+' : '-'}₹${e.amount.toStringAsFixed(0)}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: e.isIncome
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditSheet(context, ref, e);
                          } else if (value == 'delete') {
                            _handleDelete(context, ref, e);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_rounded),
                                title: Text('Edit'),
                              )),
                          PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_rounded,
                                    color: Colors.red),
                                title: Text('Delete'),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleDelete(
      BuildContext context, WidgetRef ref, ExpenseModel expense) async {
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return;
    await expense.delete();
    ref.invalidate(projectExpensesProvider(projectId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    }
  }

  void _showEditSheet(
      BuildContext context, WidgetRef ref, ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          _EditExpenseSheet(projectId: projectId, expense: expense),
    );
  }
}

class _EditExpenseSheet extends ConsumerStatefulWidget {
  final String projectId;
  final ExpenseModel expense;

  const _EditExpenseSheet({required this.projectId, required this.expense});

  @override
  ConsumerState<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<_EditExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _date;
  late bool _isIncome;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(
        text: widget.expense.amount.toStringAsFixed(0));
    _date = widget.expense.date;
    _isIncome = widget.expense.isIncome;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
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
                Text('Edit Transaction', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Expense'),
                        selected: !_isIncome,
                        onSelected: (_) => setState(() => _isIncome = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Income'),
                        selected: _isIncome,
                        onSelected: (_) => setState(() => _isIncome = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Title is required'
                      : null,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(labelText: 'Amount *'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(_date.toIso8601String().substring(0, 10)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final expense = widget.expense
                        ..title = _titleController.text.trim()
                        ..amount = double.parse(_amountController.text)
                        ..date = _date
                        ..typeStr = _isIncome ? 'income' : 'expense';
                      await expense.save();
                      ref.invalidate(
                          projectExpensesProvider(widget.projectId));
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}