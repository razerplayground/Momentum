import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/workspace_model.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class WorkspaceSelectionScreen extends ConsumerStatefulWidget {
  const WorkspaceSelectionScreen({super.key});

  @override
  ConsumerState<WorkspaceSelectionScreen> createState() =>
      _WorkspaceSelectionScreenState();
}

class _WorkspaceSelectionScreenState
    extends ConsumerState<WorkspaceSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPink.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            gradient: AppColors.purpleGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business_center_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BizPro Manager',
                                style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800)),
                            Text('Your businesses, all in one place',
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text('My Workspaces', style: AppTextStyles.displaySmall),
                    Text('Select a business to manage',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 24),
                    Expanded(
                      child: workspaces.isEmpty
                          ? EmptyState(
                              icon: Icons.business_center_outlined,
                              title: 'No Workspaces Yet',
                              subtitle:
                                  'Create your first business workspace to get started.',
                              actionLabel: 'Create Workspace',
                              onAction: () => _showAddWorkspaceSheet(context),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: workspaces.length,
                              itemBuilder: (context, i) {
                                return _WorkspaceCard(
                                  workspace: workspaces[i],
                                  onTap: () {
                                    ref
                                        .read(workspacesProvider.notifier)
                                        .setActiveWorkspace(workspaces[i].id);
                                    context.go('/home');
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Add New Business',
                      icon: Icons.add_business_rounded,
                      onTap: () => _showAddWorkspaceSheet(context),
                      gradient: AppColors.primaryGradient,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWorkspaceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AddWorkspaceSheet(),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final WorkspaceModel workspace;
  final VoidCallback onTap;

  const _WorkspaceCard({required this.workspace, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              workspace.color.withOpacity(0.85),
              workspace.color.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: emoji + arrow icon (both white)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  // Bottom: name + industry (all white)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workspace.industry,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWorkspaceSheet extends ConsumerStatefulWidget {
  const _AddWorkspaceSheet();

  @override
  ConsumerState<_AddWorkspaceSheet> createState() => _AddWorkspaceSheetState();
}

class _AddWorkspaceSheetState extends ConsumerState<_AddWorkspaceSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedEmoji = '🏢';
  int _selectedColorIndex = 0;
  String _selectedIndustry = 'General';

  final List<String> _emojis = ['🏢', '🏗️', '🛒', '💻', '🏥', '🍕', '🎓', '✈️', '🏦', '🎨'];
  final List<String> _industries = [
    'General', 'Construction', 'Technology', 'Retail',
    'Healthcare', 'Food & Beverage', 'Education', 'Finance', 'Real Estate',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('New Business Workspace', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 20),
              // Emoji picker
              Text('Choose Icon', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojis.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = _emojis[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedEmoji == _emojis[i]
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.surfaceVariant,
                        border: _selectedEmoji == _emojis[i]
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(_emojis[i],
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Color picker
              Text('Color Theme', style: AppTextStyles.labelLarge),
              const SizedBox(height: 10),
              Row(
                children: List.generate(AppColors.workspaceColors.length, (i) {
                  final color = AppColors.workspaceColors[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _selectedColorIndex == i
                              ? Border.all(
                                  color: AppColors.textPrimary, width: 2.5)
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Business Name (e.g., My Construction Co.)',
                  prefixIcon:
                      Icon(Icons.business_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedIndustry,
                decoration: const InputDecoration(
                  hintText: 'Industry',
                  prefixIcon:
                      Icon(Icons.category_rounded, color: AppColors.primary),
                ),
                items: _industries
                    .map((ind) =>
                        DropdownMenuItem(value: ind, child: Text(ind)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedIndustry = val ?? 'General'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                  prefixIcon:
                      Icon(Icons.notes_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Create Workspace',
                onTap: () {
                  if (_nameController.text.trim().isEmpty) return;
                  final workspace = WorkspaceModel.create(
                    name: _nameController.text.trim(),
                    colorValue: AppColors.workspaceColors[_selectedColorIndex]
                        .value,
                    emoji: _selectedEmoji,
                    description: _descController.text.trim(),
                    industry: _selectedIndustry,
                  );
                  ref.read(workspacesProvider.notifier).addWorkspace(workspace);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
