import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/error_handler.dart';

class ErrorSnackbar {
  ErrorSnackbar._();

  static void show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error.type == ErrorType.network
                    ? Icons.wifi_off
                    : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      error.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      error.message,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 4),
          action: (error.isRetryable && onRetry != null)
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
        ),
      );
  }
}
