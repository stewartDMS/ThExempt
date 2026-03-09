import 'package:flutter/material.dart';
import '../../models/live_event_model.dart';
import '../../services/live_events_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _meetingLinkController = TextEditingController();

  String _selectedCategory = 'general';
  String _selectedEventType = LiveEventType.values.first.value;
  DateTime? _scheduledStart;
  DateTime? _scheduledEnd;
  bool _goLiveNow = false;
  bool _allowChat = true;
  bool _allowReactions = true;
  bool _isSubmitting = false;

  static const _categories = [
    ('general', '💬 General'),
    ('world_problems', '🌍 World Problems'),
    ('ideas', '💡 Ideas'),
    ('learning', '🎓 Learning'),
    ('networking', '🤝 Networking'),
    ('feedback', '🐛 Feedback'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _scheduledStart = dt;
      } else {
        _scheduledEnd = dt;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final event = await LiveEventsService.createLiveEvent(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        category: _selectedCategory,
        eventType: _selectedEventType,
        scheduledStart: _goLiveNow ? null : _scheduledStart,
        scheduledEnd: _goLiveNow ? null : _scheduledEnd,
        meetingLink: _meetingLinkController.text.trim().isEmpty
            ? null
            : _meetingLinkController.text.trim(),
        allowChat: _allowChat,
        allowReactions: _allowReactions,
      );

      if (_goLiveNow && mounted) {
        // Start the event immediately
        await LiveEventsService.goLive(event.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are now live!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event scheduled!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_goLiveNow ? 'Go Live!' : 'Schedule',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Event Title',
                hintText: 'What is this event about?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            // Description
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Describe what attendees can expect...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            // Event type
            const Text('Event Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: LiveEventType.values.map((t) {
                final isSelected = _selectedEventType == t.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEventType = t.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(t.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Category
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(cat.$2,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Go live now toggle
            SwitchListTile(
              title: const Text('Go Live Now',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Start streaming immediately'),
              value: _goLiveNow,
              onChanged: (v) => setState(() => _goLiveNow = v),
              contentPadding: EdgeInsets.zero,
            ),
            // Schedule
            if (!_goLiveNow) ...[
              const SizedBox(height: 8),
              _DateTimePicker(
                label: 'Start Date & Time',
                value: _scheduledStart,
                onTap: () => _pickDateTime(true),
              ),
              const SizedBox(height: 10),
              _DateTimePicker(
                label: 'End Date & Time (optional)',
                value: _scheduledEnd,
                onTap: () => _pickDateTime(false),
              ),
            ],
            const SizedBox(height: 20),
            // Meeting link
            TextFormField(
              controller: _meetingLinkController,
              decoration: InputDecoration(
                labelText: 'Meeting Link (optional)',
                hintText: 'Zoom, Google Meet, YouTube Live...',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            // Settings
            const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
            SwitchListTile(
              title: const Text('Allow Chat'),
              value: _allowChat,
              onChanged: (v) => setState(() => _allowChat = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Allow Reactions'),
              value: _allowReactions,
              onChanged: (v) => setState(() => _allowReactions = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateTimePicker({required this.label, required this.value, required this.onTap});

  String _format(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? _format(value!) : 'Select date & time',
                    style: TextStyle(
                        fontSize: 14,
                        color: value != null ? Colors.black87 : Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
