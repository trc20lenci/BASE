import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../project/domain/entities/project_format.dart';
import '../../../project/presentation/providers/project_providers.dart';
import '../../domain/entities/clip_type.dart';
import '../providers/editor_controller.dart';

/// Экран подбора медиа при создании нового видео — точно по референсному
/// макету: фильтры "Все/Видео/Фото", сетка фото и видео из галереи
/// устройства с множественным выбором, кнопка-стрелка внизу справа.
///
/// Дополнительно (сверх макета, но по требованию исходного ТЗ) добавлена
/// строка выбора формата проекта (16:9/9:16/1:1/4:5), которую макет не
/// показывает явно, но формат обязателен по ТЗ — поэтому он есть здесь,
/// компактной строкой чипов, не нарушая общую компоновку экрана.
class MediaPickerPage extends ConsumerStatefulWidget {
  const MediaPickerPage({super.key});

  @override
  ConsumerState<MediaPickerPage> createState() => _MediaPickerPageState();
}

enum _MediaFilter { all, video, photo }

class _MediaPickerPageState extends ConsumerState<MediaPickerPage> {
  _MediaFilter _filter = _MediaFilter.all;
  ProjectFormat _format = ProjectFormat.ratio9x16;
  final List<AssetEntity> _selected = [];

  List<AssetEntity> _allAssets = [];
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth && !permission.hasAccess) {
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
    );
    if (paths.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final assets = await paths.first.getAssetListPaged(page: 0, size: 300);
    if (!mounted) return;
    setState(() {
      _allAssets = assets;
      _isLoading = false;
    });
  }

  List<AssetEntity> get _filteredAssets {
    switch (_filter) {
      case _MediaFilter.all:
        return _allAssets;
      case _MediaFilter.video:
        return _allAssets.where((a) => a.type == AssetType.video).toList();
      case _MediaFilter.photo:
        return _allAssets.where((a) => a.type == AssetType.image).toList();
    }
  }

  void _toggle(AssetEntity asset) {
    setState(() {
      if (_selected.contains(asset)) {
        _selected.remove(asset);
      } else {
        _selected.add(asset);
      }
    });
  }

  Future<void> _handleConfirm() async {
    if (_selected.isEmpty) return;
    final userId = ref.read(authStateChangesProvider).value?.id;
    if (userId == null) return;

    setState(() => _isCreating = true);
    try {
      final project = await ref.read(createProjectUseCaseProvider).call(
            ownerId: userId,
            title: 'Новый проект',
            format: _format,
          );

      final params = EditorControllerParams(projectId: project.id, ownerId: userId);
      final controller = ref.read(editorControllerProvider(params).notifier);

      for (final asset in _selected) {
        final file = await asset.file;
        if (file == null) continue;
        final isVideo = asset.type == AssetType.video;
        await controller.addMediaClip(
          file: file,
          type: isVideo ? ClipType.video : ClipType.photo,
          sourceDurationMs: isVideo ? asset.videoDuration.inMilliseconds : 3000,
        );
      }

      if (mounted) {
        context.pushReplacement('${RouteNames.editor}/${project.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось создать проект: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Spacer(),
                  Text('${_selected.length} выбрано', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                children: [
                  _FilterChip(label: 'Все', selected: _filter == _MediaFilter.all, onTap: () => setState(() => _filter = _MediaFilter.all)),
                  const SizedBox(width: AppSizes.sm),
                  _FilterChip(label: 'Видео', selected: _filter == _MediaFilter.video, onTap: () => setState(() => _filter = _MediaFilter.video)),
                  const SizedBox(width: AppSizes.sm),
                  _FilterChip(label: 'Фото', selected: _filter == _MediaFilter.photo, onTap: () => setState(() => _filter = _MediaFilter.photo)),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ProjectFormat.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs),
                  itemBuilder: (context, index) {
                    final f = ProjectFormat.values[index];
                    return _FilterChip(label: f.label, selected: _format == f, onTap: () => setState(() => _format = f));
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _selected.isEmpty ? AppColors.textDisabled : AppColors.accent,
        onPressed: _selected.isEmpty || _isCreating ? null : _handleConfirm,
        child: _isCreating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.arrow_forward),
      ),
    );
  }

  Widget _buildGrid() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Text(
            'Нет доступа к галерее. Разрешите доступ к фото и видео в '
            'настройках устройства.',
            style: AppTextStyles.bodySecondary.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final assets = _filteredAssets;
    if (assets.isEmpty) {
      return Center(child: Text('Нет медиафайлов', style: AppTextStyles.bodySecondary.copyWith(color: Colors.white70)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        final selectedIndex = _selected.indexOf(asset);
        return _AssetThumb(
          asset: asset,
          selected: selectedIndex != -1,
          selectionNumber: selectedIndex == -1 ? null : selectedIndex + 1,
          onTap: () => _toggle(asset),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white12,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(color: selected ? Colors.black : Colors.white70, fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
        ),
      ),
    );
  }
}

class _AssetThumb extends StatelessWidget {
  final AssetEntity asset;
  final bool selected;
  final int? selectionNumber;
  final VoidCallback onTap;

  const _AssetThumb({required this.asset, required this.selected, required this.selectionNumber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const ColoredBox(color: Color(0xFF1A1A1A));
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            },
          ),
          if (asset.type == AssetType.video)
            Positioned(
              left: 4,
              bottom: 4,
              child: Row(
                children: [
                  const Icon(Icons.videocam, size: 14, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(_formatDuration(asset.videoDuration), style: const TextStyle(fontSize: 11, color: Colors.white)),
                ],
              ),
            ),
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent : Colors.black45,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Text('$selectionNumber', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700))
                  : null,
            ),
          ),
          if (selected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(decoration: BoxDecoration(border: Border.all(color: AppColors.accent, width: 2))),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
