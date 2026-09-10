import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/todo_model.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/priority_chip.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(workspaceTodosProvider);
    final pending = todos.where((t) => !t.isCompleted).length;
    final done = todos.where((t) => t.isCompleted).length;

    // Group by category
    final categories = todos.map((t) => t.category).toSet().toList();

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
                    // Show back button when navigated to as a sub-route (not as a bottom-nav tab)
                    if (context.canPop())
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: const Icon(Icons.arrow_back_ios_rounded,
                                  size: 20, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            Text('Back', style: AppTextStyles.titleMedium
                                .copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    Text('To-Do List', style: AppTextStyles.displaySmall),
                    Text('$pending pending • $done done',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 16),
                    // Progress card
                    AnimatedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Today's Progress",
                                  style: AppTextStyles.titleMedium),
                              const Spacer(),
                              Text(
                                '${todos.isEmpty ? 0 : (done / todos.length * 100).toInt()}% Done',
                                style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: ShaderMask(
                              shaderCallback: (bounds) => AppColors.progressGradient
                                  .createShader(bounds),
                              child: LinearProgressIndicator(
                                value: todos.isEmpty ? 0 : done / todos.length,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          if (todos.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.checklist_rounded,
                title: 'All Clear!',
                subtitle: 'Add to-do items to stay organized.',
                actionLabel: 'Add To-Do',
              ),
            )
          else ...[
            for (final category in categories) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(category, style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final categoryTodos = todos
                        .where((t) => t.category == category)
                        .toList();
                    if (i >= categoryTodos.length) return null;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _TodoTile(
                        todo: categoryTodos[i],
                        onToggle: () => ref.read(todosProvider.notifier)
                            .toggle(categoryTodos[i].id),
                        onDelete: () => ref.read(todosProvider.notifier)
                            .delete(categoryTodos[i].id),
                      ),
                    );
                  },
                  childCount: todos.where((t) => t.category == category).length,
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodo(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddTodo(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddTodoSheet(parentRef: ref),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoTile({required this.todo, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: todo.isCompleted ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: todo.isCompleted ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: todo.isCompleted
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
                  todo.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    color: todo.isCompleted
                        ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                if (todo.description.isNotEmpty)
                  Text(todo.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          PriorityChip(priority: todo.priorityStr, compact: true),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textTertiary, size: 18),
          ),
        ],
      ),
    );
  }
}

class _AddTodoSheet extends StatefulWidget {
  final WidgetRef parentRef;

  const _AddTodoSheet({required this.parentRef});

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
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
            Text('New To-Do', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: _titleController,
                decoration: const InputDecoration(hintText: 'What needs to be done?',
                    prefixIcon: Icon(Icons.checklist_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            TextField(controller: _categoryController,
                decoration: const InputDecoration(hintText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary))),
            const SizedBox(height: 12),
            Row(children: ['low', 'medium', 'high'].map((p) {
              final isSelected = _priority == p;
              final color = p == 'high' ? AppColors.accentRed
                  : p == 'medium' ? AppColors.accentOrange : AppColors.accentGreen;
              return Expanded(child: Padding(
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
              ));
            }).toList()),
            const SizedBox(height: 24),
            GradientButton(label: 'Add To-Do', onTap: () {
              if (_titleController.text.trim().isEmpty) return;
              final workspaceId = widget.parentRef.read(activeWorkspaceIdProvider);
              if (workspaceId == null) return;
              final todo = TodoModel.create(
                workspaceId: workspaceId,
                title: _titleController.text.trim(),
                priority: _priority,
                category: _categoryController.text.trim().isEmpty
                    ? 'General' : _categoryController.text.trim(),
              );
              widget.parentRef.read(todosProvider.notifier).add(todo);
              Navigator.pop(context);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
