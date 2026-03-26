import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/project_role_model.dart';
import '../models/role_application_model.dart';
import '../models/project_member_model.dart';
import '../models/project_endorsement_model.dart';
import '../models/project_update_model.dart';
import '../models/project_stage.dart';
import '../models/discussion_model.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

class ProjectsService {
  static final _supabase = Supabase.instance.client;

  static const _projectSelect =
      '*, profiles!owner_id(username, avatar_url), '
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
    String? problemStatement,
    String? solutionApproach,
    Map<String, dynamic>? impactMetrics,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('projects').insert({
      'owner_id': userId,
      'title': title,
      'description': description,
      'required_skills': skills,
      'stage': stage.name,
      if (problemStatement != null && problemStatement.isNotEmpty)
        'problem_statement': problemStatement,
      if (solutionApproach != null && solutionApproach.isNotEmpty)
        'solution_approach': solutionApproach,
      if (impactMetrics != null && impactMetrics.isNotEmpty)
        'impact_metrics': impactMetrics,
    }).select(_projectSelect).single();

    return Project.fromJson(response);
  }

  // Update a project
  static Future<Project> updateProject({
    required String projectId,
    required String title,
    required String description,
    required List<String> skills,
    String? problemStatement,
    String? solutionApproach,
    Map<String, dynamic>? impactMetrics,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('projects')
        .update({
          'title': title,
          'description': description,
          'required_skills': skills,
          'problem_statement': problemStatement,
          'solution_approach': solutionApproach,
          if (impactMetrics != null) 'impact_metrics': impactMetrics,
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
        .select('*, profiles!user_id(username, avatar_url, reputation_points)')
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
          'applicant_name': profiles?['username'],
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
        .select('*, profiles!user_id(username, avatar_url)')
        .eq('project_id', projectId);

    return response.map((m) {
      final profiles = m['profiles'] as Map<String, dynamic>?;
      return ProjectMember.fromJson({
        ...m,
        'name': profiles?['username'] ?? 'Unknown',
        'avatar_url': profiles?['avatar_url'],
        'bio': profiles?['bio'],
      });
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Phase 3 — Endorsements
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns all endorsements for a project (newest first).
  static Future<List<ProjectEndorsement>> getEndorsements(
      String projectId) async {
    final response = await _supabase
        .from('project_endorsements')
        .select('*, profiles!user_id(username, avatar_url)')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return response
        .map((e) => ProjectEndorsement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns whether the current user has endorsed [projectId].
  static Future<bool> hasUserEndorsed(String projectId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('project_endorsements')
        .select('id')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  /// Endorses a project. Optionally includes a [message]. Returns the created
  /// endorsement. Throws if the user has already endorsed the project.
  static Future<ProjectEndorsement> endorseProject(
    String projectId, {
    String? message,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('project_endorsements').insert({
      'project_id': projectId,
      'user_id': userId,
      if (message != null && message.isNotEmpty) 'message': message,
    }).select('*, profiles!user_id(username, avatar_url)').single();

    return ProjectEndorsement.fromJson(response);
  }

  /// Removes the current user's endorsement of [projectId].
  static Future<void> unendorseProject(String projectId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('project_endorsements')
        .delete()
        .eq('project_id', projectId)
        .eq('user_id', userId);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Phase 3 — Project Updates (progress log)
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns all updates for a project (newest first).
  static Future<List<ProjectUpdate>> getProjectUpdates(
      String projectId) async {
    final response = await _supabase
        .from('project_updates')
        .select('*, profiles!user_id(username, avatar_url)')
        .eq('project_id', projectId)
        .isFilter('deleted_at', null)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return response
        .map((u) => ProjectUpdate.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  /// Posts a new progress update for a project (owner only).
  static Future<ProjectUpdate> addProjectUpdate({
    required String projectId,
    required String title,
    required String content,
    ProjectUpdateType updateType = ProjectUpdateType.general,
    bool isPinned = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('project_updates').insert({
      'project_id': projectId,
      'user_id': userId,
      'title': title,
      'content': content,
      'update_type': updateType.value,
      'is_pinned': isPinned,
    }).select('*, profiles!user_id(username, avatar_url)').single();

    return ProjectUpdate.fromJson(response);
  }

  /// Deletes a project update (owner only).
  static Future<void> deleteProjectUpdate(String updateId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('project_updates')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', updateId)
        .eq('user_id', userId);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Phase 3 — Project ↔ Discussion Links
  // ──────────────────────────────────────────────────────────────────────────

  static const _discussionSelect = '''
    *,
    profiles:user_id (
      id,
      username,
      avatar_url
    ),
    discussion_media (
      id,
      media_type,
      file_url,
      thumbnail_url,
      file_name,
      file_size,
      width,
      height,
      duration_seconds,
      display_order
    )
  ''';

  /// Returns all discussions explicitly linked to [projectId], including those
  /// where `discussions.linked_project_id` matches.
  static Future<List<Discussion>> getLinkedDiscussions(
      String projectId) async {
    // Explicitly linked via project_discussion_links
    final linksResponse = await _supabase
        .from('project_discussion_links')
        .select('discussion_id')
        .eq('project_id', projectId);

    final linkedIds = linksResponse
        .map((r) => r['discussion_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    // Discussions that "spawned" the project via linked_project_id
    final spawnedResponse = await _supabase
        .from('discussions')
        .select(_discussionSelect)
        .eq('linked_project_id', projectId)
        .order('created_at', ascending: false);

    final spawnedDiscussions = spawnedResponse
        .map((d) => Discussion.fromJson(d as Map<String, dynamic>))
        .toList();

    if (linkedIds.isEmpty) return spawnedDiscussions;

    // Fetch explicitly linked discussions that aren't already in the spawned list
    final spawnedIds = spawnedDiscussions.map((d) => d.id).toSet();
    final remaining = linkedIds.where((id) => !spawnedIds.contains(id)).toList();

    if (remaining.isEmpty) return spawnedDiscussions;

    final explicitResponse = await _supabase
        .from('discussions')
        .select(_discussionSelect)
        .inFilter('id', remaining)
        .order('created_at', ascending: false);

    final explicitDiscussions = explicitResponse
        .map((d) => Discussion.fromJson(d as Map<String, dynamic>))
        .toList();

    return [...spawnedDiscussions, ...explicitDiscussions];
  }

  /// Creates an explicit link between [projectId] and [discussionId].
  static Future<void> linkDiscussion({
    required String projectId,
    required String discussionId,
    String linkType = 'related',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('project_discussion_links').upsert({
      'project_id': projectId,
      'discussion_id': discussionId,
      'linked_by': userId,
      'link_type': linkType,
    }, onConflict: 'project_id,discussion_id');
  }

  /// Removes an explicit link between [projectId] and [discussionId].
  static Future<void> unlinkDiscussion({
    required String projectId,
    required String discussionId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('project_discussion_links')
        .delete()
        .eq('project_id', projectId)
        .eq('discussion_id', discussionId);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Phase 3 — Milestones (DB-backed)
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns milestones for [projectId] ordered by display_order.
  static Future<List<Map<String, dynamic>>> getProjectMilestones(
      String projectId) async {
    final response = await _supabase
        .from('project_milestones')
        .select()
        .eq('project_id', projectId)
        .order('display_order');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Adds a new milestone to [projectId].
  static Future<Map<String, dynamic>> addMilestone({
    required String projectId,
    required String title,
    String? description,
    DateTime? dueDate,
    int displayOrder = 0,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('project_milestones').insert({
      'project_id': projectId,
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      'display_order': displayOrder,
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  /// Marks a milestone as complete (sets completed_at to now).
  static Future<void> completeMilestone(String milestoneId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('project_milestones')
        .update({'completed_at': DateTime.now().toIso8601String()})
        .eq('id', milestoneId);
  }

  /// Reopens a previously completed milestone.
  static Future<void> reopenMilestone(String milestoneId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('project_milestones')
        .update({'completed_at': null})
        .eq('id', milestoneId);
  }

  /// Deletes a milestone.
  static Future<void> deleteMilestone(String milestoneId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('project_milestones')
        .delete()
        .eq('id', milestoneId);
  }
}
