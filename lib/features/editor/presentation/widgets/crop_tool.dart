import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/canvas_transform.dart';
import '../../domain/entities/clip_type.dart';
import '../../domain/entities/timeline_clip_entity.dart';

/// Полноэкранный инструмент "Кадрирование". Пользователь двигает края
/// прямоугольника поверх превью клипа, результат — нормализованный
/// прямоугольник (0..1), который применяется как crop в CanvasTransform.
///
/// Показывается через Navigator.push (не bottom sheet), т.к. кадрирование
/// требует точности и максимум экранного пространства для жестов.
class CropTool extends StatefulWidget {
  final TimelineClipEntity clip;

  const CropTool({super.key, required this.clip});

  static Future<CanvasTransform?> show(BuildContext context, TimelineClipEntity clip) {
    return Navigator.of(context).push<CanvasTransform>(
      MaterialPageRoute(builder: (_) => CropTool(clip: clip), fullscreenDialog: true),
    );
  }

  @override
  State<CropTool> createState() => _CropToolState();
}

class _CropToolState extends State<CropTool> {
  late Rect _cropRect; // в нормализованных координатах 0..1

  @override
  void initState() {
    super.initState();
    final t = widget.clip.transform;
    _cropRect = Rect.fromLTRB(t.cropLeft, t.cropTop, t.cropRight, t.cropBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Кадрирование'),
        actions: [
          TextButton(
            onPressed: () {
              final t = widget.clip.transform.copyWith(
                cropLeft: _cropRect.left,
                cropTop: _cropRect.top,
                cropRight: _cropRect.right,
                cropBottom: _cropRect.bottom,
              );
              Navigator.pop(context, t);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(
              constraints.maxWidth - AppSizes.xl,
              constraints.maxHeight - AppSizes.xl,
            );
            return SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMedia(),
                  _CropGrid(
                    rect: _cropRect,
                    canvasSize: size,
                    onChanged: (r) => setState(() => _cropRect = r),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (widget.clip.type == ClipType.photo) {
      final path = widget.clip.localPath;
      if (path != null) return Image.file(File(path), fit: BoxFit.contain);
      if (widget.clip.remoteUrl != null) {
        return Image.network(widget.clip.remoteUrl!, fit: BoxFit.contain);
      }
    }
    // Для видео показываем плейсхолдер — покадровое превью не входит в
    // MVP; кадрирование видео применяется к результату так же, как для
    // фото, просто без покадрового предпросмотра в этом инструменте.
    return const Center(
      child: Icon(Icons.videocam_outlined, color: Colors.white30, size: 48),
    );
  }
}

/// Прямоугольник кадрирования с четырьмя угловыми маркерами.
class _CropGrid extends StatelessWidget {
  final Rect rect; // нормализованный 0..1
  final Size canvasSize;
  final ValueChanged<Rect> onChanged;

  const _CropGrid({required this.rect, required this.canvasSize, required this.onChanged});

  static const double _handleSize = 28;
  static const double _minSize = 0.15;

  @override
  Widget build(BuildContext context) {
    final pxRect = Rect.fromLTRB(
      rect.left * canvasSize.width,
      rect.top * canvasSize.height,
      rect.right * canvasSize.width,
      rect.bottom * canvasSize.height,
    );

    return Stack(
      children: [
        // Затемнение вне области кадрирования.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _CropShadePainter(pxRect)),
          ),
        ),
        Positioned(
          left: pxRect.left,
          top: pxRect.top,
          width: pxRect.width,
          height: pxRect.height,
          child: GestureDetector(
            onPanUpdate: (details) => _move(details.delta),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
            ),
          ),
        ),
        _handle(pxRect.topLeft, (delta) => _resize(left: delta.dx, top: delta.dy)),
        _handle(pxRect.topRight, (delta) => _resize(right: delta.dx, top: delta.dy)),
        _handle(pxRect.bottomLeft, (delta) => _resize(left: delta.dx, bottom: delta.dy)),
        _handle(pxRect.bottomRight, (delta) => _resize(right: delta.dx, bottom: delta.dy)),
      ],
    );
  }

  Widget _handle(Offset position, ValueChanged<Offset> onDrag) {
    return Positioned(
      left: position.dx - _handleSize / 2,
      top: position.dy - _handleSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: _handleSize,
          height: _handleSize,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  void _move(Offset delta) {
    final dxN = delta.dx / canvasSize.width;
    final dyN = delta.dy / canvasSize.height;
    var newRect = rect.shift(Offset(dxN, dyN));
    // Не даём прямоугольнику выйти за пределы холста.
    if (newRect.left < 0) newRect = newRect.shift(Offset(-newRect.left, 0));
    if (newRect.top < 0) newRect = newRect.shift(Offset(0, -newRect.top));
    if (newRect.right > 1) newRect = newRect.shift(Offset(1 - newRect.right, 0));
    if (newRect.bottom > 1) newRect = newRect.shift(Offset(0, 1 - newRect.bottom));
    onChanged(newRect);
  }

  void _resize({double? left, double? top, double? right, double? bottom}) {
    double l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    if (left != null) l = (l + left / canvasSize.width).clamp(0.0, r - _minSize);
    if (top != null) t = (t + top / canvasSize.height).clamp(0.0, b - _minSize);
    if (right != null) r = (r + right / canvasSize.width).clamp(l + _minSize, 1.0);
    if (bottom != null) b = (b + bottom / canvasSize.height).clamp(t + _minSize, 1.0);
    onChanged(Rect.fromLTRB(l, t, r, b));
  }
}

class _CropShadePainter extends CustomPainter {
  final Rect cropRect;

  _CropShadePainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRect(cropRect);
    final shade = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(shade, Paint()..color = AppColors.overlay);
  }

  @override
  bool shouldRepaint(covariant _CropShadePainter oldDelegate) =>
      oldDelegate.cropRect != cropRect;
}
