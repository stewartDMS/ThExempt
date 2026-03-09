import 'package:flutter/material.dart';
import '../models/discussion_model.dart';
import '../utils/time_ago.dart';

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
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                  child: reply.authorAvatarUrl == null
                      ? Text(
                          reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: nested ? 9 : 11, fontWeight: FontWeight.bold),
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
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Text(timeAgo(reply.createdAt),
                              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(reply.content,
                          style: TextStyle(fontSize: nested ? 13 : 14, height: 1.4)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => onLike?.call(reply),
                            child: Row(
                              children: [
                                Icon(
                                  reply.isLikedByUser ? Icons.favorite : Icons.favorite_outline,
                                  size: 14,
                                  color: reply.isLikedByUser
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[500],
                                ),
                                const SizedBox(width: 3),
                                Text('${reply.likesCount}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (!nested)
                            GestureDetector(
                              onTap: () => onReply?.call(reply),
                              child: Row(
                                children: [
                                  Icon(Icons.reply, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 3),
                                  Text('Reply',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
            Divider(color: Colors.grey[200], height: 1),
        ],
      ),
    );
  }
}
