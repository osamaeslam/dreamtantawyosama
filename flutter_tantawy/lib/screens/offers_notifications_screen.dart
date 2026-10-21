import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';

class OffersNotificationsScreen extends StatefulWidget {
  final AppUser currentUser;
  const OffersNotificationsScreen({super.key, required this.currentUser});

  @override
  State<OffersNotificationsScreen> createState() =>
      _OffersNotificationsScreenState();
}

class _OffersNotificationsScreenState extends State<OffersNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PromotionOffer> _offers = [];
  List<CustomerCommentRecord> _notifications = [];
  bool _isLoading = true;

  final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final offers = await SupabaseService.instance.fetchPromotions(
        activeOnly: true,
        branchName: widget.currentUser.branchName,
      );
      setState(() {
        _offers = offers;
        _notifications = _generateMockNotifications();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _notifications = _generateMockNotifications();
        _isLoading = false;
      });
    }
  }

  List<CustomerCommentRecord> _generateMockNotifications() {
    return [
      CustomerCommentRecord(
        id: 'n1',
        customerId: 'cust_1',
        customerCode: 'CUST-001',
        customerName: 'مخازن البتروز',
        branchName: widget.currentUser.branchName,
        repName: widget.currentUser.name,
        kind: 'notification',
        body: 'تم توافق العميل على طلبية جديدة بقيمة 75,000 د.ك',
        authorName: 'نظام المبيعات',
        createdAt: '${DateFormat('yyyy-MM-dd').format(DateTime.now())} 14:30',
      ),
      CustomerCommentRecord(
        id: 'n2',
        customerId: 'cust_2',
        customerCode: 'CUST-002',
        customerName: 'مجموعة السادة الكبرى',
        branchName: widget.currentUser.branchName,
        repName: widget.currentUser.name,
        kind: 'notification',
        body: 'تم تسجيل زيارة موقع للعميل اليوم',
        authorName: 'نظام المتابعة',
        createdAt: '${DateFormat('yyyy-MM-dd').format(DateTime.now())} 10:15',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.darkSlate,
        title: Text('العروض والإشعارات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                backgroundImage: widget.currentUser.avatar != null
                    ? NetworkImage(widget.currentUser.avatar!)
                    : null,
                child: widget.currentUser.avatar == null
                    ? Icon(Icons.person,
                        color: AppTheme.primaryGold, size: 20)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGold,
          labelColor: AppTheme.primaryGold,
          unselectedLabelColor:
              isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'العروض'),
            Tab(text: 'الإشعارات'),
          ],
        ),
      ),
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOffersTab(isDark, colorScheme),
                      _buildNotificationsTab(isDark, colorScheme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersTab(bool isDark, ColorScheme colorScheme) {
    if (_offers.isEmpty) {
      return _buildEmptyState(
          Icons.local_offer_outlined, 'لا توجد عروض ترويجية نشطة');
    }

    final activeOffers =
        _offers.where((o) => o.isActive).toList();
    final inactiveOffers =
        _offers.where((o) => !o.isActive).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeOffers.isNotEmpty) ...[
            Text('العروض النشطة',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate)),
            const SizedBox(height: 8),
            ...activeOffers.map((offer) => _buildOfferCard(offer, true)),
            const SizedBox(height: 16),
          ],
          if (inactiveOffers.isNotEmpty) ...[
            Text('العروض المنتهية',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            ...inactiveOffers.map((offer) => _buildOfferCard(offer, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferCard(PromotionOffer offer, bool isActive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardColor,
              title: Text(offer.title,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, color: textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('المنتج', offer.productName, mutedColor),
                  _buildDetailRow(
                      'الفئة', offer.category ?? 'غير محددة', mutedColor),
                  _buildDetailRow('الخصم',
                      '${offer.discountPercentage.toStringAsFixed(1)}%', mutedColor),
                  _buildDetailRow(
                      'الفترة',
                      '${offer.startDate ?? '?'} → ${offer.endDate ?? '?'}',
                      mutedColor),
                  if (offer.notes != null)
                    _buildDetailRow('ملاحظات', offer.notes!, mutedColor),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إغلاق',
                      style: GoogleFonts.cairo(color: mutedColor)),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(offer.title,
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (offer.discountPercentage > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.roseRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('-${offer.discountPercentage.toInt()}%',
                          style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.roseRed)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(offer.productName,
                  style: GoogleFonts.cairo(fontSize: 12, color: mutedColor)),
              const SizedBox(height: 8),
              Text(
                  '${offer.startDate ?? '?'} → ${offer.endDate ?? '?'}',
                  style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)),
              if (offer.branchName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('فرع: ${offer.branchName}',
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: AppTheme.infoBlue)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsTab(bool isDark, ColorScheme colorScheme) {
    if (_notifications.isEmpty) {
      return _buildEmptyState(
          Icons.notifications_none, 'لا توجد إشعارات حالية');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification, isDark);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
      CustomerCommentRecord record, bool isDark) {
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Card(
      color: cardColor,
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.infoBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Icon(Icons.notifications, color: AppTheme.infoBlue, size: 22),
        ),
        title: Text(record.body,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w500, fontSize: 13, color: textColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${record.createdAt ?? ''} • ${record.customerName}',
            style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
        trailing: const Icon(Icons.chevron_left, size: 18),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardColor,
              title: Text('تفاصيل الإشعار',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, color: textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('العميل', record.customerName, mutedColor),
                  _buildDetailRow(
                      'الكود', record.customerCode, mutedColor),
                  _buildDetailRow(
                      'الفرع', record.branchName, mutedColor),
                  _buildDetailRow('الوقت',
                      '${record.createdAt ?? ''}', mutedColor),
                  _buildDetailRow('المحتوى', record.body, mutedColor),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إغلاق', style: GoogleFonts.cairo(color: mutedColor)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedColor)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.cairo(fontSize: 12, color: mutedColor)),
          ),
        ],
      ),
    );
  }
}
