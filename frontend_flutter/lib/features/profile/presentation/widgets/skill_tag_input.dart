import 'package:flutter/material.dart';

class SkillTagInput extends StatelessWidget {
  final List<String> initialSkills;

  const SkillTagInput({super.key, required this.initialSkills});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: initialSkills.map((skill) {
        return Chip(
          label: Text(skill),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {},
        );
      }).toList(),
    );
  }
}
