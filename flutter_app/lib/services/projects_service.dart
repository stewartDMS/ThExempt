import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/project_role_model.dart';
import '../models/role_application_model.dart';
import '../models/project_member_model.dart';
import '../models/project_stage.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

class ProjectsService {
  static final _supabase = Supabase.instance.client;

  static const _projectSelect =
      '*, profiles!owner_id(name, avatar_url), '
      'project_media(id, media_type, file_url, thumbnail_url, '
      'file_name, file_size, display_order)';

  // Get all projects
  static Future<List<Project>> getProjects() async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('projects')
              .select(_projectSelect)
              .order('created_at', ascending: false)
              .timeout(const Duration(seconds: 10));
          return response.map((json) => Project.fromJson(json)).toList();
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  // Get single project by ID
  static Future<Project> getProject(String id) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('projects')
              .select(_projectSelect)
              .eq('id', id)
              .single()
              .timeout(const Duration(seconds: 10));
          return Project.fromJson(response);
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  // Apply to a project (general application)
  static Future<bool> applyToProject(String projectId, String message) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('applications').insert({
      'project_id': projectId,
      'user_id': userId,
      'message': message,
    });

    return true;
  }

  // Create a new project
  static Future<Project> createProject({
    required String title,
    required String description,
    required List<String> skills,
    ProjectStage stage = ProjectStage.ideation,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('projects').insert({
      'owner_id': userId,
      'title': title,
      'description': description,
      'required_skills': skills,
      'stage': stage.name,
    }).select(_projectSelect).single();

    return Project.fromJson(response);
  }

  // Update a project
  static Future<Project> updateProject({
    required String projectId,
    required String title,
    required String description,
    required List<String> skills,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('projects')
        .update({
          'title': title,
          'description': description,
          'required_skills': skills,
        })
        .eq('id', projectId)
        .eq('owner_id', userId)
        .select(_projectSelect)
        .single();

    return Project.fromJson(response);
  }

  // Delete a project
  static Future<bool> deleteProject(String projectId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('projects')
        .delete()
        .eq('id', projectId)
        .eq('owner_id', userId);

    return true;
  }

  // Get user's projects
  static Future<List<Project>> getUserProjects(String userId) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('projects')
              .select(_projectSelect)
              .eq('owner_id', userId)
              .order('created_at', ascending: false)
              .timeout(const Duration(seconds: 10));
          return response.map((json) => Project.fromJson(json)).toList();
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  // Get all roles for a project, grouped by category
  static Future<Map<String, List<ProjectRole>>> getProjectRoles(
      String projectId) async {
    final response = await _supabase
        .from('project_roles')
        .select()
        .eq('project_id', projectId)
        .order('display_order');

    final roles = response.map((r) => ProjectRole.fromJson(r)).toList();

    final grouped = <String, List<ProjectRole>>{};
    for (final role in roles) {
      grouped.putIfAbsent(role.roleCategory, () => []).add(role);
    }
    return grouped;
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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('project_roles').insert({
      'project_id': projectId,
      'role_category': roleCategory,
      'role_title': roleTitle,
      if (description != null) 'description': description,
      'skills_required': skillsRequired,
      'display_order': displayOrder,
    }).select().single();

    return ProjectRole.fromJson(response);
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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{};
    if (roleCategory != null) body['role_category'] = roleCategory;
    if (roleTitle != null) body['role_title'] = roleTitle;
    if (description != null) body['description'] = description;
    if (skillsRequired != null) body['skills_required'] = skillsRequired;
    if (isFilled != null) body['is_filled'] = isFilled;
    if (filledBy != null) body['filled_by'] = filledBy;
    if (displayOrder != null) body['display_order'] = displayOrder;

    final response = await _supabase
        .from('project_roles')
        .update(body)
        .eq('id', roleId)
        .eq('project_id', projectId)
        .select()
        .single();

    return ProjectRole.fromJson(response);
  }

  // Delete a project role
  static Future<bool> deleteProjectRole({
    required String projectId,
    required String roleId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('project_roles')
        .delete()
        .eq('id', roleId)
        .eq('project_id', projectId);

    return true;
  }

  // Apply for a specific role
  static Future<RoleApplication> applyForRole({
    required String projectId,
    required String roleId,
    required String message,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('role_applications').insert({
      'project_id': projectId,
      'role_id': roleId,
      'user_id': userId,
      'message': message,
    }).select().single();

    return RoleApplication.fromJson(response);
  }

  // Get all role applications for a project (owner only), grouped by role
  static Future<List<RoleApplicationGroup>> getProjectRoleApplications(
      String projectId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final rolesResponse = await _supabase
        .from('project_roles')
        .select()
        .eq('project_id', projectId);

    final appsResponse = await _supabase
        .from('role_applications')
        .select('*, profiles!user_id(name, avatar_url, reputation_points)')
        .eq('project_id', projectId);

    // Pre-group applications by role_id for O(n) lookup
    final appsByRole = <String, List<Map<String, dynamic>>>{};
    for (final app in appsResponse) {
      final rid = app['role_id']?.toString() ?? '';
      appsByRole.putIfAbsent(rid, () => []).add(app as Map<String, dynamic>);
    }

    return rolesResponse.map((role) {
      final roleId = role['id']?.toString() ?? '';
      final roleApps = appsByRole[roleId] ?? [];
      final apps = roleApps.map((app) {
        final profiles = app['profiles'] as Map<String, dynamic>?;
        return RoleApplication.fromJson({
          ...app,
          'applicant_name': profiles?['name'],
          'applicant_avatar_url': profiles?['avatar_url'],
          'applicant_id': app['user_id'],
          'reputation_points': profiles?['reputation_points'] ?? 0,
        });
      }).toList();

      return RoleApplicationGroup(
        roleId: roleId,
        roleTitle: role['role_title'] ?? '',
        roleCategory: role['role_category'] ?? '',
        skillsRequired: List<String>.from(role['skills_required'] ?? []),
        applications: apps,
      );
    }).toList();
  }

  // Get current user's own role applications
  static Future<List<RoleApplication>> getMyApplications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('role_applications')
        .select(
            '*, projects!project_id(title), project_roles!role_id(role_title, role_category)')
        .eq('user_id', userId);

    return response.map((app) {
      final project = app['projects'] as Map<String, dynamic>?;
      final projectRole = app['project_roles'] as Map<String, dynamic>?;
      return RoleApplication.fromJson({
        ...app,
        'project_title': project?['title'],
        'role_title': projectRole?['role_title'],
        'role_category': projectRole?['role_category'],
      });
    }).toList();
  }

  // Accept a role application
  static Future<void> acceptApplication(String applicationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('role_applications')
        .update({'status': 'accepted'})
        .eq('id', applicationId);
  }

  // Reject a role application
  static Future<void> rejectApplication(String applicationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('role_applications')
        .update({'status': 'rejected'})
        .eq('id', applicationId);
  }

  // Withdraw own pending application
  static Future<void> withdrawApplication(String applicationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('role_applications')
        .delete()
        .eq('id', applicationId)
        .eq('user_id', userId);
  }

  // Discover projects with optional role-category filter, open-roles toggle, and sort
  static Future<List<Project>> discoverProjects({
    String? roleCategory,
    bool hasOpenRoles = false,
    String sort = 'recent',
    ProjectStage? stage,
  }) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          if (roleCategory != null) {
            final rolesResponse = await _supabase
                .from('project_roles')
                .select('project_id')
                .eq('role_category', roleCategory)
                .eq('is_filled', false)
                .timeout(const Duration(seconds: 10));

            final projectIds = rolesResponse
                .map((r) => r['project_id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet()
                .toList();

            if (projectIds.isEmpty) return <Project>[];

            var query = _supabase
                .from('projects')
                .select(_projectSelect)
                .inFilter('id', projectIds);

            final response = sort == 'popular'
                ? await query
                    .order('roles_filled', ascending: false)
                    .timeout(const Duration(seconds: 10))
                : await query
                    .order('created_at', ascending: false)
                    .timeout(const Duration(seconds: 10));

            return response.map((json) => Project.fromJson(json)).toList();
          }

          var query = _supabase
              .from('projects')
              .select(_projectSelect);

          if (hasOpenRoles) {
            query = query.eq('status', 'open');
          }

          if (stage != null) {
            query = query.eq('stage', stage.name);
          }

          final response = sort == 'popular'
              ? await query
                  .order('roles_filled', ascending: false)
                  .timeout(const Duration(seconds: 10))
              : await query
                  .order('created_at', ascending: false)
                  .timeout(const Duration(seconds: 10));

          return response.map((json) => Project.fromJson(json)).toList();
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  // Get open roles for a project (used on discovery cards)
  static Future<List<ProjectRole>> getOpenRoles(String projectId) async {
    try {
      final response = await _supabase
          .from('project_roles')
          .select()
          .eq('project_id', projectId)
          .eq('is_filled', false)
          .order('display_order');

      return response.map((r) => ProjectRole.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get project team members
  static Future<List<ProjectMember>> getProjectMembers(
      String projectId) async {
    final response = await _supabase
        .from('project_members')
        .select('*, profiles!user_id(name, avatar_url, bio)')
        .eq('project_id', projectId);

    return response.map((m) {
      final profiles = m['profiles'] as Map<String, dynamic>?;
      return ProjectMember.fromJson({
        ...m,
        'name': profiles?['name'] ?? 'Unknown',
        'avatar_url': profiles?['avatar_url'],
        'bio': profiles?['bio'],
      });
    }).toList();
  }
}
