import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppTextfield extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  const AppTextfield(
      {super.key,
      required this.hintText,
      required this.controller,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: TextField(
        onChanged: (value) => onChanged,
        controller: controller,
        cursorColor: AppColors.forest,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.hintInputText,
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: AppColors.turquiose, width: 3),
          ),
        ),
      ),
    );
  }
}
