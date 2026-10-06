import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../data/services/api_service.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String? _businessId;
  String? _requestedBusinessId;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _activities = [];
  String? _exporting;
  String? _exportMessage;
  String? _exportError;

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider);
    final activeWorkspaceId = ref.watch(activeWorkspaceProvider)?.id;
    final businessId =
        workspaces.any((workspace) => workspace.id == _businessId)
            ? _businessId!
            : activeWorkspaceId ??
                (workspaces.isNotEmpty ? workspaces.first.id : null);

    if (businessId != null && _requestedBusinessId != businessId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _requestedBusinessId != businessId) {
          _loadActivity(businessId);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity & Exports'),
        actions: [
          IconButton(
            tooltip: 'Refresh activity',
            onPressed: businessId == null || _loading
                ? null
                : () => _loadActivity(businessId),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: workspaces.isEmpty
          ? const Center(child: Text('Create a business to view its activity.'))
          : RefreshIndicator(
              onRefresh: businessId == null
                  ? () async {}
                  : () => _loadActivity(businessId),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: businessId,
                    decoration: const InputDecoration(
                      labelText: 'Business',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                    items: workspaces
                        .map(
                          (workspace) => DropdownMenuItem(
                            value: workspace.id,
                            child: Text(workspace.name),
                          ),
                        )
                        .toList(),
                    onChanged: _loading || _exporting != null
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _businessId = value);
                            _loadActivity(value);
                          },
                  ),
                  const SizedBox(height: 24),
                  Text('Export CSV', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Exported files are saved in the app documents folder.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _ExportButton(
                    label: 'Financial records',
                    description: 'Income and expenses',
                    icon: Icons.account_balance_wallet_outlined,
                    loading: _exporting == 'finances',
                    enabled: _exporting == null && businessId != null,
                    onPressed: () => _exportCsv(businessId!, 'finances'),
                  ),
                  _ExportButton(
                    label: 'Payroll records',
                    description: 'Payroll history',
                    icon: Icons.payments_outlined,
                    loading: _exporting == 'payroll',
                    enabled: _exporting == null && businessId != null,
                    onPressed: () => _exportCsv(businessId!, 'payroll'),
                  ),
                  _ExportButton(
                    label: 'Employee roster',
                    description: 'Employee details',
                    icon: Icons.people_outline_rounded,
                    loading: _exporting == 'employees',
                    enabled: _exporting == null && businessId != null,
                    onPressed: () => _exportCsv(businessId!, 'employees'),
                  ),
                  if (_exportError != null) ...[
                    const SizedBox(height: 8),
                    _Notice(message: _exportError!, isError: true),
                  ],
                  if (_exportMessage != null) ...[
                    const SizedBox(height: 8),
                    _Notice(message: _exportMessage!),
                  ],
                  const SizedBox(height: 28),
                  Text('Recent activity', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _Notice(
                      message: 'Could not load activity: $_error',
                      isError: true,
                      action: TextButton(
                        onPressed: businessId == null
                            ? null
                            : () => _loadActivity(businessId),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                  if (!_loading && _error == null && _activities.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No recent activity for this business.'),
                      ),
                    ),
                  ..._activities.map((activity) => _ActivityCard(activity)),
                ],
              ),
            ),
    );
  }

  Future<void> _loadActivity(String businessId) async {
    setState(() {
      _businessId = businessId;
      _requestedBusinessId = businessId;
      _loading = true;
      _error = null;
      _activities = [];
    });

    try {
      final response =
          await ref.read(apiServiceProvider).getAuditLogs(businessId);
      if (!mounted || _requestedBusinessId != businessId) return;
      setState(() {
        _activities = _extractActivityList(response);
        _loading = false;
      });
    } catch (error) {
      if (!mounted || _requestedBusinessId != businessId) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<Map<String, dynamic>> _extractActivityList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (response is Map) {
      for (final key in const [
        'auditLogs',
        'activities',
        'logs',
        'items',
        'data',
      ]) {
        final nested = response[key];
        if (nested is List) return _extractActivityList(nested);
        if (nested is Map) {
          final result = _extractActivityList(nested);
          if (result.isNotEmpty) return result;
        }
      }
      if (response.isNotEmpty) {
        return [Map<String, dynamic>.from(response)];
      }
    }
    return [];
  }

  Future<void> _exportCsv(String businessId, String kind) async {
    setState(() {
      _exporting = kind;
      _exportMessage = null;
      _exportError = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final response = switch (kind) {
        'finances' => await api.exportFinances(businessId),
        'payroll' => await api.exportPayroll(businessId),
        'employees' => await api.exportEmployees(businessId),
        _ => throw StateError('Unknown export type: $kind'),
      };
      final csv = _extractCsv(response);
      if (csv == null || csv.trim().isEmpty) {
        throw const FormatException('The server returned an empty CSV export.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final safeBusinessId =
          businessId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      final file = File(
        '${directory.path}${Platform.pathSeparator}${kind}_$safeBusinessId'
        '_$timestamp.csv',
      );
      await file.writeAsBytes(Uint8List.fromList(utf8.encode(csv)),
          flush: true);
      if (!mounted) return;
      setState(() {
        _exportMessage = 'Saved ${file.path}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _exportError = 'Export failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _exporting = null;
        });
      }
    }
  }

  String? _extractCsv(dynamic response) {
    if (response is String) return response;
    if (response is List<int>) return utf8.decode(response);
    if (response is Map) {
      for (final key in const ['csv', 'content', 'data', 'result']) {
        final value = response[key];
        if (value is String) return value;
        final nested = _extractCsv(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(description),
        trailing: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_rounded),
        enabled: enabled,
        onTap: enabled ? onPressed : null,
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard(this.activity);

  final Map<String, dynamic> activity;

  String _firstValue(Iterable<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = activity[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num || value is bool) return value.toString();
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final title = _firstValue(
      const ['description', 'message', 'action', 'event', 'type', 'operation'],
      fallback: 'Activity recorded',
    );
    final actor = _firstValue(
      const ['userName', 'actorName', 'performedBy', 'user', 'actor'],
    );
    final dateValue =
        _firstValue(const ['createdAt', 'timestamp', 'date', 'occurredAt']);
    final date = DateTime.tryParse(dateValue);
    final subtitle = [
      if (actor.isNotEmpty) actor,
      if (date != null)
        MaterialLocalizations.of(context).formatMediumDate(date),
    ].join(' • ');
    final details = activity.entries
        .where((entry) => !const {
              'description',
              'message',
              'action',
              'event',
              'type',
              'operation',
              'userName',
              'actorName',
              'performedBy',
              'user',
              'actor',
              'createdAt',
              'timestamp',
              'date',
              'occurredAt',
              'id',
              '_id',
            }.contains(entry.key))
        .map((entry) =>
            '${entry.key}: ${entry.value is Map || entry.value is List ? jsonEncode(entry.value) : entry.value}')
        .join('\n');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.history_rounded),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) Text(subtitle),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(details),
            ],
          ],
        ),
        isThreeLine: details.isNotEmpty,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    this.isError = false,
    this.action,
  });

  final String message;
  final bool isError;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color =
        isError ? Theme.of(context).colorScheme.error : Colors.green.shade800;
    return Card(
      color: color.withAlpha(18),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text(message, style: TextStyle(color: color))),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
