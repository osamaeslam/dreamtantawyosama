import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'supabase_service.dart';

class CartService extends ChangeNotifier {
  final Map<String, OrderItem> _items = {};
  Customer? _selectedCustomer;
  double _extraDiscount = 0.0;
  String _paymentType = 'آجل';
  String? _notes;

  Map<String, OrderItem> get items => _items;
  Customer? get selectedCustomer => _selectedCustomer;
  double get extraDiscount => _extraDiscount;
  String get paymentType => _paymentType;
  String? get notes => _notes;

  int get totalCartons => _items.values.fold(0, (sum, item) => sum + item.cartons);
  int get totalPieces => _items.values.fold(0, (sum, item) => sum + item.pieces);

  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get netTotal => (subtotal - _extraDiscount).clamp(0.0, double.infinity);

  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
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

  // إضافة صنف أو تعديل كميته بالسلة
  void addOrUpdateProduct({
    required Product product,
    required int cartons,
    int pieces = 0,
    double discount = 0,
  }) {
    if (cartons <= 0 && pieces <= 0) {
      _items.remove(product.id);
    } else {
      _items[product.id] = OrderItem(
        productId: product.id,
        productCode: product.code,
        productName: product.name,
        cartons: cartons,
        pieces: pieces,
        cartonPrice: product.promoPrice ?? product.cartonPrice,
        piecePrice: product.piecePrice,
        discount: discount,
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _extraDiscount = 0.0;
    _notes = null;
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
    );

    final success = await SupabaseService.instance.createInvoice(invoice);
    if (success) {
      clearCart();
    }
    return success;
  }
}
