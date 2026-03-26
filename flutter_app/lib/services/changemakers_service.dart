import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Phase 2 — Changemakers Directory Service
///
/// Discovers and filters impact-focused users (changemakers) by skills,
/// expertise, availability, location, and reputation.
class ChangemakersService {
  static final _supabase = Supabase.instance.client;

  /// Returns a paginated list of changemaker profiles.
  ///
  /// Filters:
  /// - [skillFilter]        — only users whose `skills` array overlaps this value
  /// - [availabilityFilter] — 'available' | 'busy' | 'open_to_collaborate'
  /// - [locationFilter]     — partial-match on the `location` field
  /// - [sort]               — 'reputation' | 'recent' | 'activity'
  /// - [limit] / [offset]   — pagination
  static Future<List<UserProfile>> getChangemakers({
    String? skillFilter,
    String? availabilityFilter,
    String? locationFilter,
    String sort = 'reputation',
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('profiles')
        .select(
          'id, name, username, bio, avatar_url, location, '
          'availability_status, skills, reputation_points, badges, '
          'primary_expertise, expertise_level, created_at',
        )
        .isFilter('deleted_at', null);

    if (skillFilter != null && skillFilter.isNotEmpty) {
      query = query.contains('skills', [skillFilter]);
    }

    if (availabilityFilter != null && availabilityFilter.isNotEmpty) {
      query = query.eq('availability_status', availabilityFilter);
    }

    if (locationFilter != null && locationFilter.isNotEmpty) {
      query = query.ilike('location', '%$locationFilter%');
    }

    final orderColumn = switch (sort) {
      'recent' => 'created_at',
      'activity' => 'reputation_points',
      _ => 'reputation_points',
    };

    final response = await query
        .order(orderColumn, ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns users whose skills overlap with [skills].
  static Future<List<UserProfile>> getUsersBySkills(
      List<String> skills) async {
    if (skills.isEmpty) return [];

    final response = await _supabase
        .from('profiles')
        .select(
          'id, name, username, bio, avatar_url, location, '
          'availability_status, skills, reputation_points, badges, '
          'primary_expertise, expertise_level, created_at',
        )
        .isFilter('deleted_at', null)
        .overlaps('skills', skills)
        .order('reputation_points', ascending: false)
        .limit(30);

    return (response as List)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns users located in or near [location] (partial match).
  static Future<List<UserProfile>> getUsersByLocation(
      String location) async {
    final response = await _supabase
        .from('profiles')
        .select(
          'id, name, username, bio, avatar_url, location, '
          'availability_status, skills, reputation_points, badges, '
          'primary_expertise, expertise_level, created_at',
        )
        .isFilter('deleted_at', null)
        .ilike('location', '%$location%')
        .not('location', 'is', null)
        .order('reputation_points', ascending: false)
        .limit(50);

    return (response as List)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns all changemakers that have a non-null location, used for the
  /// community map view.
  static Future<List<UserProfile>> getChangemakersWithLocation({
    int limit = 100,
  }) async {
    final response = await _supabase
        .from('profiles')
        .select(
          'id, name, username, avatar_url, location, '
          'availability_status, skills, reputation_points, badges, '
          'primary_expertise, expertise_level, created_at',
        )
        .isFilter('deleted_at', null)
        .not('location', 'is', null)
        .order('reputation_points', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns a summary of impact stats for [userId]:
  /// projects owned, discussions contributed, reputation score.
  static Future<Map<String, dynamic>> getUserImpactStats(
      String userId) async {
    final projectsResult = await _supabase
        .from('projects')
        .select('id')
        .eq('owner_id', userId)
        .count(CountOption.exact);

    final discussionsResult = await _supabase
        .from('discussions')
        .select('id')
        .eq('author_id', userId)
        .count(CountOption.exact);

    final profile = await _supabase
        .from('profiles')
        .select('reputation_points, badges, trust_score')
        .eq('id', userId)
        .single() as Map<String, dynamic>;

    return {
      'projects_count': projectsResult.count ?? 0,
      'discussions_count': discussionsResult.count ?? 0,
      'reputation_points': profile['reputation_points'] ?? 0,
      'trust_score': profile['trust_score'] ?? 0,
      'badges': List<String>.from(profile['badges'] as List? ?? []),
    };
  }
}
