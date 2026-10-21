import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/supabase_service.dart';
import '../services/pdf_catalog_service.dart';
import '../services/excel_catalog_service.dart';
import '../theme/app_theme.dart';
import 'order_builder_screen.dart';

class CatalogScreen extends StatefulWidget {
  final AppUser currentUser;
  const CatalogScreen({super.key, required this.currentUser});

  @override
  State<CatalogScreen> createState() => _CatalogViewState();
}

enum CatalogViewMode { grid, list }
enum SortBy { recommended, priceLow, priceHigh, discount, stockAvailability }

class _CatalogViewState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ParentProduct> _allProducts = [];
  List<ParentProduct> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedDepartment = 'الكل';
  CatalogViewMode _viewMode = CatalogViewMode.grid;
  SortBy _sortBy = SortBy.recommended;
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
    _tabController = TabController(length: _departments.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedDepartment = _departments[_tabController.index];
        });
        _applyFilter();
      }
    });
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.fetchParentProducts(
      department: _selectedDepartment != 'الكل' ? _selectedDepartment : null,
      branchName: widget.currentUser.branchName,
    );
    _allProducts = data;
    _applyFilter();
    if (mounted) setState(() => _isLoading = false);
  }

  void _exportToExcel() async {
    try {
      await ExcelCatalogService.shareCatalog(_filteredProducts);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تصدير الإكسل: $e', style: GoogleFonts.cairo())),
      );
    }
  }

  String _normalizeSearchText(String value) {
    if (value.isEmpty) return '';
    return value
        .toLowerCase()
        .replaceAll(RegExp('[إأآا]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp('[ىي]'), 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .trim();
  }

  void _applyFilter() {
    final query = _normalizeSearchText(_searchController.text);
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesDept = _selectedDepartment == 'الكل' ||
            (_selectedDepartment == 'عروض ترويجية'
                ? p.variants.any((v) => v.hasPromo)
                : p.department == _selectedDepartment);

        final matchesSearch = query.isEmpty ||
            _normalizeSearchText(p.name).contains(query) ||
            _normalizeSearchText(p.primaryCode).contains(query) ||
            _normalizeSearchText(p.unifiedCode ?? '').contains(query) ||
            _normalizeSearchText(p.department).contains(query) ||
            _normalizeSearchText(p.category).contains(query) ||
            p.variants.any((v) => _normalizeSearchText(v.color).contains(query));

        return matchesDept && matchesSearch;
      }).toList();

      // تطبيق الترتيب
       switch (_sortBy) {
        case SortBy.priceLow:
          _filteredProducts.sort((a, b) => _comparePrice(a, b, true));
          break;
        case SortBy.priceHigh:
          _filteredProducts.sort((a, b) => _comparePrice(a, b, false));
          break;
        case SortBy.discount:
          _filteredProducts.sort((a, b) {
            final discountA = _discountPercent(a);
            final discountB = _discountPercent(b);
            if (discountA == discountB) return 0;
            return discountB.compareTo(discountA);
          });
          break;
        case SortBy.stockAvailability:
          _filteredProducts.sort((a, b) {
            final tierA = _stockTier(a);
            final tierB = _stockTier(b);
            if (tierA != tierB) return tierA.compareTo(tierB);
            final stockA = a.defaultVariant?.availableForOrder ?? 0;
            final stockB = b.defaultVariant?.availableForOrder ?? 0;
            return stockB.compareTo(stockA);
          });
          break;
        case SortBy.recommended:
          _filteredProducts.sort((a, b) {
            final tierA = _stockTier(a);
            final tierB = _stockTier(b);
            if (tierA != tierB) return tierA.compareTo(tierB);
            final priorityOrder = {'مرتفع': 0, 'متوسط': 1, 'عادي': 2, 'منخفض': 3};
            final pa = priorityOrder[a.salesPriority] ?? 2;
            final pb = priorityOrder[b.salesPriority] ?? 2;
            if (pa != pb) return pa.compareTo(pb);
            return b.variants.first.availableForOrder
                .compareTo(a.variants.first.availableForOrder);
          });
          break;
      }
    });
  }

  int _comparePrice(ParentProduct a, ParentProduct b, bool ascending) {
    final priceA = a.defaultVariant?.effectiveCartonPrice ?? a.minPrice;
    final priceB = b.defaultVariant?.effectiveCartonPrice ?? b.minPrice;
    return ascending
        ? priceA.compareTo(priceB)
        : priceB.compareTo(priceA);
  }

  int _discountPercent(ParentProduct p) {
    final v = p.defaultVariant;
    if (v == null || v.promoPrice == null) return 0;
    final original = v.cartonPrice;
    if (original <= 0) return 0;
    return (((original - v.promoPrice!) / original) * 100).round();
  }

  int _stockTier(ParentProduct p) {
    final v = p.defaultVariant;
    final totalVariantStock =
        (v?.availableStock ?? 0) + (v?.octoberAvailableStock ?? 0);
    if (v == null) {
      return p.totalBranchStock > 0
          ? 0
          : p.totalOctoberStock > 0
              ? 1
              : 2;
    }
    if (totalVariantStock <= 0) {
      return 2;
    }
    if (v.availableStock > 0) return 0;
    return v.octoberAvailableStock > 0 ? 1 : 2;
  }

  void _showVariantSelector(ParentProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${product.variantsCount} ${product.variantsCount > 1 ? "شباك متاح" : "خيار"}',
              style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: product.variants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final variant = product.variants[index];
                  final isAvailable = variant.availableForOrder > 0;
                  final cart = context.read<CartService>();
                  final key = '${product.id}_${variant.id}';
                  final inCart = cart.items.containsKey(key) ? cart.items[key]!.cartons : 0;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isAvailable ? const Color(0xFFD1D5DB) : Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: variant.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          variant.imageUrl!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.inventory_2_outlined,
                                            color: AppTheme.primaryGold,
                                            size: 28,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.inventory_2_outlined,
                                          color: AppTheme.primaryGold,
                                          size: 28,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          variant.code,
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.darkSlate,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          variant.color,
                                          style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      variant.name,
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isAvailable ? null : AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'سعر الكرتونة: ${variant.effectiveCartonPrice.toStringAsFixed(0)} ج.م',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: const Color(0xFF0F766E),
                                      ),
                                    ),
                                    Text(
                                      '(شدة: ${variant.cartonQuantity})',
                                      style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isAvailable)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'نفاد',
                                    style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.roseRed, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          )),
                          if (isAvailable)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'الفرع: ${variant.availableStock} • أكتوبر: ${variant.octoberAvailableStock} كرتونة',
                                    style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 18),
                                        onPressed: inCart > 0
                                            ? () {
                                                Navigator.pop(context);
                                                cart.addOrUpdateProduct(
                                                  product: variant.rawProduct ?? Product(
                                                    id: product.id,
                                                    code: product.primaryCode,
                                                    name: product.name,
                                                    department: product.department,
                                                    category: product.category,
                                                    piecePrice: variant.piecePrice,
                                                    cartonPrice: variant.cartonPrice,
                                                    promoPrice: variant.promoPrice,
                                                    cartonQuantity: variant.cartonQuantity,
                                                    branchStockActual: variant.branchStockActual,
                                                    branchStockReserved: variant.branchStockReserved,
                                                    mainWarehouseStock: variant.mainWarehouseActual,
                                                    status: variant.status,
                                                    salesPriority: product.salesPriority,
                                                    unifiedCode: variant.unifiedCode ?? product.unifiedCode,
                                                  ),
                                                  variant: variant,
                                                  cartons: inCart - 1,
                                                  branchName: widget.currentUser.branchName,
                                                );
                                              }
                                            : null,
                                        color: inCart > 0 ? AppTheme.primaryGold : AppTheme.textMuted,
                                      ),
                                      Text('$inCart', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          cart.addOrUpdateProduct(
                                            product: variant.rawProduct ?? Product(
                                              id: product.id,
                                              code: product.primaryCode,
                                              name: product.name,
                                              department: product.department,
                                              category: product.category,
                                              piecePrice: variant.piecePrice,
                                              cartonPrice: variant.cartonPrice,
                                              promoPrice: variant.promoPrice,
                                              cartonQuantity: variant.cartonQuantity,
                                              branchStockActual: variant.branchStockActual,
                                              branchStockReserved: variant.branchStockReserved,
                                              mainWarehouseStock: variant.mainWarehouseActual,
                                              status: variant.status,
                                              salesPriority: product.salesPriority,
                                              unifiedCode: variant.unifiedCode ?? product.unifiedCode,
                                            ),
                                            variant: variant,
                                            cartons: inCart + 1,
                                            branchName: widget.currentUser.branchName,
                                          );
                                        },
                                        color: AppTheme.primaryGold,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildProductImage(String? imageUrl, double width, double height) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageSurface = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkBackground
        : const Color(0xFFF1F5F9);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: imageSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGold, size: 32),
            ),
          ),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: imageSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGold, size: 32),
      ),
    );
  }

  Widget _buildGridView(List<ParentProduct> products) {
    final cart = context.watch<CartService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isCompact = screenWidth < 380;
    final crossAxisCount = isDesktop ? 4 : screenWidth >= 650 ? 3 : 2;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageSurface = isDark ? AppTheme.darkBackground : AppTheme.backgroundLight;
    final footerSurface = isDark ? AppTheme.darkBackground : AppTheme.backgroundLight;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isDesktop ? 0.78 : isCompact ? 0.50 : 0.58,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final variant = product.defaultVariant!;
        final hasPromo = variant.hasPromo;
        final discountPct = hasPromo
            ? ((((variant.cartonPrice - variant.promoPrice!) / variant.cartonPrice) * 100).round())
            : 0;
        final effectivePrice = variant.effectiveCartonPrice;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // صورة أو أيقونة الصنف مع شارات
              Container(
                height: isCompact ? 112 : 128,
                color: imageSurface,
                child: Stack(
                  children: [
                    Center(
                      child: _buildProductImage(variant.imageUrl, 110, 110),
                    ),
                    // شارة الخصم
                    if (hasPromo && discountPct > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.roseRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'خصم $discountPct%',
                            style: GoogleFonts.cairo(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    // شارة أكثر مبيعاً
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, color: AppTheme.darkSlate, size: 12),
                            SizedBox(width: 2),
                            Text('#1', style: TextStyle(color: AppTheme.darkSlate, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    // شارة مستوى المخزون
                    if (product.defaultVariant != null)
                      Positioned(
                        top: 8,
                        right: isCompact ? 50 : 52,
                        child: Builder(builder: (context) {
                          final tier = _stockTier(product);
                          final color = tier == 0
                              ? AppTheme.emeraldGreen
                              : tier == 1
                                  ? AppTheme.primaryGold
                                  : AppTheme.roseRed;
                          final label = tier == 0
                              ? 'فرع'
                              : tier == 1
                                  ? 'مخزن'
                                  : 'نفاد';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.cairo(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          );
                        }),
                      ),
                    // شارة الكود الموحد
                    if (product.unifiedCode != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSlate,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.unifiedCode!,
                            style: GoogleFonts.cairo(fontSize: 9, color: AppTheme.secondaryGold, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // تفاصيل الصنف
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // الكود والتصنيف
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSlate,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.primaryCode,
                              style: GoogleFonts.cairo(fontSize: 9, color: AppTheme.secondaryGold, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // اسم الصنف
                      Text(
                        product.name,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // الأسعار
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${effectivePrice.toStringAsFixed(0)} ج.م',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.emeraldGreen,
                            ),
                          ),
                          Text(
                            ' / كرتونة',
                            style: GoogleFonts.cairo(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                          if (hasPromo)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                '${variant.cartonPrice.toStringAsFixed(0)} ج.م',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // شدة الكرتونة
                      Text(
                        'شدة: ${variant.cartonQuantity}',
                        style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      // مؤشر الألوان/النوافذ
                      if (product.hasMultipleVariants)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            children: product.variants.take(5).map((v) {
                              final colorVal = _colorFromHex(v.colorCode);
                              return Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colorVal,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colorScheme.surface, width: 1),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // الأزرار: إضافة للسلة + اختيار شاكل
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: footerSurface,
                  border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
                ),
                child: Row(
                  children: [
                    // زر اختيار المتغيّر
                    if (product.hasMultipleVariants)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.palette_outlined, size: 14),
                          label: Text(
                            'اختيار لون',
                            style: GoogleFonts.cairo(fontSize: 11),
                          ),
                          onPressed: () => _showVariantSelector(product),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            foregroundColor: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    if (product.hasMultipleVariants) const SizedBox(width: 8),
                    // عداد الإضافة
                    Expanded(
                      child: _buildCartCounter(product, variant, cart),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _colorFromHex(String? hex) {
    if (hex == null) return AppTheme.primaryGold;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return AppTheme.primaryGold;
  }

  Widget _buildCartCounter(ParentProduct product, ProductVariant variant, CartService cart) {
    final colorScheme = Theme.of(context).colorScheme;
    final key = '${product.id}_${variant.id}';
    final itemInCart = cart.items[key];
    final currentQty = itemInCart?.cartons ?? 0;
    final availableStock = variant.availableForOrder;

    if (currentQty > 0) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryGold),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              color: AppTheme.primaryGold,
              onPressed: () {
                if (currentQty > 0) {
                  cart.addOrUpdateProduct(
                    product: variant.rawProduct ?? _fallbackProduct(product),
                    variant: variant,
                    cartons: currentQty - 1,
                    branchName: widget.currentUser.branchName,
                  );
                }
              },
            ),
            Text(
              '$currentQty',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              color: AppTheme.primaryGold,
              onPressed: () {
                cart.addOrUpdateProduct(
                  product: variant.rawProduct ?? _fallbackProduct(product),
                  variant: variant,
                  cartons: currentQty + 1,
                  branchName: widget.currentUser.branchName,
                );
              },
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
      label: Text(
        availableStock > 0 ? 'إضافة للسلة' : 'نفاد المخزن',
        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      onPressed: availableStock > 0
          ? () {
              cart.addOrUpdateProduct(
                product: variant.rawProduct ?? _fallbackProduct(product),
                variant: variant,
                cartons: 1,
                branchName: widget.currentUser.branchName,
              );
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: availableStock > 0 ? AppTheme.primaryGold : Colors.grey.shade300,
        foregroundColor: AppTheme.darkSlate,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Product _fallbackProduct(ParentProduct p) {
    return Product(
      id: p.id,
      code: p.primaryCode,
      name: p.name,
      department: p.department,
      category: p.category,
      piecePrice: p.defaultVariant?.piecePrice ?? 0,
      cartonPrice: p.defaultVariant?.cartonPrice ?? p.minPrice,
      promoPrice: p.defaultVariant?.promoPrice,
      cartonQuantity: p.cartonQuantity,
      branchStockActual: p.defaultVariant?.branchStockActual ?? 0,
      branchStockReserved: p.defaultVariant?.branchStockReserved ?? 0,
      mainWarehouseStock: p.defaultVariant?.mainWarehouseActual ?? 0,
      status: p.status,
      salesPriority: p.salesPriority,
      unifiedCode: p.unifiedCode,
    );
  }

  Widget _buildListView(List<ParentProduct> products) {
    final cart = context.watch<CartService>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final variant = product.defaultVariant!;
        final hasPromo = variant.hasPromo;
        final discountPct = hasPromo
            ? ((((variant.cartonPrice - variant.promoPrice!) / variant.cartonPrice) * 100).round())
            : 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildProductImage(variant.imageUrl, 56, 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSlate,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.primaryCode,
                              style: GoogleFonts.cairo(fontSize: 9, color: AppTheme.secondaryGold, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasPromo && discountPct > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '🔥 خصم $discountPct%',
                            style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.roseRed, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${variant.effectiveCartonPrice.toStringAsFixed(0)} ج.م',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.emeraldGreen),
                          ),
                          if (hasPromo)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                '${variant.cartonPrice.toStringAsFixed(0)} ج.م',
                                style: GoogleFonts.cairo(fontSize: 10, color: colorScheme.onSurfaceVariant, decoration: TextDecoration.lineThrough),
                              ),
                            ),
                          Text(
                            ' / (${variant.cartonQuantity} قطعة)',
                            style: GoogleFonts.cairo(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.warehouse_outlined,
                            size: 12,
                            color: variant.availableForOrder > 0 ? AppTheme.emeraldGreen : AppTheme.roseRed,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'فرع: ${variant.availableStock} كرتونة',
                            style: GoogleFonts.cairo(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 12,
                            color: variant.octoberAvailableStock > 0 ? AppTheme.emeraldGreen : AppTheme.roseRed,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'أكتوبر: ${variant.octoberAvailableStock}',
                            style: GoogleFonts.cairo(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      Builder(builder: (context) {
                        final tier = _stockTier(product);
                        final tierColor = tier == 0
                            ? AppTheme.emeraldGreen
                            : tier == 1
                                ? AppTheme.primaryGold
                                : AppTheme.roseRed;
                        final tierLabel = tier == 0
                            ? 'متوفر في الفرع'
                            : tier == 1
                                ? 'من المخزن الرئيسي'
                                : 'غير متوفر حالياً';
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: tierColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tierLabel,
                                style: GoogleFonts.cairo(fontSize: 10, color: tierColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                     ],
                   ),
                 ),
                 _buildCartCounter(product, variant, cart),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controlSurface = colorScheme.surface;
    final searchSurface =
        isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'كتالوج المنتجات والأسعار',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
           // زر تبديل العرض (شبكة / قائمة)
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 4),
             child: ToggleButtonsTheme(
                data: ToggleButtonsThemeData(
                  borderColor: Colors.grey.shade600,
                 selectedBorderColor: AppTheme.primaryGold,
                 fillColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: ToggleButtons(
                 isSelected: [_viewMode == CatalogViewMode.grid, _viewMode == CatalogViewMode.list],
                 onPressed: (index) {
                   setState(() {
                     _viewMode = index == 0 ? CatalogViewMode.grid : CatalogViewMode.list;
                   });
                 },
                 children: const [
                   Icon(Icons.grid_view_outlined, size: 18, color: Colors.white70),
                   Icon(Icons.list_outlined, size: 18, color: Colors.white70),
                 ],
               ),
             ),
           ),
          // زر الترتيب
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PopupMenuButton<SortBy>(
              onSelected: (value) {
                setState(() => _sortBy = value);
                _applyFilter();
              },
              icon: const Icon(Icons.sort_outlined, size: 20, color: Colors.white70),
              tooltip: 'ترتيب حسب',
               itemBuilder: (context) => [
                 PopupMenuItem(
                   value: SortBy.recommended,
                   child: Text('الموصى به', style: GoogleFonts.cairo()),
                 ),
                 PopupMenuItem(
                   value: SortBy.stockAvailability,
                   child: Text('المخزون: الفرع أولاً، ثم المخزن', style: GoogleFonts.cairo()),
                 ),
                 PopupMenuItem(
                   value: SortBy.priceLow,
                   child: Text('السعر: من الأقل للأعلى', style: GoogleFonts.cairo()),
                 ),
                 PopupMenuItem(
                   value: SortBy.priceHigh,
                   child: Text('السعر: من الأعلى للأقل', style: GoogleFonts.cairo()),
                 ),
                 PopupMenuItem(
                   value: SortBy.discount,
                   child: Text('أكبر نسبة خصم', style: GoogleFonts.cairo()),
                 ),
               ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProducts,
            tooltip: 'تحديث الكتالوج',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'share') {
                PdfCatalogService.shareCatalog(_filteredProducts);
              } else if (value == 'print') {
                PdfCatalogService.printCatalog(_filteredProducts);
              } else if (value == 'excel') {
                _exportToExcel();
              }
            },
            icon: const Icon(Icons.share_rounded, size: 22, color: Colors.white70),
            tooltip: 'تصدير الكتالوج',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('تصدير إكسل', style: GoogleFonts.cairo()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('طباعة الكتالوج PDF', style: GoogleFonts.cairo()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('مشاركة الكتالوج PDF', style: GoogleFonts.cairo()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث الذكي
          Container(
            color: controlSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، الكود الموحد (#)، أو اللون...',
                hintStyle: GoogleFonts.cairo(fontSize: 13, color: colorScheme.onSurfaceVariant),
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
                fillColor: searchSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            ),
          ),

          // شريط الأقسام (Tab bar)
          Container(
            color: controlSurface,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {},
              isScrollable: true,
              indicatorColor: AppTheme.primaryGold,
              labelColor: colorScheme.onSurface,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabAlignment: TabAlignment.start,
              indicator: const BoxDecoration(),
              tabs: _departments.map((dept) {
                final isSelected = dept == _selectedDepartment;
                return Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryGold : searchSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Text(
                      dept == 'عروض ترويجية' ? '🔥 عروض ترويجية' : dept,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.darkSlate : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),

          // العداد السريع: عدد النتائج
          Container(
            color: controlSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProducts.length} صنف متاح للطلب',
                  style: GoogleFonts.cairo(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
                if (cart.items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 14, color: AppTheme.primaryGold),
                        const SizedBox(width: 4),
                        Text(
                          '${cart.items.length} أصناف',
                          style: GoogleFonts.cairo(fontSize: 11, color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // المحتوى (Grid أو List)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _allProducts.isEmpty
                                  ? 'لا توجد أصناف مسجلة في قاعدة البيانات.'
                                  : 'لا توجد أصناف مطابقة للبحث',
                              style: GoogleFonts.cairo(fontSize: 14, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : _viewMode == CatalogViewMode.grid
                        ? _buildGridView(_filteredProducts)
                        : _buildListView(_filteredProducts),
                      ),
                    ],
                  ),


      // زر الذهاب للسلة وتأكيد الطلبية
      bottomNavigationBar: cart.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: controlSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
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
                            'السلة: ${cart.totalCartons} كرتونة • ${cart.items.length} أصناف',
                            style: GoogleFonts.cairo(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            'الإجمالي: ${cart.netTotal.toStringAsFixed(2)} ج.م',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: AppTheme.darkSlate,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined),
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