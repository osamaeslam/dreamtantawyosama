import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CustomerDetailDialog extends StatelessWidget {
  final CustomerAnalytics customer;
  final NumberFormat currencyFmt;
  final bool isDark;

  const CustomerDetailDialog({
    super.key,
    required this.customer,
    required this.currencyFmt,
    required this.isDark,
  });

  Color _pctColor(double pct) {
    if (pct >= 100) return AppTheme.emeraldGreen;
    if (pct >= 80) return AppTheme.primaryGold;
    if (pct >= 50) return AppTheme.warningAmber;
    return AppTheme.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    final cardColor = isDark ? AppTheme.cardSlate : Colors.white;

    final collectionPct = customer.totalSales > 0
        ? (customer.totalCollections / customer.totalSales) * 100
        : 0.0;
    final targetPct = customer.annualTarget != null && customer.annualTarget! > 0
        ? (customer.totalSales / customer.annualTarget!) * 100
        : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSlate : AppTheme.darkSlate,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _tierColor(customer.tier).withValues(alpha: 0.15),
                    child: Icon(Icons.storefront, color: _tierColor(customer.tier), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.customerName,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${customer.customerCode} • ${customer.branchName}',
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body (scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _tierColor(customer.tier).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _tierColor(customer.tier).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        customer.tier ?? '—',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _tierColor(customer.tier),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Financial summary grid
                    _buildInfoGrid([
                      _buildInfoItem('إجمالي المبيعات', currencyFmt.format(customer.totalSales), AppTheme.primaryGold, Icons.trending_up, textColor, mutedColor),
                      _buildInfoItem('إجمالي التحصيلات', currencyFmt.format(customer.totalCollections), AppTheme.emeraldGreen, Icons.account_balance_wallet, textColor, mutedColor),
                      _buildInfoItem('المدينات', currencyFmt.format(customer.balance), customer.balance > 0 ? AppTheme.errorRed : AppTheme.emeraldGreen, Icons.account_balance, textColor, mutedColor),
                      _buildInfoItem('المستحقات المتخطية', currencyFmt.format(customer.overdueBalance), AppTheme.errorRed, Icons.warning, textColor, mutedColor),
                    ]),
                    const SizedBox(height: 16),

                    // Progress bars
                    _buildProgressSection('نسبة التحصيل', collectionPct, _pctColor(collectionPct), textColor, mutedColor),
                    const SizedBox(height: 12),
                    if (customer.annualTarget != null && customer.annualTarget! > 0)
                      _buildProgressSection('محقق الهدف السنوي', targetPct, _pctColor(targetPct), textColor, mutedColor),
                    const SizedBox(height: 16),

                    // Activity stats
                    _buildInfoGrid([
                      _buildInfoItem('عدد الطلبيات', customer.ordersCount.toString(), AppTheme.infoBlue, Icons.receipt_long, textColor, mutedColor),
                      _buildInfoItem('عدد الزيارات', customer.visitsCount.toString(), AppTheme.primaryGold, Icons.location_on, textColor, mutedColor),
                      _buildInfoItem('عدد المرتجعات', customer.returnsCount.toString(), AppTheme.warningAmber, Icons.assignment_return, textColor, mutedColor),
                    ]),
                    const SizedBox(height: 16),

                    // Dates and status
                    _buildInfoGrid([
                      _buildInfoItem('آخر طلب', _formatDate(customer.lastOrderDate), AppTheme.infoBlue, Icons.calendar_today, textColor, mutedColor),
                      _buildInfoItem('آخر زيارة', _formatDate(customer.lastVisitDate), AppTheme.primaryGold, Icons.event, textColor, mutedColor),
                      _buildInfoItem('حالة 2026', customer.hasDealtIn2026 ? 'تاجر' : 'جديد', customer.hasDealtIn2026 ? AppTheme.emeraldGreen : AppTheme.warningAmber, Icons.circle, textColor, mutedColor),
                    ]),
                    const SizedBox(height: 16),

                    // Notes section removed - notes field not in CustomerAnalytics model
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSlate : Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('إغلاق', style: GoogleFonts.cairo(color: mutedColor, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Could navigate to customer registration form
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: AppTheme.darkSlate,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.location_on, size: 14),
                    label: Text('تسجيل زيارة', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: children,
    );
  }

  Widget _buildInfoItem(
    String label, String value, Color valueColor, IconData icon,
    Color textColor, Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderColor, width: 0.3),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: valueColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: GoogleFonts.cairo(fontSize: 10, color: mutedColor, height: 1.2)),
                Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(String label, double pct, Color color, Color textColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)),
            Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0, 1),
            backgroundColor: mutedColor.withValues(alpha: 0.2),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Color _tierColor(String? tier) {
    switch (tier) {
      case 'الذهب': return AppTheme.primaryGold;
      case 'الفضة': return AppTheme.silver;
      case 'البرونز': return AppTheme.copper;
      case 'جديد': return AppTheme.infoBlue;
      case 'متوقف': return AppTheme.textMuted;
      default: return AppTheme.primaryGold;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    return dateStr;
  }
}

