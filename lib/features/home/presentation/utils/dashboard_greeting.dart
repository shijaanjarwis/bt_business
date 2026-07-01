/// Time-of-day greeting for the dashboard header.
abstract final class DashboardGreeting {
  static ({String hindi, String english}) forTime([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) {
      return (hindi: 'Suprabhat', english: 'Good Morning');
    }
    if (hour >= 12 && hour < 17) {
      return (hindi: 'Namaste', english: 'Good Afternoon');
    }
    return (hindi: 'Namaste', english: 'Good Evening');
  }
}
