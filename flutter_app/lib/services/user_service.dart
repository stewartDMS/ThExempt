import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../utils/base64_utils.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

class UserService {
  static final _supabase = Supabase.instance.client;

  // Clear user session (logout)
  static Future<void> logout() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  // Get user profile by ID
  static Future<UserProfile> getProfile(String userId) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('profiles')
              .select()
              .eq('id', userId)
              .single()
              .timeout(const Duration(seconds: 10));
          return UserProfile.fromJson(response);
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  // Update own profile
  static Future<UserProfile> updateProfile({
    required String name,
    String? username,
    String? bio,
    String? location,
    String? githubUrl,
    String? linkedinUrl,
    String? websiteUrl,
    String? availabilityStatus,
    List<String>? skills,
    String? avatarUrl,
    String? coverImageUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{'name': name};
    if (username != null) body['username'] = username;
    if (bio != null) body['bio'] = bio;
    if (location != null) body['location'] = location;
    if (githubUrl != null) body['github_url'] = githubUrl;
    if (linkedinUrl != null) body['linkedin_url'] = linkedinUrl;
    if (websiteUrl != null) body['website_url'] = websiteUrl;
    if (availabilityStatus != null) {
      body['availability_status'] = availabilityStatus;
    }
    if (skills != null) body['skills'] = skills;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (coverImageUrl != null) body['cover_image_url'] = coverImageUrl;

    final response = await _supabase
        .from('profiles')
        .update(body)
        .eq('id', userId)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  // Upload avatar to Supabase Storage
  static Future<String> uploadAvatar({
    required String base64Image,
    required String fileName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final bytes = base64DataUrlToBytes(base64Image);
    final path = '$userId/$fileName';

    await _supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final avatarUrl = _supabase.storage.from('avatars').getPublicUrl(path);

    // Update profile with new avatar URL
    await _supabase
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);

    return avatarUrl;
  }

  // Get user stats
  static Future<Map<String, int>> getUserStats(String userId) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final profileResponse = await _supabase
              .from('profiles')
              .select('profile_views, reputation_points')
              .eq('id', userId)
              .single()
              .timeout(const Duration(seconds: 10));

          final projectsResponse = await _supabase
              .from('projects')
              .select('id')
              .eq('owner_id', userId)
              .timeout(const Duration(seconds: 10));

          return {
            'total_projects': projectsResponse.length,
            'total_likes':
                (profileResponse['reputation_points'] as num?)?.toInt() ?? 0,
            'profile_views':
                (profileResponse['profile_views'] as num?)?.toInt() ?? 0,
          };
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }
}

