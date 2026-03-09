import 'package:flutter/material.dart';

class ReactionPicker extends StatefulWidget {
  final void Function(String reactionType) onReact;

  const ReactionPicker({super.key, required this.onReact});

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> {
  static const _reactions = [
    ('like', '👍'),
    ('love', '❤️'),
    ('fire', '🔥'),
    ('clap', '👏'),
    ('think', '🤔'),
  ];

  final Map<String, int> _animatingCounts = {};

  void _handleReact(String type) {
    setState(() {
      _animatingCounts[type] = (_animatingCounts[type] ?? 0) + 1;
    });
    widget.onReact(type);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          final count = (_animatingCounts[type] ?? 1) - 1;
          if (count <= 0) {
            _animatingCounts.remove(type);
          } else {
            _animatingCounts[type] = count;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _reactions.map((r) {
          final isAnimating = (_animatingCounts[r.$1] ?? 0) > 0;
          return GestureDetector(
            onTap: () => _handleReact(r.$1),
            child: AnimatedScale(
              scale: isAnimating ? 1.4 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isAnimating
                      ? Theme.of(context).colorScheme.primary.withAlpha(30)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Text(r.$2, style: const TextStyle(fontSize: 22)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
