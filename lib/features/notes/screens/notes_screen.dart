import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/note_model.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../dashboard/dashboard_navigation_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/avatar_stack.dart';
import '../../../shared/widgets/priority_chip.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NoteModel> _filteredNotes(List<NoteModel> notes) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return notes;

    return notes.where((note) {
      final searchableText = [
        note.title,
        note.content,
        note.tags.join(' '),
      ].join(' ').toLowerCase();
      return searchableText.contains(query);
    }).toList();
  }

  void _openAddNote() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddNoteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(workspaceNotesProvider);
    final filteredNotes = _filteredNotes(notes);
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;

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
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.read(dashboardTabIndexProvider.notifier).state =
                                0;
                            context.go('/home');
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Notes',
                                style: AppTextStyles.displaySmall),
                            Text(
                              hasSearchQuery
                                  ? '${filteredNotes.length} Results'
                                  : '${notes.length} Notes',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSearchVisible = !_isSearchVisible;
                              if (!_isSearchVisible) {
                                _searchController.clear();
                              }
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 254, 254),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.search_rounded,
                                color: AppColors.textPrimary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.more_horiz_rounded,
                              color: AppColors.textPrimary, size: 20),
                        ),
                      ],
                    ),
                    if (_isSearchVisible) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded,
                                      color: AppColors.textSecondary),
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Browse Categories',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _BrowseItem(
                            icon: Icons.star_rounded,
                            label: 'Shortcut',
                            color: AppColors.primary,
                            bg: AppColors.cardPurple),
                        _BrowseItem(
                            icon: Icons.label_rounded,
                            label: 'Tags',
                            color: AppColors.accentBlue,
                            bg: AppColors.cardBlue),
                        _BrowseItem(
                            icon: Icons.access_time_rounded,
                            label: 'Recent',
                            color: AppColors.accentOrange,
                            bg: AppColors.cardOrange),
                        _BrowseItem(
                            icon: Icons.people_rounded,
                            label: 'Shared',
                            color: AppColors.accentPink,
                            bg: AppColors.cardPink),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Daily Notes',
                      subtitle: hasSearchQuery
                          ? '${filteredNotes.length} Results'
                          : '${notes.length} Notes',
                      actionLabel: 'See All',
                      onAction: () {},
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          if (notes.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.sticky_note_2_outlined,
                title: 'No Notes Yet',
                subtitle:
                    'Create your first note to capture ideas and information.',
                actionLabel: 'Create Note',
                onAction: _openAddNote,
              ),
            )
          else if (filteredNotes.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching notes',
                subtitle: 'Try a different keyword or clear the search filter.',
                actionLabel: 'Clear Search',
                onAction: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _NoteCard(
                    note: filteredNotes[i],
                    onTap: () =>
                        context.go('/home/notes/${filteredNotes[i].id}'),
                    onToggleCompletion: () => ref
                        .read(notesProvider.notifier)
                        .toggleCompletion(filteredNotes[i].id),
                  ),
                ),
                childCount: filteredNotes.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notesScreenFab',
        onPressed: _openAddNote,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }
}

class _BrowseItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  const _BrowseItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onToggleCompletion;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onToggleCompletion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      color: Color(note.colorValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with emoji
          Row(
            children: [
              Expanded(
                child: Text(
                  note.isPinned ? '📌 ${note.title}' : note.title,
                  style: AppTextStyles.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Checkbox(
                value: note.isCompleted,
                onChanged: (_) => onToggleCompletion(),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note.content,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppColors.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(note.createdAt),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.accentBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PriorityChip(priority: note.priorityStr, compact: true),
              const Spacer(),
              if (note.sharedWithIds.isNotEmpty)
                AvatarStack(
                  names: note.sharedWithIds,
                  size: 24,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-screen "Add Note" page.
/// Opened from the FAB and from the "Create Note" button in the empty state.
class AddNoteScreen extends ConsumerStatefulWidget {
  const AddNoteScreen({super.key});

  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _priority = 'medium';
  int _colorIndex = 0;
  bool _isSaving = false;

  final List<Color> _colors = [
    AppColors.cardPurple,
    AppColors.cardBlue,
    AppColors.cardOrange,
    AppColors.cardPink,
    AppColors.cardGreen,
    AppColors.cardTeal,
  ];

  final List<String> _priorities = ['low', 'medium', 'high'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a workspace before saving.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final note = NoteModel.create(
        workspaceId: workspaceId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        priority: _priority,
        colorValue: _colors[_colorIndex].value,
      );
      await ref.read(notesProvider.notifier).addNote(note);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Note created successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Unable to save note: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppColors.textPrimary),
        ),
        title: Text('Add Note', style: AppTextStyles.headlineSmall),
        centerTitle: false,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Note Color', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: _colors.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      return GestureDetector(
                        onTap: () => setState(() => _colorIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: _colorIndex == i
                                ? Border.all(
                                    color: AppColors.primary, width: 2.5)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Priority', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _priorities.map((p) {
                      final selected = _priority == p;
                      return ChoiceChip(
                        label: Text(p[0].toUpperCase() + p.substring(1)),
                        selected: selected,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        onSelected: (_) => setState(() => _priority = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Note Title',
                      prefixIcon:
                          Icon(Icons.title_rounded, color: AppColors.primary),
                    ),
                    validator: (value) {
                      final title = (value ?? '').trim();
                      if (title.isEmpty) return 'Note title is required.';
                      if (title.length > 20) {
                        return 'Note title must be 20 characters or less.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _contentController,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Write your note...',
                      alignLabelWithHint: true,
                      prefixIcon:
                          Icon(Icons.notes_rounded, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: _isSaving ? 'Saving...' : 'Save Note',
                    onTap: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}