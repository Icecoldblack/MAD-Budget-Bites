import 'package:flutter/material.dart';

/// Shows how far along the lunch plan is:
///   1. Planned  ->  2. Bought  ->  3. Finished
/// A finished step gets a check mark.
class PlanProgress extends StatelessWidget {
  final bool isBought;
  final bool isFinished;

  const PlanProgress({
    super.key,
    required this.isBought,
    required this.isFinished,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // A plan is always "Planned" once it exists.
          _buildStep(context, 'Planned', true),
          _buildLine(context),
          _buildStep(context, 'Bought', isBought),
          _buildLine(context),
          _buildStep(context, 'Finished', isFinished),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String label, bool isDone) {
    final theme = Theme.of(context);
    final color = isDone ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Column(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildLine(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
