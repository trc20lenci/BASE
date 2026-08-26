import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/project_format.dart';
import '../providers/project_providers.dart';

/// Экран создания проекта: ввод названия и выбор формата
/// (16:9, 9:16, 1:1, 4:5). После создания сразу открывается редактор.
class CreateProjectPage extends ConsumerStatefulWidget {
  const CreateProjectPage({super.key});

  @override
  ConsumerState<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends ConsumerState<CreateProjectPage> {
  final _titleController = TextEditingController(text: 'Новый проект');
  ProjectFormat _selectedFormat = ProjectFormat.ratio9x16;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    setState(() => _isCreating = true);
    try {
      final project = await ref.read(createProjectUseCaseProvider).call(
            ownerId: user.id,
            title: _titleController.text.trim().isEmpty
                ? 'Новый проект'
                : _titleController.text.trim(),
            format: _selectedFormat,
          );
      if (mounted) {
        context.pushReplacement('${RouteNames.editor}/${project.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось создать проект: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый проект')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(controller: _titleController, label: 'Название проекта'),
              const SizedBox(height: AppSizes.xl),
              Text('Формат', style: AppTextStyles.h3),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: ProjectFormat.values.map((format) {
                  final isSelected = format == _selectedFormat;
                  return ChoiceChip(
                    label: Text(format.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFormat = format),
                    backgroundColor: AppColors.surfaceElevated,
                    selectedColor: AppColors.accent,
                    labelStyle: AppTextStyles.body.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const Spacer(),
              AppButton(
                label: 'Создать и открыть редактор',
                isLoading: _isCreating,
                onPressed: _handleCreate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
