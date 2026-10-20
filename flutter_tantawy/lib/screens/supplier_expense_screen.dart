import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// صفحة الموردين والمصروفات — تسمح للـ admin/manager/supervisor
/// بعرض الموردين، تسجيل مصروفات جديدة، وتصفية حسب الفترة.
class SupplierExpenseScreen extends StatefulWidget {
  final AppUser currentUser;

  const SupplierExpenseScreen({super.key, required this.currentUser});

  @override
  State<SupplierExpenseScreen> createState() => _SupplierExpenseScreenState();
}

class _SupplierExpenseScreenState extends State<SupplierExpenseScreen> {
  late Future<List<Supplier>> _suppliersFuture;
  late Future<List<Expense>> _expensesFuture;
  DateTime? _expenseStartDate;
  DateTime? _expenseEndDate;

  @override
  void initState() {
    super.initState();
    _refreshSuppliers();
    _refreshExpenses();
  }

  void _refreshSuppliers() {
    _suppliersFuture = SupabaseService.instance.fetchSuppliers();
  }

  void _refreshExpenses() {
    _expensesFuture = SupabaseService.instance.fetchExpenses(
      branchName: widget.currentUser.branchName,
      startDate: _expenseStartDate,
      endDateExclusive: _expenseEndDate,
    );
  }

  void _applyExpenseFilter(DateTime? start, DateTime? end) {
    setState(() {
      _expenseStartDate = start;
      _expenseEndDate = end;
    });
    _refreshExpenses();
  }

  Future<void> _showExpenseForm() async {
    final formKey = GlobalKey<FormState>();
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final supplierController = TextEditingController();
    String paymentMethod = 'نقدي';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة مصروف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: 'الفئة', hintText: 'مثال: مصاعب، وقود', border: const OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: 'المبلغ (ج.م)', border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null ? 'أدخل مبلغًا صحيحًا' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: supplierController,
                  decoration: InputDecoration(labelText: 'اسم المورد (اختياري)', border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  items: ['نقدي', 'تحويل بنكي', 'شيك'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => paymentMethod = v!,
                  decoration: InputDecoration(labelText: 'طريقة الدفع', border: const OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final expense = Expense(
                id: '',
                branchName: widget.currentUser.branchName,
                repName: widget.currentUser.name,
                supplierName: supplierController.text.trim().isEmpty ? null : supplierController.text.trim(),
                category: categoryController.text.trim(),
                amount: double.tryParse(amountController.text) ?? 0,
                paymentMethod: paymentMethod,
                date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                createdAt: DateTime.now().toIso8601String(),
              );

              final success = await SupabaseService.instance.logExpense(expense);
              if (!mounted) return;
              if (success) {
                Navigator.pop(ctx);
                _refreshExpenses();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل المصروف'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.darkSlate),
            child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('الموردين والمصروفات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (widget.currentUser.role == 'admin' || widget.currentUser.role == 'manager' || widget.currentUser.role == 'branch_manager')
            IconButton(icon: const Icon(Icons.add, size: 20), tooltip: 'إضافة مصروف', onPressed: _showExpenseForm),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: AppTheme.primaryGold,
              labelColor: AppTheme.primaryGold,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: [
                Tab(text: 'الموردين', icon: Icon(Icons.business_outlined, size: 20)),
                Tab(text: 'المصروفات', icon: Icon(Icons.money_off_outlined, size: 20)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // === الموردين ===
                  _buildSuppliersTab(),
                  // === المصروفات ===
                  _buildExpensesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuppliersTab() {
    return FutureBuilder<List<Supplier>>(
      future: _suppliersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final suppliers = snapshot.data ?? [];
        if (suppliers.isEmpty) {
          return const Center(child: Text('لا يوجد موردين مسجلين بعد'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: suppliers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final s = suppliers[i];
            return Card(
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.business, color: AppTheme.darkSlate),
                ),
                title: Text(s.name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.phone != null && s.phone!.isNotEmpty) Text('📱 ${s.phone!}'),
                    if (s.email != null && s.email!.isNotEmpty) Text('📧 ${s.email!}'),
                    if (s.taxNumber != null && s.taxNumber!.isNotEmpty) Text('ضريبي: ${s.taxNumber!}'),
                  ],
                ),
                isThreeLine: true,
                trailing: s.isActive ? const Icon(Icons.check_circle, color: Colors.green) : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: InputChip(
                  label: Text(
                    _expenseStartDate == null
                        ? 'من تاريخ'
                        : DateFormat('yyyy/MM/dd').format(_expenseStartDate!),
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                    _applyExpenseFilter(picked, _expenseEndDate);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputChip(
                  label: Text(
                    _expenseEndDate == null
                        ? 'إلى تاريخ'
                        : DateFormat('yyyy/MM/dd').format(_expenseEndDate!),
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                    _applyExpenseFilter(_expenseStartDate, picked?.add(const Duration(days: 1)));
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Expense>>(
            future: _expensesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final expenses = snapshot.data ?? [];
              if (expenses.isEmpty) {
                return const Center(child: Text('لا يوجد مصروفات مسجلة'));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: expenses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final e = expenses[i];
                  final priorityColor = e.amount > 5000 ? Colors.red.shade100 : Colors.green.shade50;
                  return Card(
                    color: priorityColor,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                        child: const Icon(Icons.money_off, color: AppTheme.darkSlate),
                      ),
                      title: Text(e.category, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      subtitle: Text('${DateFormat('yyyy/MM/dd').format(DateTime.parse(e.date))}\n${e.supplierName ?? ''} - ${e.paymentMethod}', style: GoogleFonts.cairo(fontSize: 11)),
                      isThreeLine: true,
                      trailing: Text('${e.amount.toStringAsFixed(2)} ج.م', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
