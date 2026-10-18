import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_navigation.dart';
import '../widgets/responsive_layout.dart';
import 'catalog_screen.dart';
import 'collection_forecast_view.dart';
import 'all_customers_analytics_view.dart';
import 'invoices_screen.dart';
import 'inventory_screen.dart';
import 'order_builder_screen.dart';
import 'rep_dashboard_screen.dart';
import 'target_performance_screen.dart';
import 'visits_screen.dart';

class AdaptiveHomeScreen extends StatefulWidget {
  final AppUser currentUser;
  const AdaptiveHomeScreen({super.key, required this.currentUser});

  @override
  State<AdaptiveHomeScreen> createState() => _AdaptiveHomeScreenState();
}

class _AdaptiveHomeScreenState extends State<AdaptiveHomeScreen> {
  int _selectedIndex = 0;

  void _selectSecondaryDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final colorScheme = Theme.of(context).colorScheme;
    final cartCount = cart.items.length;

    return ResponsiveLayout(
      // 1. مظهر الموبايل (Phone < 650px): شريط سفلي متجاوب
      mobile: Scaffold(
        body: _selectedIndex == AppNavigation.moreIndex
            ? _buildMoreScreen(context)
            : _buildSelectedScreen(_selectedIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex < 3 ? _selectedIndex : 3,
          backgroundColor: colorScheme.surface,
          indicatorColor: AppTheme.primaryGold.withOpacity(0.22),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex =
                index == 3 ? AppNavigation.moreIndex : index);
          },
          destinations: [
            AppNavigation.buildMobileDestination(0, cartCount),
            AppNavigation.buildMobileDestination(1, cartCount),
            AppNavigation.buildMobileDestination(2, cartCount),
            AppNavigation.buildMobileDestination(AppNavigation.moreIndex, cartCount),
          ],
        ),
      ),

      // 2. مظهر التابلت والويب (Tablet & Web Desktop >= 650px): NavigationRail جانبي
      desktop: Scaffold(
        body: Row(
          children: [
            AppNavigationRail(
              selectedIndex: _selectedIndex,
              cartItemCount: cartCount,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
            const VerticalDivider(
                thickness: 1, width: 1, color: Color(0xFF334155)),
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

  Widget _buildMoreScreen(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      (index: 3, title: 'الفواتق والطباعة', subtitle: 'عرض الفواتق ومتابعة المستندات', icon: Icons.receipt_long_outlined),
      (index: 4, title: 'الزيارات وخط السير', subtitle: 'تسجيل الزيارات ومتابعة التحصيل', icon: Icons.location_on_outlined),
      (index: 5, title: 'حركة المخزون', subtitle: 'الأرصدة والمعاملات اليومية', icon: Icons.warehouse_outlined),
      (index: 6, title: 'توقعات التحصيل', subtitle: 'متابعة التوقعات الأسبوعية', icon: Icons.energy_savings_leaf_outlined),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('المزيد من الأقسام')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'أدوات العمل',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'يمكنك الوصول إلى الأقسام الإضافية من هنا.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: AppTheme.darkSlate),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _selectSecondaryDestination(item.index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
