import 'package:flutter/material.dart';
import '../services/skills_service.dart';

class CategorizedSkillPicker extends StatefulWidget {
  final List<String> selectedSkills;
  final Function(List<String>) onSkillsChanged;

  const CategorizedSkillPicker({
    super.key,
    required this.selectedSkills,
    required this.onSkillsChanged,
  });

  @override
  State<CategorizedSkillPicker> createState() => _CategorizedSkillPickerState();
}

class _CategorizedSkillPickerState extends State<CategorizedSkillPicker> {
  Map<String, List<Map<String, dynamic>>> _skillCategories = {};
  bool _isLoading = true;
  String _selectedCategory = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSkillCategories();
  }

  Future<void> _loadSkillCategories() async {
    try {
      final categories = await SkillsService.getSkillCategories();
      setState(() {
        _skillCategories = categories;
        _selectedCategory = categories.keys.isNotEmpty ? categories.keys.first : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load skills: $e')),
        );
      }
    }
  }

  Future<void> _searchSkills(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await SkillsService.searchSkills(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      debugPrint('Search error: $e');
    }
  }

  void _toggleSkill(String skillName) {
    final newSkills = List<String>.from(widget.selectedSkills);
    if (newSkills.contains(skillName)) {
      newSkills.remove(skillName);
    } else {
      newSkills.add(skillName);
    }
    widget.onSkillsChanged(newSkills);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final showSearch = _searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search skills...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchSkills('');
                    },
                  )
                : null,
          ),
          onChanged: _searchSkills,
        ),
        const SizedBox(height: 16),

        // Show search results or category tabs
        if (showSearch)
          _buildSearchResults()
        else
          _buildCategoryView(),

        // Selected skills
        if (widget.selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected Skills (${widget.selectedSkills.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedSkills.map((skill) {
              return Chip(
                label: Text(skill),
                onDeleted: () => _toggleSkill(skill),
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                labelStyle: const TextStyle(color: Color(0xFF6366F1)),
                deleteIconColor: const Color(0xFF6366F1),
                side: BorderSide(
                    color: const Color(0xFF6366F1).withOpacity(0.3)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('No skills found')),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final skill = _searchResults[index];
          final isSelected = widget.selectedSkills.contains(skill['name']);

          return ListTile(
            leading: Text(skill['icon'] ?? '📌',
                style: const TextStyle(fontSize: 24)),
            title: Text(skill['name'] ?? ''),
            subtitle: Text(
                '${skill['parent_category'] ?? ''} • ${skill['description'] ?? ''}'),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
                : const Icon(Icons.add_circle_outline),
            onTap: () => _toggleSkill(skill['name'] ?? ''),
          );
        },
      ),
    );
  }

  Widget _buildCategoryView() {
    if (_skillCategories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('No skill categories available')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _skillCategories.keys.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Skills in selected category
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _skillCategories[_selectedCategory]?.length ?? 0,
            itemBuilder: (context, index) {
              final skill = _skillCategories[_selectedCategory]![index];
              final isSelected =
                  widget.selectedSkills.contains(skill['name']);

              return ListTile(
                leading: Text(skill['icon'] ?? '📌',
                    style: const TextStyle(fontSize: 24)),
                title: Text(skill['name'] ?? ''),
                subtitle: Text(skill['description'] ?? ''),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
                    : const Icon(Icons.add_circle_outline),
                onTap: () => _toggleSkill(skill['name'] ?? ''),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
