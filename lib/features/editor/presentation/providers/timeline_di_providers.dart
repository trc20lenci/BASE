import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/timeline_remote_data_source.dart';
import '../../data/repositories/timeline_repository_impl.dart';
import '../../domain/repositories/timeline_repository.dart';
import '../../domain/usecases/load_timeline_usecase.dart';
import '../../domain/usecases/save_timeline_usecase.dart';
import '../../domain/usecases/upload_audio_track_usecase.dart';
import '../../domain/usecases/upload_clip_media_usecase.dart';

final timelineRemoteDataSourceProvider = Provider<TimelineRemoteDataSource>((ref) {
  return TimelineRemoteDataSource();
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepositoryImpl(ref.watch(timelineRemoteDataSourceProvider));
});

final loadTimelineUseCaseProvider = Provider<LoadTimelineUseCase>((ref) {
  return LoadTimelineUseCase(ref.watch(timelineRepositoryProvider));
});

final saveTimelineUseCaseProvider = Provider<SaveTimelineUseCase>((ref) {
  return SaveTimelineUseCase(ref.watch(timelineRepositoryProvider));
});

final uploadClipMediaUseCaseProvider = Provider<UploadClipMediaUseCase>((ref) {
  return UploadClipMediaUseCase(ref.watch(timelineRepositoryProvider));
});

final uploadAudioTrackUseCaseProvider = Provider<UploadAudioTrackUseCase>((ref) {
  return UploadAudioTrackUseCase(ref.watch(timelineRepositoryProvider));
});
