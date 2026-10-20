import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'supabase_service.dart';

class CartService extends ChangeNotifier {
  final Map<String, OrderItem> _items = {};
  Customer? _selectedCustomer;
  ProductVariant? _selectedVariant;
  double _extraDiscount = 0.0;
  String _paymentType = 'نقدي';
  String? _notes;

  Map<String, OrderItem> get items => _items;
  Customer? get selectedCustomer => _selectedCustomer;
  ProductVariant? get selectedVariant => _selectedVariant;
  double get extraDiscount => _extraDiscount;
  String get paymentType => _paymentType;
  String? get notes => _notes;

  int get totalCartons => _items.values.fold(0, (sum, item) => sum + item.cartons);
  int get totalPieces => _items.values.fold(0, (sum, item) => sum + item.pieces);

  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get netTotal => (subtotal - _extraDiscount).clamp(0.0, double.infinity);

  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    _paymentType = _invoicePaymentType(customer?.paymentTerms);
    notifyListeners();
  }

  String _invoicePaymentType(String? savedTerms) {
    final terms = savedTerms?.trim().toLowerCase() ?? '';
    if (terms.isEmpty) return 'نقدي';
    if (terms.contains('نقد') || terms.contains('كاش') || terms.contains('cash')) {
      return 'نقدي';
    }
    return 'آجل';
  }

  void selectVariant(ProductVariant? variant) {
    _selectedVariant = variant;
    notifyListeners();
  }

  void setExtraDiscount(double discount) {
    _extraDiscount = discount;
    notifyListeners();
  }

  void setPaymentType(String type) {
    _paymentType = type;
    notifyListeners();
  }

  void setNotes(String? text) {
    _notes = text;
    notifyListeners();
  }

  /// إضافة صنف أو تعديل كميته بالسلة — يدعم الآن المتغيّرات (Variants/Colors)
  /// إذا تم تمرير [variant] يتم استخدام رصيد وسعر الـ Variant بدلاً من الأصل
  void addOrUpdateProduct({
    required Product product,
    required int cartons,
    int pieces = 0,
    double discount = 0,
    ProductVariant? variant,
    String? branchName,
  }) {
    final key = variant != null ? '${product.id}_${variant.id}' : product.id;
    if (cartons <= 0 && pieces <= 0) {
      _items.remove(key);
    } else {
      final branchAvailable = variant?.availableStock ??
          product.availableStock.clamp(0, product.branchStockActual).toInt();
      final octoberAvailable = variant?.octoberAvailableStock ??
          (product.mainWarehouseStock -
                  (product.mainWarehouseReserved ?? 0))
              .clamp(0, product.mainWarehouseStock)
              .toInt();
      final branchFulfilled =
          cartons.clamp(0, branchAvailable).toInt();
      final octoberFulfilled =
          (cartons - branchFulfilled).clamp(0, octoberAvailable).toInt();
      final shortage = (cartons - branchFulfilled - octoberFulfilled)
          .clamp(0, cartons)
          .toInt();
      _items[key] = OrderItem(
        productId: product.id,
        productCode: variant?.code ?? product.code,
        productName: variant?.name ?? product.name,
        cartons: cartons,
        pieces: pieces,
        cartonPrice: variant?.effectiveCartonPrice ?? product.promoPrice ?? product.cartonPrice,
        piecePrice: variant?.piecePrice ?? product.piecePrice,
        discount: discount,
        variantId: variant?.id,
        unifiedCode: variant?.unifiedCode ?? product.unifiedCode,
        color: variant?.color,
        branchStockAtOrder: branchAvailable,
        octoberStockAtOrder: octoberAvailable,
        branchName: branchName,
        fulfillFromMainWarehouse: octoberFulfilled > 0,
        fulfilledFrom: branchFulfilled > 0 && octoberFulfilled > 0
            ? 'mixed'
            : octoberFulfilled > 0
                ? 'main_warehouse'
                : 'branch',
        isShortage: shortage > 0,
        shortageCartons: shortage,
        needsOctoberSupply: octoberFulfilled > 0,
      );
    }
    notifyListeners();
  }

  /// نسخة مخصصة لإضافة متغيّر (Variant) مباشرة بدلاً من المنتج الأصلي
  void addOrUpdateVariant({
    required ProductVariant variant,
    required int cartons,
    int pieces = 0,
    double discount = 0,
  }) {
    final key = '${variant.productId}_${variant.id}';
    if (cartons <= 0 && pieces <= 0) {
      _items.remove(key);
    } else {
      final branchAvailable = variant.availableStock;
      final octoberAvailable = variant.octoberAvailableStock;
      final branchFulfilled =
          cartons.clamp(0, branchAvailable).toInt();
      final octoberFulfilled = (cartons - branchFulfilled)
          .clamp(0, octoberAvailable)
          .toInt();
      final shortage =
          (cartons - branchFulfilled - octoberFulfilled)
              .clamp(0, cartons)
              .toInt();
      _items[key] = OrderItem(
        productId: variant.productId,
        productCode: variant.code,
        productName: variant.name,
        cartons: cartons,
        pieces: pieces,
        cartonPrice: variant.effectiveCartonPrice,
        piecePrice: variant.piecePrice,
        discount: discount,
        variantId: variant.id,
        unifiedCode: variant.unifiedCode,
        color: variant.color,
        branchStockAtOrder: branchAvailable,
        octoberStockAtOrder: octoberAvailable,
        fulfilledFrom: branchFulfilled > 0 && octoberFulfilled > 0
            ? 'mixed'
            : octoberFulfilled > 0
                ? 'main_warehouse'
                : 'branch',
        fulfillFromMainWarehouse: octoberFulfilled > 0,
        isShortage: shortage > 0,
        shortageCartons: shortage,
        needsOctoberSupply: octoberFulfilled > 0,
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    // Remove by exact key OR by product prefix (تدعم المتغيّرات)
    if (_items.containsKey(productId)) {
      _items.remove(productId);
    } else {
      // Remove all variants of this product
      _items.removeWhere((key, _) => key.startsWith('${productId}_'));
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _extraDiscount = 0.0;
    _notes = null;
    _paymentType = 'نقدي';
    _selectedVariant = null;
    notifyListeners();
  }

  // إنشاء وإرسال الطلبية إلى Supabase
  Future<bool> submitOrder({
    required AppUser currentUser,
  }) async {
    if (_selectedCustomer == null || _items.isEmpty) return false;

    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final invoice = OrderInvoice(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: invoiceNumber,
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerCode: _selectedCustomer!.code,
      repId: currentUser.id,
      repName: currentUser.name,
      branchName: currentUser.branchName,
      date: DateTime.now(),
      items: _items.values.toList(),
      subtotal: subtotal,
      discount: _extraDiscount,
      totalAmount: netTotal,
      status: 'جديد',
      paymentType: _paymentType,
      notes: _notes,
      customerPhone: _selectedCustomer!.phone,
      supervisorName: currentUser.supervisorName,
    );

    final success = await SupabaseService.instance.createInvoice(invoice);
    if (success) {
      clearCart();
    }
    return success;
  }

  // ===================== حفظ/تحميل المسودة (Draft Persistence) =====================

  Future<void> saveDraftToPrefs(String draftKey) async {
    final prefs = await SharedPreferences.getInstance();

    final itemsJson = _items.values.map((item) => item.toJson()).toList();

    final draft = {
      'customer_id': _selectedCustomer?.id,
      'customer_name': _selectedCustomer?.name,
      'customer_code': _selectedCustomer?.code,
      'items': itemsJson,
      'extra_discount': _extraDiscount,
      'payment_type': _paymentType,
      'notes': _notes,
      'saved_at': DateTime.now().toIso8601String(),
    };

    await prefs.setString('${draftKey}_customer_id', _selectedCustomer?.id ?? '');
    await prefs.setString(draftKey, jsonEncode(draft));
  }

  Future<void> loadDraftFromPrefs(String draftKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(draftKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final draft = jsonDecode(raw) as Map<String, dynamic>;

      final itemsData = draft['items'] as List<dynamic>? ?? [];
      _items.clear();
      for (final itemJson in itemsData) {
        final item = OrderItem.fromJson(itemJson as Map<String, dynamic>);
        final productId = item.productId;
        _items[productId] = item;
      }

      _extraDiscount = (draft['extra_discount'] as num?)?.toDouble() ?? 0;
      _paymentType = draft['payment_type']?.toString() ?? 'نقدي';
      _notes = draft['notes']?.toString();

      notifyListeners();
    } catch (e) {
      debugPrint('[CartService] Failed to load draft: $e');
    }
  }

  void clearDraft(String draftKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(draftKey);
    await prefs.remove('${draftKey}_customer_id');
  }
}
