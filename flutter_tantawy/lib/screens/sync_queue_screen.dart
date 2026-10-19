import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/offline_queue_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';

/// Screen showing the full sync queue with tabs for
/// [pending|failed|completed] and manual retry/skip per item.
class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('طابور المزامنة', style: GoogleFonts.cairo()),
        bottom: AppBar(
          backgroundColor: isDark ? AppTheme.cardSlate : AppTheme.backgroundLight,
          title: const ConnectionStatusBar(),
          automaticallyImplyLeading: false,
          toolbarHeight: 32,
        ),
        bottom: Tab(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SegmentedButton<int>(
              style: SegmentedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.cardSlate : AppTheme.backgroundLight,
                selectedForegroundColor: AppTheme.darkSlate,
              ),
              segments: const [
                ButtonSegment(value: 0, label: Text('معلق')),
                ButtonSegment(value: 1, label: Text('فاشل')),
                ButtonSegment(value: 2, label: Text('مكتمل')),
              ],
              selected: {_selectedTab},
              onValueChanged: (v) => setState(() => _selectedTab = v.first),
            ),
          ),
        ),
      ),
      body: Consumer<OfflineQueueService>(
        builder: (context, queue, _) {
          if (queue.allItems.isEmpty && _selectedTab != 0) {
            // Reset to pending tab if nothing exists
          }

          List<OfflineAction> items;
          switch (_selectedTab) {
            case 0:
              items = queue.allItems.where((e) => e.status == OfflineItemStatus.pending).toList();
              break;
            case 1:
              items = queue.allItems.where((e) => e.status == OfflineItemStatus.failed).toList();
              break;
            case 2:
              items = queue.allItems.where((e) => e.status == OfflineItemStatus.completed || e.status == OfflineItemStatus.skipped).toList();
              break;
            default:
              items = queue.allItems;
          }

          if (items.isEmpty && queue.allItems.isEmpty) {
            return _buildEmptyState(context);
          }

          if (items.isEmpty) {
            return Center(
              child: Text(
                'لا توجد عناصر في هذه الفئة',
                style: GoogleFonts.cairo(color: Theme.of(context).hintColor),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildQueueItem(
              context, items[index], cardColor, borderColor,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final queue = context.read<OfflineQueueService>();
          queue.purgeCompleted();
        },
        icon: const Icon(Icons.delete_sweep),
        label: Text('حذف المكتملات', style: GoogleFonts.cairo()),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  Widget _buildQueueItem(
    BuildContext context,
    OfflineAction action,
    Color cardColor,
    Color borderColor,
  ) {
    final statusColor = _statusColor(action.status);
    final queue = context.read<OfflineQueueService>();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            _statusIcon(action.status),
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          formatOfflineItemType(action.type),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${action.repName} • ${action.branchName}',
              style: GoogleFonts.cairo(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (action.errorMessage != null)
              Text(
                'الخطأ: ${action.errorMessage!}',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppTheme.errorRed,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'المحاولة ${action.retryCount}',
              style: GoogleFonts.cairo(fontSize: 11),
            ),
          ],
        ),
        trailing: (action.status == OfflineItemStatus.failed ||
            action.status == OfflineItemStatus.pending)
            ? IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: AppTheme.primaryGold,
                tooltip: 'إعادة المحاولة',
                onPressed: () => queue.retryItem(action.id),
              )
            : null,
      ),
    );
  }

  Color _statusColor(OfflineItemStatus status) {
    switch (status) {
      case OfflineItemStatus.pending:
        return AppTheme.warningAmber;
      case OfflineItemStatus.processing:
        return AppTheme.infoBlue;
      case OfflineItemStatus.failed:
        return AppTheme.errorRed;
      case OfflineItemStatus.completed:
        return AppTheme.emeraldGreen;
      case OfflineItemStatus.skipped:
        return AppTheme.silver;
    }
  }

  IconData _statusIcon(OfflineItemStatus status) {
    switch (status) {
      case OfflineItemStatus.pending:
        return Icons.schedule;
      case OfflineItemStatus.processing:
        return Icons.sync;
      case OfflineItemStatus.failed:
        return Icons.error;
      case OfflineItemStatus.completed:
        return Icons.check_circle;
      case OfflineItemStatus.skipped:
        return Icons.cancel;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_check,
            size: 64,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          Text(
            'الطابور فارغ — كل الإجراءات متماثلة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
