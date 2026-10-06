import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job_model.dart';
import '../models/workspace_model.dart';
import '../services/api_service.dart';
import 'workspace_provider.dart';

final jobsProvider =
    StateNotifierProvider<JobNotifier, AsyncValue<List<JobModel>>>((ref) {
  final notifier = JobNotifier(ref.watch(apiServiceProvider));
  ref.listen<List<WorkspaceModel>>(workspacesProvider, (_, workspaces) {
    notifier.loadJobs(workspaces);
  });
  notifier.loadJobs(ref.read(workspacesProvider));
  return notifier;
});

class JobNotifier extends StateNotifier<AsyncValue<List<JobModel>>> {
  final ApiService _apiService;
  List<WorkspaceModel> _workspaces = [];
  int _loadGeneration = 0;

  JobNotifier(this._apiService) : super(const AsyncLoading());

  Future<void> loadJobs(List<WorkspaceModel> workspaces) async {
    final generation = ++_loadGeneration;
    final requestedWorkspaces = List<WorkspaceModel>.of(workspaces);
    _workspaces = requestedWorkspaces;
    state = const AsyncLoading();
    try {
      final jobsByBusiness = await Future.wait(
        requestedWorkspaces.map((workspace) async {
          final jobs = await _apiService.getJobs(workspace.id);
          return jobs
              .map((json) => JobModel.fromApiJson(
                    json,
                    businessId: workspace.id,
                  ))
              .toList();
        }),
      );
      if (generation != _loadGeneration) return;
      state = AsyncData(jobsByBusiness.expand((jobs) => jobs).toList());
    } catch (error, stackTrace) {
      if (generation != _loadGeneration) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> addJob({
    required String businessId,
    required String title,
    required String department,
    required String status,
  }) async {
    final created = await _apiService.createJob(
      businessId,
      {
        'title': title,
        'department': department,
        'status': status,
      },
    );
    _replaceInState(JobModel.fromApiJson(created, businessId: businessId));
  }

  Future<void> updateJob(
    JobModel job, {
    required String title,
    required String department,
    required String status,
  }) async {
    await _apiService.updateJob(
      job.businessId,
      job.id,
      {
        'title': title,
        'department': department,
        'status': status,
      },
    );
    final updated = JobModel(
      id: job.id,
      businessId: job.businessId,
      title: title,
      department: department,
      status: status,
    );
    _replaceInState(updated);
  }

  Future<void> deleteJob(JobModel job) async {
    await _apiService.deleteJob(job.businessId, job.id);
    final jobs = state.valueOrNull;
    if (jobs != null) {
      state = AsyncData(jobs.where((item) => item.id != job.id).toList());
    }
  }

  void _replaceInState(JobModel job) {
    final jobs = state.valueOrNull;
    if (jobs == null) {
      state = AsyncData([job]);
      return;
    }
    state = AsyncData([
      ...jobs.where((item) => item.id != job.id),
      job,
    ]);
  }

  Future<void> refresh() => loadJobs(_workspaces);
}
