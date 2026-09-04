import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../editor/presentation/providers/editor_controller.dart';
import '../../domain/entities/export_progress.dart';
import '../../domain/entities/export_quality.dart';
import '../../domain/entities/export_settings.dart';
import '../providers/export_providers.dart';

/// Экран экспорта — верстка точно повторяет референсный макет: вкладки
/// Видео/GIF, "Ultra HD от ИИ" (заглушка-тумблер), слайдер разрешения с
/// premium-метками (диамант) на 1080p/2K-4K, слайдер частоты кадров,
/// слайдер битрейта, Smart HDR, строка "Водяной знак", ориентировочный
/// размер файла внизу.
///
/// Разрешения 1080p/2K-4K визуально заблокированы (как и вкладка
/// "Подписка" — см. предупреждение там же), т.к. реальной проверки
/// оплаты в проекте нет. Экспорт GIF, Ultra HD от ИИ и Smart HDR —
/// визуальные тумблеры без реального эффекта, т.к. сам движок рендера
/// ещё не подключён (см. VideoExportEngine).
class ExportPage extends ConsumerStatefulWidget {
  final String projectId;

  const ExportPage({super.key, required this.projectId});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  int _tab = 0; // 0 = видео, 1 = gif
  ExportQuality _quality = ExportQuality.p720;
  ExportFrameRate _frameRate = ExportFrameRate.fps30;
  double _bitrate = 5;
  bool _aiUpscale = false;
  bool _smartHdr = false;

  static const _qualitySteps = ExportQuality.values;
  static const _frameSteps = ExportFrameRate.values;
  static const _bitrateSteps = [5.0, 10.0, 20.0, 50.0, 100.0];

  void _soon() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скоро')));

  Future<void> _handleExport(EditorControllerParams params) async {
    final timeline = ref.read(editorControllerProvider(params)).timeline;
    final settings = ExportSettings(
      quality: _quality,
      frameRate: _frameRate,
      bitrateMbps: _bitrate.round(),
      enableAiUpscale: _aiUpscale,
      enableSmartHdr: _smartHdr,
    );
    await ref.read(exportControllerProvider.notifier).exportAndSave(timeline: timeline, settings: settings);
  }

  double get _estimatedSizeMb {
    // Грубая оценка "МБ ≈ битрейт(мбит/с) * длительность(с) / 8" — чисто
    // для отображения на экране, как в референсе; не участвует в реальном
    // рендере (движок рендера ещё не подключён).
    return (_bitrate * 12 / 8).clamp(1, 999);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateChangesProvider).value?.id;
    final exportState = ref.watch(exportControllerProvider);
    final isBusy = exportState.status == ExportStatus.rendering || exportState.status == ExportStatus.savingToGallery;

