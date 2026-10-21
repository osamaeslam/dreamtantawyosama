import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_navigation.dart';
import '../widgets/responsive_layout.dart';
import 'about_screen.dart';
import 'catalog_screen.dart';
import 'collection_forecast_view.dart';
import 'all_customers_analytics_view.dart';
import 'executive_analytics_dashboard.dart';
import 'home_screen.dart';
import 'invoices_screen.dart';
import 'inventory_screen.dart';
import 'order_builder_screen.dart';
import 'sync_queue_screen.dart';
import 'tasks_roles_screen.dart';
import 'visits_dashboard_screen.dart';
import 'offers_notifications_screen.dart';
import 'users_management_screen.dart';

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

  /// Route-map: index → builder for the screen.
  /// Adding a new destination only requires extending this map —
  /// no fragile switch statements to update.
  List<Widget> _buildScreens(BuildContext context) {
    return [
      HomeScreen(currentUser: widget.currentUser),
      CatalogScreen(currentUser: widget.currentUser),
      OrderBuilderScreen(currentUser: widget.currentUser),
      InvoicesScreen(currentUser: widget.currentUser),
      VisitsDashboardScreen(currentUser: widget.currentUser),
      InventoryScreen(currentUser: widget.currentUser),
      CollectionForecastView(currentUser: widget.currentUser),
      const SyncQueueScreen(),
      OffersNotificationsScreen(currentUser: widget.currentUser),
      OffersNotificationsScreen(currentUser: widget.currentUser),
      TasksRolesScreen(currentUser: widget.currentUser),
      UsersManagementScreen(currentUser: widget.currentUser),
      ExecutiveAnalyticsDashboard(currentUser: widget.currentUser),
      AboutScreen(currentUser: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final colorScheme = Theme.of(context).colorScheme;
    final cartCount = cart.items.length;
    final visibleDestinationIndices =
        AppNavigation.visibleDestinationIndices(widget.currentUser.role);
    final visibleMobileDestinationIndices = visibleDestinationIndices
        .where(AppNavigation.mobileTabIndices.contains)
        .toList();
    final selectedVisibleIndex =
        visibleMobileDestinationIndices.indexOf(_selectedIndex);

    return ResponsiveLayout(
      // 1. مظهر الموبايل (Phone < 650px): شريط سفلي + Drawer
      mobile: Scaffold(
        appBar: AppBar(
          title: Text(
            AppNavigation.destinations[_selectedIndex == AppNavigation.moreIndex
                    ? 0
                    : _selectedIndex >= 0 &&
                        _selectedIndex < AppNavigation.destinations.length
                ? _selectedIndex
                : 0]
                .label,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            if (_selectedIndex == AppNavigation.moreIndex)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() {
                  _selectedIndex = 0;
                }),
              ),
          ],
        ),
        drawer: _buildMobileDrawer(visibleDestinationIndices, cartCount),
        body: _selectedIndex == AppNavigation.moreIndex
            ? _buildMoreScreen(context)
            : _buildSelectedScreen(_selectedIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex == AppNavigation.moreIndex
              ? visibleMobileDestinationIndices.length
              : selectedVisibleIndex < 0
                  ? 0
                  : selectedVisibleIndex,
          backgroundColor: colorScheme.surface,
          indicatorColor: AppTheme.primaryGold.withValues(alpha: 0.22),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => setState(() {
            _selectedIndex = index == visibleMobileDestinationIndices.length
                ? AppNavigation.moreIndex
                : visibleMobileDestinationIndices[index];
          }),
          destinations: [
            ...visibleMobileDestinationIndices.map((index) =>
                AppNavigation.buildMobileDestination(index, cartCount)),
            AppNavigation.buildMobileDestination(
                AppNavigation.moreIndex, cartCount),
          ],
        ),
      ),

      // 2. مظهر التابلت (650px - 1100px): Sidebar مدمج بأيقونات مدمجة
      tablet: Scaffold(
        appBar: AppBar(
          title: Text(
            AppNavigation.destinations[_selectedIndex]
                .label,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Row(
          children: [
            AppNavigationRail(
              selectedIndex: _selectedIndex,
              cartItemCount: cartCount,
              visibleDestinationIndices: visibleDestinationIndices,
              onSelected: (index) => setState(() => _selectedIndex = index),
              compact: true,
            ),
            const VerticalDivider(
                thickness: 1, width: 1, color: Color(0xFF334155)),
            Expanded(
              child: _buildSelectedScreen(_selectedIndex),
            ),
          ],
        ),
      ),

      // 3. مظهر الويب/ديسكتوب (>= 1100px): NavigationRail كامل
      desktop: Scaffold(
        body: Row(
          children: [
            AppNavigationRail(
              selectedIndex: _selectedIndex,
              cartItemCount: cartCount,
              visibleDestinationIndices: visibleDestinationIndices,
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
    final screens = _buildScreens(context);
    if (index < 0 || index >= screens.length) {
      return HomeScreen(currentUser: widget.currentUser);
    }
    return screens[index];
  }

  Widget _buildMobileDrawer(
    List<int> visibleDestinationIndices,
    int cartCount,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.darkSlate,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGold, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      color: AppTheme.darkSlate,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'مجموعة الطنطاوي',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.currentUser.name,
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade300,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ...visibleDestinationIndices.map((index) => ListTile(
                leading: Icon(
                  AppNavigation.destinations[index].icon,
                  color: _selectedIndex == index
                      ? AppTheme.primaryGold
                      : null,
                ),
                title: Text(
                  AppNavigation.destinations[index].label,
                  style: TextStyle(
                    color: _selectedIndex == index
                        ? AppTheme.primaryGold
                        : null,
                    fontWeight: _selectedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: _selectedIndex == index,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildMoreScreen(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleDestinationIndices =
        AppNavigation.visibleDestinationIndices(widget.currentUser.role);
    final items = [
      (index: 3, title: 'الفواتق والطباعة', subtitle: 'عرض الفواتق ومتابعة المستندات', icon: Icons.receipt_long_outlined),
      (index: 4, title: 'الزيارات وخط السير', subtitle: 'تسجيل الزيارات ومتابعة التحصيل', icon: Icons.location_on_outlined),
      (index: 5, title: 'حركة المخزون', subtitle: 'الأرصدة والمعاملات اليومية', icon: Icons.warehouse_outlined),
      (index: 6, title: 'توقعات التحصيل', subtitle: 'متابعة التوقعات الأسبوعية', icon: Icons.energy_savings_leaf_outlined),
      (index: 7, title: 'طابور المزامنة', subtitle: 'العناصر المعلقة والمعالجة غير المتصلة', icon: Icons.cloud_sync_outlined),
      (index: 8, title: 'العروض', subtitle: 'العروض الترويجية والخصومات', icon: Icons.local_offer_outlined),
      (index: 9, title: 'الإشعارات', subtitle: 'الإشعارات والتنبيهات', icon: Icons.notifications_outlined),
      (index: 10, title: 'المهام والأدوار', subtitle: 'دليل الاستخدام والصلاحيات', icon: Icons.menu_book_outlined),
      (index: 11, title: 'إدارة الموظفين', subtitle: 'إدارة حسابات وأدوار الموظفين', icon: Icons.people_outline),
      (index: 12, title: 'لوحة التحليلات', subtitle: 'تحليل البيانات ولوحة الإدارة', icon: Icons.analytics_outlined),
      (index: 13, title: 'عن البرنامج', subtitle: 'معلومات عن التطبيق والشركة', icon: Icons.info_outlined),
    ].where((item) => visibleDestinationIndices.contains(item.index)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المزيد من الأقسام'),
        backgroundColor: AppTheme.darkSlate,
        foregroundColor: Colors.white,
      ),
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
                    color: AppTheme.primaryGold.withValues(alpha: 0.14),
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


