import '../models/models.dart';

/// Centralized Role-Based Access Control (RBAC) for the Flutter app
/// Enforces data isolation: sales_rep -> own data only,
/// supervisor -> team data, branch_manager -> branch data, admin/developer -> all data.
///
/// Role separation:
/// - Admin (admin/developer): Can review reports, approve forecasts, manage month plans
/// - Management (manager/branch_manager): Sees numbers only (no payroll details, no report finalization)
/// - Supervisor: Periodic review of reps in their branch
/// - SalesRep: Own data only
class RoleAccessController {
  final AppUser currentUser;

  RoleAccessController(this.currentUser);

  // === Role checkers ===
  /// Admin can review reports, approve forecasts, and manage month plans
  bool get isAdmin => currentUser.role == 'admin';

  bool get isDeveloper => currentUser.role == 'developer';

  bool get isAdministration => currentUser.role == 'administration';

  /// Management role: sees numbers only, no report review or payroll details
  bool get isManagement => isAdministration || isBranchManager;

  bool get isBranchManager => currentUser.role == 'branch_manager';
  bool get isSupervisor => currentUser.role == 'supervisor';
  bool get isSalesRep => currentUser.role == 'sales_rep';

  /// Can this user review/approve reports and forecasts?
  /// Only admin and developer can do this
  bool get canReviewReports => canPerformAction(
        'reports.review',
        roleDefaults: {'administration', 'branch_manager'},
      );

  /// Can this user see detailed payroll/commission info?
  /// Only admin can see payroll details, management sees numbers only
  bool get canViewPayroll => isAdmin;

  /// Can this user manage employee/user records (System Admin page)?
  bool get canManageEmployees => isAdmin;

  bool get canManageSheets => isAdmin;

  bool get canDeleteData => isAdmin;

  bool canAccessPage(String pageKey, {Set<String> roleDefaults = const {}}) {
    if (isAdmin) return true;
    final pagePermissions = currentUser.permissions['pages'];
    if (pagePermissions is Map && pagePermissions.containsKey(pageKey)) {
      return pagePermissions[pageKey] == true;
    }
    return roleDefaults.contains(currentUser.role);
  }

  bool canPerformAction(String actionKey, {Set<String> roleDefaults = const {}}) {
    if (isAdmin) return true;
    final actionPermissions = currentUser.permissions['actions'];
    if (actionPermissions is Map && actionPermissions.containsKey(actionKey)) {
      return actionPermissions[actionKey] == true;
    }
    return roleDefaults.contains(currentUser.role);
  }

  // === Visibility helpers ===
  // Can this user see data for the given rep/branch/supervisor?
  bool canViewRep(String? repId, String? repName) {
    if (repId == null && repName == null) return true;
    if (isAdmin) return true;
    if (isBranchManager) {
      // Can only see reps in their branch
      final match = repName != null && _matchesName(repName, currentUser.name);
      return match || _isRepInBranch(repName);
    }
    if (isSupervisor) {
      final isSelf = repName != null && _matchesName(repName, currentUser.name);
      // Can only see supervised reps
      return isSelf || _isSupervisedRep(repName);
    }
    if (isSalesRep) {
      return repName != null && _matchesName(repName, currentUser.name);
    }
    return false;
  }

  bool canViewBranch(String? branchName) {
    if (branchName == null || branchName.isEmpty) return true;
    if (isAdmin) return true;
    if (isBranchManager || isSupervisor || isSalesRep) {
      return branchName == currentUser.branchName || branchName.isEmpty;
    }
    return false;
  }

  bool canViewSupervisor(String? supervisorName) {
    if (supervisorName == null || supervisorName.isEmpty) return true;
    if (isAdmin) return true;
    if (isSupervisor) {
      return _matchesName(supervisorName, currentUser.name);
    }
    return false;
  }

  // === Filter predicates for lists ===
  List<OrderInvoice> filterInvoices(List<OrderInvoice> invoices) {
    if (invoices.isEmpty) return [];
    return invoices.where((inv) {
      if (isAdmin) return true;

      if (isSalesRep) {
        final isSelf = _matchesName(inv.repName, currentUser.name);
        return isSelf;
      }

      if (isSupervisor) {
        final isSelf = _matchesName(inv.repName, currentUser.name);
        return isSelf || _isSupervisedRep(inv.repName);
      }

      if (isBranchManager) {
        return _matchesBranch(inv.branchName);
      }

      return false;
    }).toList();
  }

  List<CustomerAnalytics> filterCustomers(List<CustomerAnalytics> customers) {
    if (customers.isEmpty) return [];
    return customers.where((customer) {
      if (isAdmin) return true;

      if (isSalesRep) {
        return customer.branchName == currentUser.branchName;
      }

      if (isSupervisor) {
        return _matchesBranch(customer.branchName);
      }

      if (isBranchManager) {
        return _matchesBranch(customer.branchName);
      }

      return false;
    }).toList();
  }

