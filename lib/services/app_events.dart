import 'package:flutter/foundation.dart';

/// Global signal that user-facing data (bookings, payments, profile) changed.
///
/// The user shell keeps Profile and My Bookings alive together inside an
/// IndexedStack, so each screen's `initState` runs only once. Without a shared
/// signal a mutation in one tab (e.g. cancelling a booking, creating a new one,
/// editing the profile) leaves the other tab showing stale data.
///
/// Any screen that displays this data listens to [dataVersion] and reloads when
/// it changes; every DbService mutation bumps it, so all views stay in sync.
class AppEvents {
  AppEvents._();

  /// Increments whenever persisted user data changes.
  static final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  /// Notify all listeners that data changed and views should reload.
  static void notifyDataChanged() => dataVersion.value++;
}
