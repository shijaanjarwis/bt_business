/// Sort register rows newest business date first, then latest time first.
abstract final class RegisterEntrySort {
  static int compareDates(DateTime aDate, DateTime aCreated, DateTime bDate, DateTime bCreated) {
    final dateCompare = bDate.compareTo(aDate);
    if (dateCompare != 0) return dateCompare;
    return bCreated.compareTo(aCreated);
  }
}
