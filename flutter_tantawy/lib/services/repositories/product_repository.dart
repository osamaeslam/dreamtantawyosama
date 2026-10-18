import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import 'base_repository.dart';

/// All Supabase read/write operations for the product catalog, variants,
/// branches, stock reservation and promotions.
class ProductRepository extends BaseRepository {
  const ProductRepository();

  Future<List<Product>> fetchProducts({
    String? branchName,
    String? department,
  }) async {
    try {
      var query = client.from('products').select();
      if (department != null && department != 'الكل') {
        query = query.eq('department', department);
      }
      final data = await query.order('name');
      return (data as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchProducts', e);
      return [];
    }
  }

  /// جلب منتجات مجمّعة مع متغيّرها (الألوان/النوافذ) — يطابق بنية ParentProduct في types.ts
  Future<List<ParentProduct>> fetchParentProducts({
    String? department,
    String? branchName,
    String? searchQuery,
  }) async {
    try {
      var query =
          client.from('parent_products').select('*, variants:variants!inner(*)');
      if (department != null && department != 'الكل') {
        query = query.eq('department', department);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
            'name.ilike.%$searchQuery%,primary_code.ilike.%$searchQuery%,unified_code.ilike.%$searchQuery%');
      }
      final data = await query.order('name');
      return (data as List<dynamic>)
          .map((e) => ParentProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchParentProducts', e);
      final products =
          await fetchProducts(branchName: branchName, department: department);
      return products
          .map((p) => _fallbackParentProduct(p))
          .toList();
    }
  }

  /// جلب متغيّرات منتج واحد (الألوان والنوافذ/الشبابيك)
  Future<List<ProductVariant>> fetchProductVariants({
    required String productId,
  }) async {
    try {
      final data = await client
          .from('product_variants')
          .select()
          .eq('product_id', productId)
          .order('name');
      return (data as List<dynamic>)
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchProductVariants', e);
      return [];
    }
  }

  // ===================== الفروع (Branches) =====================
  Future<List<Branch>> fetchBranches() async {
    try {
      final data = await client.from('branches').select();
      return (data as List<dynamic>)
          .map((e) => Branch.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchBranches', e);
      return [];
    }
  }

  /// جلب أرصدة فرع محدد لمنتج — يدعم شاشة كتالوج المنتجات
  Future<Map<String, int>> fetchProductBranchStock(
    String productId,
    String branchName,
  ) async {
    try {
      final data = await client
          .from('product_stocks')
          .select('quantity_actual, quantity_reserved')
          .eq('product_id', productId)
          .eq('branch_name', branchName)
          .maybeSingle();
      if (data == null) return {};
      return {
        'actual': (data['quantity_actual'] as num?)?.toInt() ?? 0,
        'reserved': (data['quantity_reserved'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      logError('fetchProductBranchStock', e);
      return {};
    }
  }

  /// تحديث رصيد الصنف لمنع الحجز المزدوج
  Future<bool> reserveStock({
    required String productId,
    required int cartonsToReserve,
  }) async {
    try {
      final res = await client.rpc('reserve_product_stock', params: {
        'p_id': productId,
        'quantity': cartonsToReserve,
      });
      return res == true;
    } catch (e) {
      logError('reserveStock', e);
      return false;
    }
  }

  // ===================== العروض الترويجية (Promotions) =====================
  Future<List<PromotionOffer>> fetchPromotions({
    bool activeOnly = true,
    String? branchName,
    String? productCode,
  }) async {
    try {
      var query = client.from('promotions').select();
      if (activeOnly) {
        final now = DateTime.now().toIso8601String();
        query = query
            .eq('status', 'نشط')
            .gte('start_date', now)
            .lte('end_date', now);
      }
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (productCode != null && productCode.isNotEmpty) {
        query = query.eq('product_code', productCode);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((e) => PromotionOffer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchPromotions', e);
      return [];
    }
  }

  // ===================== Realtime Stream =====================
  RealtimeChannel subscribeToOrders(
    void Function(Map<String, dynamic> payload) onEvent,
  ) {
    return client
        .channel('public:invoices')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (payload) => onEvent(payload.newRecord),
        )
        .subscribe();
  }

  ParentProduct _fallbackParentProduct(Product p) {
    final fallbackVariant = ProductVariant(
      id: '${p.id}_default',
      productId: p.id,
      code: p.code,
      name: p.name,
      color: p.color ?? 'أبيض',
      branchStockActual: p.branchStockActual,
      branchStockReserved: p.branchStockReserved,
      cartonQuantity: p.cartonQuantity,
      piecePrice: p.piecePrice,
      cartonPrice: p.cartonPrice,
      promoPrice: p.promoPrice,
      status: p.status,
      imageUrl: p.imageUrl,
      unifiedCode: p.unifiedCode,
    );
    return ParentProduct(
      id: p.id,
      primaryCode: p.code,
      unifiedCode: p.unifiedCode,
      name: p.name,
      department: p.department,
      category: p.category,
      classification: p.classification,
      familyName: p.familyName,
      salesPriority: p.salesPriority,
      status: p.status,
      cartonQuantity: p.cartonQuantity,
      imageUrl: p.imageUrl,
      minPrice: p.cartonPrice,
      maxPrice: p.cartonPrice,
      totalBranchStock: p.availableStock,
      variants: [fallbackVariant],
      variantsCount: 1,
      hasMultipleVariants: false,
      defaultVariant: fallbackVariant,
    );
  }
}
