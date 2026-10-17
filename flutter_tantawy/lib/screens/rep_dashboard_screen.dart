import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_theme.dart';
import 'catalog_screen.dart';
import 'collection_forecast_view.dart';
import 'all_customers_analytics_view.dart';
import 'invoices_screen.dart';
import 'inventory_screen.dart';
import 'order_builder_screen.dart';
import 'rep_performance_screen.dart';
import 'target_performance_screen.dart';
import 'management_dashboard.dart';
import 'returns_screen.dart';
import 'visits_screen.dart';

class RepDashboardScreen extends StatelessWidget {
  final AppUser currentUser;
  const RepDashboardScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
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
              child: const Center(
                child: Icon(Icons.storefront_rounded, size: 22, color: AppTheme.darkSlate),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مجموعة الطنطاوي',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.secondaryGold),
                ),
                Text(
                  '${currentUser.branchName} | ${currentUser.name}',
                  style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderBuilderScreen(currentUser: currentUser)),
                  );
                },
              ),
              if (cart.items.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.items.length}',
                      style: const TextStyle(color: AppTheme.darkSlate, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Dark mode toggle
          IconButton(
            icon: Icon(
              context.watch<ThemeModeProvider>().isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: Colors.white70,
            ),
            onPressed: () {
              context.read<ThemeModeProvider>().toggleTheme();
            },
            tooltip: 'تبديل الوضع الليلي',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة الترحيب والهدف اليومي
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSlate),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مبيعات اليوم المحققة', style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF94A3B8))),
                          Text('48,500 ج.م', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('85% من الهدف', style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF6EE7B7), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.85,
                      minHeight: 8,
                      backgroundColor: Color(0xFF334155),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // شبكة الأزرار السريعة
            Text('المهام والعمليات الميدانية', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildQuickAction(
                  context,
                  title: 'كتالوج المنتجات',
                  subtitle: 'الأسعار والأرصدة الفورية',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CatalogScreen(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'طلبية جديدة',
                  subtitle: 'حجز فوري للعميل',
                  icon: Icons.add_shopping_cart_rounded,
                  color: const Color(0xFF10B981),
                  badge: cart.items.isNotEmpty ? '${cart.items.length}' : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderBuilderScreen(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'المبيعات والفواتير',
                  subtitle: 'طباعة حرارية وتصدير',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InvoicesScreen(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'المرتجعات',
                  subtitle: 'إذن مرتجع مبيعات',
                  icon: Icons.assignment_return_outlined,
                  color: const Color(0xFFEC4899),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReturnsScreen(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'لوحة الإدارة',
                  subtitle: 'نظرة تنفيذية كاملة',
                  icon: Icons.dashboard_outlined,
                  color: const Color(0xFF06B6D4),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManagementDashboard(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'أهداف وإنجاز',
                  subtitle: 'الهدف والمحقق',
                  icon: Icons.track_changes_outlined,
                  color: const Color(0xFF8B5CF8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TargetPerformanceScreen(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'حركة المخزون',
                  subtitle: 'المعاملات اليومية',
                  icon: Icons.warehouse_outlined,
                  color: const Color(0xFF14B8A8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InventoryScreen(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'أدائي وأهدافي',
                  subtitle: 'تفاصيل الهدف الشخصي',
                  icon: Icons.track_changes_outlined,
                  color: const Color(0xFF8B5CF8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RepPerformanceScreen(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'توقعات التحصيل',
                  subtitle: 'توقعات الأسبوع',
                  icon: Icons.energy_saver,
                  color: const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CollectionForecastView(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'تحليلات العملاء',
                  subtitle: 'أداء العملاء والأرصدة',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF8B5CF8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AllCustomersAnalyticsView(currentUser: currentUser)),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  title: 'الزيارات والتحصيل',
                  subtitle: 'خط السير وتسجيل الحضور',
                  icon: Icons.location_on_outlined,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VisitsScreen(currentUser: currentUser)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(badge, style: const TextStyle(color: AppTheme.darkSlate, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                Text(subtitle, style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