    if (userId == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    final params = EditorControllerParams(projectId: widget.projectId, ownerId: userId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
              child: Row(
                children: [
                  _TopTab(label: 'видео', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                  const SizedBox(width: AppSizes.lg),
                  _TopTab(label: 'GIF', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                  const Spacer(),
                  TextButton(
                    onPressed: _soon,
                    style: TextButton.styleFrom(backgroundColor: const Color(0xFF232323)),
                    child: const Text('AI UHD', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14C7C1), foregroundColor: Colors.black),
                    onPressed: isBusy ? null : () => _handleExport(params),
                    child: isBusy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Экспорт'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tab == 1
                  ? Center(child: Text('Экспорт в GIF — скоро', style: const TextStyle(color: Colors.white54)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.lg, AppSizes.md, AppSizes.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ToggleRow(
                            title: 'Ultra HD от ИИ',
                            badge: '1 генерация',
                            subtitle: 'Сделайте видео чётче и плавнее с помощью ИИ-улучшений',
                            trailing: 'Предпросмотр',
                            value: _aiUpscale,
                            onChanged: (v) => setState(() => _aiUpscale = v),
                            onTrailingTap: _soon,
                          ),
                          const SizedBox(height: AppSizes.xl),
                          const Text('Разрешение', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                          const SizedBox(height: AppSizes.xs),
                          const Text('Стандартное разрешение: используется в большинстве случаев', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          _StepSlider(
                            steps: _qualitySteps.length,
                            index: _qualitySteps.indexOf(_quality),
                            onChanged: (i) {
                              final q = _qualitySteps[i];
                              if (q.isPremium) {
                                _soon();
                                return;
                              }
                              setState(() => _quality = q);
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _qualitySteps
                                .map((q) => Text(
                                      q.label,
                                      style: TextStyle(color: q == _quality ? Colors.white : Colors.white38, fontSize: 12, fontWeight: q == _quality ? FontWeight.w700 : FontWeight.w400),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: AppSizes.xl),
                          const Text('Частота кадров', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                          const SizedBox(height: AppSizes.xs),
                          const Text('Плавное воспроизведение', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          _StepSlider(
                            steps: _frameSteps.length,
                            index: _frameSteps.indexOf(_frameRate),
                            onChanged: (i) => setState(() => _frameRate = _frameSteps[i]),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _frameSteps
                                .map((f) => Text('${f.value}', style: TextStyle(color: f == _frameRate ? Colors.white : Colors.white38, fontSize: 12)))
                                .toList(),
                          ),
                          const SizedBox(height: AppSizes.xl),
                          const Text('Битрейт (мбит/с)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                          const SizedBox(height: AppSizes.xs),
                          const Text('Рекомендовано для этого видео (5)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          _StepSlider(
                            steps: _bitrateSteps.length,
                            index: _bitrateSteps.indexOf(_bitrateSteps.firstWhere((b) => b == _bitrate, orElse: () => _bitrateSteps.first)),
                            onChanged: (i) => setState(() => _bitrate = _bitrateSteps[i]),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _bitrateSteps
                                .map((b) => Text('${b.round()}', style: TextStyle(color: b == _bitrate ? Colors.white : Colors.white38, fontSize: 12)))
                                .toList(),
                          ),
                          const SizedBox(height: AppSizes.xl),
                          _ToggleRow(
                            title: 'Smart HDR',
                            subtitle: 'Преобразует ваш клип в HDR-видео',
                            value: _smartHdr,
                            onChanged: (v) => setState(() => _smartHdr = v),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          InkWell(
                            onTap: _soon,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Водяной знак', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                                Row(children: [Text('Нет', style: TextStyle(color: Colors.white70)), Icon(Icons.chevron_right, color: Colors.white38)]),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white12, height: AppSizes.xl),
                          Center(
                            child: Text(
                              'Приблизительный размер файла: ${_estimatedSizeMb.toStringAsFixed(1)} МБ',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ),
                          if (exportState.status == ExportStatus.error) ...[
                            const SizedBox(height: AppSizes.sm),
                            Center(child: Text(exportState.errorMessage ?? 'Ошибка экспорта', style: const TextStyle(color: Colors.redAccent))),
                          ],
                          if (exportState.status == ExportStatus.done) ...[
                            const SizedBox(height: AppSizes.sm),
                            const Center(child: Text('Видео сохранено в галерею', style: TextStyle(color: Colors.greenAccent))),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white38, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          const SizedBox(height: 4),
          if (selected) Container(width: 24, height: 2, color: const Color(0xFF14C7C1)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String? badge;
  final String? subtitle;
  final String? trailing;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTrailingTap;

  const _ToggleRow({
    required this.title,
    this.badge,
    this.subtitle,
    this.trailing,
    required this.value,
    required this.onChanged,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  if (badge != null) ...[
                    const SizedBox(width: AppSizes.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF14C7C1), borderRadius: BorderRadius.circular(6)),
                      child: Text(badge!, style: const TextStyle(fontSize: 10, color: Colors.black)),
                    ),
                  ],
                ],
              ),
              if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: const TextStyle(color: Colors.white38, fontSize: 12))),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: InkWell(
                    onTap: onTrailingTap,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.play_circle_outline, size: 16, color: Color(0xFF14C7C1)),
                      const SizedBox(width: 4),
                      Text(trailing!, style: const TextStyle(color: Color(0xFF14C7C1), fontSize: 13)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF14C7C1)),
      ],
    );
  }
}

class _StepSlider extends StatelessWidget {
  final int steps;
  final int index;
  final ValueChanged<int> onChanged;

  const _StepSlider({required this.steps, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFF14C7C1),
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        overlayColor: const Color(0x2214C7C1),
        trackHeight: 3,
      ),
      child: Slider(
        min: 0,
        max: (steps - 1).toDouble(),
        divisions: steps - 1,
        value: index.clamp(0, steps - 1).toDouble(),
        onChanged: (v) => onChanged(v.round()),
      ),
    );
  }
}
