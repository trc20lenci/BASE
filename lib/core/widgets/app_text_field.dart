import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: suffixIcon,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSizes.xs),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.sm),
            child: Text(errorText!, style: AppTextStyles.errorText),
          ),
        ],
      ],
    );
  }
}
