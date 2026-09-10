import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/models/workspace_model.dart';
import 'data/models/project_model.dart';
import 'data/models/task_model.dart';
import 'data/models/note_model.dart';
import 'data/models/appointment_model.dart';
import 'data/models/todo_model.dart';
import 'data/models/employee_model.dart';
import 'data/models/followup_model.dart';
import 'data/models/expense_model.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(WorkspaceModelAdapter());
  Hive.registerAdapter(ProjectModelAdapter());
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(NoteModelAdapter());
  Hive.registerAdapter(AppointmentModelAdapter());
  Hive.registerAdapter(TodoModelAdapter());
  Hive.registerAdapter(EmployeeModelAdapter());
  Hive.registerAdapter(FollowupModelAdapter());
  Hive.registerAdapter(ExpenseModelAdapter());

  // Open all boxes
  await Future.wait([
    Hive.openBox<WorkspaceModel>(AppConstants.workspaceBox),
    Hive.openBox<ProjectModel>(AppConstants.projectBox),
    Hive.openBox<TaskModel>(AppConstants.taskBox),
    Hive.openBox<NoteModel>(AppConstants.noteBox),
    Hive.openBox<AppointmentModel>(AppConstants.appointmentBox),
    Hive.openBox<TodoModel>(AppConstants.todoBox),
    Hive.openBox<EmployeeModel>(AppConstants.employeeBox),
    Hive.openBox<FollowupModel>(AppConstants.followupBox),
    Hive.openBox<ExpenseModel>(AppConstants.expenseBox),
    Hive.openBox(AppConstants.settingsBox),
  ]);

  runApp(const ProviderScope(child: BizProApp()));
}

class BizProApp extends ConsumerWidget {
  const BizProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
