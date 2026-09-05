import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_video/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart' show Color;
import '../../../editor/domain/entities/audio_track_entity.dart';
import '../../../editor/domain/entities/clip_type.dart';
import '../../../editor/domain/entities/editor_timeline_entity.dart';
import '../../../editor/domain/entities/media_overlay_entity.dart';
import '../../../editor/domain/entities/text_overlay_entity.dart';
import '../../../editor/domain/entities/timeline_clip_entity.dart';
import '../../../project/domain/entities/project_format.dart';
import '../../domain/entities/export_settings.dart';
import '../../domain/repositories/video_export_engine.dart';

/// Реализация [VideoExportEngine] поверх `ffmpeg_kit_flutter_new_video`
/// (мейнтенящийся форк оригинального ffmpeg-kit, обновлённый под Android
/// V2 embedding и Flutter 3+ — см. README).
///
/// ВАЖНОЕ ОГРАНИЧЕНИЕ ПАКЕТА (осознанный выбор, не баг): флейвор `_video`
/// НЕ включает GPL-кодеки (libx264/libx265) — только LGPL-библиотеки
/// (dav1d, libvpx, libwebp, libtheora, fontconfig/freetype/fribidi/
/// libass для субтитров/drawtext). Поэтому видео кодируется через
/// `libvpx-vp9` (VP9), а не H.264. VP9-в-MP4 воспроизводится большинством
/// современных плееров/приложений, но если нужна максимальная
/// совместимость именно с H.264 (старые Smart TV, некоторые площадки) —
/// смените зависимость в pubspec.yaml на `ffmpeg_kit_flutter_new_min_gpl`
/// (или другой `*_gpl` флейвор) и поменяйте здесь `_videoCodec` на
/// `'libx264'` — остальной код менять не придётся.
///
/// ДРУГИЕ ИЗВЕСТНЫЕ ОГРАНИЧЕНИЯ ЭТОЙ ВЕРСИИ (см. итоговое сообщение в
/// чате при внедрении):
/// 1. Собственная трансформация (масштаб/поворот/позиция) БАЗОВОГО клипа
///    от пользовательского жеста на холсте пока НЕ применяется при
///    экспорте — базовый клип всегда кадрируется/масштабируется "cover"
///    на весь холст. Кадрирование (crop) — применяется. Наложения
///    (picture-in-picture) — применяются с масштабом и позицией (без
///    поворота).
/// 2. Ключевые кадры (KeyframeEntity) нигде в UI ещё не создаются, поэтому
///    и не обрабатываются здесь.
/// 3. `enableAiUpscale`/`enableSmartHdr` — визуальные тумблеры без
///    реального эффекта (нет ИИ-апскейла/HDR-конвейера).
/// 4. Не тестировалось на реальном устройстве — команды построены по
///    задокументированному синтаксису FFmpeg, но перед продакшеном нужно
///    прогнать реальный экспорт и прислать лог, если что-то упадёт
///    (session.getLogs() выводится в текст исключения).
class FfmpegExportEngine implements VideoExportEngine {
  const FfmpegExportEngine();

  static const String _videoCodec = 'libvpx-vp9';
  static const String _audioCodec = 'aac';
  static const _uuid = Uuid();

