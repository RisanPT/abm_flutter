/// Institute timezone helpers — Saudi Arabia (Arabia Standard Time, UTC+3, no DST).
///
/// "Today" and date defaults are anchored to Saudi local time regardless of the
/// device's own timezone, so a class planned/attended on a given calendar day
/// matches Saudi time (the same anchor the backend uses).
const Duration kInstituteTzOffset = Duration(hours: 3);

/// "Now" in Saudi local time.
DateTime instituteNow() => DateTime.now().toUtc().add(kInstituteTzOffset);

/// Today's calendar day in Saudi time, as a UTC-midnight DateTime.
DateTime instituteToday() {
  final n = instituteNow();
  return DateTime.utc(n.year, n.month, n.day);
}
