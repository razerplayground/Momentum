import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_service.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final isGlobalView = ref.watch(globalViewEnabledProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: _buildAccountDrawer(context),
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
                    AppColors.primary.withAlpha((0.15 * 255).round()),
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
                    AppColors.accentPink.withAlpha((0.12 * 255).round()),
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
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                      child: Row(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BizPro Manager',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleLarge.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800)),
                                Text('Your businesses, all in one place',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text('My Workspaces', style: AppTextStyles.displaySmall),
                    Text('Select a business to manage',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 24),
                    if (workspaces.isNotEmpty) ...[
                      _GlobalViewCard(
                        isSelected: isGlobalView,
                        onTap: () {
                          ref
                              .read(workspacesProvider.notifier)
                              .setGlobalView(true);
                          context.go('/home');
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
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
                                  onEdit: () => _showEditWorkspaceSheet(
                                      context, workspaces[i]),
                                  onDelete: () =>
                                      _deleteWorkspace(context, workspaces[i]),
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

  Widget _buildAccountDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Close menu',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
              const SizedBox(height: 16),
              Text('BizPro Manager', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),
              Text(
                AuthService.getSessionEmail(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Change workspace'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentRed,
                    side: BorderSide(
                      color: AppColors.accentRed.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  void _showEditWorkspaceSheet(BuildContext context, WorkspaceModel workspace) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditWorkspaceSheet(workspace: workspace),
    );
  }

  void _deleteWorkspace(BuildContext context, WorkspaceModel workspace) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workspace?'),
        content: Text(
          'Are you sure you want to delete "${workspace.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;

      final activeWorkspaceId = ref.read(activeWorkspaceIdProvider);
      await ref.read(workspacesProvider.notifier).deleteWorkspace(workspace.id);

      if (activeWorkspaceId == workspace.id) {
        final remaining = ref.read(workspacesProvider);
        if (remaining.isNotEmpty) {
          ref
              .read(workspacesProvider.notifier)
              .setActiveWorkspace(remaining.first.id);
        } else {
          ref.read(activeWorkspaceIdProvider.notifier).state = null;
        }
      }
    });
  }
}

class _EditWorkspaceSheet extends ConsumerStatefulWidget {
  final WorkspaceModel workspace;

  const _EditWorkspaceSheet({required this.workspace});

  @override
  ConsumerState<_EditWorkspaceSheet> createState() =>
      _EditWorkspaceSheetState();
}

class _EditWorkspaceSheetState extends ConsumerState<_EditWorkspaceSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late String _selectedEmoji;
  late int _selectedColorIndex;
  late String _selectedIndustry;

  final List<String> _emojis = [
    '🏢',
    '🏗️',
    '🛒',
    '💻',
    '🏥',
    '🍕',
    '🎓',
    '✈️',
    '🏦',
    '🎨'
  ];
  final List<String> _industries = [
    'General',
    'Construction',
    'Technology',
    'Retail',
    'Healthcare',
    'Food & Beverage',
    'Education',
    'Finance',
    'Real Estate',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workspace.name);
    _descController = TextEditingController(text: widget.workspace.description);
    _selectedEmoji = widget.workspace.emoji;
    _selectedIndustry = widget.workspace.industry;
    _selectedColorIndex = AppColors.workspaceColors.indexWhere(
      (color) => color.toARGB32() == widget.workspace.colorValue,
    );
    if (_selectedColorIndex == -1) {
      _selectedColorIndex = 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

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
              Text('Edit Business Workspace',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 20),
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
                            ? AppColors.primary.withAlpha((0.12 * 255).round())
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
                initialValue: _selectedIndustry,
                decoration: const InputDecoration(
                  hintText: 'Industry',
                  prefixIcon:
                      Icon(Icons.category_rounded, color: AppColors.primary),
                ),
                items: _industries
                    .map(
                        (ind) => DropdownMenuItem(value: ind, child: Text(ind)))
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
                label: 'Save Changes',
                onTap: () {
                  if (_nameController.text.trim().isEmpty) return;
                  final updated = widget.workspace.copyWith(
                    name: _nameController.text.trim(),
                    description: _descController.text.trim(),
                    emoji: _selectedEmoji,
                    colorValue: AppColors.workspaceColors[_selectedColorIndex]
                        .toARGB32(),
                    industry: _selectedIndustry,
                  );
                  ref
                      .read(workspacesProvider.notifier)
                      .updateWorkspace(updated);
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

class _GlobalViewCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _GlobalViewCard({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? AppColors.primaryGradient
              : LinearGradient(
                  colors: [AppColors.surface, AppColors.surfaceVariant],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha((0.18 * 255).round())
                    : AppColors.primary.withAlpha((0.12 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.public_rounded,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Workspaces',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Global View',
                    style: AppTextStyles.bodySmall.copyWith(
                      color:
                          isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.18 * 255).round()),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Active',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final WorkspaceModel workspace;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkspaceCard({
    required this.workspace,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

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
              workspace.color.withAlpha((0.85 * 255).round()),
              workspace.color.withAlpha((0.6 * 255).round()),
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
                  color: Colors.white.withAlpha((0.12 * 255).round()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: emoji + actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withAlpha((0.2 * 255).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withAlpha((0.2 * 255).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onTap,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withAlpha((0.2 * 255).round()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
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

  final List<String> _emojis = [
    '🏢',
    '🏗️',
    '🛒',
    '💻',
    '🏥',
    '🍕',
    '🎓',
    '✈️',
    '🏦',
    '🎨'
  ];
  final List<String> _industries = [
    'General',
    'Construction',
    'Technology',
    'Retail',
    'Healthcare',
    'Food & Beverage',
    'Education',
    'Finance',
    'Real Estate',
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
              Text('New Business Workspace',
                  style: AppTextStyles.headlineSmall),
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
                            ? AppColors.primary.withAlpha((0.12 * 255).round())
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
                initialValue: _selectedIndustry,
                decoration: const InputDecoration(
                  hintText: 'Industry',
                  prefixIcon:
                      Icon(Icons.category_rounded, color: AppColors.primary),
                ),
                items: _industries
                    .map(
                        (ind) => DropdownMenuItem(value: ind, child: Text(ind)))
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
                        .toARGB32(),
                    emoji: _selectedEmoji,
                    description: _descController.text.trim(),
                    industry: _selectedIndustry,
                    ownerEmail: AuthService.getSessionEmail(),
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
