import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../../../services/chat_service.dart';

class ProjectChatWidget extends StatefulWidget {
  final Project project;
  final String? currentUserId;
  final String? currentUserName;

  const ProjectChatWidget({
    super.key,
    required this.project,
    this.currentUserId,
    this.currentUserName,
  });

  @override
  State<ProjectChatWidget> createState() => _ProjectChatWidgetState();
}

class _ProjectChatWidgetState extends State<ProjectChatWidget> {
  bool _isOpen = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  dynamic _channel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final msgs =
        await ChatService.getMessages(widget.project.id);
    if (mounted) {
      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
        _loading = false;
      });
      _subscribe();
    }
  }

  void _subscribe() {
    _channel = ChatService.subscribeToMessages(
      widget.project.id,
      (msg) {
        if (mounted) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      },
    );
  }

  @override
  void dispose() {
    if (_channel != null) {
      ChatService.unsubscribe(_channel);
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await ChatService.sendMessage(widget.project.id, text);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating chat button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => setState(() => _isOpen = !_isOpen),
            backgroundColor: Colors.indigo,
            child: Icon(
              _isOpen ? Icons.close : Icons.chat_outlined,
              color: Colors.white,
            ),
          ),
        ),
        // Chat panel
        if (_isOpen)
          Positioned(
            right: 16,
            bottom: 80,
            width: 320,
            height: 400,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: Colors.indigo,
                      child: Row(
                        children: [
                          const Icon(Icons.chat,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Team Chat',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                            onPressed: () =>
                                setState(() => _isOpen = false),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator())
                          : _messages.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No messages yet.\nSay hello! 👋',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, i) {
                                    final msg = _messages[i];
                                    final isMe = msg.userId ==
                                        widget.currentUserId;
                                    return _MessageBubble(
                                        message: msg, isMe: isMe);
                                  },
                                ),
                    ),
                    // Input
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                              color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'Type a message…',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                      color: Colors.grey[300]!),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.indigo),
                            onPressed: _sendMessage,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: isMe ? Colors.indigo : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                message.userName,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              message.content,
              style: TextStyle(
                  fontSize: 13,
                  color: isMe ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
