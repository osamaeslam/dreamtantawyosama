import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient? _client;
  SupabaseClient get client {
    _client ??= Supabase.instance.client;
    return _client!;
  }

  // تهيئة الاتصال بقاعدة بيانات Supabase
  static Future<void> initialize({
    required String supabaseUrl,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: kDebugMode,
    );
  }

  // ===================== المنتجات (Products) =====================
  Future<List<Product>> fetchProducts({String? branchName, String? department}) async {
    try {
      var query = client.from('products').select();
      if (department != null && department != 'الكل') {
        query = query.eq('department', department);
      }
      final data = await query.order('name');
      return (data as List<dynamic>).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching products from Supabase: $e');
      return [];
    }
  }

  // تحديث رصيد الصنف لمنع الحجز المزدوج
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
      debugPrint('Error reserving stock: $e');
      return false;
    }
  }

  // ===================== العملاء (Customers) =====================
  Future<List<Customer>> fetchCustomers({String? repName, String? branchName}) async {
    try {
      var query = client.from('customers').select();
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      final data = await query.order('name');
      return (data as List<dynamic>).map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching customers from Supabase: $e');
      return [];
    }
  }

  // ===================== الطلبيات والفواتير (Orders & Invoices) =====================
  Future<List<OrderInvoice>> fetchInvoices({String? repName, String? status}) async {
    try {
      var query = client.from('invoices').select();
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      if (status != null && status != 'الكل') {
        query = query.eq('status', status);
      }
      final data = await query.order('date', ascending: false);
      return (data as List<dynamic>).map((e) => OrderInvoice.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
      return [];
    }
  }

  Future<bool> createInvoice(OrderInvoice invoice) async {
    try {
      await client.from('invoices').insert(invoice.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving invoice: $e');
      return false;
    }
  }

  // اعتماد الفاتورة من المشرف
  Future<bool> updateInvoiceStatus(String invoiceId, String newStatus) async {
    try {
      await client.from('invoices').update({'status': newStatus}).eq('id', invoiceId);
      return true;
    } catch (e) {
      debugPrint('Error updating invoice status: $e');
      return false;
    }
  }

  // ===================== الزيارات الميدانية (Visits) =====================
  Future<List<CustomerVisit>> fetchVisits({String? repName, DateTime? date}) async {
    try {
      var query = client.from('visits').select();
      if (repName != null) {
        query = query.eq('rep_name', repName);
      }
      final data = await query.order('date', ascending: false);
      return (data as List<dynamic>).map((e) => CustomerVisit.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching visits: $e');
      return [];
    }
  }

  Future<bool> logVisit(CustomerVisit visit) async {
    try {
      await client.from('visits').insert(visit.toJson());
      return true;
    } catch (e) {
      debugPrint('Error logging visit: $e');
      return false;
    }
  }

  // ===================== الاشتراك اللحظي (Realtime Stream) =====================
  RealtimeChannel subscribeToOrders(Function(Map<String, dynamic> payload) onEvent) {
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
}
