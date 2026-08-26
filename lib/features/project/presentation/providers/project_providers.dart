import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/project_remote_data_source.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/delete_project_usecase.dart';
import '../../domain/usecases/duplicate_project_usecase.dart';
import '../../domain/usecases/rename_project_usecase.dart';
import '../../domain/usecases/watch_projects_usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final projectRemoteDataSourceProvider = Provider<ProjectRemoteDataSource>((ref) {
  return ProjectRemoteDataSource();
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl(ref.watch(projectRemoteDataSourceProvider));
});

final createProjectUseCaseProvider = Provider<CreateProjectUseCase>((ref) {
  return CreateProjectUseCase(ref.watch(projectRepositoryProvider));
});

final watchProjectsUseCaseProvider = Provider<WatchProjectsUseCase>((ref) {
  return WatchProjectsUseCase(ref.watch(projectRepositoryProvider));
});

final renameProjectUseCaseProvider = Provider<RenameProjectUseCase>((ref) {
  return RenameProjectUseCase(ref.watch(projectRepositoryProvider));
});

final deleteProjectUseCaseProvider = Provider<DeleteProjectUseCase>((ref) {
  return DeleteProjectUseCase(ref.watch(projectRepositoryProvider));
});

final duplicateProjectUseCaseProvider = Provider<DuplicateProjectUseCase>((ref) {
  return DuplicateProjectUseCase(ref.watch(projectRepositoryProvider));
});

/// Список проектов текущего авторизованного пользователя.
/// Зависит от authStateChangesProvider — как только auth.currentUser
/// известен, подписываемся на Firestore-стрим его проектов.
final userProjectsProvider = StreamProvider<List<ProjectEntity>>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(watchProjectsUseCaseProvider).call(user.id);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});
