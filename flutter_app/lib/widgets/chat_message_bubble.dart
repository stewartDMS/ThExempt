import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/live_event_model.dart';
import '../utils/time_ago.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: message.userAvatarUrl != null ? NetworkImage(message.userAvatarUrl!) : null,
            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
            child: message.userAvatarUrl == null
                ? Text(
                    message.userName.isNotEmpty ? message.userName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.userName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    if (message.isPinned) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.push_pin, size: 12, color: AppColors.rebellionOrange),
                    ],
                    const SizedBox(width: 6),
                    Text(timeAgo(message.createdAt),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: message.isPinned
                        ? AppColors.rebellionOrange.withAlpha(25)
                        : isCurrentUser
                            ? Theme.of(context).colorScheme.primary.withAlpha(25)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: message.isPinned ? Border.all(color: AppColors.rebellionOrange.withAlpha(80)) : null,
                  ),
                  child: Text(message.message, style: const TextStyle(fontSize: 13, height: 1.3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
