import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/offline_cache_service.dart';
<<<<<<< HEAD
import '../services/connectivity_service.dart';
=======
>>>>>>> f8bb073f53d7558c0a5b3e084573d66bdbef98e5
import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';

/// Calendar / list view of **overdue** invoices grouped by region (branch).
///
/// Uses the offline cache for reads so the list renders while offline,
/// showing a "Last updated" timestamp. Financial operations (invoice
/// creation, status change) remain online-only via the gated
/// [SupabaseService].
class InvoiceCalendarScreen extends StatefulWidget {
  final AppUser currentUser;
  const InvoiceCalendarScreen({super.key, required this.currentUser});

  @override
  State<InvoiceCalendarScreen> createState() => _InvoiceCalendarScreenState();
}

class _InvoiceCalendarScreenState extends State<InvoiceCalendarScreen> {
  Map<String, List<OrderInvoice>> _grouped = {};
  DateTime? _lastUpdated;
  bool _isLoading = true;
  bool _fromCache = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    final cache = OfflineCacheService();
    final cacheResult = await cache.fetchWithCache<List<OrderInvoice>>(
      'overdue_invoices_${widget.currentUser.branchName}',
      () => SupabaseService.instance.fetchInvoices(
        repName: widget.currentUser.name,
        status: 'مستحق',
        branchName: widget.currentUser.branchName,
      ),
      ConnectivityService.instance.currentStatus == ConnectionStatus.online,
    );

    setState(() {
      _fromCache = cacheResult.isFromCache;
      _lastUpdated = cacheResult.isFromCache ? cacheResult.cachedAt : DateTime.now();
      if (cacheResult.data != null) {
        _grouped = _groupByRegion(cacheResult.data!);
        _errorMessage = '';
      } else {
        _errorMessage = _fromCache ? '' : 'فشل تحميل الفواتير';
      }
    });
  }

  Map<String, List<OrderInvoice>> _groupByRegion(List<OrderInvoice> invoices) {
    // Only include unpaid / overdue invoices
    final overdue = invoices.where((inv) {
      final lower = inv.status.toLowerCase();
      return lower.contains('مستحق') || lower.contains('متأخر');
    });

    final Map<String, List<OrderInvoice>> groups = {};
    for (final inv in overdue) {
      final region = inv.branchName.isNotEmpty ? inv.branchName : 'غير محدد';
      groups.putIfAbsent(region, () => []).add(inv);
    }

    // Sort each group by due date ascending
    for (final entry in groups.entries) {
<<<<<<< HEAD
      entry.value.sort((a, b) => a.date.compareTo(b.date));
=======
      entry.getValue().sort((a, b) => a.date.compareTo(b.date));
>>>>>>> f8bb073f53d7558c0a5b3e084573d66bdbef98e5
    }

    // Sort regions alphabetically
    final sorted = Map.fromEntries(groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('تقويم الفواتير المستحقة', style: GoogleFonts.cairo()),
        bottom: AppBar(
          backgroundColor: isDark ? AppTheme.cardSlate : AppTheme.backgroundLight,
          title: const ConnectionStatusBar(),
          automaticallyImplyLeading: false,
          toolbarHeight: 32,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _grouped.isEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
                  children: [
                    if (_fromCache && _lastUpdated != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardSlate : AppTheme.backgroundLight,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.update, size: 14, color: AppTheme.darkTextMuted),
                            const SizedBox(width: 6),
                            Text(
                              'آخر تحديث: ${DateFormat('yyyy/MM/dd – hh:mm').format(_lastUpdated!)}',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                              ),
                            ),
                            if (_fromCache)
                              Text(
                                ' (من التخزين المحلي)',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: AppTheme.warningAmber,
                                ),
                              ),
                          ],
                        ),
                      ),
                    Expanded(child: _buildGroupByRegion()),
                  ],
                ),
    );
  }

  Widget _buildGroupByRegion() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    if (_grouped.isEmpty) {
      return Center(
        child: Text(
          'لا توجد فواتير مستحقة',
          style: GoogleFonts.cairo(color: Theme.of(context).hintColor),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _grouped.entries.map((entry) {
        final region = entry.key;
        final invoices = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$region (${invoices.length})',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.darkSlate,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...invoices.map((inv) => _buildInvoiceCard(inv, cardColor, borderColor)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInvoiceCard(
    OrderInvoice inv,
    Color cardColor,
    Color borderColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysOverdue = DateTime.now().difference(inv.date).inDays;
    final statusColor = inv.status.toLowerCase().contains('متأخر')
        ? AppTheme.roseRed
        : inv.status.toLowerCase().contains('مستحق')
            ? AppTheme.warningAmber
            : AppTheme.infoBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(Icons.receipt, color: statusColor, size: 20),
        ),
        title: Text(
          inv.customerName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${inv.invoiceNumber} • ${_formatDate(inv.date)} • ${daysOverdue} يوم متأخر',
          style: GoogleFonts.cairo(fontSize: 11),
        ),
        trailing: Text(
          '${inv.totalAmount.toInt()} ${_formatCurrency()}',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppTheme.roseRed,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => DateFormat('yyyy/MM/dd').format(date);
  String _formatCurrency() => 'د.ك';
}
