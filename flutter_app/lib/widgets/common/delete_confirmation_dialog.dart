import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A reusable confirmation dialog for destructive actions such as deleting
/// projects or discussions.
class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
  });

  /// Shows the confirmation dialog and returns `true` if the user confirmed,
  /// or `false` / `null` if they cancelled.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(title: title, message: message),
    );
  }

  /// Runs [action] while displaying a full-screen loading overlay,
  /// removing the overlay once [action] completes or throws.
  static Future<T> withLoadingOverlay<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    final loadingOverlay = OverlayEntry(
      builder: (_) => const ColoredBox(
        color: Colors.black26,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    Overlay.of(context).insert(loadingOverlay);
    try {
      return await action();
    } finally {
      loadingOverlay.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 14, color: AppColors.grey600),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.grey600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
