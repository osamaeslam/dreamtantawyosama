import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class OrderBuilderScreen extends StatefulWidget {
  final AppUser currentUser;
  const OrderBuilderScreen({super.key, required this.currentUser});

  @override
  State<OrderBuilderScreen> createState() => _OrderBuilderScreenState();
}

class _OrderBuilderScreenState extends State<OrderBuilderScreen> {
  List<Customer> _customers = [];
  bool _isLoadingCustomers = true;
  bool _isSubmitting = false;

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  void _fetchCustomers() async {
    try {
      final data = await SupabaseService.instance.fetchCustomers(
        repName: rbac.isSalesRep ? widget.currentUser.name : null,
        repId: rbac.isSalesRep ? widget.currentUser.id : null,
        branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
      );

      _customers = rbac.filterCustomerAccounts(data);
      if (!mounted) return;
      final cart = context.read<CartService>();
      final currentCustomer = cart.selectedCustomer;
      if (currentCustomer != null) {
        Customer? refreshedCustomer;
        for (final customer in _customers) {
          if (customer.id == currentCustomer.id) {
            refreshedCustomer = customer;
            break;
          }
        }
        cart.selectCustomer(refreshedCustomer);
      }
      setState(() => _isLoadingCustomers = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل قائمة العملاء: $e')),
      );
    }
  }

  void _submitOrder() async {
    final cart = context.read<CartService>();
    if (cart.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العميل أولاً')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await cart.submitOrder(currentUser: widget.currentUser);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text('تم حفظ الطلبية بنجاح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              'تم ترحيل الطلبية لقاعدة بيانات المنظومة، وهي الآن في انتظار اعتماد المشرف وأمين المخزن.',
              style: GoogleFonts.cairo(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text('العودة للكتالوج', style: GoogleFonts.cairo()),
              ),
            ],
          ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حفظ الطلبية، يرجى المحاولة ثانية')),
      );
    }
  }

  Widget _customerSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 12)),
        Text(
          value,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final customer = cart.selectedCustomer;
    final projectedCustomerBalance = customer == null
        ? 0.0
        : (customer.balance ?? customer.currentBalance) +
            (cart.paymentType == 'نقدي' ? 0 : cart.netTotal);
    final exceedsCreditLimit = customer != null &&
        customer.creditLimit > 0 &&
        projectedCustomerBalance > customer.creditLimit;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('إنشاء وتأكيد الطلبية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('السلة فارغة حالياً', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('الذهاب للكتالوج لإضافة أصناف', style: GoogleFonts.cairo()),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // اختيار العميل
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_pin_outlined, color: AppTheme.primaryGold),
                              const SizedBox(width: 8),
                              Text('بيانات العميل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isLoadingCustomers
                              ? const LinearProgressIndicator()
                              : _customers.isEmpty
                                  ? Text(
                                      'لا يوجد عملاء مسندون لهذا المندوب في قاعدة العملاء.',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    )
                              : DropdownButtonFormField<Customer>(
                                  value: cart.selectedCustomer,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'اختر العميل من القائمة',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  items: _customers.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text('${c.name} (${c.code})', style: GoogleFonts.cairo(fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) => cart.selectCustomer(val),
                                ),
                          if (cart.selectedCustomer != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: exceedsCreditLimit
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: exceedsCreditLimit
                                      ? const Color(0xFFFECACA)
                                      : const Color(0xFFBBF7D0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('المديونية الحالية:', style: GoogleFonts.cairo(fontSize: 12)),
                                      Text('${(cart.selectedCustomer!.balance ?? cart.selectedCustomer!.currentBalance).toStringAsFixed(2)} ج.م',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('المستحق / المتأخر:', style: GoogleFonts.cairo(fontSize: 12)),
                                      Text('${(cart.selectedCustomer!.dueBalance ?? cart.selectedCustomer!.totalOverdueAndDue ?? cart.selectedCustomer!.overdueBalance).toStringAsFixed(2)} ج.م',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  _customerSummaryRow(
                                    'الحد الائتماني:',
                                    '${cart.selectedCustomer!.creditLimit.toStringAsFixed(2)} ج.م',
                                  ),
                                  _customerSummaryRow(
                                    'طريقة الدفع المسجلة:',
                                    cart.paymentType,
                                  ),
                                  _customerSummaryRow(
                                    'إجمالي الفاتورة:',
                                    '${cart.netTotal.toStringAsFixed(2)} ج.م',
                                  ),
                                  _customerSummaryRow(
                                    'المديونية بعد الفاتورة:',
                                    '${projectedCustomerBalance.toStringAsFixed(2)} ج.م',
                                  ),
                                  if (exceedsCreditLimit)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '⚠️ تنبيه: العميل متجاوز للحد الائتماني المسموح به ويتطلب موافقة المشرف',
                                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // قائمة الأصناف المختارة
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الأصناف المحجوزة (${cart.items.length})',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                              TextButton(
                                onPressed: () => cart.clearCart(),
                                child: Text('مسح السلة', style: GoogleFonts.cairo(color: Colors.red, fontSize: 12)),
                              ),
                            ],
                          ),
                          const Divider(),
                          ...cart.items.values.map((item) {
                            final hasVariant = item.variantId != null || item.color != null;
                            final branchQuantity =
                                item.cartons.clamp(0, item.branchStockAtOrder ?? 0);
                            final octoberQuantity =
                                (item.cartons - branchQuantity)
                                    .clamp(0, item.octoberStockAtOrder ?? 0);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(item.productName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                                            if (hasVariant) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.darkSlate,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item.productCode,
                                                  style: GoogleFonts.cairo(fontSize: 9, color: AppTheme.secondaryGold, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (item.color != null)
                                          Text(
                                            'لون: ${item.color}',
                                            style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
                                          ),
                                        Text(
                                          '${item.cartons} كرتونة × ${item.cartonPrice.toStringAsFixed(0)} ج.م = ${item.totalPrice.toStringAsFixed(1)} ج.م',
                                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          'صرف متوقع: الفرع $branchQuantity • أكتوبر $octoberQuantity',
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        if ((item.shortageCartons ?? 0) > 0)
                                          Text(
                                            'نقص ${item.shortageCartons} كرتونة — يحتاج مراجعة المشرف',
                                            style: GoogleFonts.cairo(
                                              fontSize: 10,
                                              color: AppTheme.roseRed,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => cart.removeItem(item.productId + (item.variantId != null ? '_${item.variantId}' : '')),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // طريقة الدفع والخصم
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الدفع والإجمالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('طريقة الدفع المسجلة للعميل:',
                                  style: GoogleFonts.cairo(fontSize: 12)),
                              Text(
                                cart.paymentType,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('المجموع قبل الخصم:', style: GoogleFonts.cairo(fontSize: 13)),
                              Text('${cart.subtotal.toStringAsFixed(2)} ج.م', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الصافي النهائي:', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
                              Text('${cart.netTotal.toStringAsFixed(2)} ج.م',
                                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F766E))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // زر الحفظ النهائي
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: AppTheme.darkSlate,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSubmitting ? null : _submitOrder,
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded),
                              const SizedBox(width: 8),
                              Text('إرسال الطلبية للاعتماد والصرف',
                                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
