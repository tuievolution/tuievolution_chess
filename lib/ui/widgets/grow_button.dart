import 'package:flutter/material.dart';
import '../../core/theme.dart';

enum GrowButtonType { primary, secondary, outline }

class GrowButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final GrowButtonType type;
  final IconData? icon;
  final double width;

  const GrowButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = GrowButtonType.primary,
    this.icon,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (type) {
      case GrowButtonType.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.black;
        break;
      case GrowButtonType.secondary:
        backgroundColor = AppColors.surface(context);
        textColor = AppColors.textPrimary(context);
        break;
      case GrowButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.textPrimary(context);
        borderSide = BorderSide(color: AppColors.border(context), width: 1);
        break;
    }

    return SizedBox(
      width: width,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderSide,
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
