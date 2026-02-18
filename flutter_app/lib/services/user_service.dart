import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/project_model.dart';

class UserService {
  static const String apiUrl = 'http://localhost:5000/api';

  // Get user's projects
  static Future<List<Project>> getUserProjects(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('$apiUrl/users/$userId/projects'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> projectsJson = jsonDecode(response.body);
        return projectsJson.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user projects');
      }
    } catch (e) {
      throw Exception('Cannot connect to server: $e');
    }
  }

  // Clear user session (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }
}
