import 'package:flutter/material.dart';
import '../../models/live_event_model.dart';
import '../../services/live_events_service.dart';
import '../../widgets/live_event_card.dart';
import 'create_event_screen.dart';

class EventsHomeScreen extends StatefulWidget {
  const EventsHomeScreen({super.key});

  @override
  State<EventsHomeScreen> createState() => _EventsHomeScreenState();
}

class _EventsHomeScreenState extends State<EventsHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<LiveEvent> _liveNow = [];
  List<LiveEvent> _upcoming = [];
  List<LiveEvent> _past = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        LiveEventsService.getLiveEvents(status: 'live'),
        LiveEventsService.getLiveEvents(status: 'upcoming'),
        LiveEventsService.getLiveEvents(status: 'past'),
      ]);
      if (mounted) {
        setState(() {
          _liveNow = results[0];
          _upcoming = results[1];
          _past = results[2];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_liveNow.isNotEmpty) ...[
                    const Icon(Icons.circle, size: 8, color: Colors.red),
                    const SizedBox(width: 4),
                  ],
                  const Text('Live'),
                ],
              ),
            ),
            const Tab(text: 'Upcoming'),
            const Tab(text: 'Past'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _EventsList(events: _liveNow, emptyMessage: 'No live events right now', onRefresh: _loadEvents),
                _EventsList(events: _upcoming, emptyMessage: 'No upcoming events', onRefresh: _loadEvents),
                _EventsList(events: _past, emptyMessage: 'No past events', onRefresh: _loadEvents),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const CreateEventScreen()))
            .then((_) => _loadEvents()),
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<LiveEvent> events;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const _EventsList({required this.events, required this.emptyMessage, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.live_tv_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(emptyMessage,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: events.length,
        itemBuilder: (_, i) => LiveEventCard(event: events[i]),
      ),
    );
  }
}
