import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'order_builder_screen.dart';

class CatalogScreen extends StatefulWidget {
  final AppUser currentUser;
  const CatalogScreen({super.key, required this.currentUser});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedDepartment = 'الكل';
  final _searchController = TextEditingController();

  final List<String> _departments = [
    'الكل',
    'أدوات منزلية',
    'أجهزة كهربائية',
    'بلاستيك وميلامين',
    'زجاج وبورسلين',
    'عروض ترويجية',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.fetchProducts();
    if (data.isEmpty) {
      // بيانات تجريبية مطابقة في حال عدم الاتصال المباشر
      _allProducts = _generateMockProducts();
    } else {
      _allProducts = data;
    }
    _applyFilter();
    if (mounted) setState(() => _isLoading = false);
  }

  List<Product> _generateMockProducts() {
    return [
      Product(
        id: 'p1',
        code: 'TNT-101',
        name: 'طقم حلل جرانيت 10 قطع تركي فاخر',
        department: 'أدوات منزلية',
        category: 'جرانيت وسيراميك',
        piecePrice: 450.0,
        cartonPrice: 1800.0,
        cartonQuantity: 4,
        branchStockActual: 24,
        branchStockReserved: 4,
        mainWarehouseStock: 150,
        status: 'متاح',
        salesPriority: 'مرتفع',
      ),
      Product(
        id: 'p2',
        code: 'TNT-102',
        name: 'طقم كاسات كريستال بوهيمي 6 قطع',
        department: 'زجاج وبورسلين',
        category: 'كريستال',
        piecePrice: 120.0,
        cartonPrice: 1440.0,
        cartonQuantity: 12,
        branchStockActual: 10,
        branchStockReserved: 0,
        mainWarehouseStock: 80,
        status: 'متاح',
        salesPriority: 'عادي',
      ),
      Product(
        id: 'p3',
        code: 'TNT-103',
        name: 'خلاط يدوي تورنيدو 1000 وات مع مضرب',
        department: 'أجهزة كهربائية',
        category: 'محضرات طعام',
        piecePrice: 350.0,
        cartonPrice: 2100.0,
        promoPrice: 1950.0,
        cartonQuantity: 6,
        branchStockActual: 18,
        branchStockReserved: 2,
        mainWarehouseStock: 200,
        status: 'عرض ترويجي',
        salesPriority: 'مرتفع',
      ),
      Product(
        id: 'p4',
        code: 'TNT-104',
        name: 'طقم علب ثلاجة محكمة الغلق 5 قطع',
        department: 'بلاستيك وميلامين',
        category: 'حافظات طعام',
        piecePrice: 45.0,
        cartonPrice: 1080.0,
        cartonQuantity: 24,
        branchStockActual: 45,
        branchStockReserved: 5,
        mainWarehouseStock: 320,
        status: 'متاح',
        salesPriority: 'عادي',
      ),
    ];
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesDept = _selectedDepartment == 'الكل' || p.department == _selectedDepartment;
        final matchesSearch = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.code.toLowerCase().contains(query);
        return matchesDept && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text(
          'كتالوج المنتجات والأسعار',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProducts,
            tooltip: 'تحديث الكتالوج',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'ابحث باسم الصنف أو الكود...',
                hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // شريط الأقسام
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              itemCount: _departments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final dept = _departments[index];
                final isSelected = dept == _selectedDepartment;
                return ChoiceChip(
                  label: Text(dept, style: GoogleFonts.cairo(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGold,
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(color: isSelected ? AppTheme.darkSlate : const Color(0xFF475569)),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedDepartment = dept);
                      _applyFilter();
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // قائمة المنتجات
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد أصناف مطابقة للبحث',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final itemInCart = cart.items[product.id];
                          final currentCartons = itemInCart?.cartons ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: currentCartons > 0 ? AppTheme.primaryGold : const Color(0xFFE2E8F0),
                                width: currentCartons > 0 ? 1.5 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // صورة أو أيقونة
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGold, size: 30),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // تفاصيل الصنف
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.darkSlate,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    product.code,
                                                    style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.secondaryGold, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  product.department,
                                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.name,
                                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'سعر الكرتونة: ${product.promoPrice != null ? product.promoPrice : product.cartonPrice} ج.م',
                                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F766E)),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '(شدة: ${product.cartonQuantity})',
                                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  const SizedBox(height: 10),

                                  // الرصيد وأزرار الإضافة للسلة
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // مؤشر الرصيد
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.warehouse_outlined,
                                            size: 16,
                                            color: product.availableStock > 0 ? const Color(0xFF10B981) : Colors.red,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'متاح بالفرع: ${product.availableStock} كرتونة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: product.availableStock > 0 ? const Color(0xFF065F46) : Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // عداد الإضافة للسلة
                                      Row(
                                        children: [
                                          if (currentCartons > 0) ...[
                                            IconButton.filledTonal(
                                              icon: const Icon(Icons.remove, size: 16),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              onPressed: () {
                                                cart.addOrUpdateProduct(product: product, cartons: currentCartons - 1);
                                              },
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$currentCartons',
                                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                          ],
                                          IconButton.filled(
                                            icon: const Icon(Icons.add, size: 16),
                                            style: IconButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.darkSlate),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            onPressed: () {
                                              if (currentCartons < product.availableStock) {
                                                cart.addOrUpdateProduct(product: product, cartons: currentCartons + 1);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('الكمية المطلوبة تتجاوز الرصيد المتاح بالفرع')),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      // زر الذهاب للسلة وتأكيد الطلبية
      bottomNavigationBar: cart.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'السلة: ${cart.totalCartons} كرتونة',
                            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            'الإجمالي: ${cart.netTotal.toStringAsFixed(2)} ج.م',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkSlate,
                        foregroundColor: AppTheme.secondaryGold,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.secondaryGold),
                      label: Text('إتمام الطلبية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderBuilderScreen(currentUser: widget.currentUser),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
