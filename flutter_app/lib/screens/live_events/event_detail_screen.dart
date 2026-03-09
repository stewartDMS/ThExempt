import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/live_event_model.dart';
import '../../services/live_events_service.dart';
import '../../widgets/live_event_card.dart';
import '../../utils/time_ago.dart';
import 'live_host_screen.dart';
import 'live_viewer_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  LiveEvent? _event;
  bool _loading = true;
  bool _rsvpLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final event = await LiveEventsService.getLiveEvent(widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rsvp(String status) async {
    setState(() => _rsvpLoading = true);
    try {
      await LiveEventsService.rsvpToEvent(widget.eventId, status);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _rsvpLoading = false);
    }
  }

  Future<void> _removeRsvp() async {
    setState(() => _rsvpLoading = true);
    try {
      await LiveEventsService.removeRsvp(widget.eventId);
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _rsvpLoading = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dayOfWeek = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dayOfWeek, $month ${dt.day} · $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? const Center(child: Text('Event not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Status badge
                      if (_event!.isLive)
                        _LiveBadge()
                      else if (_event!.isPast)
                        _StatusBadge(label: 'ENDED', color: Colors.grey),
                      if (_event!.isLive || _event!.isPast) const SizedBox(height: 12),
                      // Title
                      Text(_event!.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                              height: 1.3)),
                      const SizedBox(height: 12),
                      // Event type
                      _InfoRow(
                        icon: Icons.category_outlined,
                        text: LiveEventType.fromValue(_event!.eventType)?.label ??
                            _event!.eventType,
                      ),
                      // Host
                      const SizedBox(height: 8),
                      _HostRow(event: _event!),
                      // Scheduled time
                      if (_event!.scheduledStart != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          text: _formatDateTime(_event!.scheduledStart!),
                        ),
                      ],
                      // RSVP count
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.people_outline,
                        text: '${_event!.rsvpCount} attending',
                      ),
                      // Viewers (if live)
                      if (_event!.isLive) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.visibility_outlined,
                          text: '${_event!.viewersCount} watching now',
                        ),
                      ],
                      // Description
                      if (_event!.description != null &&
                          _event!.description!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('About this event',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_event!.description!,
                            style: const TextStyle(fontSize: 14, height: 1.6)),
                      ],
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Action buttons
                      _ActionButtons(
                        event: _event!,
                        rsvpLoading: _rsvpLoading,
                        onRsvp: _rsvp,
                        onRemoveRsvp: _removeRsvp,
                        onJoinLive: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => LiveViewerScreen(event: _event!),
                        )),
                        onHostLive: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => LiveHostScreen(event: _event!),
                        )).then((_) => _load()),
                        onOpenMeetingLink: () async {
                          final url = _event!.meetingLink;
                          if (url == null) return;
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                        onWatchRecording: () async {
                          final url = _event!.recordingUrl;
                          if (url == null) return;
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.white),
          SizedBox(width: 6),
          Text('LIVE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
      ],
    );
  }
}

class _HostRow extends StatelessWidget {
  final LiveEvent event;
  const _HostRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: event.hostAvatarUrl != null ? NetworkImage(event.hostAvatarUrl!) : null,
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(50),
          child: event.hostAvatarUrl == null
              ? Text(
                  event.hostName.isNotEmpty ? event.hostName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hosted by', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(event.hostName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final LiveEvent event;
  final bool rsvpLoading;
  final void Function(String) onRsvp;
  final VoidCallback onRemoveRsvp;
  final VoidCallback onJoinLive;
  final VoidCallback onHostLive;
  final VoidCallback onOpenMeetingLink;
  final VoidCallback onWatchRecording;

  const _ActionButtons({
    required this.event,
    required this.rsvpLoading,
    required this.onRsvp,
    required this.onRemoveRsvp,
    required this.onJoinLive,
    required this.onHostLive,
    required this.onOpenMeetingLink,
    required this.onWatchRecording,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    if (event.isLive) {
      widgets.add(ElevatedButton.icon(
        onPressed: onJoinLive,
        icon: const Icon(Icons.play_circle_outline),
        label: const Text('Watch Live'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ));
      if (event.meetingLink != null) {
        widgets.add(const SizedBox(height: 10));
        widgets.add(OutlinedButton.icon(
          onPressed: onOpenMeetingLink,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open Meeting Link'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ));
      }
    } else if (event.isPast) {
      if (event.recordingUrl != null) {
        widgets.add(ElevatedButton.icon(
          onPressed: onWatchRecording,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Watch Recording'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ));
      } else {
        widgets.add(Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: const Center(child: Text('This event has ended', style: TextStyle(color: Colors.grey))),
        ));
      }
    } else {
      // Upcoming
      if (event.userRsvpStatus == 'attending') {
        widgets.add(OutlinedButton.icon(
          onPressed: rsvpLoading ? null : onRemoveRsvp,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          label: const Text("You're Going", style: TextStyle(color: Colors.green)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.green),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ));
        widgets.add(const SizedBox(height: 8));
        widgets.add(TextButton(
          onPressed: rsvpLoading ? null : onRemoveRsvp,
          child: const Text("Can't make it", style: TextStyle(color: Colors.grey)),
        ));
      } else {
        widgets.add(ElevatedButton.icon(
          onPressed: rsvpLoading ? null : () => onRsvp('attending'),
          icon: rsvpLoading
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.event_available),
          label: const Text('RSVP - Attending'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ));
        widgets.add(const SizedBox(height: 8));
        widgets.add(OutlinedButton(
          onPressed: rsvpLoading ? null : () => onRsvp('maybe'),
          child: const Text('Maybe'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ));
      }
      if (event.meetingLink != null) {
        widgets.add(const SizedBox(height: 10));
        widgets.add(OutlinedButton.icon(
          onPressed: onOpenMeetingLink,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Meeting Link'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widgets);
  }
}
