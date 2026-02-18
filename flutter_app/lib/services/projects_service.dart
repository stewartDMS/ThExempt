import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/project_model.dart';

class ProjectsService {
  // API URL - Update this based on your setup:
  // iOS Simulator: 'http://localhost:5000/api'
  // Android Emulator: 'http://10.0.2.2:5000/api'
  // Physical device: 'http://YOUR_IP:5000/api'
  static const String apiUrl = 'http://localhost:5000/api';

  // Get all projects
  static Future<List<Project>> getProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('$apiUrl/projects'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> projectsJson = jsonDecode(response.body);
        return projectsJson.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load projects');
      }
    } catch (e) {
      throw Exception('Cannot connect to server: $e');
    }
  }

  // Get single project by ID
  static Future<Project> getProject(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('$apiUrl/projects/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Project.fromJson(data);
      } else {
        throw Exception('Failed to load project');
      }
    } catch (e) {
      throw Exception('Cannot connect to server: $e');
    }
  }

  // Apply to a project
  static Future<bool> applyToProject(String projectId, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/projects/$projectId/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Failed to apply: $e');
    }
  }

  // Create a new project
  static Future<Project> createProject({
    required String title,
    required String description,
    required List<String> skills,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'required_skills': skills,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Project.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create project');
      }
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // Update a project
  static Future<Project> updateProject({
    required String projectId,
    required String title,
    required String description,
    required List<String> skills,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$apiUrl/projects/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'required_skills': skills,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Project.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update project');
      }
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  // Delete a project
  static Future<bool> deleteProject(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/projects/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

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
}
