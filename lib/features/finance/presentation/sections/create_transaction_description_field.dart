import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class CreateTransactionDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool isPlan;

  const CreateTransactionDescriptionField({
    super.key,
    required this.controller,
    required this.isPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: controller,
        autofocus: isPlan,
        maxLines: 1,
        style: GoogleFonts.dmSans(fontSize: 14),
        decoration: InputDecoration(
          hintText: isPlan ? 'Name *' : 'Add a note…',
          hintStyle: GoogleFonts.dmSans(color: AppColors.textTertiary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
