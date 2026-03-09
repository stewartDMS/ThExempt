import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/live_event_model.dart';
import '../../services/live_events_service.dart';
import '../../widgets/chat_message_bubble.dart';

class LiveHostScreen extends StatefulWidget {
  final LiveEvent event;

  const LiveHostScreen({super.key, required this.event});

  @override
  State<LiveHostScreen> createState() => _LiveHostScreenState();
}

class _LiveHostScreenState extends State<LiveHostScreen> {
  late LiveEvent _event;
  List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  final _scrollController = ScrollController();
  bool _endingStream = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadCurrentUser();
    if (!_event.isLive) _goLive();
    _loadChat();
    _startPolling();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _currentUserId = prefs.getString('userId'));
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _goLive() async {
    try {
      final updated = await LiveEventsService.goLive(_event.id);
      if (mounted) setState(() => _event = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error going live: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadChat();
    });
  }

  Future<void> _loadChat() async {
    try {
      final messages = await LiveEventsService.getChatMessages(_event.id);
      if (mounted) {
        setState(() => _messages = messages);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _endStream() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Stream'),
        content: const Text('Are you sure you want to end the live stream?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('End Stream')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _endingStream = true);
    try {
      await LiveEventsService.endStream(_event.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _endingStream = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_event.title,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis),
                        if (_event.isLive)
                          Row(children: [
                            const Icon(Icons.circle, size: 8, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('${_event.viewersCount} watching',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ]),
                      ],
                    ),
                  ),
                  // End stream button
                  TextButton(
                    onPressed: _endingStream ? null : _endStream,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withAlpha(200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _endingStream
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('End', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // Preview area
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              color: const Color(0xFF111111),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam, size: 48, color: Colors.white54),
                    const SizedBox(height: 12),
                    Text(
                      _event.isLive ? 'You are LIVE' : 'Going live...',
                      style: TextStyle(
                        color: _event.isLive ? Colors.red : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_event.meetingLink != null) ...[
                      const SizedBox(height: 8),
                      Text(_event.meetingLink!,
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
            // Chat section
            Expanded(
              child: Container(
                color: const Color(0xFF111111),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          const Text('Live Chat',
                              style: TextStyle(
                                  color: Colors.white70, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${_messages.length} messages',
                              style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(
                              child: Text('No messages yet',
                                  style: TextStyle(color: Colors.white38)),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) => ChatMessageBubble(
                                message: _messages[i],
                                isCurrentUser: _messages[i].userId == _currentUserId,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
