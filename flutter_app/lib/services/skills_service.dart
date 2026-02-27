import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SkillsService {
  static const String apiUrl = 'http://localhost:5000/api';

  // Get all skill categories grouped by parent
  static Future<Map<String, List<Map<String, dynamic>>>> getSkillCategories() async {
    final response = await http.get(
      Uri.parse('$apiUrl/skills/categories'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> raw = json.decode(response.body);
      return raw.map((key, value) =>
          MapEntry(key, List<Map<String, dynamic>>.from(value)));
    } else {
      throw Exception('Failed to load skill categories');
    }
  }

  // Get skills by parent category
  static Future<List<Map<String, dynamic>>> getSkillsByCategory(String parentCategory) async {
    final response = await http.get(
      Uri.parse('$apiUrl/skills/categories/$parentCategory'),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load skills');
    }
  }

  // Search skills
  static Future<List<Map<String, dynamic>>> searchSkills(String query) async {
    final response = await http.get(
      Uri.parse('$apiUrl/skills/search?query=${Uri.encodeQueryComponent(query)}'),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to search skills');
    }
  }

  // Update user's primary expertise
  static Future<void> updateExpertise({
    required String primaryExpertise,
    String expertiseLevel = 'intermediate',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$apiUrl/users/me/expertise'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'primary_expertise': primaryExpertise,
        'expertise_level': expertiseLevel,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update expertise');
    }
  }
}
