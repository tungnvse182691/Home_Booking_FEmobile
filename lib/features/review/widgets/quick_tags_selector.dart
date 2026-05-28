import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class QuickTagsSelector extends StatelessWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final Function(String) onToggle;

  const QuickTagsSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: availableTags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return FilterChip(
          label: Text(
            tag,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? AppTheme.primary : Colors.black87,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onToggle(tag),
          selectedColor: AppTheme.primary.withValues(alpha: 0.1),
          checkmarkColor: AppTheme.primary,
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppTheme.primary : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }
}
