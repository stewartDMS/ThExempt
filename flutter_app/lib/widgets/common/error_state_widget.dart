import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/error_handler.dart';

class ErrorStateWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(
              _iconForType(error.type),
              size: 64,
              color: AppColors.error.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              error.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error.message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
              ),
              textAlign: TextAlign.center,
            ),
            if (error.isRetryable && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.timeout:
        return Icons.timer_off;
      case ErrorType.validation:
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }
}
