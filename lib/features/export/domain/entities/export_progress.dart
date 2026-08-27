import 'dart:io';

enum ExportStatus { idle, rendering, savingToGallery, done, error }

class ExportProgress {
  final ExportStatus status;
  final double progress; // 0..1
  final File? resultFile;
  final String? errorMessage;

  const ExportProgress({
    this.status = ExportStatus.idle,
    this.progress = 0,
    this.resultFile,
    this.errorMessage,
  });

  ExportProgress copyWith({
    ExportStatus? status,
    double? progress,
    File? resultFile,
    String? errorMessage,
  }) {
    return ExportProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      resultFile: resultFile ?? this.resultFile,
      errorMessage: errorMessage,
    );
  }
}
