import 'package:flutter/material.dart';
import '../models/live_event_model.dart';
import '../utils/time_ago.dart';
import '../screens/live_events/event_detail_screen.dart';

class LiveEventCard extends StatelessWidget {
  final LiveEvent event;

  const LiveEventCard({super.key, required this.event});

  String _formatScheduled() {
    final dt = event.scheduledStart;
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays > 0) return 'In ${diff.inDays}d';
    if (diff.inHours > 0) return 'In ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'In ${diff.inMinutes}m';
    if (diff.isNegative && event.endedAt == null) return 'Starting...';
    return timeAgo(dt);
  }

  @override
  Widget build(BuildContext context) {
    final typeInfo = LiveEventType.fromValue(event.eventType);
    final typeLabel = typeInfo?.label ?? event.eventType;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: event.isLive ? Colors.red.withAlpha(120) : Colors.grey[300]!,
          width: event.isLive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (event.isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text('LIVE', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (event.isPast) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('ENDED',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(typeLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (event.isLive)
                    Row(children: [
                      Icon(Icons.visibility, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text('${event.viewersCount}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ])
                  else if (event.scheduledStart != null)
                    Text(_formatScheduled(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 8),
              Text(event.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(event.description!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: event.hostAvatarUrl != null ? NetworkImage(event.hostAvatarUrl!) : null,
                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                    child: event.hostAvatarUrl == null
                        ? Text(event.hostName.isNotEmpty ? event.hostName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(event.hostName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text('${event.rsvpCount}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(width: 12),
                  if (event.isLive)
                    _JoinButton(label: 'Join Live', color: Colors.red)
                  else if (event.isPast && event.recordingUrl != null)
                    _JoinButton(label: 'Watch', color: Colors.grey[700]!)
                  else if (!event.isPast)
                    _JoinButton(
                      label: event.userRsvpStatus == 'attending' ? '✓ Going' : 'RSVP',
                      color: event.userRsvpStatus == 'attending'
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final String label;
  final Color color;

  const _JoinButton({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}
