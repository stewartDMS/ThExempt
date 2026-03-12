import 'package:flutter/foundation.dart';

import 'error_handler.dart';

class RetryHelper {
  RetryHelper._();

  /// Executes [operation], retrying on retryable errors with exponential
  /// backoff up to [maxAttempts] times.
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffFactor = 2.0,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;
      try {
        return await operation();
      } catch (error) {
        if (attempt >= maxAttempts) rethrow;

        final appError = ErrorHandler.handleError(error);
        if (!appError.isRetryable) rethrow;

        debugPrint(
          '[RetryHelper] Attempt $attempt/$maxAttempts failed. '
          'Retrying in ${delay.inSeconds}s…',
        );
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffFactor).round(),
        );
      }
    }
  }
}
