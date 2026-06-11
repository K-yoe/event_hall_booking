import 'package:flutter/material.dart';
import 'services/database_helper.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';
import 'screens/guest/guest_home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/booking/hall_selection_screen.dart';
import 'screens/user/booking/hall_detail_screen.dart';
import 'screens/user/booking/date_time_screen.dart';
import 'screens/user/booking/services_screen.dart';
import 'screens/user/booking/summary_screen.dart';
import 'screens/user/booking/booking_success_screen.dart';
import 'screens/user/management/my_bookings_screen.dart';
import 'screens/user/management/edit_booking_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/manage_halls_screen.dart';
import 'screens/admin/add_edit_hall_screen.dart';
import 'screens/admin/all_bookings_screen.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/payment/payment_method_screen.dart';
import 'screens/payment/payment_processing_screen.dart';
import 'screens/payment/payment_history_screen.dart';
import 'screens/user/browse_screen.dart';
import 'screens/user/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Open (and on first run, create + seed) the local SQLite database.
  try {
    await DatabaseHelper.instance.database;
    await SessionService.instance.restore();
  } catch (e) {
    // ignore: avoid_print
    print('Database init failed: $e');
  }
  runApp(const EventHallBookingApp());
}

class EventHallBookingApp extends StatelessWidget {
  const EventHallBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventSpace',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const GuestHomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/user/home': (_) => const HallSelectionScreen(),
        '/user/hall-detail': (_) => const HallDetailScreen(),
        '/user/date-time': (_) => const DateTimeScreen(),
        '/user/services': (_) => const ServicesScreen(),
        '/user/summary': (_) => const SummaryScreen(),
        '/user/booking-success': (_) => const BookingSuccessScreen(),
        '/user/my-bookings': (_) => const MyBookingsScreen(),
        '/user/edit-booking': (_) => const EditBookingScreen(),
        '/payment/method': (_) => const PaymentMethodScreen(),
        '/payment/processing': (_) => const PaymentProcessingScreen(),
        '/payment/success': (_) => const PaymentSuccessScreen(),
        '/payment/failed': (_) => const PaymentFailedScreen(),
        '/payment/history': (_) => const PaymentHistoryScreen(),
        '/admin/dashboard': (_) => const AdminDashboardScreen(),
        '/admin/manage-halls': (_) => const ManageHallsScreen(),
        '/admin/add-hall': (_) => const AddEditHallScreen(),
        '/admin/all-bookings': (_) => const AllBookingsScreen(),
        '/admin/manage-users': (_) => const ManageUsersScreen(),
        '/user/browse': (_) => const BrowseScreen(),
        '/user/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
