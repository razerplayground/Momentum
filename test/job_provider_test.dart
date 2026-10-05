import 'dart:async';

import 'package:bussiness_management/data/models/workspace_model.dart';
import 'package:bussiness_management/data/providers/job_provider.dart';
import 'package:bussiness_management/data/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the latest job load when requests complete out of order',
      () async {
    final apiService = _ControlledJobApiService();
    final notifier = JobNotifier(apiService);

    final firstLoad = notifier.loadJobs([_workspace('old-business')]);
    final secondLoad = notifier.loadJobs([_workspace('current-business')]);

    apiService.pendingRequests['current-business']!.complete([
      {'id': 'current-job', 'title': 'Current job'},
    ]);
    await secondLoad;

    apiService.pendingRequests['old-business']!.complete([
      {'id': 'stale-job', 'title': 'Stale job'},
    ]);
    await firstLoad;

    expect(
      notifier.state.asData!.value.map((job) => job.businessId),
      ['current-business'],
    );
    expect(
      notifier.state.asData!.value.map((job) => job.id),
      ['current-job'],
    );
  });
}

WorkspaceModel _workspace(String id) {
  final now = DateTime(2026);
  return WorkspaceModel(
    id: id,
    name: id,
    colorValue: 0,
    createdAt: now,
    updatedAt: now,
  );
}

class _ControlledJobApiService extends ApiService {
  final Map<String, Completer<List<Map<String, dynamic>>>> pendingRequests = {};

  @override
  Future<List<Map<String, dynamic>>> getJobs(String businessId) {
    return pendingRequests
        .putIfAbsent(
          businessId,
          () => Completer<List<Map<String, dynamic>>>(),
        )
        .future;
  }
}
