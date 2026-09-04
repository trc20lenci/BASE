/// Разрешение экспортируемого видео.
///
/// По исходному ТЗ обязательны только 720p и 1080p — 480p и 2K/4K
/// добавлены сверху по референсному макету экрана экспорта и помечены
/// [isPremium] (визуально заблокированы, как и вкладка "Подписка" —
/// реальной проверки оплаты нет, см. предупреждение в
/// SubscriptionTabPage).
enum ExportQuality {
  p480(width: 854, height: 480, label: '480P', isPremium: false),
  p720(width: 1280, height: 720, label: '720P', isPremium: false),
  p1080(width: 1920, height: 1080, label: '1080P', isPremium: true),
  uhd(width: 3840, height: 2160, label: '2K/4K', isPremium: true);

  final int width;
  final int height;
  final String label;
  final bool isPremium;

  const ExportQuality({
    required this.width,
    required this.height,
    required this.label,
    required this.isPremium,
  });
}

/// Частота кадров экспорта.
enum ExportFrameRate {
  fps24(24),
  fps25(25),
  fps30(30),
  fps50(50),
  fps60(60);

  final int value;

  const ExportFrameRate(this.value);
}
