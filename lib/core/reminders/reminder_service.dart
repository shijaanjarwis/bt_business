import '../accounting/transaction_types.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'reminder_models.dart';

/// Single source of truth for reminder business rules — offline, no duplicates.
abstract final class ReminderService {
  static bool isSaleOrPurchase(String type) {
    return type == TransactionTypes.sale || type == TransactionTypes.purchase;
  }

  /// Pending when sale/purchase has remaining balance, or payment has a reminder set.
  static bool isPending({
    required String transactionType,
    required double dueAmount,
    required DateTime? reminderDate,
  }) {
    if (isSaleOrPurchase(transactionType)) {
      return dueAmount > 0;
    }
    return reminderDate != null;
  }

  /// Clears reminder automatically when remaining is zero on sale/purchase.
  static DateTime? effectiveReminderDate({
    required String transactionType,
    required double dueAmount,
    required DateTime? requestedReminderDate,
  }) {
    if (requestedReminderDate == null) return null;
    if (isSaleOrPurchase(transactionType) && dueAmount <= 0) return null;
    return DateTime(
      requestedReminderDate.year,
      requestedReminderDate.month,
      requestedReminderDate.day,
    );
  }

  static String? reminderDateIso(DateTime? date) {
    if (date == null) return null;
    return DateFormatter.isoDate(date);
  }

