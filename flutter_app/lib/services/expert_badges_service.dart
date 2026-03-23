import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expert_badge_model.dart';

/// Phase 1 — Expert badges & trust system
///
/// Wraps the user_expertise, expert_verifications tables and the
/// profiles.badges / trust_score columns via the Supabase client.
class ExpertBadgesService {
  static final _supabase = Supabase.instance.client;

  // ── Expertise areas ────────────────────────────────────────────────────

  /// Returns all expertise areas for [userId], with nested verifications.
  static Future<List<UserExpertise>> getExpertise(String userId) async {
    final response = await _supabase
        .from('user_expertise')
        .select('*, expert_verifications(id, verification_type, verified_by, created_at)')
        .eq('user_id', userId)
        .order('is_primary', ascending: false)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => UserExpertise.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Self-declares a new expertise area for the signed-in user.
  static Future<UserExpertise> addExpertise({
    required String area,
    String level = 'self_declared',
    String? evidenceUrl,
    bool isPrimary = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Clear existing primary if needed
    if (isPrimary) {
      await _supabase
          .from('user_expertise')
          .update({'is_primary': false})
          .eq('user_id', userId)
          .eq('is_primary', true);
    }

    final response = await _supabase
        .from('user_expertise')
        .insert({
          'user_id': userId,
          'area': area,
          'level': level,
          if (evidenceUrl != null) 'evidence_url': evidenceUrl,
          'is_primary': isPrimary,
        })
        .select()
        .single();

    return UserExpertise.fromJson(response as Map<String, dynamic>);
  }

  /// Removes an expertise area owned by the signed-in user.
  static Future<void> removeExpertise(String expertiseId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('user_expertise')
        .delete()
        .eq('id', expertiseId)
        .eq('user_id', userId);
  }

  // ── Verifications ──────────────────────────────────────────────────────

  /// Endorses another user's expertise entry.
  /// [verificationType] must be 'community', 'admin', or 'credential'.
  static Future<ExpertVerification> verifyExpertise({
    required String expertiseId,
    String verificationType = 'community',
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('expert_verifications')
        .insert({
          'user_expertise_id': expertiseId,
          'verified_by': userId,
          'verification_type': verificationType,
          if (notes != null) 'notes': notes,
        })
        .select()
        .single();

    // After 3 community verifications, escalate level to community_verified
    if (verificationType == 'community') {
      final count = await _supabase
          .from('expert_verifications')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_expertise_id', expertiseId)
          .eq('verification_type', 'community');

      if ((count.count ?? 0) >= 3) {
        final expertise = await _supabase
            .from('user_expertise')
            .select('level')
            .eq('id', expertiseId)
            .single();

        if ((expertise as Map)['level'] == 'self_declared') {
          await _supabase
              .from('user_expertise')
              .update({'level': 'community_verified'})
              .eq('id', expertiseId);
        }
      }
    }

    return ExpertVerification.fromJson(response as Map<String, dynamic>);
  }

  // ── Badges ─────────────────────────────────────────────────────────────

  /// Returns the badge list and trust score for [userId].
  /// Also computes Phase 1 badges from cross-table counts and
  /// persists any newly earned badges back to profiles.badges.
  static Future<UserBadges> getBadges(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select('trust_score, badges')
        .eq('id', userId)
        .single() as Map<String, dynamic>;

    final score    = (profile['trust_score'] as num?)?.toInt() ?? 0;
    final existing = Set<String>.from(profile['badges'] as List? ?? []);

    // Threshold badges
    if (score >= 100)  existing.add('Contributor');
    if (score >= 500)  existing.add('Expert');
    if (score >= 1000) existing.add('Master');

    // Verified Expert — has at least one expert_verified expertise entry
    final expertCount = await _supabase
        .from('user_expertise')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('user_id', userId)
        .inFilter('level', ['expert_verified', 'platform_verified']);
    if ((expertCount.count ?? 0) >= 1) existing.add('Verified Expert');

    // Community Pillar — has given >= 10 community verifications
    final givenCount = await _supabase
        .from('expert_verifications')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('verified_by', userId)
        .eq('verification_type', 'community');
    if ((givenCount.count ?? 0) >= 10) existing.add('Community Pillar');

    // Movement Builder — linked at least one discussion to a project
    final linkedCount = await _supabase
        .from('discussions')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('author_id', userId)
        .eq('stage', 'project_linked');
    if ((linkedCount.count ?? 0) >= 1) existing.add('Movement Builder');

    // Resource Contributor — added >= 5 discussion resources
    final resourceCount = await _supabase
        .from('discussion_resources')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('uploaded_by', userId);
    if ((resourceCount.count ?? 0) >= 5) existing.add('Resource Contributor');

    final badgeList = existing.toList();

    // Persist newly earned badges
    if (badgeList.length != (profile['badges'] as List?)?.length) {
      await _supabase
          .from('profiles')
          .update({'badges': badgeList})
          .eq('id', userId);
    }

    return UserBadges(userId: userId, badges: badgeList, trustScore: score);
  }
}
