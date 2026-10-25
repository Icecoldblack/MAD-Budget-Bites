import 'package:flutter/material.dart';

// Planned -> Bought -> Finished, with a check mark on each step that is done.
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

    Color color = theme.colorScheme.outline;
    IconData icon = Icons.radio_button_unchecked;
    if (isDone) {
      color = theme.colorScheme.primary;
      icon = Icons.check_circle;
    }

    return Column(
      children: [
        Icon(icon, color: color),
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
