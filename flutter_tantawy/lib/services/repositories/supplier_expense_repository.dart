import '../../models/models.dart';
import 'base_repository.dart';

/// Repository للموردين والمصروفات المالية.
class SupplierExpenseRepository extends BaseRepository {
  const SupplierExpenseRepository();

  // ===================== الموردين (Suppliers) =====================
  Future<List<Supplier>> fetchSuppliers({bool activeOnly = true}) async {
    try {
      var query = client.from('suppliers').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final data = await query.order('name');
      return (data as List<dynamic>)
          .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
          .where((s) => s.deletedAt == null)
          .toList();
    } catch (e) {
      logError('fetchSuppliers', e);
      return [];
    }
  }

  Future<Supplier?> fetchSupplierById(String id) async {
    try {
      final data = await client
          .from('suppliers')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return Supplier.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      logError('fetchSupplierById', e);
      return null;
    }
  }

  Future<bool> createSupplier(Supplier supplier) async {
    try {
      await client.from('suppliers').insert(supplier.toJson());
      return true;
    } catch (e) {
      logError('createSupplier', e);
      return false;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      await client
          .from('suppliers')
          .update(supplier.toJson())
          .eq('id', supplier.id);
      return true;
    } catch (e) {
      logError('updateSupplier', e);
      return false;
    }
  }

  Future<bool> softDeleteSupplier(String id) async {
    try {
      await client
          .from('suppliers')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return true;
    } catch (e) {
      logError('softDeleteSupplier', e);
      return false;
    }
  }

  // ===================== المصروفات (Expenses) =====================
  Future<List<Expense>> fetchExpenses({
    String? branchName,
    String? repName,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDateExclusive,
  }) async {
    try {
      var query = client.from('expenses').select();

      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().substring(0, 10));
      }
      if (endDateExclusive != null) {
        query = query.lt('date', endDateExclusive.toIso8601String().substring(0, 10));
      }

      final data = await query.order('date', ascending: false);
      return (data as List<dynamic>)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .where((e) => e.deletedAt == null)
          .toList();
    } catch (e) {
      logError('fetchExpenses', e);
      return [];
    }
  }

  Future<bool> logExpense(Expense expense) async {
    try {
      await client.from('expenses').insert(expense.toJson());
      return true;
    } catch (e) {
      logError('logExpense', e);
      return false;
    }
  }

  Future<bool> softDeleteExpense(String id) async {
    try {
      await client
          .from('expenses')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return true;
    } catch (e) {
      logError('softDeleteExpense', e);
      return false;
    }
  }

  /// مجموع المصروفات حسب الفترة
  Future<double> sumExpenses({
    String? branchName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = client.from('expenses').select('amount');

      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().substring(0, 10));
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().substring(0, 10));
      }

      final data = await query;
      final rows = data as List<dynamic>;
      double sum = 0;
      for (final row in rows) {
        final val = (row as Map<String, dynamic>)['amount'];
        sum += (val is num) ? val.toDouble() : (double.tryParse(val?.toString() ?? '0') ?? 0);
      }
      return sum;
    } catch (e) {
      logError('sumExpenses', e);
      return 0;
    }
  }
}
