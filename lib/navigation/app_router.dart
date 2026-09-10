import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/workspace/screens/workspace_selection_screen.dart';
import '../features/dashboard/screens/dashboard_shell.dart';
import '../features/projects/screens/projects_screen.dart';
import '../features/projects/screens/project_detail_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';
import '../features/tasks/screens/task_detail_screen.dart';
import '../features/notes/screens/notes_screen.dart';
import '../features/notes/screens/note_detail_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/todo/screens/todo_screen.dart';
import '../features/employees/screens/employees_screen.dart';
import '../features/employees/screens/employee_detail_screen.dart';
import '../features/followups/screens/followups_screen.dart';
import '../features/expenses/screens/expenses_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: '/workspaces',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const WorkspaceSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardShell(),
      routes: [
        GoRoute(
          path: 'projects',
          builder: (context, state) => const ProjectsScreen(),
          routes: [
            GoRoute(
              path: ':projectId',
              builder: (context, state) => ProjectDetailScreen(
                projectId: state.pathParameters['projectId']!,
              ),
              routes: [
                GoRoute(
                  path: 'expenses',
                  builder: (context, state) => ExpensesScreen(
                    projectId: state.pathParameters['projectId']!,
                  ),
                ),
                GoRoute(
                  path: 'followups',
                  builder: (context, state) => FollowupsScreen(
                    projectId: state.pathParameters['projectId'],
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'tasks',
          builder: (context, state) => const TasksScreen(),
          routes: [
            GoRoute(
              path: ':taskId',
              builder: (context, state) => TaskDetailScreen(
                taskId: state.pathParameters['taskId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'notes',
          builder: (context, state) => const NotesScreen(),
          routes: [
            GoRoute(
              path: ':noteId',
              builder: (context, state) => NoteDetailScreen(
                noteId: state.pathParameters['noteId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: 'todo',
          builder: (context, state) => const TodoScreen(),
        ),
        GoRoute(
          path: 'employees',
          builder: (context, state) => const EmployeesScreen(),
          routes: [
            GoRoute(
              path: ':employeeId',
              builder: (context, state) => EmployeeDetailScreen(
                employeeId: state.pathParameters['employeeId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'followups',
          builder: (context, state) => const FollowupsScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.error}')),
  ),
);