  @override
  Future<File> render({
    required EditorTimelineEntity timeline,
    required ProjectFormat format,
    required ExportSettings settings,
    required void Function(double progress) onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final workDir = Directory('${tempDir.path}/base_export_${_uuid.v4()}')..createSync(recursive: true);

    try {
      final canvas = _resolveCanvasSize(settings.quality.height, format.aspectRatio);
      final totalDurationMs = timeline.totalDurationMs.clamp(1, 1 << 31);

      onProgress(0.02);

      // --- Этап 1: нормализация каждого клипа под размер холста ---------
      final segmentFiles = <File>[];
      var processedMs = 0;
      for (final clip in timeline.clips) {
        final localFile = await _ensureLocalFile(clip.displayPath, workDir, 'clip_${clip.id}');
        final segment = File('${workDir.path}/seg_${clip.order}_${clip.id}.mp4');

        await _processClip(
          clip: clip,
          input: localFile,
          output: segment,
          canvas: canvas,
          fps: settings.frameRate.value,
          bitrateMbps: settings.bitrateMbps,
          onProgress: (p) {
            final localMs = (p * clip.durationMs).round();
            onProgress(0.05 + 0.45 * ((processedMs + localMs) / totalDurationMs));
          },
        );

        segmentFiles.add(segment);
        processedMs += clip.durationMs;
      }

      if (segmentFiles.isEmpty) {
        throw StateError('В проекте нет ни одного клипа — нечего экспортировать.');
      }

      onProgress(0.5);

      // --- Этап 2: склейка сегментов -------------------------------------
      var currentOutput = File('${workDir.path}/concat.mp4');
      await _concatSegments(segmentFiles, currentOutput);
      onProgress(0.6);

      // --- Этап 3: наложения (picture-in-picture) -------------------------
      final sortedOverlays = [...timeline.overlays]..sort((a, b) => a.order.compareTo(b.order));
      for (final overlay in sortedOverlays) {
        final overlayFile = await _ensureLocalFile(overlay.displayPath, workDir, 'overlay_${overlay.id}');
        final next = File('${workDir.path}/ov_${overlay.id}.mp4');
        await _applyOverlay(base: currentOutput, overlay: overlay, overlayFile: overlayFile, canvas: canvas, output: next);
        currentOutput = next;
      }
      onProgress(0.75);

      // --- Этап 4: текст (drawtext) ---------------------------------------
      if (timeline.textOverlays.isNotEmpty) {
        final next = File('${workDir.path}/texted.mp4');
        await _applyText(base: currentOutput, texts: timeline.textOverlays, canvas: canvas, output: next);
        currentOutput = next;
      }
      onProgress(0.85);

      // --- Этап 5: пользовательские аудиодорожки (микс) -------------------
      if (timeline.audioTracks.isNotEmpty) {
        final audioFiles = <File>[];
        for (final track in timeline.audioTracks) {
          audioFiles.add(await _ensureLocalFile(track.displayPath, workDir, 'audio_${track.id}'));
        }
        final next = File('${workDir.path}/mixed.mp4');
        await _mixAudio(base: currentOutput, tracks: timeline.audioTracks, files: audioFiles, output: next);
        currentOutput = next;
      }
      onProgress(0.95);

      // --- Финал: копируем результат в постоянное расположение ------------
      final outputsDir = await getApplicationDocumentsDirectory();
      final finalFile = File('${outputsDir.path}/base_export_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await currentOutput.copy(finalFile.path);

      onProgress(1.0);
      return finalFile;
    } finally {
      // Чистим все промежуточные файлы независимо от исхода.
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
    }
  }

  // -------------------------------------------------------------------
  // Разрешение холста
  // -------------------------------------------------------------------

  /// [refHeight] — "уровень" разрешения из ExportQuality (720/1080/...),
  /// трактуется как размер КОРОТКОЙ стороны кадра, независимо от того,
  /// портретный проект или альбомный — это соответствует бытовому
  /// смыслу "720p"/"1080p" для видео любой ориентации.
  (int width, int height) _resolveCanvasSize(int refHeight, double aspectRatio) {
    int w, h;
    if (aspectRatio >= 1) {
      h = refHeight;
      w = (refHeight * aspectRatio).round();
    } else {
      w = refHeight;
      h = (refHeight / aspectRatio).round();
    }
    // H.264/VP9 требуют чётные ширину/высоту.
    if (w.isOdd) w += 1;
    if (h.isOdd) h += 1;
    return (w, h);
  }

  // -------------------------------------------------------------------
  // Подготовка локальных файлов (скачивание remoteUrl при отсутствии
  // localPath — например, если клип открыт с другого устройства)
  // -------------------------------------------------------------------

  Future<File> _ensureLocalFile(String? pathOrUrl, Directory workDir, String name) async {
    if (pathOrUrl == null) {
      throw StateError('У элемента "$name" нет ни локального файла, ни remoteUrl.');
    }
    if (!pathOrUrl.startsWith('http')) {
      return File(pathOrUrl);
    }

    final extension = pathOrUrl.split('.').last.split('?').first;
    final dest = File('${workDir.path}/$name.$extension');
    final request = await HttpClient().getUrl(Uri.parse(pathOrUrl));
    final response = await request.close();
    await response.pipe(dest.openWrite());
    return dest;
  }

  // -------------------------------------------------------------------
  // Этап 1: нормализация клипа
  // -------------------------------------------------------------------

  Future<void> _processClip({
    required TimelineClipEntity clip,
    required File input,
    required File output,
    required (int width, int height) canvas,
    required int fps,
    required int bitrateMbps,
    required void Function(double progress) onProgress,
  }) async {
    final (cw, ch) = canvas;
    final t = clip.transform;
    final cropW = (t.cropRight - t.cropLeft).clamp(0.05, 1.0);
    final cropH = (t.cropBottom - t.cropTop).clamp(0.05, 1.0);

    // cover-fit в холст, затем "зум" в прямоугольник кадрирования —
    // см. комментарий в классе про то, что сам жест-трансформ (scale/
    // rotation/dx/dy) базового клипа при экспорте пока не применяется.
    final videoFilter = 'scale=w=$cw:h=$ch:force_original_aspect_ratio=increase,'
        'crop=$cw:$ch,'
        'crop=w=${(cw * cropW).round()}:h=${(ch * cropH).round()}:x=${(cw * t.cropLeft).round()}:y=${(ch * t.cropTop).round()},'
        'scale=$cw:$ch,'
        'setpts=PTS/${clip.speed},fps=$fps';

    final effectiveVolume = clip.isMuted ? 0.0 : clip.volume;
    final audioFilter = 'volume=$effectiveVolume,atempo=${clip.speed.clamp(0.5, 2.0)}';

    final buffer = StringBuffer('-y ');
    if (clip.type == ClipType.photo) {
      buffer.write('-loop 1 -t ${(clip.durationMs / 1000).toStringAsFixed(3)} -i "${input.path}" ');
      buffer.write('-vf "$videoFilter" -an ');
    } else {
      final startSec = (clip.trimStartMs / 1000).toStringAsFixed(3);
      final endSec = (clip.trimEndMs / 1000).toStringAsFixed(3);
      buffer.write('-ss $startSec -to $endSec -i "${input.path}" ');
      buffer.write('-vf "$videoFilter" -filter:a "$audioFilter" -c:a $_audioCodec ');
    }
    buffer.write('-c:v $_videoCodec -b:v ${bitrateMbps}M -pix_fmt yuv420p "${output.path}"');

    await _run(buffer.toString(), totalDurationMs: clip.durationMs, onProgress: onProgress);
  }

  // -------------------------------------------------------------------
  // Этап 2: склейка (concat demuxer — все сегменты уже в одном
  // кодеке/разрешении/fps, поэтому склейка идёт без перекодирования)
  // -------------------------------------------------------------------

  Future<void> _concatSegments(List<File> segments, File output) async {
    final listFile = File('${output.parent.path}/concat_list.txt');
    final content = segments.map((f) => "file '${f.path.replaceAll("'", "'\\''")}'").join('\n');
    await listFile.writeAsString(content);

    final command = '-y -f concat -safe 0 -i "${listFile.path}" -c copy "${output.path}"';
    await _run(command, totalDurationMs: 1, onProgress: (_) {});
  }

  // -------------------------------------------------------------------
  // Этап 3: наложение picture-in-picture (масштаб + позиция; без поворота
  // — см. ограничения класса)
  // -------------------------------------------------------------------

  Future<void> _applyOverlay({
    required File base,
    required MediaOverlayEntity overlay,
    required File overlayFile,
    required (int width, int height) canvas,
    required File output,
  }) async {
    final (cw, ch) = canvas;
    final spriteW = (cw * 0.4 * overlay.transform.scale).round();
    final x = '(($cw-w)/2)+${(overlay.transform.dx * cw).round()}';
    final y = '(($ch-h)/2)+${(overlay.transform.dy * ch).round()}';

    final inputPrefix = overlay.type == ClipType.video ? '-stream_loop -1 ' : '-loop 1 ';
    final filter = '[1:v]scale=$spriteW:-1,format=yuva420p,colorchannelmixer=aa=${overlay.opacity}[ov];'
        '[0:v][ov]overlay=x=$x:y=$y:shortest=1[outv]';

    final command = '-y -i "${base.path}" $inputPrefix-i "${overlayFile.path}" '
        '-filter_complex "$filter" -map "[outv]" -map 0:a? '
        '-c:v $_videoCodec -c:a copy -shortest "${output.path}"';

    await _run(command, totalDurationMs: 1, onProgress: (_) {});
  }

  // -------------------------------------------------------------------
  // Этап 4: текст (drawtext) — все текстовые слои показываются в течение
  // всего видео (см. TextOverlayEntity — у него нет привязки ко времени,
  // это соответствует текущему поведению живого предпросмотра)
  // -------------------------------------------------------------------

  Future<void> _applyText({
    required File base,
    required List<TextOverlayEntity> texts,
    required (int width, int height) canvas,
    required File output,
  }) async {
    final (cw, ch) = canvas;
    final filters = texts.map((t) {
      final realFontSize = (t.fontSize * (cw / TextOverlayEntity.fontSizeReferenceCanvasWidth)).round();
      final hexColor = _colorToFfmpegHex(t.color);
      final x = '(w-text_w)/2+${(t.dx * cw).round()}';
      final y = '(h-text_h)/2+${(t.dy * ch).round()}';
      return "drawtext=text='${_escapeDrawText(t.text)}':fontcolor=$hexColor:fontsize=$realFontSize:x=$x:y=$y";
    }).join(',');

    final command = '-y -i "${base.path}" -vf "$filters" -c:v $_videoCodec -c:a copy "${output.path}"';
    await _run(command, totalDurationMs: 1, onProgress: (_) {});
  }

  String _escapeDrawText(String text) {
    return text.replaceAll('\\', r'\\').replaceAll(':', r'\:').replaceAll("'", r"\'").replaceAll('%', r'\%');
  }

  String _colorToFfmpegHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '0x$r$g$b';
  }

  // -------------------------------------------------------------------
  // Этап 5: микс пользовательских аудиодорожек с уже имеющимся звуком
  // (duration=first — итоговая длительность равна длительности видео;
  // более короткие дорожки дополняются тишиной, более длинные обрезаются)
  // -------------------------------------------------------------------

  Future<void> _mixAudio({
    required File base,
    required List<AudioTrackEntity> tracks,
    required List<File> files,
    required File output,
  }) async {
    final inputs = StringBuffer('-i "${base.path}" ');
    for (final f in files) {
      inputs.write('-i "${f.path}" ');
    }

    final filterParts = <String>[];
    final labels = <String>['0:a'];
    for (var i = 0; i < tracks.length; i++) {
      final label = 'a${i + 1}';
      filterParts.add('[${i + 1}:a]volume=${tracks[i].volume}[$label]');
      labels.add(label);
    }
    filterParts.add('${labels.map((l) => '[$l]').join()}amix=inputs=${labels.length}:duration=first:dropout_transition=0[aout]');

    final command = '-y $inputs-filter_complex "${filterParts.join(';')}" '
        '-map 0:v -map "[aout]" -c:v copy -c:a $_audioCodec "${output.path}"';

    await _run(command, totalDurationMs: 1, onProgress: (_) {});
  }

  // -------------------------------------------------------------------
  // Запуск ffmpeg с прогрессом и понятной ошибкой при неудаче
  // -------------------------------------------------------------------

  Future<void> _run(
    String command, {
    required int totalDurationMs,
    required void Function(double progress) onProgress,
  }) async {
    final completer = Completer<void>();

    await FFmpegKit.executeAsync(
      command,
      (FFmpegSession session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          completer.complete();
        } else {
          final output = await session.getOutput();
          completer.completeError(
            StateError('Команда FFmpeg завершилась с ошибкой (код: $returnCode).\n'
                'Команда: $command\n'
                'Вывод FFmpeg:\n$output'),
          );
        }
      },
      null,
      (Statistics statistics) {
        final progress = (statistics.getTime() / totalDurationMs).clamp(0.0, 1.0);
        onProgress(progress.isNaN ? 0 : progress);
      },
    );

    return completer.future;
  }
}
