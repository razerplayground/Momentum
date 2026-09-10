import 'package:hive/hive.dart';

part 'expense_model.g.dart';

enum ExpenseType { income, expense }
enum ExpenseCategory {
  materials,
  labor,
  equipment,
  travel,
  utilities,
  marketing,
  office,
  other
}

@HiveType(typeId: 8)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String workspaceId;

  @HiveField(2)
  String projectId;

  @HiveField(3)
  String title;

  @HiveField(4)
  String description;

  @HiveField(5)
  double amount;

  @HiveField(6)
  String typeStr; // income or expense

  @HiveField(7)
  String categoryStr;

  @HiveField(8)
  DateTime date;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  String? receiptUrl;

  @HiveField(11)
  String? addedById;

  ExpenseModel({
    required this.id,
    required this.workspaceId,
    required this.projectId,
    required this.title,
    this.description = '',
    required this.amount,
    this.typeStr = 'expense',
    this.categoryStr = 'other',
    required this.date,
    required this.createdAt,
    this.receiptUrl,
    this.addedById,
  });

  ExpenseType get type => typeStr == 'income' ? ExpenseType.income : ExpenseType.expense;

  bool get isIncome => type == ExpenseType.income;

  ExpenseCategory get category => ExpenseCategory.values.firstWhere(
      (e) => e.name == categoryStr,
      orElse: () => ExpenseCategory.other);

  factory ExpenseModel.create({
    required String workspaceId,
    required String projectId,
    required String title,
    required double amount,
    String type = 'expense',
    String category = 'other',
    String description = '',
    DateTime? date,
  }) {
    return ExpenseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: workspaceId,
      projectId: projectId,
      title: title,
      amount: amount,
      typeStr: type,
      categoryStr: category,
      description: description,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
    );
  }
}
