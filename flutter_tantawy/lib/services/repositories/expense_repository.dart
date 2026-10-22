import '../../models/models.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository {
  const ExpenseRepository();

  Future<List<Expense>> fetchExpenses({
    String? branchName,
    String? repName,
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
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDateExclusive != null) {
        query = query.lt('date', endDateExclusive.toIso8601String());
      }
      final data = await query.order('date', ascending: false);
      return (data as List<dynamic>)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchExpenses', e);
      return [];
    }
  }

  Future<Expense?> fetchExpenseById(String id) async {
    try {
      final data = await client.from('expenses').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      return Expense.fromJson(data);
    } catch (e) {
      logError('fetchExpenseById', e);
      return null;
    }
  }

  Future<bool> createExpense(Expense expense) async {
    try {
      await client.from('expenses').insert(expense.toJson());
      return true;
    } catch (e) {
      logError('createExpense', e);
      return false;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    try {
      await client.from('expenses').update(expense.toJson()).eq('id', expense.id);
      return true;
    } catch (e) {
      logError('updateExpense', e);
      return false;
    }
  }

  Future<bool> softDeleteExpense(String id) async {
    try {
      await client.from('expenses').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
      return true;
    } catch (e) {
      logError('softDeleteExpense', e);
      return false;
    }
  }

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
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }
      final data = await query;
      double total = 0;
      for (final row in data as List<dynamic>) {
        total += (row['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      logError('sumExpenses', e);
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getExpenseSummaryByCategory({
    String? branchName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = client.from('expenses').select('category, amount');
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }
      final data = await query;
      final Map<String, double> summary = {};
      for (final row in data as List<dynamic>) {
        final category = row['category'] as String? ?? 'أخرى';
        final amount = (row['amount'] as num?)?.toDouble() ?? 0;
        summary[category] = (summary[category] ?? 0) + amount;
      }
      return summary.entries.map((e) => {'category': e.key, 'amount': e.value}).toList();
    } catch (e) {
      logError('getExpenseSummaryByCategory', e);
      return [];
    }
  }

  Future<List<String>> fetchExpenseCategories() async {
    try {
      final data = await client.from('expenses').select('category').order('category');
      return data
          .map((row) => row['category'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
    } catch (e) {
      logError('fetchExpenseCategories', e);
      return [];
    }
  }
}
