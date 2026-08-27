/// Качество экспортируемого видео. По ТЗ — 720p и 1080p.
enum ExportQuality {
  p720(width: 1280, height: 720, label: '720p'),
  p1080(width: 1920, height: 1080, label: '1080p');

  final int width;
  final int height;
  final String label;

  const ExportQuality({required this.width, required this.height, required this.label});
}
