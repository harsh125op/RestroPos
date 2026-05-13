import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/settings/presentation/providers/store_details_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/inventory/presentation/screens/product_list_screen.dart';
import 'features/billing/presentation/screens/create_invoice_screen.dart';
import 'features/billing/presentation/screens/invoice_history.dart';
import 'features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/billing/presentation/providers/billing_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.e('Flutter Framework Error', details.exception, details.stack);
  };

  // Handle platform errors (async/native)
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('Platform Error', error, stack);
    return true;
  };

  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('store_details');
  StoreDetails? storeDetails;
  if (data != null) {
    try {
      storeDetails = StoreDetails.fromMap(jsonDecode(data));
    } catch (e) {
      AppLogger.e('Failed to parse store details in main', e);
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        if (storeDetails != null)
          storeDetailsProvider.overrideWith((ref) => StoreDetailsNotifier(storeDetails))
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'QuickPOS Restaurant',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoiceHistoryProvider).value ?? [];
    final now = DateTime.now();
    final todayInvoices = invoices.where((inv) =>
        inv.date.year == now.year &&
        inv.date.month == now.month &&
        inv.date.day == now.day);
    final todaySales = todayInvoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text("QuickPOS"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome to TableTap,",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Text(
              "Restaurant Overview",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Today's Sales Card
            Card(
              elevation: 0,
              color: Colors.indigo.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.currency_rupee, color: Colors.indigo),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Today's Sales", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("₹${todaySales.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Printer Status
            Row(
              children: [
                const Icon(Icons.print, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text("Printer Status: Ready (External App)", style: TextStyle(color: Colors.green[700], fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _DashboardCard(
                  title: "Menu Items",
                  icon: Icons.restaurant_menu,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                ),
                _DashboardCard(
                  title: "New Order",
                  icon: Icons.add_shopping_cart,
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen())),
                ),
                _DashboardCard(
                  title: "Sales History",
                  icon: Icons.history,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen())),
                ),
                _DashboardCard(
                  title: "Reports",
                  icon: Icons.analytics,
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsDashboardScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
void _noOp() {}
