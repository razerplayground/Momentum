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

  @HiveField(8)
  String ownerEmail;

  WorkspaceModel({
    required this.id,
    required this.name,
    this.description = '',
    this.emoji = '🏢',
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.industry = 'General',
    this.ownerEmail = '',
  });

  Color get color => Color(colorValue);

  WorkspaceModel copyWith({
    String? name,
    String? description,
    String? emoji,
    int? colorValue,
    String? industry,
    String? ownerEmail,
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
      ownerEmail: ownerEmail ?? this.ownerEmail,
    );
  }

  factory WorkspaceModel.create({
    required String name,
    required int colorValue,
    String emoji = '🏢',
    String description = '',
    String industry = 'General',
    String ownerEmail = '',
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
      ownerEmail: ownerEmail,
    );
  }

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Untitled Workspace',
      description: json['description'] as String? ?? json['address'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🏢',
      colorValue: json['colorValue'] is int
          ? json['colorValue'] as int
          : (json['color'] is int ? json['color'] as int : 0xFF6C5CE7),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      industry: json['industry'] as String? ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'industry': industry,
    };
  }
}
