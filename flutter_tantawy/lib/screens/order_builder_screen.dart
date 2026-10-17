import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/pdf_invoice_service.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  void _fetchCustomers() async {
    final data = await SupabaseService.instance.fetchCustomers();
    if (data.isEmpty) {
      // عملاء تجريبيين
      _customers = [
        Customer(
          id: 'c1',
          code: 'CUST-001',
          name: 'معرض الأمل للأدوات المنزلية',
          storeName: 'معرض الأمل',
          phone: '01099887766',
          branchName: 'فرع القاهرة الكبرى',
          currentBalance: 12500,
          creditLimit: 50000,
          overdueBalance: 0,
          tier: 'مميز',
        ),
        Customer(
          id: 'c2',
          code: 'CUST-002',
          name: 'سنتر النور والبركة',
          storeName: 'سنتر النور',
          phone: '01122334455',
          branchName: 'فرع القاهرة الكبرى',
          currentBalance: 62000,
          creditLimit: 50000,
          overdueBalance: 15000,
          tier: 'متوسط',
        ),
        Customer(
          id: 'c3',
          code: 'CUST-003',
          name: 'هايبر ماركت الفرسان',
          storeName: 'الفرسان',
          phone: '01233445566',
          branchName: 'فرع القاهرة الكبرى',
          currentBalance: 8000,
          creditLimit: 100000,
          overdueBalance: 0,
          tier: 'راقي',
        ),
      ];
    } else {
      _customers = data;
    }
    if (mounted) setState(() => _isLoadingCustomers = false);
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
    setState(() => _isSubmitting = false);

    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

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
                                color: cart.selectedCustomer!.isOverCreditLimit
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cart.selectedCustomer!.isOverCreditLimit
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
                                      Text('الرصيد الحالي:', style: GoogleFonts.cairo(fontSize: 12)),
                                      Text('${cart.selectedCustomer!.currentBalance} ج.م',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('الحد الائتماني:', style: GoogleFonts.cairo(fontSize: 12)),
                                      Text('${cart.selectedCustomer!.creditLimit} ج.م',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  if (cart.selectedCustomer!.isOverCreditLimit)
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(
                                          '${item.cartons} كرتونة × ${item.cartonPrice} ج.م = ${item.totalPrice.toStringAsFixed(1)} ج.م',
                                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => cart.removeItem(item.productId),
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
                          Text('خيارات الدفع والإجمالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text('آجل', style: GoogleFonts.cairo(fontSize: 13)),
                                  value: 'آجل',
                                  groupValue: cart.paymentType,
                                  onChanged: (val) => cart.setPaymentType(val!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text('نقدي', style: GoogleFonts.cairo(fontSize: 13)),
                                  value: 'نقدي',
                                  groupValue: cart.paymentType,
                                  onChanged: (val) => cart.setPaymentType(val!),
                                  contentPadding: EdgeInsets.zero,
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
