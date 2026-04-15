import 'package:flutter/material.dart';
import '../models/live_event_model.dart';
import '../utils/time_ago.dart';
import '../screens/live_events/event_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

const _kCardBg        = Color(0xFF1C1C1E);
const _kBorder        = Color(0xFF3A3A3C);
const _kTextPrimary   = Colors.white;
const _kTextSecondary = Color(0xFFAAAAAA);

class LiveEventCard extends StatelessWidget {
  final LiveEvent event;

  const LiveEventCard({super.key, required this.event});

  String _formatScheduled() {
    final dt = event.scheduledStart;
    if (dt == null) return '';
    final now  = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays > 0)    return 'In ${diff.inDays}d';
    if (diff.inHours > 0)   return 'In ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'In ${diff.inMinutes}m';
    if (diff.isNegative && event.endedAt == null) return 'Starting…';
    return timeAgo(dt);
  }

  @override
  Widget build(BuildContext context) {
    final typeInfo  = LiveEventType.fromValue(event.eventType);
    final typeLabel = typeInfo?.label ?? event.eventType;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: event.isLive
              ? AppColors.deepRed.withOpacity(0.5)
              : _kBorder,
          width: event.isLive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: event.id)),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status row ──────────────────────────────────────────
              Row(
                children: [
                  if (event.isLive) ...[
                    _StatusBadge(
                        label: 'LIVE',
                        color: AppColors.deepRed,
                        icon: Icons.circle),
                    const SizedBox(width: 8),
                  ] else if (event.isPast) ...[
                    _StatusBadge(
                        label: 'ENDED',
                        color: const Color(0xFF555558)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                          fontSize: 11, color: _kTextSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (event.isLive)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility,
                            size: 12, color: _kTextSecondary),
                        const SizedBox(width: 3),
                        Text('${event.viewersCount}',
                            style: const TextStyle(
                                fontSize: 11, color: _kTextSecondary)),
                      ],
                    )
                  else if (event.scheduledStart != null)
                    Text(
                      _formatScheduled(),
                      style: const TextStyle(
                          fontSize: 11, color: _kTextSecondary),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Title ────────────────────────────────────────────────
              Text(
                event.title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.description!,
                  style: const TextStyle(
                      fontSize: 12, color: _kTextSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const Spacer(),

              // ── Host + CTA row ────────────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundImage: event.hostAvatarUrl != null
                        ? NetworkImage(event.hostAvatarUrl!)
                        : null,
                    backgroundColor:
                        AppColors.electricBlue.withOpacity(0.3),
                    child: event.hostAvatarUrl == null
                        ? Text(
                            event.hostName.isNotEmpty
                                ? event.hostName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.hostName,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _kTextSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.people_outline,
                      size: 13, color: _kTextSecondary),
                  const SizedBox(width: 3),
                  Text(
                    '${event.rsvpCount}',
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSecondary),
                  ),
                  const SizedBox(width: 10),
                  if (event.isLive)
                    _CtaButton(
                        label: 'Join Live',
                        color: AppColors.deepRed)
                  else if (event.isPast && event.recordingUrl != null)
                    _CtaButton(
                        label: 'Watch',
                        color: const Color(0xFF555558))
                  else if (!event.isPast)
                    _CtaButton(
                      label: event.userRsvpStatus == 'attending'
                          ? '✓ Going'
                          : 'RSVP',
                      color: event.userRsvpStatus == 'attending'
                          ? AppColors.forestGreen
                          : AppColors.electricBlue,
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 7, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final Color color;

  const _CtaButton({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
