import 'package:supabase_flutter/supabase_flutter.dart';

class SkillsService {
  static final _supabase = Supabase.instance.client;

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
}

