import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class UserService {
  static const String apiUrl = 'http://localhost:5000/api';

  // Clear user session (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  // Get user profile by ID
  static Future<User> getProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final response = await http.get(
      Uri.parse('$apiUrl/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Update own profile
  static Future<User> updateProfile({
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$apiUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        if (username != null) 'username': username,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
        if (githubUrl != null) 'github_url': githubUrl,
        if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
        if (websiteUrl != null) 'website_url': websiteUrl,
        if (availabilityStatus != null) 'availability_status': availabilityStatus,
        if (skills != null) 'skills': skills,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update profile');
    }
  }

  // Upload avatar (base64 encoded image)
  static Future<String> uploadAvatar({
    required String base64Image,
    required String fileName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$apiUrl/users/avatar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'base64Image': base64Image,
        'fileName': fileName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['avatar_url'] as String;
    } else {
      throw Exception('Failed to upload avatar');
    }
  }

  // Get user stats
  static Future<Map<String, int>> getUserStats(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final response = await http.get(
      Uri.parse('$apiUrl/users/$userId/stats'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'total_projects': data['total_projects'] ?? 0,
        'total_likes': data['total_likes'] ?? 0,
        'profile_views': data['profile_views'] ?? 0,
      };
    } else {
      throw Exception('Failed to load stats');
    }
  }
}
