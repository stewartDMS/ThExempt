import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/live_event_model.dart';
import '../../services/live_events_service.dart';
import '../../widgets/chat_message_bubble.dart';
import '../../widgets/reaction_picker.dart';

class LiveViewerScreen extends StatefulWidget {
  final LiveEvent event;

  const LiveViewerScreen({super.key, required this.event});

  @override
  State<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<LiveViewerScreen> {
  List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sendingMessage = false;
  int _viewersCount = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _viewersCount = widget.event.viewersCount;
    _loadCurrentUser();
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
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadChat();
    });
  }

  Future<void> _loadChat() async {
    try {
      final messages = await LiveEventsService.getChatMessages(widget.event.id);
      if (mounted) {
        setState(() => _messages = messages);
        // Auto-scroll to bottom
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

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _sendingMessage) return;

    setState(() => _sendingMessage = true);
    try {
      final msg = await LiveEventsService.sendChatMessage(widget.event.id, text);
      _chatController.clear();
      if (mounted) {
        setState(() {
          _messages = [..._messages, msg];
          _sendingMessage = false;
        });
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
    } catch (_) {
      if (mounted) setState(() => _sendingMessage = false);
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        Text(widget.event.title,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis),
                        Text(widget.event.hostName,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Live badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.red, borderRadius: BorderRadius.circular(4)),
                    child: const Text('LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  // Viewer count
                  Row(children: [
                    const Icon(Icons.visibility, size: 14, color: Colors.white54),
                    const SizedBox(width: 3),
                    Text('$_viewersCount',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ]),
                ],
              ),
            ),
            // Video area placeholder
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              color: const Color(0xFF111111),
              child: widget.event.meetingLink != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.live_tv, size: 48, color: Colors.white54),
                          const SizedBox(height: 12),
                          const Text('Live stream active',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Open Stream'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.live_tv, size: 48, color: Colors.white54),
                          SizedBox(height: 12),
                          Text('Live stream', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
            ),
            // Reactions (if allowed)
            if (widget.event.allowReactions)
              Container(
                color: const Color(0xFF1A1A1A),
                child: ReactionPicker(
                  onReact: (type) => LiveEventsService.sendReaction(widget.event.id, type),
                ),
              ),
            // Chat section
            if (widget.event.allowChat) ...[
              Expanded(
                child: Container(
                  color: const Color(0xFF111111),
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text('No messages yet',
                              style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => ChatMessageBubble(
                            message: _messages[i],
                            isCurrentUser: _messages[i].userId == _currentUserId,
                          ),
                        ),
                ),
              ),
              // Chat input
              Container(
                color: const Color(0xFF1A1A1A),
                padding: EdgeInsets.only(
                  left: 12,
                  right: 8,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Say something...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          filled: true,
                          fillColor: Colors.white10,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _sendingMessage ? null : _sendMessage,
                      icon: _sendingMessage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white54))
                          : const Icon(Icons.send, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Chat is disabled for this event',
                      style: TextStyle(color: Colors.white38)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
