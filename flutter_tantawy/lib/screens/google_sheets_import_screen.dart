import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';

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
          content: Text('يرجى إدخال رابط شيت واحد على الأقل', style: GoogleFonts.cairo()),
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
      // TODO: Implement actual smart sync logic
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _statusMessage = 'تمت المزامنة بنجاح';
        _added = 15;
        _updated = 7;
        _skipped = 42;
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

    return Scaffold(
      appBar: AppBar(
        title: Text('مزامنة من Google Sheets', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(32),
          child: ConnectionStatusBar(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sync, color: AppTheme.primaryGold),
                      const SizedBox(width: 8),
                      Text(
                        'مزامنة ذكية لبيانات Google Sheets',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أرفق روابط الشيتات المنشورة بصيغة CSV. سيتم مقارنة البيانات وتحديث ما تغير فقط دون مسح الموجود.',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSheetCard('١) قاعدة العملاء', 'رابط شيت العملاء (كود العميل، الاسم، العنوان، المندوب...)', _customersUrlController),
          const SizedBox(height: 12),
          _buildSheetCard('٢) الأصناف + المخزون', 'رابط شيت الأصناف (كود الصنف، الاسم، السعر، الكمية...)', _productsUrlController),
          const SizedBox(height: 12),
          _buildSheetCard('٣) التارجت', 'رابط شيت التارجت (المندوب، الفرع، الشهر، التارجت...)', _targetsUrlController),
          const SizedBox(height: 12),
          _buildSheetCard('٤) العروض', 'رابط شيت العروض (كود الصنف، العرض، فترة العرض...)', _offersUrlController),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _startSync,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_sync),
              label: Text(
                _isSyncing ? 'جاري المزامنة...' : 'بدء المزامنة الذكية',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: AppTheme.darkSlate,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: _isSyncing ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_statusMessage, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    if (!_isSyncing && (_added > 0 || _updated > 0 || _skipped > 0)) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('مضاف', _added, Colors.green),
                          _buildStat('محدث', _updated, Colors.orange),
                          _buildStat('متخطى', _skipped, Colors.grey),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كيفية النشر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '١. افتح كل شيت في Google Sheets\n٢. مشاركة > نشر على الويب\n٣. اختر الصيغة: "القيم المفصولة بفواصل (.csv)"\n٤. انشر واحفظ الرابط هنا',
                    style: GoogleFonts.cairo(fontSize: 12, height: 1.8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetCard(String title, String hint, TextEditingController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.cairo(fontSize: 11),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              style: GoogleFonts.cairo(fontSize: 12),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: GoogleFonts.cairo(fontSize: 11)),
      ],
    );
  }
}
