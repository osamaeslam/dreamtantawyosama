import 'package:flutter/material.dart';
import 'google_sheets_import_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/role_dashboard_summary.dart';
import 'about_screen.dart';
import 'adaptive_home_screen.dart';
import 'all_customers_analytics_view.dart';
import 'catalog_screen.dart';
import 'collection_forecast_view.dart';
import 'employee_management_screen.dart';
import 'invoices_screen.dart';
import 'inventory_screen.dart';
import 'management_dashboard.dart';
import 'offers_notifications_screen.dart';
import 'order_builder_screen.dart';
import 'rep_performance_screen.dart';
import 'returns_screen.dart';
import 'sync_queue_screen.dart';
import 'target_performance_screen.dart';
import 'tasks_roles_screen.dart';
import 'visits_screen.dart';

/// HomeScreen موحدة - الصفحة الرئيسية لكل الأدوار
///
/// - بروفيل الموظف العلوي (مش مرئية للـ admin/manager/supervisor)
/// - KPI Cards (مبيعات / تحصيل / أرصدة)
/// - شبكة إيقونات التبويبات المتغيرة حسب الدور
class HomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool showProfilePhoto = _showUserProfilePhoto(widget.currentUser.role);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar الذي يحتوي على بروفيل الموظف
          SliverAppBar(
            pinned: false,
            floating: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 140,
            title: _buildHeaderProfile(context, cart.items.length, showProfilePhoto),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: IconButton(
                  icon: Icon(
                    context.watch<ThemeModeProvider>().isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  onPressed: () => context.read<ThemeModeProvider>().toggleTheme(),
                  tooltip: 'تبديل الوضع الليلي',
                ),
              ),
              // زر الطلبات مع البِج
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 24),
                      if (cart.items.isNotEmpty)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGold,
                              shape: BoxShape.circle,
                            ),
                            constraints:
                                const BoxConstraints(minWidth: 18, minHeight: 18),
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderBuilderScreen(currentUser: widget.currentUser),
                    ),
                  ),
                  tooltip: 'الطلبية',
                ),
              ),
            ],
          ),

          // شريط الاتصال
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const ConnectionStatusBar(),
            ),
          ),

          // ملخص الأداء (KPI Cards)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RoleDashboardSummary(currentUser: widget.currentUser),
            ),
          ),

          // العنوان: المهام والعمليات / مساحات العمل
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _buildSectionTitle(context),
            ),
          ),

           // شبكة التبويبات
           SliverToBoxAdapter(
             child: Padding(
               padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
               child: _buildQuickActionsGrid(context, cart.items.length),
             ),
           ),
        ],
      ),
    );
  }

  /// نعرض صورة الموظف فقط للـ sales_rep والـ supervisor
  bool _showUserProfilePhoto(String role) {
    // المندوب والمشرف المباشر: يظهر له صورة الموظف
    // الإدارة العامة والمدير العام: مش محتاجين صور، يركزوا على الأرقام
    return role == 'sales_rep' || role == 'supervisor';
  }

  Widget _buildHeaderProfile(BuildContext context, int cartCount, bool showPhoto) {
    final now = DateTime.now();
    final dateLabel = DateFormat('yyyy/MM/dd').format(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (showPhoto) ...[
             // صورة الموظف للمندوب والمشرف المباشر
             Container(
               width: 60,
               height: 60,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 border: Border.all(
                   color: AppTheme.primaryGold.withOpacity(0.4),
                   width: 2,
                 ),
                 image: const DecorationImage(
                   image: NetworkImage(''),
                   fit: BoxFit.cover,
                 ),
               ),
             ),
            const SizedBox(width: 14),
          ] else ...[
            const SizedBox(width: 6),
          ],

          // الاسم والدور والفرع
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مجموعة الطنطاوي للتجارة',
                  style: GoogleFonts.cairo(
                    color: AppTheme.darkTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أهلاً ${widget.currentUser.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_roleLabel(widget.currentUser.role)}  •  ${widget.currentUser.branchName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: AppTheme.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (!showPhoto) ...[
            const SizedBox(width: 10),
            // أيقونة للـ admin/manager/supervisor
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGold, Color(0xFFD97706)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGold.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.space_dashboard_rounded,
                color: AppTheme.darkSlate,
                size: 28,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
      case 'developer':
        return 'الإدارة العامة';
      case 'manager':
        return 'المدير العام';
      case 'branch_manager':
        return 'مدير الفرع';
      case 'supervisor':
        return 'مشرف المناديب';
      default:
        return 'مندوب مبيعات';
    }
  }

  Widget _buildSectionTitle(BuildContext context) {
    final bool isSalesRep = widget.currentUser.role == 'sales_rep';
    final cartCount = Provider.of<CartService>(context).items.length;

    final visibleCount = _getMenuItems(cartCount)
        .where((item) => item.allowedRoles.contains(widget.currentUser.role))
        .length;

    return Row(
      children: [
        Expanded(
          child: Text(
            isSalesRep ? 'المهام والعمليات الميدانية' : 'مساحات العمل',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          '$visibleCount أقسام',
          style: GoogleFonts.cairo(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, int cartCount) {
    final items = _getMenuItems(cartCount)
        .where((item) => item.allowedRoles.contains(widget.currentUser.role))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 700
                ? 4
                : constraints.maxWidth >= 500
                    ? 3
                    : 2;

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth < 420 ? 0.95 : 1.05,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _QuickActionCard(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.icon,
              color: item.color,
              badge: item.badge,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.buildScreen()),
                );
              },
            );
          },
        );
      },
    );
  }

  List<HomeMenuItem> _getMenuItems(int cartCount) {
    final adminRoles = ['admin', 'developer'];
    final managementRoles = ['admin', 'manager', 'branch_manager', 'supervisor', 'developer'];
    final allRoles = ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'];

    return [
      HomeMenuItem(
        title: 'طلبية جديدة',
        subtitle: 'ابدأ حجز أصناف للعميل',
        icon: Icons.add_shopping_cart_rounded,
        color: AppTheme.primaryGold,
        badge: cartCount > 0 ? '$cartCount' : null,
        allowedRoles: ['sales_rep'],
        buildScreen: () => OrderBuilderScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'الزيارات والتحصيل',
        subtitle: 'خط السير وتسجيل الحضور',
        icon: Icons.location_on_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => VisitsScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'كتالوج المنتجات',
        subtitle: 'الأسعار والأرصدة الفورية',
        icon: Icons.inventory_2_outlined,
        color: AppTheme.primaryGold,
        allowedRoles: allRoles,
        buildScreen: () => CatalogScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'المبيعات والفواتير',
        subtitle: 'عرض الفواتير والطباعة',
        icon: Icons.receipt_long_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => InvoicesScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'المرتجعات',
        subtitle: 'إذن مرتجع المبيعات',
        icon: Icons.assignment_return_outlined,
        color: AppTheme.roseRed,
        allowedRoles: allRoles,
        buildScreen: () => ReturnsScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'لوحة الإدارة',
        subtitle: 'ملخص الأداء والمؤشرات',
        icon: Icons.dashboard_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: managementRoles,
        buildScreen: () => ManagementDashboardScreenWrapper(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'أهداف وإنجاز',
        subtitle: 'الهدف والمحقق',
        icon: Icons.track_changes_outlined,
        color: AppTheme.emeraldGreen,
        allowedRoles: allRoles,
        buildScreen: () => TargetPerformanceScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'حركة المخزون',
        subtitle: 'المعاملات اليومية',
        icon: Icons.warehouse_outlined,
        color: AppTheme.emeraldGreen,
        allowedRoles: allRoles,
        buildScreen: () => InventoryScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'أدائي وأهدافي',
        subtitle: 'تفاصيل الهدف الشخصي',
        icon: Icons.assessment_outlined,
        color: AppTheme.emeraldGreen,
        allowedRoles: ['sales_rep'],
        buildScreen: () => RepPerformanceScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'توقعات التحصيل',
        subtitle: 'توقعات الأسبوع',
        icon: Icons.energy_savings_leaf_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => CollectionForecastView(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'تحليلات العملاء',
        subtitle: 'أداء العملاء والأرصدة',
        icon: Icons.analytics_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: managementRoles,
        buildScreen: () => AllCustomersAnalyticsView(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'طابور المزامنة',
        subtitle: 'العناصر المعلقة',
        icon: Icons.cloud_sync_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => const SyncQueueScreen(),
      ),
      HomeMenuItem(
        title: 'مزامنة من Google Sheets',
        subtitle: 'رفع ومزامنة البيانات الذكية',
        icon: Icons.cloud_upload_outlined,
        color: AppTheme.emeraldGreen,
        allowedRoles: managementRoles,
        buildScreen: () => const GoogleSheetsImportScreen(),
      ),
      HomeMenuItem(
        title: 'إدارة الموظفين',
        subtitle: 'إدارة حسابات وأدوار الموظفين',
        icon: Icons.manage_accounts_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: adminRoles,
        buildScreen: () => EmployeeManagementScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'العروض',
        subtitle: 'العروض الترويجية والخصومات',
        icon: Icons.local_offer_outlined,
        color: AppTheme.roseRed,
        allowedRoles: allRoles,
        buildScreen: () => OffersNotificationsScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'الإشعارات',
        subtitle: 'التنبيهات والإشعارات',
        icon: Icons.notifications_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => OffersNotificationsScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'المهام والأدوار',
        subtitle: 'دليل الاستخدام والصلاحيات',
        icon: Icons.menu_book_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => TasksRolesScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'نبذة عن البرنامج',
        subtitle: 'معلومات عن التطبيق والشركة',
        icon: Icons.info_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => AboutScreen(currentUser: widget.currentUser),
      ),
      HomeMenuItem(
        title: 'المهام والأدوار',
        subtitle: 'دليل الاستخدام والصلاحيات',
        icon: Icons.menu_book_outlined,
        color: AppTheme.infoBlue,
        allowedRoles: allRoles,
        buildScreen: () => TasksRolesScreen(currentUser: widget.currentUser),
      ),
    ];
  }
}

/// Wrapper حول ManagementDashboard لاستخدامها في HomeScreen
class ManagementDashboardScreenWrapper extends StatelessWidget {
  final AppUser currentUser;

  const ManagementDashboardScreenWrapper({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة والتحليل'),
      ),
      body: ManagementDashboard(currentUser: currentUser),
    );
  }
}

/// نموذج عنصر قائمة HomeScreen
class HomeMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final List<String> allowedRoles;
  final Widget Function() buildScreen;

  HomeMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    required this.allowedRoles,
    required this.buildScreen,
  });
}

/// بطاقة عنصر سريع في الـ HomeScreen
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
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
}
