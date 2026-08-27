import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../editor/presentation/providers/editor_controller.dart';
import '../../domain/entities/export_progress.dart';
import '../../domain/entities/export_quality.dart';
import '../providers/export_providers.dart';

/// Экран экспорта: выбор качества (720p/1080p), рендер и сохранение в
/// галерею устройства. Использует уже сохранённый таймлайн проекта
/// (загружается через тот же editorControllerProvider, что и редактор,
/// чтобы не читать Firestore второй раз).
class ExportPage extends ConsumerStatefulWidget {
  final String projectId;

  const ExportPage({super.key, required this.projectId});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  ExportQuality _quality = ExportQuality.p1080;

  Future<void> _handleExport(EditorControllerParams params) async {
    final timeline = ref.read(editorControllerProvider(params)).timeline;
    await ref
        .read(exportControllerProvider.notifier)
        .exportAndSave(timeline: timeline, quality: _quality);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateChangesProvider).value?.id;
    final exportState = ref.watch(exportControllerProvider);

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final params = EditorControllerParams(projectId: widget.projectId, ownerId: userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Экспорт')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Качество видео', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              children: ExportQuality.values.map((q) {
                final selected = q == _quality;
                final isBusy = exportState.status == ExportStatus.rendering ||
                    exportState.status == ExportStatus.savingToGallery;
                return ChoiceChip(
                  label: Text(q.label),
                  selected: selected,
                  onSelected: isBusy ? null : (_) => setState(() => _quality = q),
                  backgroundColor: AppColors.surfaceElevated,
                  selectedColor: AppColors.accent,
                  labelStyle: AppTextStyles.body.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.xl),
            _buildStatus(exportState),
            const Spacer(),
            AppButton(
              label: _buttonLabel(exportState),
              isLoading: exportState.status == ExportStatus.rendering ||
                  exportState.status == ExportStatus.savingToGallery,
              onPressed: exportState.status == ExportStatus.rendering ||
                      exportState.status == ExportStatus.savingToGallery
                  ? null
                  : () => _handleExport(params),
            ),
          ],
        ),
      ),
    );
  }

  String _buttonLabel(ExportProgress state) {
    switch (state.status) {
      case ExportStatus.done:
        return 'Экспортировать снова';
      case ExportStatus.error:
        return 'Повторить экспорт';
      default:
        return 'Экспортировать в ${_quality.label}';
    }
  }

  Widget _buildStatus(ExportProgress state) {
    switch (state.status) {
      case ExportStatus.idle:
        return const SizedBox.shrink();
      case ExportStatus.rendering:
        return _StatusRow(
          icon: Icons.movie_creation_outlined,
          text: 'Рендер видео… ${(state.progress * 100).toStringAsFixed(0)}%',
          color: AppColors.textSecondary,
        );
      case ExportStatus.savingToGallery:
        return const _StatusRow(
          icon: Icons.download_outlined,
          text: 'Сохранение в галерею…',
          color: AppColors.textSecondary,
        );
      case ExportStatus.done:
        return const _StatusRow(
          icon: Icons.check_circle_outline,
          text: 'Видео сохранено в галерею',
          color: AppColors.success,
        );
      case ExportStatus.error:
        return _StatusRow(
          icon: Icons.error_outline,
          text: state.errorMessage ?? 'Не удалось экспортировать видео',
          color: AppColors.error,
        );
    }
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSizes.sm),
        Expanded(child: Text(text, style: AppTextStyles.bodySecondary.copyWith(color: color))),
      ],
    );
  }
}
