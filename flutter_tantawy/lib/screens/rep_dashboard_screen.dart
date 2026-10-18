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

class RepDashboardScreen extends StatelessWidget {
  final AppUser currentUser;
  const RepDashboardScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          final maxWidth = constraints.maxWidth >= 1100 ? 1080.0 : 900.0;
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
                    _buildDailySummary(context, isDark),
                    const SizedBox(height: 24),
                    Text(
                      'المهام والعمليات الميدانية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: constraints.maxWidth < 360 ? 1.0 : 1.16,
                      children: [
                        _buildQuickAction(
                          context,
                          title: 'طلبية جديدة',
                          subtitle: 'ابدأ حجز أصناف للعميل',
                          icon: Icons.add_shopping_cart_rounded,
                          color: AppTheme.primaryGold,
                          badge: cart.items.isNotEmpty
                              ? '${cart.items.length}'
                              : null,
                          onTap: () => _open(
                            context,
                            OrderBuilderScreen(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'الزيارات والتحصيل',
                          subtitle: 'خط السير وتسجيل الحضور',
                          icon: Icons.location_on_outlined,
                          color: AppTheme.infoBlue,
                          onTap: () => _open(
                            context,
                            VisitsScreen(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'كتالوج المنتجات',
                          subtitle: 'الأسعار والأرصدة الفورية',
                          icon: Icons.inventory_2_outlined,
                          color: AppTheme.primaryGold,
                          onTap: () => _open(
                            context,
                            CatalogScreen(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'المبيعات والفواتير',
                          subtitle: 'عرض الفواتير والطباعة',
                          icon: Icons.receipt_long_outlined,
                          color: AppTheme.infoBlue,
                          onTap: () => _open(
                            context,
                            InvoicesScreen(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'المرتجعات',
                          subtitle: 'إذن مرتجع المبيعات',
                          icon: Icons.assignment_return_outlined,
                          color: AppTheme.roseRed,
                          onTap: () => _open(
                            context,
                            ReturnsScreen(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'لوحة الإدارة',
                          subtitle: 'نظرة تنفيذية كاملة',
                          icon: Icons.dashboard_outlined,
                          color: AppTheme.infoBlue,
                          onTap: () => _open(
                            context,
                            ManagementDashboard(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'أهداف وإنجاز',
                          subtitle: 'الهدف والمحقق',
                          icon: Icons.track_changes_outlined,
                          color: AppTheme.emeraldGreen,
                          onTap: () => _open(
                            context,
                            TargetPerformanceScreen(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'حركة المخزون',
                          subtitle: 'المعاملات اليومية',
                          icon: Icons.warehouse_outlined,
                          color: AppTheme.emeraldGreen,
                          onTap: () => _open(
                            context,
                            InventoryScreen(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'أدائي وأهدافي',
                          subtitle: 'تفاصيل الهدف الشخصي',
                          icon: Icons.assessment_outlined,
                          color: AppTheme.emeraldGreen,
                          onTap: () => _open(
                            context,
                            RepPerformanceScreen(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'توقعات التحصيل',
                          subtitle: 'توقعات الأسبوع',
                          icon: Icons.energy_savings_leaf_outlined,
                          color: AppTheme.infoBlue,
                          onTap: () => _open(
                            context,
                            CollectionForecastView(currentUser: currentUser),
                          ),
                        ),
                        _buildQuickAction(
                          context,
                          title: 'تحليلات العملاء',
                          subtitle: 'أداء العملاء والأرصدة',
                          icon: Icons.analytics_outlined,
                          color: AppTheme.infoBlue,
                          onTap: () => _open(
                            context,
                            AllCustomersAnalyticsView(currentUser: currentUser),
                          ),
                        ),
                      ],
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

  Widget _buildDailySummary(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص إنجاز اليوم',
                      style: GoogleFonts.cairo(
                        color: mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مبيعات اليوم المحققة',
                      style: GoogleFonts.cairo(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '48,500 ج.م',
                      style: GoogleFonts.cairo(
                        color: textColor,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '85% من الهدف',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppTheme.emeraldGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.85,
              minHeight: 8,
              backgroundColor: AppTheme.borderSlate,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'واصل متابعة الطلبات والزيارات لإكمال هدفك اليومي',
            style: GoogleFonts.cairo(fontSize: 11, color: mutedColor),
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: AppTheme.darkSlate,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 2),
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
