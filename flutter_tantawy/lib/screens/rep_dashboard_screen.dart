import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';
import 'all_customers_analytics_view.dart';
import 'catalog_screen.dart';
import 'collection_forecast_view.dart';
import 'invoices_screen.dart';
import 'inventory_screen.dart';
import 'management_dashboard.dart';
import 'order_builder_screen.dart';
import 'rep_performance_screen.dart';
import 'returns_screen.dart';
import 'target_performance_screen.dart';
import 'visits_screen.dart';

class _DashboardMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<UserRole> allowedRoles;
  final Widget Function() buildScreen;
  final String? badge;

  const _DashboardMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.allowedRoles,
    required this.buildScreen,
    this.badge,
  });
}

class RepDashboardScreen extends StatelessWidget {
  final AppUser currentUser;
  const RepDashboardScreen({super.key, required this.currentUser});

  UserRole? _dashboardRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'branch_manager':
        return UserRole.branchManager;
      case 'supervisor':
        return UserRole.supervisor;
      case 'sales_rep':
        return UserRole.salesRep;
      case 'developer':
        return UserRole.developer;
      default:
        return null;
    }
  }

  List<_DashboardMenuItem> _dashboardMenuItems(int cartCount) {
    const managementRoles = [
      UserRole.admin,
      UserRole.manager,
      UserRole.branchManager,
      UserRole.supervisor,
      UserRole.developer,
    ];
    const allRoles = [
      UserRole.admin,
      UserRole.manager,
      UserRole.branchManager,
      UserRole.supervisor,
      UserRole.salesRep,
      UserRole.developer,
    ];

    return [
      _DashboardMenuItem(
        title: 'طلبية جديدة',
        subtitle: 'ابدأ حجز أصناف للعميل',
        icon: Icons.add_shopping_cart_rounded,
        color: AppTheme.primaryGold,
        badge: cartCount > 0 ? '$cartCount' : null,
        allowedRoles: const [UserRole.salesRep],
        buildScreen: () => OrderBuilderScreen(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'الزيارات والتحصيل',
        subtitle: 'خط السير وتسجيل الحضور',
        icon: Icons.location_on_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => VisitsScreen(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'كتالوج المنتجات',
        subtitle: 'الأسعار والأرصدة الفورية',
        icon: Icons.inventory_2_outlined,
        color: AppTheme.primaryGold,
        allowedRoles: allRoles,
        buildScreen: () => CatalogScreen(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'المبيعات والفواتير',
        subtitle: 'عرض الفواتير والطباعة',
        icon: Icons.receipt_long_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => InvoicesScreen(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'المرتجعات',
        subtitle: 'إذن مرتجع المبيعات',
        icon: Icons.assignment_return_outlined,
        color: AppTheme.roseRed,
        allowedRoles: allRoles,
        buildScreen: () => ReturnsScreen(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'لوحة الإدارة',
        subtitle: 'ملخص الأداء والمؤشرات',
        icon: Icons.dashboard_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: managementRoles,
        buildScreen: () => ManagementDashboard(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'أهداف وإنجاز',
        subtitle: 'الهدف والمحقق',
        icon: Icons.track_changes_outlined,
        color: AppTheme.emeraldGreen,
        allowedRoles: allRoles,
        buildScreen: () => TargetPerformanceScreen(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'حركة المخزون',
        subtitle: 'المعاملات اليومية',
        icon: Icons.warehouse_outlined,
        color: AppTheme.emeraldGreen,
        allowedRoles: allRoles,
        buildScreen: () => InventoryScreen(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'أدائي وأهدافي',
        subtitle: 'تفاصيل الهدف الشخصي',
        icon: Icons.assessment_outlined,
        color: AppTheme.emeraldGreen,
        allowedRoles: const [UserRole.salesRep],
        buildScreen: () => RepPerformanceScreen(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'توقعات التحصيل',
        subtitle: 'توقعات الأسبوع',
        icon: Icons.energy_savings_leaf_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => CollectionForecastView(currentUser: currentUser),
      ),
      _DashboardMenuItem(
        title: 'تحليلات العملاء',
        subtitle: 'أداء العملاء والأرصدة',
        icon: Icons.analytics_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: managementRoles,
        buildScreen: () => AllCustomersAnalyticsView(currentUser: currentUser),
      ),
    ];
  }

  String _roleLabel => switch (currentUser.role) {
        'admin' || 'developer' => 'الإدارة العامة',
        'manager' => 'المدير العام',
        'branch_manager' => 'مدير الفرع',
        'supervisor' => 'مشرف المناديب',
        _ => 'مندوب مبيعات',
      };

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGold, width: 2),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 22,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مجموعة الطنطاوي',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${currentUser.branchName} | ${currentUser.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.darkTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OrderBuilderScreen(currentUser: currentUser),
                  ),
                ),
                tooltip: 'الطلبية',
              ),
              if (cart.items.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGold,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.items.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.darkSlate,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              context.watch<ThemeModeProvider>().isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => context.read<ThemeModeProvider>().toggleTheme(),
            tooltip: 'تبديل الوضع الليلي',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 1100 ? 1180.0 : 960.0;
          final columns = constraints.maxWidth >= 1100
              ? 4
              : constraints.maxWidth >= 650
                  ? 3
                  : 2;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomePanel(context),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentUser.role == 'sales_rep'
                                ? 'المهام والعمليات الميدانية'
                                : 'مساحات العمل',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '${_dashboardMenuItems(cart.items.length).where((item) => item.allowedRoles.contains(_dashboardRole(currentUser.role))).length} أقسام',
                          style: GoogleFonts.cairo(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: constraints.maxWidth < 360 ? 1.0 : 1.16,
                      children: _dashboardMenuItems(cart.items.length)
                          .where((item) => item.allowedRoles.contains(
                              _dashboardRole(currentUser.role)))
                          .map((item) => _buildQuickAction(
                                context,
                                title: item.title,
                                subtitle: item.subtitle,
                                icon: item.icon,
                                color: item.color,
                                badge: item.badge,
                                onTap: () =>
                                    _open(context, item.buildScreen()),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomePanel(BuildContext context) {
    final now = DateTime.now();
    final dateLabel = '${now.day}/${now.month}/${now.year}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppTheme.darkSlate, AppTheme.cardSlate],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSlate.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkSlate.withOpacity(0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'مجموعة الطنطاوي',
                      style: GoogleFonts.cairo(
                        color: AppTheme.secondaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'أهلًا ${currentUser.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_roleLabel  •  ${currentUser.branchName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: AppTheme.darkTextMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.secondaryGold, size: 14),
                      const SizedBox(width: 7),
                      Text(
                        dateLabel,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppTheme.primaryGold.withOpacity(0.35)),
            ),
            child: const Icon(
              Icons.space_dashboard_rounded,
              color: AppTheme.secondaryGold,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.16)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.darkSlate,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.arrow_outward_rounded,
                        size: 17, color: color.withOpacity(0.7)),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
