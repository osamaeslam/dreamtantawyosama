import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';
import 'catalog_screen.dart';
import 'collection_forecast_view.dart';
import 'all_customers_analytics_view.dart';
import 'invoices_screen.dart';
import 'inventory_screen.dart';
import 'order_builder_screen.dart';
import 'rep_dashboard_screen.dart';
import 'target_performance_screen.dart';
import 'management_dashboard.dart';
import 'returns_screen.dart';
import 'visits_screen.dart';

class AdaptiveHomeScreen extends StatefulWidget {
  final AppUser currentUser;
  const AdaptiveHomeScreen({super.key, required this.currentUser});

  @override
  State<AdaptiveHomeScreen> createState() => _AdaptiveHomeScreenState();
}

class _AdaptiveHomeScreenState extends State<AdaptiveHomeScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'الرئيسية والمبيعات',
    'كتالوج الأصناف والأسعار',
    'الطلبيات وسلة الحجز',
    'الفواتير والطباعة',
    'الزيارات وخط السير',
    'حركة المخزون',
    'توقعات التحصيل',
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final themeProvider = context.watch<ThemeModeProvider>();

    return ResponsiveLayout(
      // 1. مظهر الموبايل (Phone < 650px): شريط سفلي متجاوب
      mobile: Scaffold(
        body: _buildSelectedScreen(_selectedIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          backgroundColor: AppTheme.darkSlate,
          indicatorColor: AppTheme.primaryGold,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'الكتالوج'),
            NavigationDestination(
              icon: Badge(
                label: Text('${cart.items.length}'),
                isLabelVisible: cart.items.isNotEmpty,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_bag),
              label: 'الطلبية',
            ),
            const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'الفواتير'),
            const NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on), label: 'الزيارات'),
            const NavigationDestination(icon: Icon(Icons.warehouse_outlined), selectedIcon: Icon(Icons.warehouse), label: 'المخزون'),
            const NavigationDestination(icon: Icon(Icons.energy_saver), selectedIcon: Icon(Icons.energy_saver_outlined), label: 'التوقعات'),
          ],
        ),
      ),

      // 2. مظهر التابلت والويب (Tablet & Web Desktop >= 650px): NavigationRail جانبي وشاشة موسعة Master-Detail
      desktop: Scaffold(
        body: Row(
          children: [
            // القائمة الجانبية في الويب (NavigationRail)
            NavigationRail(
              selectedIndex: _selectedIndex,
              backgroundColor: AppTheme.darkSlate,
              indicatorColor: AppTheme.primaryGold,
              useIndicator: true,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGold, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.storefront_rounded, color: AppTheme.darkSlate, size: 24),
                  ),
                ),
              ),
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              selectedLabelTextStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.secondaryGold, fontSize: 11),
              unselectedLabelTextStyle: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 10),
              destinations: [
                const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined, color: Colors.white), selectedIcon: Icon(Icons.dashboard, color: AppTheme.darkSlate), label: Text('الرئيسية')),
                const NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined, color: Colors.white), selectedIcon: Icon(Icons.inventory_2, color: AppTheme.darkSlate), label: Text('الكتالوج')),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text('${cart.items.length}'),
                    isLabelVisible: cart.items.isNotEmpty,
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                  ),
                  selectedIcon: const Icon(Icons.shopping_bag, color: AppTheme.darkSlate),
                  label: const Text('الطلبية'),
                ),
                const NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined, color: Colors.white), selectedIcon: Icon(Icons.receipt_long, color: AppTheme.darkSlate), label: Text('الفواتير')),
                const NavigationRailDestination(icon: Icon(Icons.location_on_outlined, color: Colors.white), selectedIcon: Icon(Icons.location_on, color: AppTheme.darkSlate), label: Text('الزيارات')),
                const NavigationRailDestination(icon: Icon(Icons.warehouse_outlined, color: Colors.white), selectedIcon: Icon(Icons.warehouse, color: AppTheme.darkSlate), label: Text('المخزون')),
                const NavigationRailDestination(icon: Icon(Icons.energy_saver, color: Colors.white), selectedIcon: Icon(Icons.energy_saver_outlined, color: AppTheme.darkSlate), label: Text('التوقعات')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF334155)),

            // مساحة العرض الرئيسية في Flutter Web
            Expanded(
              child: _buildSelectedScreen(_selectedIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedScreen(int index) {
    switch (index) {
      case 0:
        return RepDashboardScreen(currentUser: widget.currentUser);
      case 1:
        return CatalogScreen(currentUser: widget.currentUser);
      case 2:
        return OrderBuilderScreen(currentUser: widget.currentUser);
      case 3:
        return InvoicesScreen(currentUser: widget.currentUser);
      case 4:
        return VisitsScreen(currentUser: widget.currentUser);
      case 5:
        return InventoryScreen(currentUser: widget.currentUser);
      case 6:
        return CollectionForecastView(currentUser: widget.currentUser);
      default:
        return RepDashboardScreen(currentUser: widget.currentUser);
    }
  }
}
