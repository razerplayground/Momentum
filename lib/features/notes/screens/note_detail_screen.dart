import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/notes_provider.dart';
import '../../../shared/widgets/priority_chip.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(workspaceNotesProvider)
        .where((n) => n.id == noteId)
        .firstOrNull;

    if (note == null) {
      return const Scaffold(body: Center(child: Text('Note not found')));
    }

    return Scaffold(
      backgroundColor: Color(note.colorValue),
      appBar: AppBar(
        backgroundColor: Color(note.colorValue),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
            onPressed: () => ref.read(notesProvider.notifier).togglePin(noteId),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRed),
            onPressed: () {
              ref.read(notesProvider.notifier).deleteNote(noteId);
              context.pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.title, style: AppTextStyles.displaySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                PriorityChip(priority: note.priorityStr),
                const SizedBox(width: 8),
                if (note.tags.isNotEmpty) ...note.tags.map((tag) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag, style: AppTextStyles.labelSmall),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  note.content.isEmpty ? 'No content...' : note.content,
                  style: AppTextStyles.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
