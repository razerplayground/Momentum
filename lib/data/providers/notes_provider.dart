import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';
import '../../core/constants/app_constants.dart';
import 'workspace_provider.dart';

final notesProvider =
    StateNotifierProvider<NoteNotifier, List<NoteModel>>((ref) {
  return NoteNotifier(ref);
});

final workspaceNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(notesProvider);
  final userWorkspaceIds = ref.watch(userWorkspaceIdsProvider);
  final activeId = ref.watch(activeWorkspaceIdProvider);
  final isGlobalView = ref.watch(globalViewEnabledProvider);
  if (isGlobalView) {
    return notes
        .where((note) => userWorkspaceIds.contains(note.workspaceId))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
  if (activeId == null) return [];
  return notes.where((n) => n.workspaceId == activeId).toList()
    ..sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
});

class NoteNotifier extends StateNotifier<List<NoteModel>> {
  final Ref _ref;

  NoteNotifier(this._ref) : super([]) {
    _loadNotes();
  }

  void _loadNotes() {
    final box = Hive.box<NoteModel>(AppConstants.noteBox);
    state = box.values.toList();
  }

  Future<void> addNote(NoteModel note) async {
    final box = Hive.box<NoteModel>(AppConstants.noteBox);
    await box.put(note.id, note);
    state = [...state, note];
  }

  Future<void> updateNote(NoteModel note) async {
    final box = Hive.box<NoteModel>(AppConstants.noteBox);
    await box.put(note.id, note);
    state = state.map((n) => n.id == note.id ? note : n).toList();
  }

  Future<void> togglePin(String id) async {
    final note = state.firstWhere((n) => n.id == id);
    final updated = NoteModel(
      id: note.id,
      workspaceId: note.workspaceId,
      projectId: note.projectId,
      title: note.title,
      content: note.content,
      tags: note.tags,
      priorityStr: note.priorityStr,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      sharedWithIds: note.sharedWithIds,
      isPinned: !note.isPinned,
      colorValue: note.colorValue,
    );
    await updateNote(updated);
  }

  Future<void> deleteNote(String id) async {
    final box = Hive.box<NoteModel>(AppConstants.noteBox);
    await box.delete(id);
    state = state.where((n) => n.id != id).toList();
  }
}
