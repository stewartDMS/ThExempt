import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/project_model.dart';
import '../models/project_role_model.dart';
import '../models/role_application_model.dart';
import '../models/project_member_model.dart';

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

  // Get all roles for a project, grouped by category
  static Future<Map<String, List<ProjectRole>>> getProjectRoles(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('$apiUrl/projects/$projectId/roles'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.map((category, rolesJson) => MapEntry(
          category,
          (rolesJson as List<dynamic>)
              .map((r) => ProjectRole.fromJson(r as Map<String, dynamic>))
              .toList(),
        ));
      } else {
        throw Exception('Failed to load project roles');
      }
    } catch (e) {
      throw Exception('Cannot connect to server: $e');
    }
  }

  // Add a role to a project
  static Future<ProjectRole> addProjectRole({
    required String projectId,
    required String roleCategory,
    required String roleTitle,
    String? description,
    List<String> skillsRequired = const [],
    int displayOrder = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$apiUrl/projects/$projectId/roles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'role_category': roleCategory,
          'role_title': roleTitle,
          if (description != null) 'description': description,
          'skills_required': skillsRequired,
          'display_order': displayOrder,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProjectRole.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to add role');
      }
    } catch (e) {
      throw Exception('Failed to add role: $e');
    }
  }

  // Update a project role
  static Future<ProjectRole> updateProjectRole({
    required String projectId,
    required String roleId,
    String? roleCategory,
    String? roleTitle,
    String? description,
    List<String>? skillsRequired,
    bool? isFilled,
    String? filledBy,
    int? displayOrder,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('Not authenticated');

      final body = <String, dynamic>{};
      if (roleCategory != null) body['role_category'] = roleCategory;
      if (roleTitle != null) body['role_title'] = roleTitle;
      if (description != null) body['description'] = description;
      if (skillsRequired != null) body['skills_required'] = skillsRequired;
      if (isFilled != null) body['is_filled'] = isFilled;
      if (filledBy != null) body['filled_by'] = filledBy;
      if (displayOrder != null) body['display_order'] = displayOrder;

      final response = await http.put(
        Uri.parse('$apiUrl/projects/$projectId/roles/$roleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return ProjectRole.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update role');
      }
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  // Delete a project role
  static Future<bool> deleteProjectRole({
    required String projectId,
    required String roleId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$apiUrl/projects/$projectId/roles/$roleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete role: $e');
    }
  }

  // Apply for a specific role
  static Future<RoleApplication> applyForRole({
    required String projectId,
    required String roleId,
    required String message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$apiUrl/projects/$projectId/roles/$roleId/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RoleApplication.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to submit application');
      }
    } catch (e) {
      throw Exception('Failed to apply: $e');
    }
  }

  // Get all role applications for a project (owner only), grouped by role
  static Future<List<RoleApplicationGroup>> getProjectRoleApplications(
      String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$apiUrl/projects/$projectId/role-applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((g) =>
                RoleApplicationGroup.fromJson(g as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to load applications');
      }
    } catch (e) {
      throw Exception('Failed to load applications: $e');
    }
  }

  // Get current user's own role applications
  static Future<List<RoleApplication>> getMyApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$apiUrl/users/me/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((a) => RoleApplication.fromJson(a as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to load applications');
      }
    } catch (e) {
      throw Exception('Failed to load applications: $e');
    }
  }

  // Accept a role application
  static Future<void> acceptApplication(String applicationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$apiUrl/role-applications/$applicationId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to accept application');
      }
    } catch (e) {
      throw Exception('Failed to accept: $e');
    }
  }

  // Reject a role application
  static Future<void> rejectApplication(String applicationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$apiUrl/role-applications/$applicationId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to reject application');
      }
    } catch (e) {
      throw Exception('Failed to reject: $e');
    }
  }

  // Withdraw own pending application
  static Future<void> withdrawApplication(String applicationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$apiUrl/role-applications/$applicationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to withdraw application');
      }
    } catch (e) {
      throw Exception('Failed to withdraw: $e');
    }
  }

  // Discover projects with optional role-category filter, open-roles toggle, and sort
  static Future<List<Project>> discoverProjects({
    String? roleCategory,
    bool hasOpenRoles = false,
    String sort = 'recent',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final queryParams = <String, String>{
        if (roleCategory != null) 'role_category': roleCategory,
        if (hasOpenRoles) 'has_open_roles': 'true',
        'sort': sort,
      };

      final uri = Uri.parse('$apiUrl/projects/discover')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> projectsJson = jsonDecode(response.body);
        return projectsJson.map((json) => Project.fromJson(json)).toList();
      } else {
        // Fall back to all projects if the discover endpoint is not available
        return getProjects();
      }
    } catch (e) {
      // Fall back to all projects on error
      return getProjects();
    }
  }

  // Get open roles for a project (used on discovery cards)
  static Future<List<ProjectRole>> getOpenRoles(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('$apiUrl/projects/$projectId/open-roles'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((r) => ProjectRole.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get project team members
  static Future<List<ProjectMember>> getProjectMembers(
      String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('$apiUrl/projects/$projectId/members'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((m) =>
                ProjectMember.fromJson(m as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load members');
      }
    } catch (e) {
      throw Exception('Failed to load members: $e');
    }
  }
}
