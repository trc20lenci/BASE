/// Формат проекта, выбирается при создании (ТЗ раздел "Создание проекта").
enum ProjectFormat {
  ratio16x9('16:9', 16 / 9),
  ratio9x16('9:16', 9 / 16),
  ratio1x1('1:1', 1),
  ratio4x5('4:5', 4 / 5);

  final String label;
  final double aspectRatio;

  const ProjectFormat(this.label, this.aspectRatio);

  static ProjectFormat fromLabel(String label) {
    return ProjectFormat.values.firstWhere(
      (f) => f.label == label,
      orElse: () => ProjectFormat.ratio9x16,
    );
  }
}
