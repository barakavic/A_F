import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/project.dart';
import '../data/models/fundraiser_stats.dart';
import '../data/services/project_service.dart';

final projectServiceProvider = Provider((ref) => ProjectService());

final activeProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return await service.getActiveProjects();
});

final myProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return await service.getMyProjects();
});

final fundraiserStatsProvider = FutureProvider.autoDispose<FundraiserStats>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return await service.getFundraiserStats();
});
