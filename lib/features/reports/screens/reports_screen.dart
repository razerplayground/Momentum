import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/workspace_provider.dart';
import '../../../data/services/api_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _businessId;
  String? _loadedBusinessId;
  bool _allBusinesses = true;
  bool _loading = false;
  String? _error;
  dynamic _overview;
  dynamic _financialTrend;
  dynamic _projectAnalytics;

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider);
    final activeWorkspaceId = ref.watch(activeWorkspaceProvider)?.id;
    final businessId = workspaces.any((item) => item.id == _businessId)
        ? _businessId!
        : activeWorkspaceId ??
            (workspaces.isNotEmpty ? workspaces.first.id : null);

    if (_loadedBusinessId != (_allBusinesses ? '*' : businessId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _loadedBusinessId != (_allBusinesses ? '*' : businessId)) {
          _loadReports(businessId);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: _loading ? null : () => _loadReports(businessId),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadReports(businessId),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.business_center_outlined),
                  label: Text('All businesses'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.business_outlined),
                  label: Text('One business'),
                ),
              ],
              selected: {_allBusinesses},
              onSelectionChanged: _loading
                  ? null
                  : (selection) {
                      setState(() => _allBusinesses = selection.first);
                      _loadReports(businessId);
                    },
            ),
            if (!_allBusinesses) ...[
              const SizedBox(height: 16),
              if (workspaces.isEmpty)
                const Text('Create a business to view its reports.')
              else
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
                  onChanged: _loading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _businessId = value);
                          _loadReports(value);
                        },
                ),
            ],
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Could not load reports: $_error'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () => _loadReports(businessId),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_overview != null) ...[
              _ReportSection(
                title: _allBusinesses
                    ? 'Organization overview'
                    : 'Business overview',
                data: _overview,
              ),
              if (!_allBusinesses) ...[
                if (_financialTrend != null)
                  _ReportSection(
                    title: 'Financial trend',
                    data: _financialTrend,
                  ),
                if (_projectAnalytics != null)
                  _ReportSection(
                    title: 'Project analytics',
                    data: _projectAnalytics,
                  ),
              ],
            ],
            if (!_loading &&
                _error == null &&
                _overview == null &&
                (_allBusinesses || businessId != null))
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('No report data available.')),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadReports(String? businessId) async {
    if (!_allBusinesses && businessId == null) {
      setState(() {
        _overview = null;
        _financialTrend = null;
        _projectAnalytics = null;
        _loadedBusinessId = null;
        _loading = false;
        _error = null;
      });
      return;
    }

    final requestKey = _allBusinesses ? '*' : businessId!;
    setState(() {
      _businessId = businessId;
      _loadedBusinessId = requestKey;
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final results = _allBusinesses
          ? await Future.wait<dynamic>([
              api.getOrganizationReportOverview(),
            ])
          : await Future.wait<dynamic>([
              api.getBusinessReport(businessId!),
              api.getFinancialTrend(businessId),
              api.getProjectAnalytics(businessId),
            ]);
      if (!mounted || _loadedBusinessId != requestKey) return;
      setState(() {
        _overview = _unwrapReport(results[0]);
        _financialTrend =
            _allBusinesses ? null : _unwrapReport(results[1]);
        _projectAnalytics =
            _allBusinesses ? null : _unwrapReport(results[2]);
        _loading = false;
      });
    } catch (error) {
      if (!mounted || _loadedBusinessId != requestKey) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final dynamic data;

  const _ReportSection({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final content = _unwrapReport(data);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 10),
          if (content is Map)
            _ReportMap(data: Map<String, dynamic>.from(content))
          else if (content is List)
            _ReportList(data: content)
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_displayValue(content)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportMap extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReportMap({required this.data});

  @override
  Widget build(BuildContext context) {
    final scalarEntries = data.entries
        .where((entry) => entry.value != null && !_isStructured(entry.value))
        .toList();
    final structuredEntries =
        data.entries.where((entry) => _isStructured(entry.value)).toList();

    return Column(
      children: [
        if (scalarEntries.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: scalarEntries
                .map(
                  (entry) => SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 50) / 2,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _humanize(entry.key),
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _displayValue(entry.value),
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ...structuredEntries.map(
          (entry) => _ReportSection(title: _humanize(entry.key), data: entry.value),
        ),
        if (scalarEntries.isEmpty && structuredEntries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No metrics reported.'),
            ),
          ),
      ],
    );
  }
}

class _ReportList extends StatelessWidget {
  final List<dynamic> data;

  const _ReportList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No data reported.'),
        ),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < data.length; index++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: data[index] is Map
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayValue(
                            _firstReportValue(
                              Map<String, dynamic>.from(data[index] as Map),
                              const ['month', 'name', 'title', 'label'],
                            ),
                          ),
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _ReportMap(
                          data: Map<String, dynamic>.from(data[index] as Map),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: Text('Item ${index + 1}')),
                        Text(_displayValue(data[index])),
                      ],
                    ),
            ),
          ),
      ],
    );
  }
}

dynamic _unwrapReport(dynamic value) {
  var report = value;
  for (var depth = 0; depth < 3 && report is Map; depth++) {
    final map = Map<String, dynamic>.from(report);
    final nested = map['data'] ?? map['report'] ?? map['overview'];
    if (nested is Map || nested is List) {
      report = nested;
    } else {
      return map;
    }
  }
  return report;
}

bool _isStructured(dynamic value) => value is Map || value is List;

dynamic _firstReportValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map[key] != null) return map[key];
  }
  return null;
}

String _humanize(String value) {
  final spaced = value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');
  return spaced.isEmpty
      ? spaced
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _displayValue(dynamic value) {
  if (value == null) return '—';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is Map || value is List) return value.toString();
  return value.toString();
}
