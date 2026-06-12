import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading  = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: isOutlined
          ? OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      )
          : DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : AppColors.primaryGradient,
          color: isLoading ? AppColors.textLight : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading ? [] : [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 0.3,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}