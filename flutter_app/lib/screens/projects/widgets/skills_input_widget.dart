import 'package:flutter/material.dart';

class SkillsInputWidget extends StatefulWidget {
  final List<String> selectedSkills;
  final Function(List<String>) onSkillsChanged;

  const SkillsInputWidget({
    super.key,
    required this.selectedSkills,
    required this.onSkillsChanged,
  });

  @override
  State<SkillsInputWidget> createState() => _SkillsInputWidgetState();
}

class _SkillsInputWidgetState extends State<SkillsInputWidget> {
  final TextEditingController _skillController = TextEditingController();

  // Suggested skills
  final List<String> _suggestedSkills = [
    'React',
    'Flutter',
    'Node.js',
    'Python',
    'JavaScript',
    'TypeScript',
    'Java',
    'C++',
    'Swift',
    'Kotlin',
    'Go',
    'Rust',
    'PHP',
    'Ruby',
    'SQL',
    'MongoDB',
    'PostgreSQL',
    'Firebase',
    'AWS',
    'Docker',
    'Kubernetes',
    'GraphQL',
    'REST API',
    'UI/UX Design',
    'Figma',
  ];

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill(String skill) {
    final trimmedSkill = skill.trim();
    if (trimmedSkill.isNotEmpty && 
        !widget.selectedSkills.contains(trimmedSkill)) {
      final updatedSkills = List<String>.from(widget.selectedSkills)
        ..add(trimmedSkill);
      widget.onSkillsChanged(updatedSkills);
      _skillController.clear();
    }
  }

  void _removeSkill(String skill) {
    final updatedSkills = List<String>.from(widget.selectedSkills)
      ..remove(skill);
    widget.onSkillsChanged(updatedSkills);
  }

  @override
  Widget build(BuildContext context) {
    final availableSuggestions = _suggestedSkills
        .where((skill) => !widget.selectedSkills.contains(skill))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field
        TextField(
          controller: _skillController,
          decoration: InputDecoration(
            labelText: 'Add Skills',
            hintText: 'Type a skill and press Enter',
            prefixIcon: const Icon(Icons.code),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addSkill(_skillController.text),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: _addSkill,
        ),
        const SizedBox(height: 12),

        // Selected skills chips
        if (widget.selectedSkills.isNotEmpty) ...[
          const Text(
            'Selected Skills:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedSkills.map((skill) {
              return Chip(
                label: Text(skill),
                onDeleted: () => _removeSkill(skill),
                deleteIcon: const Icon(Icons.close, size: 18),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Suggested skills
        if (availableSuggestions.isNotEmpty) ...[
          const Text(
            'Suggested Skills:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSuggestions.take(10).map((skill) {
              return ActionChip(
                label: Text(skill),
                onPressed: () => _addSkill(skill),
                avatar: const Icon(Icons.add, size: 16),
                backgroundColor: Colors.grey[100],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