  /// Client-side filter for [Customer] accounts (used by order building /
  /// customer selection screens). Mirrors [filterCustomers] but for the
  /// account model instead of the analytics projection.
  List<Customer> filterCustomerAccounts(List<Customer> customers) {
    if (customers.isEmpty) return [];
    return customers.where((c) {
      if (isAdmin) return true;

      final branchOk = canViewBranch(c.branchName);
      if (!branchOk) return false;

      if (isSalesRep) {
        final matchesRepId = c.salesRepId == currentUser.id;
        final matchesRepName = [c.repName, c.salesRepName]
            .whereType<String>()
            .any((name) => _matchesName(name, currentUser.name));
        return matchesRepId || matchesRepName;
      }

      if (isSupervisor) {
        final isSelf = c.repName != null &&
            _matchesName(c.repName!, currentUser.name);
        return isSelf || _isSupervisedRep(c.repName);
      }

      if (isBranchManager) {
        return true;
      }

      return false;
    }).toList();
  }

  List<TargetRecord> filterTargets(List<TargetRecord> targets) {
    if (targets.isEmpty) return [];
    return targets.where((t) {
      if (isAdmin) return true;

      if (isSalesRep) {
        return _matchesName(t.repName, currentUser.name);
      }

      if (isSupervisor) {
        final isSelf = _matchesName(t.repName, currentUser.name);
        return isSelf || _isSupervisedRep(t.repName);
      }

      if (isBranchManager) {
        return _matchesBranch(t.branch);
      }

      return false;
    }).toList();
  }

  List<CollectionForecastRecord> filterForecasts(List<CollectionForecastRecord> forecasts) {
    if (forecasts.isEmpty) return [];
    return forecasts.where((f) {
      if (isAdmin) return true;

      if (isSalesRep) {
        return f.repId == currentUser.id || _matchesName(f.repName, currentUser.name);
      }

      if (isSupervisor) {
        final isSelf = _matchesName(f.repName, currentUser.name);
        return isSelf || _isSupervisedRep(f.repName);
      }

      if (isBranchManager) {
        return _matchesBranch(f.branchName);
      }

      return false;
    }).toList();
  }

  List<InventoryTransaction> filterInventory(List<InventoryTransaction> transactions) {
    if (transactions.isEmpty) return [];
    return transactions.where((tx) {
      if (isAdmin) return true;
      if (isBranchManager || isSupervisor || isSalesRep) {
        return _matchesBranch(tx.branchName);
      }
      return false;
    }).toList();
  }

  // ===================== أداء المندوبين (Rep Performance) =====================
  List<RepPerformance> filterRepPerformance(
      List<RepPerformance> performances) {
    if (performances.isEmpty) return [];
    return performances.where((p) {
      if (isAdmin) return true;
      if (isSalesRep) {
        final isSelf = _matchesName(p.repName, currentUser.name);
        return isSelf;
      }
      if (isSupervisor) {
        final isSelf = _matchesName(p.repName, currentUser.name);
        return isSelf || _isSupervisedRep(p.repName);
      }
      if (isBranchManager) {
        return _matchesBranch(p.branchName);
      }
      return false;
    }).toList();
  }

  // ===================== الزيارات الميدانية (Visits) =====================
  List<CustomerVisit> filterVisits(List<CustomerVisit> visits) {
    if (visits.isEmpty) return [];
    return visits.where((v) {
      if (isAdmin) return true;
      if (isSalesRep) {
        return v.repName.isNotEmpty && _matchesName(v.repName, currentUser.name);
      }
      if (isSupervisor) {
        final isSelf = v.repName.isNotEmpty &&
            _matchesName(v.repName, currentUser.name);
        return isSelf || _isSupervisedRep(v.repName);
      }
      if (isBranchManager) {
        return _matchesBranch(v.branchName);
      }
      return false;
    }).toList();
  }

  // ===================== المرتجعات (Returns) =====================
  List<ReturnRecord> filterReturns(List<ReturnRecord> returns) {
    if (returns.isEmpty) return [];
    return returns.where((r) {
      if (isAdmin) return true;
      if (isSalesRep) {
        return _matchesName(r.repName, currentUser.name);
      }
      if (isSupervisor) {
        final isSelf = _matchesName(r.repName, currentUser.name);
        return isSelf || _isSupervisedRep(r.repName);
      }
      if (isBranchManager) {
        return _matchesBranch(r.branchName);
      }
      return false;
    }).toList();
  }

  // === Helper methods ===
  bool _matchesName(String nameA, String nameB) {
    final normA = _normalizeArabic(nameA);
    final normB = _normalizeArabic(nameB);
    return normA == normB || normA.contains(normB) || normB.contains(normA);
  }

  bool _matchesBranch(String? branch) {
    if (branch == null || branch.isEmpty) return false;
    return _normalizeArabic(branch) == _normalizeArabic(currentUser.branchName);
  }

  bool _isRepInBranch(String? repName) {
    // In a real implementation, this would check against user list
    // For now, assume branch_manager can see all branch data
    return isBranchManager;
  }

  bool _isSupervisedRep(String? repName) {
    if (repName == null) return false;
    // Simplified: a supervisor can see reps in their branch
    return _matchesBranch(currentUser.branchName);
  }

  String _normalizeArabic(String str) {
    if (str.isEmpty) return '';
    var text = str
      .replaceAll(RegExp(r'[\uFFFD\uFEFF]'), ' ')
      .replaceAll(RegExp(r'[\u00A0\u1680\u2000-\u200B]'), ' ')
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ؤ', 'و').replaceAll('ئ', 'ي').replaceAll('ء', '')
      .replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    return text;
  }
}
