/// Shared date filter periods for register list screens.
enum RegisterDatePeriod {
  today('Aaj', 'Today'),
  yesterday('Kal', 'Yesterday'),
  thisWeek('Is Hafte', 'This Week'),
  thisMonth('Is Mahine', 'This Month'),
  custom('Khud Chunein', 'Custom');

  const RegisterDatePeriod(this.hindiLabel, this.englishLabel);

  final String hindiLabel;
  final String englishLabel;
}

abstract final class RegisterDateRange {
  static ({DateTime start, DateTime end}) resolve({
    required RegisterDatePeriod period,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return switch (period) {
      RegisterDatePeriod.today => (start: todayDate, end: todayDate),
      RegisterDatePeriod.yesterday => (
          start: todayDate.subtract(const Duration(days: 1)),
          end: todayDate.subtract(const Duration(days: 1)),
        ),
      RegisterDatePeriod.thisWeek => (
          start: todayDate.subtract(Duration(days: todayDate.weekday - 1)),
          end: todayDate,
        ),
      RegisterDatePeriod.thisMonth => (
          start: DateTime(todayDate.year, todayDate.month),
          end: todayDate,
        ),
      RegisterDatePeriod.custom => (
          start: customStart ?? todayDate,
          end: customEnd ?? todayDate,
        ),
    };
  }

  static bool includesDate({
    required DateTime date,
    required RegisterDatePeriod period,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime? now,
  }) {
    final range = resolve(
      period: period,
      customStart: customStart,
      customEnd: customEnd,
      now: now,
    );
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}
