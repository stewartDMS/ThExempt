import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/discussion_model.dart';

class DiscussionsService {
  static const String apiUrl = 'http://localhost:5000/api';

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Create a new discussion thread.
  static Future<Discussion> createDiscussion({
    required String category,
    required String title,
    required String content,
    List<String>? tags,
    String? imageUrl,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$apiUrl/discussions'),
      headers: headers,
      body: jsonEncode({
        'category': category,
        'title': title,
        'content': content,
        if (tags != null) 'tags': tags,
        if (imageUrl != null) 'image_url': imageUrl,
      }),
    );

    if (response.statusCode == 201) {
      return Discussion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create discussion: ${response.body}');
  }

  /// List discussions with optional filters.
  static Future<List<Discussion>> getDiscussions({
    String? category,
    String? search,
    String sort = 'recent',
    int page = 1,
  }) async {
    final headers = await _authHeaders();
    final params = {
      'sort': sort,
      'page': page.toString(),
      if (category != null) 'category': category,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$apiUrl/discussions').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => Discussion.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load discussions');
  }

  /// Get a single discussion by ID.
  static Future<Discussion> getDiscussion(String id) async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$apiUrl/discussions/$id'), headers: headers);

    if (response.statusCode == 200) {
      return Discussion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load discussion');
  }

  /// Add a reply to a discussion.
  static Future<DiscussionReply> addReply({
    required String discussionId,
    required String content,
    String? parentReplyId,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$apiUrl/discussions/$discussionId/replies'),
      headers: headers,
      body: jsonEncode({
        'content': content,
        if (parentReplyId != null) 'parent_reply_id': parentReplyId,
      }),
    );

    if (response.statusCode == 201) {
      return DiscussionReply.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to add reply');
  }

  /// Get nested replies for a discussion.
  static Future<List<DiscussionReply>> getReplies(String discussionId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$apiUrl/discussions/$discussionId/replies'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => DiscussionReply.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load replies');
  }

  /// Like a discussion post (or reply if [replyId] is provided).
  static Future<void> likeDiscussion(String discussionId, {String? replyId}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$apiUrl/discussions/$discussionId/like'),
      headers: headers,
      body: jsonEncode({if (replyId != null) 'reply_id': replyId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to like');
    }
  }

  /// Remove a like from a discussion (or reply if [replyId] is provided).
  static Future<void> unlikeDiscussion(String discussionId, {String? replyId}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$apiUrl/discussions/$discussionId/like')
        .replace(queryParameters: {if (replyId != null) 'reply_id': replyId});
    final request = http.Request('DELETE', uri);
    request.headers.addAll(headers);
    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception('Failed to unlike');
    }
  }
}
