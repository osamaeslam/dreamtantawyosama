import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';
import '../services/google_sheets_sync_service.dart';

class GoogleSheetsImportScreen extends StatefulWidget {
  const GoogleSheetsImportScreen({super.key});

  @override
  State<GoogleSheetsImportScreen> createState() => _GoogleSheetsImportScreenState();
}

class _GoogleSheetsImportScreenState extends State<GoogleSheetsImportScreen> {
  final _customersUrlController = TextEditingController();
  final _productsUrlController = TextEditingController();
  final _targetsUrlController = TextEditingController();
  final _offersUrlController = TextEditingController();

  bool _isSyncing = false;
  String _statusMessage = '';
  String _currentSheet = '';
  int _progressCurrent = 0;
  int _progressTotal = 0;
  int _added = 0;
  int _updated = 0;
  int _skipped = 0;

  @override
  void dispose() {
    _customersUrlController.dispose();
    _productsUrlController.dispose();
    _targetsUrlController.dispose();
    _offersUrlController.dispose();
    super.dispose();
  }

  Future<void> _startSync() async {
    if (_customersUrlController.text.isEmpty &&
        _productsUrlController.text.isEmpty &&
        _targetsUrlController.text.isEmpty &&
        _offersUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخول رابط شيت واحد على الأقل',
              style: GoogleFonts.cairo()),
          backgroundColor: AppTheme.primaryGold,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _statusMessage = 'جاري المزامنة الذكية...';
      _added = 0;
      _updated = 0;
      _skipped = 0;
    });

    try {
      final result = await GoogleSheetsSyncService.instance.syncAll(
        productsUrl: _productsUrlController.text.isEmpty ? null : _productsUrlController.text,
        customersUrl: _customersUrlController.text.isEmpty ? null : _customersUrlController.text,
        targetsUrl: _targetsUrlController.text.isEmpty ? null : _targetsUrlController.text,
        offersUrl: _offersUrlController.text.isEmpty ? null : _offersUrlController.text,
        onProgress: (sheetName, current, total) {
          setState(() {
            _currentSheet = sheetName;
            _progressCurrent = current;
            _progressTotal = total;
          });
        },
      );

      setState(() {
        _statusMessage = result.message.isNotEmpty
            ? result.message
            : 'تمت المزامنة بنجاح';
        _added = result.added;
        _updated = result.updated;
        _skipped = result.skipped;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ أثناء المزامنة: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('مزامنة من Google Sheets',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(32),
          child: ConnectionStatusBar(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: cardColor,
            borderOnForeground: false,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.smart_toy, color: AppTheme.primaryGold, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'المزامنة الذكية لبيانات Google Sheets',
                        style: GoogleFonts.cairo(
                            fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'أرفق روابط الشيتات المنشورة بصيغة CSV. سيتم مقارنة البيانات وتحديث ما تغير فقط دون مسح الموجود.',
                    style: GoogleFonts.cairo(fontSize: 13, color: mutedColor, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSheetCard('١) قاعدة العملاء',
              'رابط شيت العملاء (كود العميل، الاسم، العنوان، المندوب...)',
              _customersUrlController,
              isDark: isDark),
          const SizedBox(height: 12),
          _buildSheetCard('٢) الأصناف + المخزون',
              'رابط شيت الأصناف (كود الصنف، الاسم، السعر، الكمية...)',
              _productsUrlController,
              isDark: isDark),
          const SizedBox(height: 12),
          _buildSheetCard('٣) التارجت',
              'رابط شيت التارجت (المندوب، الفرع، الشهر، التارجت...)',
              _targetsUrlController,
              isDark: isDark),
          const SizedBox(height: 12),
          _buildSheetCard('٤) العروض',
              'رابط شيت العروض (كود الصنف، العرض، فترة العرض...)',
              _offersUrlController,
              isDark: isDark),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _startSync,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.cloud_upload, color: AppTheme.darkSlate),
              label: Text(
                _isSyncing ? 'جاري المزامنة...' : 'بدء المزامنة الذكية',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: AppTheme.darkSlate,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ),
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              color: cardColor,
              borderOnForeground: false,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSyncing ? Icons.sync : Icons.check_circle,
                          color: _isSyncing ? Colors.orange : AppTheme.emeraldGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _statusMessage,
                          style: GoogleFonts.cairo(
                              fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ],
                    ),
                    if (_isSyncing && _progressTotal > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        'المعالجة حالياً: $_currentSheet',
                        style: GoogleFonts.cairo(fontSize: 13, color: mutedColor),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _progressTotal > 0 ? _progressCurrent / _progressTotal : 0,
                        backgroundColor: mutedColor.withOpacity(0.2),
                        color: AppTheme.primaryGold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_progressCurrent / $_progressTotal',
                        style: GoogleFonts.cairo(fontSize: 12, color: mutedColor),
                      ),
                    ],
                    if (!_isSyncing && (_added > 0 || _updated > 0 || _skipped > 0)) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('تمت الإضافة', _added, AppTheme.emeraldGreen),
                          _buildStat('تم التحديث', _updated, AppTheme.infoBlue),
                          _buildStat('تم تخطيها', _skipped, mutedColor),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            color: cardColor,
            borderOnForeground: false,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كيفية النشر',
                      style: GoogleFonts.cairo(
                          fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 12),
                  Text(
                    '١. افتح كل شيت في Google Sheets\n'
                    '٢. مشاركة > نشر على الويب\n'
                    '٣. اختر الصيغة: "القيم المفصولة بفواصل (.csv)"\n'
                    '٤. انشر واحفظ الرابط هنا',
                    style: GoogleFonts.cairo(
                        fontSize: 13, height: 1.7, color: mutedColor),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الرابط يجب أن يبدأ بـ https://docs.google.com/spreadsheets/d/.../export?format=csv',
                            style: GoogleFonts.cairo(fontSize: 11, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetCard(String title, String hint, TextEditingController controller,
      {required bool isDark}) {
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Card(
      color: cardColor,
      borderOnForeground: false,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.cairo(fontSize: 12, color: mutedColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.primaryGold, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: isDark ? AppTheme.darkBackground : Colors.white,
              ),
              style: GoogleFonts.cairo(fontSize: 13, color: textColor),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;

    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.cairo(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.cairo(fontSize: 12, color: textColor)),
      ],
    );
  }
}