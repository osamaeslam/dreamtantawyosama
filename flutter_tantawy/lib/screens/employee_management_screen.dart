import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/role_access_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';

class EmployeeManagementScreen extends StatefulWidget {
  final AppUser currentUser;
  const EmployeeManagementScreen({super.key, required this.currentUser});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  List<AppUser> _employees = [];
  Map<String, RepPerformance> _performanceMap = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rbac = RoleAccessController(widget.currentUser);
      final employees = await SupabaseService.instance.fetchUsers(
        branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
      );

      // Fetch performance data for sales reps
      final performances = await SupabaseService.instance.fetchRepPerformance();

      setState(() {
        _employees = employees;
        // Build performance map keyed by rep name
        _performanceMap = {};
        for (final perf in performances) {
          _performanceMap[perf.repName] = perf;
        }
        _errorMessage = '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل بيانات الموظفين: $e';
        _isLoading = false;
      });
    }
  }

  List<AppUser> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    return _employees.where((e) {
      final query = _searchQuery.toLowerCase();
      return e.name.toLowerCase().contains(query) ||
          e.username.toLowerCase().contains(query) ||
          e.phone.toLowerCase().contains(query) ||
          e.branchName.toLowerCase().contains(query) ||
          e.role.toLowerCase().contains(query);
    }).toList();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'مدير عام';
      case 'manager':
        return 'مدير إدارة';
      case 'branch_manager':
        return 'مدير فرع';
      case 'supervisor':
        return 'مشرف';
      case 'sales_rep':
        return 'مندوب مبيعات';
      case 'developer':
        return 'مطور';
      default:
        return role;
    }
  }

  String _performanceLevel(AppUser emp) {
    if (emp.role != 'sales_rep') return '';
    final perf = _performanceMap[emp.name];
    if (perf == null) return '';
    final rate = perf.salesPercentage;
    if (rate >= 100) return 'ممتاز';
    if (rate >= 80) return 'جيد';
    if (rate >= 60) return 'مقبول';
    return 'ضعيف';
  }

  Color _performanceColor(String level) {
    switch (level) {
      case 'ممتاز':
        return AppTheme.emeraldGreen;
      case 'جيد':
        return AppTheme.infoBlue;
      case 'مقبول':
        return AppTheme.warningAmber;
      case 'ضعيف':
        return AppTheme.errorRed;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'branch_manager':
        return Icons.store_mall_directory;
      case 'supervisor':
        return Icons.supervisor_account;
      case 'sales_rep':
        return Icons.person_outline;
      case 'developer':
        return Icons.code;
      default:
        return Icons.person;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.roseRed;
      case 'manager':
        return AppTheme.infoBlue;
      case 'branch_manager':
        return AppTheme.warningAmber;
      case 'supervisor':
        return AppTheme.emeraldGreen;
      case 'sales_rep':
        return AppTheme.primaryGold;
      case 'developer':
        return AppTheme.silver;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.darkSlate,
        title: Text('إدارة الموظفين',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
              backgroundImage: widget.currentUser.avatar != null
                  ? NetworkImage(widget.currentUser.avatar!)
                  : null,
              child: widget.currentUser.avatar == null
                  ? Icon(Icons.person, color: AppTheme.primaryGold, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث عن موظف...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: GoogleFonts.cairo(fontSize: 13),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(_errorMessage,
                            style: GoogleFonts.cairo(color: AppTheme.errorRed)),
                      )
                    : _filteredEmployees.isEmpty
                        ? _buildEmptyState(mutedColor)
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredEmployees.length,
                            separatorBuilder: (context, i) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final emp = _filteredEmployees[index];
                              return _buildEmployeeCard(emp, cardColor, textColor, mutedColor, isDark);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.manage_accounts_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text('لا يوجد موظفين مطابقين',
              style: GoogleFonts.cairo(fontSize: 13, color: mutedColor)),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(
    AppUser emp,
    Color cardColor,
    Color textColor,
    Color mutedColor,
    bool isDark,
  ) {
    final roleColor = _roleColor(emp.role);
    final isActive = emp.isActive;

    return Card(
      color: cardColor,
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: roleColor.withOpacity(0.15),
          backgroundImage: emp.avatar != null ? NetworkImage(emp.avatar!) : null,
          child: emp.avatar == null
              ? Icon(Icons.person, color: roleColor, size: 20)
              : null,
        ),
        title: Row(
          children: [
            Text(emp.name,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
            const SizedBox(width: 6),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
               decoration: BoxDecoration(
                 color: roleColor.withOpacity(0.15),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Icon(_roleIcon(emp.role), size: 12, color: roleColor),
                   const SizedBox(width: 2),
                   Text(
                     _roleLabel(emp.role),
                     style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor),
                   ),
                 ],
               ),
             ),
          ],
        )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${emp.username} • ${emp.branchName}',
                style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  size: 12,
                  color: isActive ? AppTheme.emeraldGreen : AppTheme.errorRed,
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'نشط' : 'غير نشط',
                  style: GoogleFonts.cairo(fontSize: 10, color: isActive ? AppTheme.emeraldGreen : AppTheme.errorRed),
                ),
                if (emp.phone.isNotEmpty)
                  Text(' • ${emp.phone}',
                      style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
                if (emp.role == 'sales_rep') ...[
                  const SizedBox(width: 4),
                  Builder(
                    builder: (context) {
                      final level = _performanceLevel(emp);
                      if (level.isEmpty) return const SizedBox.shrink();
                      final color = _performanceColor(level);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(level,
                            style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (value) => _handleAction(value, emp),
          itemBuilder: (context) => [
            if (emp.isActive)
              PopupMenuItem(
                value: 'deactivate',
                child: Text('إيقاف التفعيل', style: GoogleFonts.cairo()),
              ),
            if (!emp.isActive)
              PopupMenuItem(
                value: 'activate',
                child: Text('تفعيل الحساب', style: GoogleFonts.cairo()),
              ),
            PopupMenuItem(
              value: 'reset_password',
              child: Text('إعادة تعيين كلمة المرور', style: GoogleFonts.cairo()),
            ),
            if (RoleAccessController(widget.currentUser).isAdmin)
              PopupMenuItem(
                value: 'edit_role',
                child: Text('تغيير الدور', style: GoogleFonts.cairo()),
              ),
          ],
        ),
               onTap: () {
          final level = _performanceLevel(emp);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardColor,
              title: Text(emp.name,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('اسم المستخدم', emp.username, mutedColor),
                  _buildDetailRowWithIcon('الدور', _roleLabel(emp.role), _roleIcon(emp.role), roleColor, mutedColor),
                  _buildDetailRow('الفرع', emp.branchName, mutedColor),
                  _buildDetailRow('الهاتف', emp.phone, mutedColor),
                  _buildDetailRow('الحالة', isActive ? 'نشط' : 'غير نشط', mutedColor),
                  if (emp.supervisorName != null)
                    _buildDetailRow('المشرف', emp.supervisorName!, mutedColor),
                  if (level.isNotEmpty)
                    _buildDetailRow('مستوى الأداء', level, mutedColor),
                  if (emp.role == 'sales_rep') ...[
                    Builder(
                      builder: (context) {
                        final perf = _performanceMap[emp.name];
                        if (perf == null) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('إجمالي المبيعات', perf.sales2026.toStringAsFixed(2), mutedColor),
                            _buildDetailRow('إجمالي التحصيل', perf.collections2026.toStringAsFixed(2), mutedColor),
                            _buildDetailRow('عدد الطلبات', perf.ordersCount.toString(), mutedColor),
                            _buildDetailRow('عدد الزيارات', perf.visitsCount.toString(), mutedColor),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إغلاق', style: GoogleFonts.cairo(color: mutedColor)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleAction(String action, AppUser emp) async {
    switch (action) {
      case 'deactivate':
        await _updateUserStatus(emp, false);
        break;
      case 'activate':
        await _updateUserStatus(emp, true);
        break;
      case 'reset_password':
        _showResetPasswordDialog(emp);
        break;
      case 'edit_role':
        _showEditRoleDialog(emp);
        break;
    }
  }

  Future<void> _updateUserStatus(AppUser emp, bool isActive) async {
    try {
      await SupabaseService.instance.updateUserStatus(emp.id, isActive);
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e', style: GoogleFonts.cairo())),
      );
    }
  }

  void _showResetPasswordDialog(AppUser emp) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إعادة تعيين كلمة المرور',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              style: GoogleFonts.cairo(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await SupabaseService.instance.updateUserPassword(
                    emp.id, controller.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تحديث كلمة المرور',
                        style: GoogleFonts.cairo())),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e', style: GoogleFonts.cairo())),
                  );
                }
              }
            },
            child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(AppUser emp) {
    String selectedRole = emp.role;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تغيير دور ${emp.name}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: DropdownButtonFormField<String>(
          value: selectedRole,
          items: const [
            DropdownMenuItem(value: 'admin', child: Text('مدير عام')),
            DropdownMenuItem(value: 'manager', child: Text('مدير إدارة')),
            DropdownMenuItem(value: 'branch_manager', child: Text('مدير فرع')),
            DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
            DropdownMenuItem(value: 'sales_rep', child: Text('مندوب مبيعات')),
            DropdownMenuItem(value: 'developer', child: Text('مطور')),
          ],
          onChanged: (v) => setState(() => selectedRole = v ?? emp.role),
          style: GoogleFonts.cairo(),
          dropdownColor: Theme.of(context).cardColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () async {
              if (selectedRole != emp.role) {
                try {
                  await SupabaseService.instance.updateUserRole(emp.id, selectedRole);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تحديث الدور',
                        style: GoogleFonts.cairo())),
                  );
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e', style: GoogleFonts.cairo())),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithIcon(String label, String value, IconData icon, Color iconColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text('$label: ',
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: mutedColor)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.cairo(fontSize: 12, color: mutedColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: mutedColor)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.cairo(fontSize: 12, color: mutedColor)),
          ),
        ],
      ),
    );
  }
}
