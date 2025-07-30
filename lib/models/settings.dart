import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 1)
class Settings extends HiveObject {
  @HiveField(0)
  double monthlyAllowance;

  @HiveField(1)
  double currentBalance;

  @HiveField(2)
  DateTime lastBalanceUpdate;

  @HiveField(3, defaultValue: 'monthly')
  String allowanceFrequency; // 'weekly' or 'monthly'

  @HiveField(4, defaultValue: 4) // Thursday = 4 (Monday = 1)
  int allowanceDay; // For weekly: 1-7 (Mon-Sun), For monthly: 1-28

  @HiveField(5)
  DateTime? lastAllowanceDate; // Track when allowance was last added

  Settings({
    required this.monthlyAllowance,
    required this.currentBalance,
    required this.lastBalanceUpdate,
    this.allowanceFrequency = 'monthly',
    this.allowanceDay = 4, // Default to Thursday
    this.lastAllowanceDate,
  });

  // Getter for weekly allowance amount
  double get weeklyAllowance => monthlyAllowance / 4.33; // Average weeks per month

  // Getter for display amount based on frequency
  double get displayAllowance => allowanceFrequency == 'weekly' ? weeklyAllowance : monthlyAllowance;

  // Getter for frequency display text
  String get frequencyText => allowanceFrequency == 'weekly' ? 'Weekly' : 'Monthly';

  // Get day name for weekly frequency
  String get allowanceDayName {
    if (allowanceFrequency == 'weekly') {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[allowanceDay - 1];
    } else {
      return '${allowanceDay}${_getOrdinalSuffix(allowanceDay)}';
    }
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  // Check if allowance should be added today
  bool shouldAddAllowance() {
    final now = DateTime.now();

    // If never received allowance, add it
    if (lastAllowanceDate == null) return true;

    if (allowanceFrequency == 'weekly') {
      // Check if it's the right day of week and at least a week has passed
      return now.weekday == allowanceDay &&
          now.difference(lastAllowanceDate!).inDays >= 7;
    } else {
      // Monthly: check if it's the right day of month and we're in a new month
      return now.day == allowanceDay &&
          (now.month != lastAllowanceDate!.month || now.year != lastAllowanceDate!.year);
    }
  }

  // Get next allowance date
  DateTime getNextAllowanceDate() {
    final now = DateTime.now();

    if (allowanceFrequency == 'weekly') {
      // Find next occurrence of allowanceDay
      int daysUntilNext = (allowanceDay - now.weekday) % 7;
      if (daysUntilNext == 0 && (lastAllowanceDate == null || now.difference(lastAllowanceDate!).inDays < 7)) {
        daysUntilNext = 7; // If today is allowance day but we already got it, next week
      }
      return now.add(Duration(days: daysUntilNext));
    } else {
      // Monthly
      DateTime nextMonth = DateTime(now.year, now.month + 1, allowanceDay);
      if (now.day < allowanceDay) {
        nextMonth = DateTime(now.year, now.month, allowanceDay);
      }
      return nextMonth;
    }
  }

  // Default settings
  static Settings defaultSettings() {
    return Settings(
      monthlyAllowance: 150.0,
      currentBalance: 150.0,
      lastBalanceUpdate: DateTime.now(),
      allowanceFrequency: 'monthly',
      allowanceDay: 1, // 1st of month for monthly, Monday for weekly
      lastAllowanceDate: null,
    );
  }
}