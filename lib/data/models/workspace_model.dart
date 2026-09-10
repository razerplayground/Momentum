import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'workspace_model.g.dart';

@HiveType(typeId: 0)
class WorkspaceModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String emoji;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  String industry; // Construction, Tech, Retail, etc.

  WorkspaceModel({
    required this.id,
    required this.name,
    this.description = '',
    this.emoji = '🏢',
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.industry = 'General',
  });

  Color get color => Color(colorValue);

  WorkspaceModel copyWith({
    String? name,
    String? description,
    String? emoji,
    int? colorValue,
    String? industry,
  }) {
    return WorkspaceModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      industry: industry ?? this.industry,
    );
  }

  factory WorkspaceModel.create({
    required String name,
    required int colorValue,
    String emoji = '🏢',
    String description = '',
    String industry = 'General',
  }) {
    return WorkspaceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      emoji: emoji,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      industry: industry,
    );
  }
}
