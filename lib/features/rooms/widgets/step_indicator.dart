import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final isCompleted = index + 1 < currentStep;
            final isCurrent = index + 1 == currentStep;
            
            return Row(
              children: [
                // Circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent || isCompleted ? AppTheme.primary : Colors.grey[300],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // Line
                if (index < totalSteps - 1)
                  Container(
                    width: 40,
                    height: 2,
                    color: index + 1 < currentStep ? AppTheme.primary : Colors.grey[300],
                  ),
              ],
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Bước $currentStep / $totalSteps',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
