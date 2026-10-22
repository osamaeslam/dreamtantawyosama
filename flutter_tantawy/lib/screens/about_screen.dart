import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';

class AboutScreen extends StatelessWidget {
  final AppUser currentUser;
  const AboutScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.darkSlate,
        title: Text('نبذة عن البرنامج',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGold, Color(0xFFD97706)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'ط',
                        style: GoogleFonts.cairo(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Name
                  Text(
                    'نظام طنطاوي للتجارة والتوزيع',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dream Tantawy Trading & Distribution System',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: mutedColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Version Card
                  _buildInfoCard(
                    cardColor: cardColor,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    icon: Icons.info_outline,
                    iconColor: AppTheme.infoBlue,
                    title: 'الإصدار',
                    value: 'نسخة 1.0.0',
                  ),
                  const SizedBox(height: 12),

                  // Company Info Card
                  _buildInfoCard(
                    cardColor: cardColor,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    icon: Icons.storefront_outlined,
                    iconColor: AppTheme.primaryGold,
                    title: 'الشركة',
                    value: 'مجموعة الطنطاوي للتجارة',
                    subtitle: 'نظام إدارة مبيعات متكامل\nللوكلات والمناديب التجاريين',
                  ),
                  const SizedBox(height: 12),

                  // Features Card
                  Card(
                    color: cardColor,
                    elevation: 2,
                    child: ExpansionTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                         child: Icon(Icons.star_outline,
                             color: AppTheme.emeraldGreen, size: 20),
                      ),
                      title: Text('الميزات',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFeatureItem('إدارة المنتجات والكتالوج', Icons.inventory_2_outlined),
                              _buildFeatureItem('إنشاء وإدارة الطلبات', Icons.shopping_bag_outlined),
                              _buildFeatureItem('متابعة الفواتير والمدفوعات', Icons.receipt_long_outlined),
                              _buildFeatureItem('تسجيل الزيارات والتحصيل', Icons.location_on_outlined),
                              _buildFeatureItem('توقعات التحصيل الأسبوعية', Icons.energy_savings_leaf_outlined),
                              _buildFeatureItem('تقارير الأداء والتحليلات', Icons.analytics_outlined),
                              _buildFeatureItem('إدارة الموظفين والأدوار', Icons.manage_accounts_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Copyright
                  Text(
                    '© 2026 مجموعة الطنطاوي للتجارة. جميع الحقوق محفوظة.',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: mutedColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Card(
      color: cardColor,
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: GoogleFonts.cairo(fontSize: 11, color: mutedColor, height: 1.3),
                maxLines: 2)
            : null,
        trailing: Text(value,
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }

  Widget _buildFeatureItem(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGold),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.cairo(fontSize: 12)),
        ],
      ),
    );
  }
}


