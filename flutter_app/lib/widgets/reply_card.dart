import 'package:flutter/material.dart';
import '../models/discussion_model.dart';
import '../theme/app_colors.dart';
import '../utils/time_ago.dart';

// ── Dark palette ──────────────────────────────────────────────────────────────
const _kDivider       = Color(0xFF2C2C2F);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class ReplyCard extends StatelessWidget {
  final DiscussionReply reply;
  final bool nested;
  final void Function(DiscussionReply)? onLike;
  final void Function(DiscussionReply)? onReply;

  const ReplyCard({
    super.key,
    required this.reply,
    this.nested = false,
    this.onLike,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: nested ? 24 : 0, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: nested ? 12 : 15,
                  backgroundImage: reply.authorAvatarUrl != null
                      ? NetworkImage(reply.authorAvatarUrl!)
                      : null,
                  backgroundColor:
                      AppColors.electricBlue.withOpacity(0.2),
                  child: reply.authorAvatarUrl == null
                      ? Text(
                          reply.authorName.isNotEmpty
                              ? reply.authorName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontSize: nested ? 9 : 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brightCyan),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(reply.authorName,
                              style: TextStyle(
                                  fontSize: nested ? 12 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextPrimary)),
                          const SizedBox(width: 6),
                          Text(timeAgo(reply.createdAt),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _kTextSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(reply.content,
                          style: TextStyle(
                              fontSize: nested ? 13 : 14,
                              height: 1.4,
                              color: _kTextPrimary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => onLike?.call(reply),
                            child: Row(
                              children: [
                                Icon(
                                  reply.isLikedByUser
                                      ? Icons.favorite
                                      : Icons.favorite_outline,
                                  size: 14,
                                  color: reply.isLikedByUser
                                      ? AppColors.deepRed
                                      : _kTextSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text('${reply.likesCount}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _kTextSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (!nested)
                            GestureDetector(
                              onTap: () => onReply?.call(reply),
                              child: const Row(
                                children: [
                                  Icon(Icons.reply,
                                      size: 14,
                                      color: _kTextSecondary),
                                  SizedBox(width: 3),
                                  Text('Reply',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _kTextSecondary)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nested replies
          if (reply.replies.isNotEmpty)
            ...reply.replies.map((r) => ReplyCard(
                  reply: r,
                  nested: true,
                  onLike: onLike,
                )),
          if (!nested)
            const Divider(color: _kDivider, height: 1),
        ],
      ),
    );
  }
}
