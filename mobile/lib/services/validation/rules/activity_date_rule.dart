import '../../../../core/config/app_rules.dart';
import '../validation_rule.dart';

class ActivityDateRule extends ValidationRule {
  ActivityDateRule({this.nowProvider});

  final DateTime Function()? nowProvider;

  @override
  Future<ValidationResult> validate(ValidationContext context) async {
    final now = nowProvider?.call() ?? DateTime.now();
    final activityDate = context.activity.startDateLocal;

    final isToday =
        activityDate.year == now.year &&
        activityDate.month == now.month &&
        activityDate.day == now.day;

    if (!isToday) {
      return const ValidationResult(
        isValid: false,
        reason: 'La actividad no corresponde al día actual.',
        confidence: AppRules.rejectedConfidence,
      );
    }

    return const ValidationResult(
      isValid: true,
      reason: 'La actividad corresponde al día actual.',
      confidence: AppRules.defaultConfidence,
    );
  }
}
