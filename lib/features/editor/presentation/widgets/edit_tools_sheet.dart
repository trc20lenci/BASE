import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/clip_type.dart';
import '../../domain/entities/timeline_clip_entity.dart';

/// Панель "Изменить" для выбранного клипа — повторяет референсный макет:
/// горизонтальный ряд иконок (Разделить/Громкость/Анимации/Эффекты/
/// Удалить/Скорость) со стрелкой "назад" слева.
///
/// Реально работают: Разделить, Громкость (перетаскиваемая полоса),
/// Удалить, Скорость (набор чипов). Анимации и Эффекты — заглушки
/// "Скоро", это отдельные крупные фичи вне текущего этапа.
class EditToolsSheet extends StatefulWidget {
  final TimelineClipEntity clip;
  final VoidCallback onSplit;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onDelete;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onSoon;
  final VoidCallback onClose;

  const EditToolsSheet({
    super.key,
    required this.clip,
    required this.onSplit,
    required this.onVolumeChanged,
    required this.onDelete,
    required this.onSpeedChanged,
    required this.onSoon,
    required this.onClose,
  });

  @override
  State<EditToolsSheet> createState() => _EditToolsSheetState();
}

enum _SubView { main, volume, speed }

class _EditToolsSheetState extends State<EditToolsSheet> {
  _SubView _view = _SubView.main;
  late double _volume = widget.clip.volume;
  late double _speed = widget.clip.speed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      child: SafeArea(
        top: false,
        child: switch (_view) {
          _SubView.main => _buildMainRow(),
          _SubView.volume => _buildVolumeView(),
          _SubView.speed => _buildSpeedView(),
        },
      ),
    );
  }

  Widget _buildMainRow() {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.chevron_left, color: Colors.white)),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _ToolIcon(icon: Icons.vertical_align_center, label: 'Разделить', onTap: () {
                  widget.onSplit();
                  Navigator.pop(context);
                }),
                if (widget.clip.type == ClipType.video)
                  _ToolIcon(icon: Icons.volume_up_outlined, label: 'Громкость', onTap: () => setState(() => _view = _SubView.volume)),
                _ToolIcon(icon: Icons.movie_filter_outlined, label: 'Анимации', onTap: widget.onSoon),
                _ToolIcon(icon: Icons.auto_awesome_outlined, label: 'Эффекты', onTap: widget.onSoon),
                _ToolIcon(icon: Icons.delete_outline, label: 'Удалить', color: AppColors.error, onTap: () {
                  widget.onDelete();
                  Navigator.pop(context);
                }),
                if (widget.clip.type == ClipType.video)
                  _ToolIcon(icon: Icons.speed_outlined, label: 'Скорость', onTap: () => setState(() => _view = _SubView.speed)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _view = _SubView.main), icon: const Icon(Icons.chevron_left, color: Colors.white)),
              const Text('Громкость клипа', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(_volume * 100).round()}%', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.volume_mute, color: Colors.white38, size: 18),
              Expanded(
                child: Slider(
                  min: 0,
                  max: 1,
                  value: _volume,
                  activeColor: AppColors.accent,
                  inactiveColor: Colors.white24,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    widget.onVolumeChanged(v);
                  },
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white38, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedView() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _view = _SubView.main), icon: const Icon(Icons.chevron_left, color: Colors.white)),
              const Text('Скорость', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: speeds.map((s) {
              final selected = s == _speed;
              return ChoiceChip(
                label: Text('${s}x'),
                selected: selected,
                onSelected: (_) {
                  setState(() => _speed = s);
                  widget.onSpeedChanged(s);
                },
                backgroundColor: const Color(0xFF262626),
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ToolIcon({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color ?? Colors.white70)),
          ],
        ),
      ),
    );
  }
}