  static DateTime? parseReminderDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.parse(iso);
  }

  /// Amount shown on reminder cards — remaining for sale/purchase, full for payments.
  static double reminderAmount({
    required String transactionType,
    required double totalAmount,
    required double dueAmount,
  }) {
    if (isSaleOrPurchase(transactionType) && dueAmount > 0) {
      return dueAmount;
    }
    return totalAmount;
  }

  static int daysFromToday(DateTime reminderDate, {DateTime? reference}) {
    final ref = reference ?? DateTime.now();
    final due = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
    final today = DateTime(ref.year, ref.month, ref.day);
    return today.difference(due).inDays;
  }

  static String dueLabel(DateTime reminderDate, {DateTime? reference}) {
    final days = daysFromToday(reminderDate, reference: reference);
    if (days == 0) return 'Today';
    if (days == 1) return 'Overdue by 1 day';
    if (days > 1) return 'Overdue by $days days';
    if (days == -1) return 'Tomorrow';
    return 'In ${-days} days';
  }

  static ReminderEntry mapRow(Map<String, Object?> row) {
    final type = row['type']! as String;
    final total = (row['total_amount'] as num?)?.toDouble() ?? 0;
    final due = (row['due_amount'] as num?)?.toDouble() ?? 0;
    final reminderIso = row['reminder_date']! as String;

    final dateIso = row['date'] as String?;
    final transactionDate =
        dateIso != null && dateIso.isNotEmpty ? DateTime.parse(dateIso) : null;

    return ReminderEntry(
      transactionId: row['id']! as String,
      transactionType: type,
      partyId: row['party_id']! as String,
      partyName: row['party_name']! as String,
      partyPhone: row['party_phone'] as String? ?? '',
      amount: reminderAmount(
        transactionType: type,
        totalAmount: total,
        dueAmount: due,
      ),
      reminderDate: DateTime.parse(reminderIso),
      dueAmount: due,
      direction: ReminderDirection.fromTransactionType(type),
      transactionDate: transactionDate,
      notes: row['notes'] as String? ?? '',
    );
  }

  /// Groups pending entries by party ID — one card per party on list screens.
  static List<PartyPendingGroup> groupByParty(List<ReminderEntry> entries) {
    final grouped = <String, List<ReminderEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.partyId, () => []).add(entry);
    }

    final groups = grouped.entries.map((bucket) {
      final partyEntries = [...bucket.value]
        ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
      final first = partyEntries.first;
      final oldestDueDate = partyEntries.first.reminderDate;
      final totalPendingAmount = partyEntries.fold<double>(
        0,
        (sum, entry) => sum + entry.amount,
      );

      return PartyPendingGroup(
        partyId: first.partyId,
        partyName: first.partyName,
        partyPhone: first.partyPhone,
        totalPendingAmount: totalPendingAmount,
        entryCount: partyEntries.length,
        oldestDueDate: oldestDueDate,
        direction: first.direction,
        entries: partyEntries,
      );
    }).toList()
      ..sort((a, b) => a.oldestDueDate.compareTo(b.oldestDueDate));

    return groups;
  }

  static ReminderDashboardSummary summarize(List<ReminderEntry> entries, {DateTime? reference}) {
    final ref = reference ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    double receiveToday = 0;
    double payToday = 0;
    double pendingReceivable = 0;
    double pendingPayable = 0;
    double tomorrowReceive = 0;
    double tomorrowPay = 0;
    double next7Receive = 0;
    double next7Pay = 0;
    double overdueReceive = 0;
    double overduePay = 0;
    var todayCount = 0;

    for (final entry in entries) {
      final due = DateTime(
        entry.reminderDate.year,
        entry.reminderDate.month,
        entry.reminderDate.day,
      );
      final isReceive = entry.direction == ReminderDirection.receive;

      if (isReceive) {
        pendingReceivable += entry.amount;
      } else {
        pendingPayable += entry.amount;
      }

      if (due.isBefore(today)) {
        if (isReceive) {
          overdueReceive += entry.amount;
        } else {
          overduePay += entry.amount;
        }
        todayCount++;
      } else if (due == today) {
        if (isReceive) {
          receiveToday += entry.amount;
        } else {
          payToday += entry.amount;
        }
        todayCount++;
      } else if (due == tomorrow) {
        if (isReceive) {
          tomorrowReceive += entry.amount;
        } else {
          tomorrowPay += entry.amount;
        }
      } else if (due.isAfter(tomorrow) && !due.isAfter(weekEnd)) {
        if (isReceive) {
          next7Receive += entry.amount;
        } else {
          next7Pay += entry.amount;
        }
      }
    }

    return ReminderDashboardSummary(
      receiveToday: receiveToday,
      payToday: payToday,
      pendingReceivable: pendingReceivable,
      pendingPayable: pendingPayable,
      tomorrowReceive: tomorrowReceive,
      tomorrowPay: tomorrowPay,
      next7DaysReceive: next7Receive,
      next7DaysPay: next7Pay,
      overdueReceive: overdueReceive,
      overduePay: overduePay,
      todayReminderCount: todayCount,
    );
  }

  /// Builds 3-level notification copy — grouped when multiple reminders due.
  static ReminderNotificationContent buildNotificationContent({
    required ReminderNotificationLevel level,
    required List<ReminderEntry> dueTodayAndOverdue,
    DateTime? reference,
  }) {
    if (dueTodayAndOverdue.isEmpty) {
      return const ReminderNotificationContent(title: '', body: '');
    }

    final payload = notificationListPayload(dueTodayAndOverdue);
    final sorted = _sortedForNotification(dueTodayAndOverdue, reference: reference);

    if (sorted.length == 1) {
      final entry = sorted.first;
      return ReminderNotificationContent(
        title: _titleForLevel(level),
        body: _singleEntryBody(level, entry, reference: reference),
        payload: payload,
      );
    }

    final lines = sorted
        .take(6)
        .map((entry) => '• ${entry.partyName} ${CurrencyFormatter.format(entry.amount)}')
        .join('\n');
    final count = sorted.length;
    final overdueCount = sorted
        .where((e) => daysFromToday(e.reminderDate, reference: reference) > 0)
        .length;

    final body = switch (level) {
      ReminderNotificationLevel.morning => overdueCount == count
          ? '$count overdue payments.\n$lines\nTap to view all reminders.'
          : '$count reminders pending today.\n$lines\nTap to view all reminders.',
      ReminderNotificationLevel.afternoon =>
        '$count reminders abhi bhi baaki hain.\n$lines',
      ReminderNotificationLevel.evening =>
        'Aaj ka last reminder — $count baaki hain.\n$lines',
    };

    return ReminderNotificationContent(
      title: _titleForLevel(level, grouped: true),
      body: body,
      payload: payload,
    );
  }

  static String _titleForLevel(ReminderNotificationLevel level, {bool grouped = false}) {
    return switch (level) {
      ReminderNotificationLevel.morning =>
        grouped ? "Today's Payment Reminders" : "Today's Payment Reminder",
      ReminderNotificationLevel.afternoon => 'Reminder',
      ReminderNotificationLevel.evening => 'Last Reminder Today',
    };
  }

  static String _singleEntryBody(
    ReminderNotificationLevel level,
    ReminderEntry entry, {
    DateTime? reference,
  }) {
    final amount = CurrencyFormatter.format(entry.amount);
    final days = daysFromToday(entry.reminderDate, reference: reference);
    final isReceive = entry.direction == ReminderDirection.receive;
    final overdueSuffix = days > 0
        ? ' — Overdue by $days ${days == 1 ? 'day' : 'days'}'
        : '';

    return switch (level) {
      ReminderNotificationLevel.morning => isReceive
          ? '${entry.partyName} se $amount lena hai aaj$overdueSuffix.'
          : '${entry.partyName} ko $amount dena hai aaj$overdueSuffix.',
      ReminderNotificationLevel.afternoon => isReceive
          ? '${entry.partyName} se $amount lena abhi bhi baaki hai$overdueSuffix.'
          : '${entry.partyName} ko $amount dena abhi bhi baaki hai$overdueSuffix.',
      ReminderNotificationLevel.evening => isReceive
          ? '${entry.partyName} se $amount lena abhi bhi baaki hai$overdueSuffix.'
          : '${entry.partyName} ko $amount dena abhi bhi baaki hai$overdueSuffix.',
    };
  }

  static List<ReminderEntry> _sortedForNotification(
    List<ReminderEntry> entries, {
    DateTime? reference,
  }) {
    return [...entries]
      ..sort((a, b) {
        final aDays = daysFromToday(a.reminderDate, reference: reference);
        final bDays = daysFromToday(b.reminderDate, reference: reference);
        if (aDays != bDays) return bDays.compareTo(aDays);
        return a.reminderDate.compareTo(b.reminderDate);
      });
  }

  /// Tap payload for reminder list screens — receive-today, pay-today, or home.
  static String notificationListPayload(List<ReminderEntry> entries) {
    if (entries.isEmpty) return 'list:home';

    final hasReceive = entries.any((e) => e.direction == ReminderDirection.receive);
    final hasPay = entries.any((e) => e.direction == ReminderDirection.payment);

    if (hasReceive && !hasPay) return 'list:receive-today';
    if (hasPay && !hasReceive) return 'list:pay-today';
    return 'list:home';
  }

  /// Legacy morning body builder — kept for tests.
  static String buildMorningNotificationBody({
    required List<ReminderEntry> dueTodayAndOverdue,
    required ReminderDashboardSummary summary,
    DateTime? reference,
  }) {
    return buildNotificationContent(
      level: ReminderNotificationLevel.morning,
      dueTodayAndOverdue: dueTodayAndOverdue,
      reference: reference,
    ).body;
  }

  /// Payload for notification tap — `list:slug` or `transactionType:transactionId`.
  static String notificationPayload(ReminderEntry entry) {
    return '${entry.transactionType}:${entry.transactionId}';
  }
}
