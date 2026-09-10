import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../projects/screens/projects_screen.dart';
import '../../tasks/screens/tasks_screen.dart';
import '../../notes/screens/notes_screen.dart';
import '../../calendar/screens/calendar_screen.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _currentIndex = 0;

  void _onFabTap() {
    switch (_currentIndex) {
      case 0:
        // Show quick add dialog
        _showQuickAdd();
        break;
      case 1:
        context.go('/home/projects');
        break;
      case 2:
        // Navigate to add task
        break;
      case 3:
        // Navigate to add note
        break;
      case 4:
        // Navigate to add appointment
        break;
    }
  }

  void _showQuickAdd() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Quick Add', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _QuickAddItem(
              icon: Icons.folder_rounded, label: 'New Project',
              color: const Color(0xFF7C3AED),
              onTap: () { Navigator.pop(context); context.go('/home/projects'); },
            ),
            _QuickAddItem(
              icon: Icons.task_alt_rounded, label: 'New Task',
              color: const Color(0xFF3B82F6),
              onTap: () { Navigator.pop(context); context.go('/home/tasks'); },
            ),
            _QuickAddItem(
              icon: Icons.sticky_note_2_rounded, label: 'New Note',
              color: const Color(0xFF22C55E),
              onTap: () { Navigator.pop(context); context.go('/home/notes'); },
            ),
            _QuickAddItem(
              icon: Icons.event_rounded, label: 'New Appointment',
              color: const Color(0xFFF59E0B),
              onTap: () { Navigator.pop(context); context.go('/home/calendar'); },
            ),
            _QuickAddItem(
              icon: Icons.people_rounded, label: 'Add Employee',
              color: const Color(0xFFEC4899),
              onTap: () { Navigator.pop(context); context.go('/home/employees'); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _switchTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onTabSwitch: _switchTab),
      const ProjectsScreen(),
      const TasksScreen(),
      const NotesScreen(),
      const CalendarScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        onFabTap: _onFabTap,
      ),
    );
  }
}

class _QuickAddItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddItem({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
