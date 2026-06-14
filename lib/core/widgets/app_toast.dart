import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

enum _ToastType { success, error, info }

void showSuccessToast(BuildContext context, String message) =>
    _show(context, message, _ToastType.success);

void showErrorToast(BuildContext context, String message) =>
    _show(context, message, _ToastType.error);

void showInfoToast(BuildContext context, String message) =>
    _show(context, message, _ToastType.info);

void _show(BuildContext context, String message, _ToastType type) {
  final (icon, bg, border, iconColor) = switch (type) {
    _ToastType.success => (
        Icons.check_circle_rounded,
        const Color(0xFFF0FDF4),
        const Color(0xFF059669),
        const Color(0xFF059669),
      ),
    _ToastType.error => (
        Icons.error_rounded,
        const Color(0xFFFFF1F1),
        const Color(0xFFEF4444),
        const Color(0xFFEF4444),
      ),
    _ToastType.info => (
        Icons.info_rounded,
        const Color(0xFFFFF7ED),
        const Color(0xFFFF7A00),
        const Color(0xFFFF7A00),
      ),
  };

  toastification.show(
    context: context,
    alignment: Alignment.topCenter,
    animationDuration: const Duration(milliseconds: 300),
    autoCloseDuration: const Duration(seconds: 3),
    showProgressBar: false,
    dragToClose: true,
    style: ToastificationStyle.flat,
    backgroundColor: bg,
    borderSide: BorderSide(color: border.withValues(alpha: 0.3)),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
    title: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    ),
  );
}
