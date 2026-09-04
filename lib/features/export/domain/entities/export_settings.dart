import 'export_quality.dart';

/// Полный набор настроек рендера — собирается на экране экспорта и
/// передаётся в VideoExportEngine.render(...) одним объектом, чтобы не
/// раздувать сигнатуру метода на каждый новый параметр макета.
class ExportSettings {
  final ExportQuality quality;
  final ExportFrameRate frameRate;
  final int bitrateMbps;
  final bool enableAiUpscale;
  final bool enableSmartHdr;

  const ExportSettings({
    required this.quality,
    this.frameRate = ExportFrameRate.fps30,
    this.bitrateMbps = 5,
    this.enableAiUpscale = false,
    this.enableSmartHdr = false,
  });

  ExportSettings copyWith({
    ExportQuality? quality,
    ExportFrameRate? frameRate,
    int? bitrateMbps,
    bool? enableAiUpscale,
    bool? enableSmartHdr,
  }) {
    return ExportSettings(
      quality: quality ?? this.quality,
      frameRate: frameRate ?? this.frameRate,
      bitrateMbps: bitrateMbps ?? this.bitrateMbps,
      enableAiUpscale: enableAiUpscale ?? this.enableAiUpscale,
      enableSmartHdr: enableSmartHdr ?? this.enableSmartHdr,
    );
  }
}
