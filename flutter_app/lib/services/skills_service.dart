import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/skill_marketplace_model.dart';

class SkillsService {
  static final _supabase = Supabase.instance.client;

  // ── Skill taxonomy ─────────────────────────────────────────────────────────

  // Get all skill categories grouped by parent
  static Future<Map<String, List<Map<String, dynamic>>>> getSkillCategories() async {
    final response = await _supabase
        .from('skill_categories')
        .select()
        .order('display_order');

    final result = <String, List<Map<String, dynamic>>>{};
    for (final skill in response) {
      final parent = skill['parent_category'] as String? ?? 'Other';
      result.putIfAbsent(parent, () => []).add(skill as Map<String, dynamic>);
    }
    return result;
  }

  // Get skills by parent category
  static Future<List<Map<String, dynamic>>> getSkillsByCategory(String parentCategory) async {
    final response = await _supabase
        .from('skill_categories')
        .select()
        .eq('parent_category', parentCategory)
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  // Search skills
  static Future<List<Map<String, dynamic>>> searchSkills(String query) async {
    final response = await _supabase
        .from('skill_categories')
        .select()
        .ilike('name', '%$query%')
        .order('name')
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  // Update user's primary expertise
  static Future<void> updateExpertise({
    required String primaryExpertise,
    String expertiseLevel = 'intermediate',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('profiles').update({
      'primary_expertise': primaryExpertise,
      'expertise_level': expertiseLevel,
    }).eq('id', userId);
  }

  // ── Skill Offers ──────────────────────────────────────────────────────────

  /// Returns all active skill offers, optionally filtered by [skillCategory].
  static Future<List<SkillOffer>> getSkillOffers({
    String? skillCategory,
    int limit = 30,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('skill_offers')
        .select('*, profiles(name, avatar_url, location)')
        .eq('is_active', true)
        .isFilter('deleted_at', null);

    if (skillCategory != null && skillCategory.isNotEmpty) {
      query = query.contains('skill_categories', [skillCategory]);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((e) => SkillOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns skill offers belonging to the current user.
  static Future<List<SkillOffer>> getMySkillOffers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('skill_offers')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => SkillOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new skill offer for the current user.
  static Future<SkillOffer> createSkillOffer({
    required String title,
    required String description,
    required List<String> skillCategories,
    int? rateCreditsPerHour,
    bool equityPreferred = false,
    int? availableHoursPerWeek,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('skill_offers')
        .insert({
          'user_id': userId,
          'title': title,
          'description': description,
          'skill_categories': skillCategories,
          if (rateCreditsPerHour != null)
            'rate_credits_per_hour': rateCreditsPerHour,
          'equity_preferred': equityPreferred,
          if (availableHoursPerWeek != null)
            'available_hours_per_week': availableHoursPerWeek,
        })
        .select()
        .single();

    return SkillOffer.fromJson(response as Map<String, dynamic>);
  }

  /// Deletes a skill offer owned by the current user (soft delete).
  static Future<void> deleteSkillOffer(String offerId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('skill_offers')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', offerId)
        .eq('user_id', userId);
  }

  // ── Skill Requests ────────────────────────────────────────────────────────

  /// Returns all open skill requests, optionally filtered by [skillCategory].
  static Future<List<SkillRequest>> getSkillRequests({
    String? skillCategory,
    int limit = 30,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('skill_requests')
        .select('*, profiles(name, avatar_url), projects(title)')
        .eq('status', 'open')
        .isFilter('deleted_at', null);

    if (skillCategory != null && skillCategory.isNotEmpty) {
      query = query.contains('skill_categories', [skillCategory]);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((e) => SkillRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new skill request.
  static Future<SkillRequest> createSkillRequest({
    required String title,
    required String description,
    required List<String> skillCategories,
    String? projectId,
    int? budgetCredits,
    double? equityOffered,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('skill_requests')
        .insert({
          'requester_id': userId,
          'title': title,
          'description': description,
          'skill_categories': skillCategories,
          if (projectId != null) 'project_id': projectId,
          if (budgetCredits != null) 'budget_credits': budgetCredits,
          if (equityOffered != null) 'equity_offered': equityOffered,
        })
        .select()
        .single();

    return SkillRequest.fromJson(response as Map<String, dynamic>);
  }
}

