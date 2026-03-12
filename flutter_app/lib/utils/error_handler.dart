import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ErrorType {
  network,
  auth,
  validation,
  notFound,
  server,
  timeout,
  unknown,
}

class AppError implements Exception {
  final String title;
  final String message;
  final String? technicalDetails;
  final ErrorType type;
  final bool isRetryable;

  const AppError({
    required this.title,
    required this.message,
    this.technicalDetails,
    required this.type,
    this.isRetryable = false,
  });

  @override
  String toString() => 'AppError(${type.name}): $title – $message';
}

class ErrorHandler {
  ErrorHandler._();

  static AppError handleError(dynamic error) {
    if (error is AppError) return error;

    if (error is SocketException) {
      return AppError(
        title: 'No Internet Connection',
        message: 'Please check your connection and try again.',
        type: ErrorType.network,
        isRetryable: true,
        technicalDetails: error.toString(),
      );
    }

    if (error is TimeoutException) {
      return AppError(
        title: 'Request Timed Out',
        message:
            'The server is taking too long to respond. Please try again.',
        type: ErrorType.timeout,
        isRetryable: true,
        technicalDetails: error.toString(),
      );
    }

    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }

    if (error is AuthException) {
      return _handleAuthError(error);
    }

    return AppError(
      title: 'Something Went Wrong',
      message: 'An unexpected error occurred. Please try again.',
      type: ErrorType.unknown,
      isRetryable: true,
      technicalDetails: error.toString(),
    );
  }

  static AppError _handlePostgrestError(PostgrestException error) {
    final statusCode = error.code;

    if (statusCode == '401' || statusCode == 'PGRST301') {
      return AppError(
        title: 'Unauthorized',
        message: 'Please log in again to continue.',
        type: ErrorType.auth,
        isRetryable: false,
        technicalDetails: error.toString(),
      );
    }

    if (statusCode == '404' || statusCode == 'PGRST116') {
      return AppError(
        title: 'Not Found',
        message: 'The requested resource could not be found.',
        type: ErrorType.notFound,
        isRetryable: false,
        technicalDetails: error.toString(),
      );
    }

    if (statusCode?.startsWith('5') ?? false) {
      return AppError(
        title: 'Server Error',
        message: 'Our servers are having issues. Please try again later.',
        type: ErrorType.server,
        isRetryable: true,
        technicalDetails: error.toString(),
      );
    }

    return AppError(
      title: 'Request Failed',
      message: error.message.isNotEmpty
          ? error.message
          : 'Something went wrong with your request.',
      type: ErrorType.unknown,
      isRetryable: true,
      technicalDetails: error.toString(),
    );
  }

  static AppError _handleAuthError(AuthException error) {
    return AppError(
      title: 'Authentication Error',
      message: error.message,
      type: ErrorType.auth,
      isRetryable: false,
      technicalDetails: error.toString(),
    );
  }

  /// Logs the technical details of an [AppError] in debug builds.
  static void log(AppError error) {
    debugPrint('[ErrorHandler] ${error.title}: ${error.technicalDetails}');
  }
}

/// Shared form field validators used across the app.
class AppValidators {
  AppValidators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }
}
