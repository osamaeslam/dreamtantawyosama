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
  List<AppUser> _allActiveEmployees = [];
  List<Branch> _branches = [];
  List<RepPerformance> _targetData = [];
  Map<String, RepPerformance> _performanceMap = {};
  bool _isLoading = true;
  bool _isFiltersLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedBranch = 'الكل';
  String _selectedRep = 'الكل';

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final branchName = rbac.isAdmin ? null : widget.currentUser.branchName;
      final employees = await SupabaseService.instance.fetchUsers(branchName: branchName);
      final branches = rbac.isAdmin ? await SupabaseService.instance.fetchBranches() : [];
      final targetData = rbac.isAdmin
          ? await SupabaseService.instance.fetchRepPerformance()
          : await SupabaseService.instance.fetchRepPerformance(branchName: widget.currentUser.branchName);

      setState(() {
        _employees = employees.where((e) => e.isActive).toList();
        _allActiveEmployees = List.from(_employees);
        _branches = branches;
        _targetData = targetData;
        _performanceMap = {for (final p in targetData) p.repName: p};
        _errorMessage = '';
        _isLoading = false;
        _isFiltersLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل بيانات الموظفين: $e';
        _isLoading = false;
        _isFiltersLoading = false;
      });
    }
  }

  List<AppUser> get _filteredEmployees {
    if (_searchQuery.isEmpty && _selectedBranch == 'الكل' && _selectedRep == 'الكل') {
      return _employees;
    }
    return _employees.where((e) {
      final query = _normalizeSearchText(_searchQuery);
      final matchesSearch = query.isEmpty ||
          _normalizeSearchText(e.name).contains(query) ||
          _normalizeSearchText(e.username).contains(query) ||
          _normalizeSearchText(e.phone).contains(query) ||
          _normalizeSearchText(e.branchName).contains(query) ||
          _normalizeSearchText(e.role).contains(query);
      final matchesBranch = _selectedBranch == 'الكل' || e.branchName == _selectedBranch;
      final matchesRep = _selectedRep == 'الكل' || e.supervisorName == _selectedRep;
      return matchesSearch && matchesBranch && matchesRep;
    }).toList();
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

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'مدير عام';
      case 'manager': return 'مدير إدارة';
      case 'branch_manager': return 'مدير فرع';
      case 'supervisor': return 'مشرف';
      case 'sales_rep': return 'مندوب مبيعات';
      case 'developer': return 'مطور';
      default: return role;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin': return Icons.admin_panel_settings;
      case 'manager': return Icons.manage_accounts;
      case 'branch_manager': return Icons.store_mall_directory;
      case 'supervisor': return Icons.supervisor_account;
      case 'sales_rep': return Icons.person_outline;
      case 'developer': return Icons.code;
      default: return Icons.person;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return AppTheme.roseRed;
      case 'manager': return AppTheme.infoBlue;
      case 'branch_manager': return AppTheme.warningAmber;
      case 'supervisor': return AppTheme.emeraldGreen;
      case 'sales_rep': return AppTheme.primaryGold;
      case 'developer': return AppTheme.silver;
      default: return AppTheme.textMuted;
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
      case 'ممتاز': return AppTheme.emeraldGreen;
      case 'جيد': return AppTheme.infoBlue;
      case 'مقبول': return AppTheme.warningAmber;
      case 'ضعيف': return AppTheme.errorRed;
      default: return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.cardSlate : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('إدارة الموظفين', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              const ConnectionStatusBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'بحث بالاسم، الموظف، أو الفرع...',
                          hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 11),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 16),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (rbac.isAdmin)
                      SizedBox(
                        width: 130,
                        child: DropdownButtonFormField<String>(
                          value: _selectedBranch,
                          decoration: InputDecoration(
                            labelText: 'الفرع',
                            labelStyle: GoogleFonts.cairo(fontSize: 10, color: Colors.white70),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            border: const OutlineInputBorder(),
                          ),
                          items: ['الكل', ..._branches.map((b) => b.name)]
                              .map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.cairo(fontSize: 11))))
                              .toList(),
                          onChanged: (v) => setState(() { _selectedBranch = v ?? 'الكل'; _applyFilters(); }),
                          dropdownColor: AppTheme.darkSlate,
                          style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: AppTheme.errorRed, size: 48),
                      const SizedBox(height: 12),
                      Text(_errorMessage, style: GoogleFonts.cairo(color: AppTheme.errorRed)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                      ),
                    ],
                  ),
                )
              : _buildBody(isDark, cardColor, textColor, mutedColor, borderColor, bgColor),
      floatingActionButton: rbac.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEmployeeDialog(),
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.darkSlate,
              icon: const Icon(Icons.person_add, size: 18),
              label: Text('إضافة موظف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  void _applyFilters() {
    setState(() {});
  }

  Widget _buildBody(bool isDark, Color cardColor, Color textColor, Color mutedColor, Color borderColor, Color bgColor) {
    final filtered = _filteredEmployees;

    return Column(
      children: [
        // KPI Summary Cards
        if (!rbac.isSalesRep) _buildKpiCards(isDark, cardColor, textColor, mutedColor, borderColor),

        // Hierarchy tree for managers
        if (rbac.isAdmin || rbac.isManagement) ...[
          _buildSupervisorHierarchy(isDark, cardColor, textColor, mutedColor, borderColor),
          const SizedBox(height: 8),
        ],

      // Target upload quick action (admin only)
      if (rbac.isAdmin) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddTargetDialog,
                  icon: const Icon(Icons.add_chart, size: 16, color: AppTheme.infoBlue),
                  label: Text('إضافة هدف للمنسق', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.infoBlue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.infoBlue),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${filtered.length} موظف', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)),
            ],
          ),
        ),
      ],

        // Employee list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 48, color: mutedColor),
                      const SizedBox(height: 12),
                      Text('لا يوجد موظفين مطابقين لبحثك', style: GoogleFonts.cairo(fontSize: 13, color: mutedColor)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final emp = filtered[index];
                    return _buildEmployeeCard(emp, cardColor, textColor, mutedColor, borderColor, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKpiCards(bool isDark, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    final totalEmployees = _employees.length;
    final totalSalesReps = _employees.where((e) => e.role == 'sales_rep').length;
    final totalSupervisors = _employees.where((e) => e.role == 'supervisor').length;
    final totalBranches = _branches.length;
    final avgAchievement = _targetData.isNotEmpty
        ? _targetData.map((t) => t.salesPercentage).reduce((a, b) => a + b) / _targetData.length
        : 0.0;

    return Container(
      color: cardColor,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildKpiCard('إجمالي الموظفين', totalEmployees.toString(), AppTheme.infoBlue, textColor, mutedColor, borderColor, cardColor),
          _buildKpiCard('مندوبين', totalSalesReps.toString(), AppTheme.primaryGold, textColor, mutedColor, borderColor, cardColor),
          _buildKpiCard('مشرفين', totalSupervisors.toString(), AppTheme.emeraldGreen, textColor, mutedColor, borderColor, cardColor),
          _buildKpiCard('فروع', totalBranches.toString(), AppTheme.warningAmber, textColor, mutedColor, borderColor, cardColor),
          _buildKpiCard('متوسط التحقيق', '${avgAchievement.toStringAsFixed(1)}%', AppTheme.silver, textColor, mutedColor, borderColor, cardColor),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color, Color textColor, Color mutedColor, Color borderColor, Color cardColor) {
    return SizedBox(
      width: 150,
      child: Card(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Icon(Icons.people, size: 16, color: color),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              Text(title, style: GoogleFonts.cairo(fontSize: 9, color: mutedColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisorHierarchy(bool isDark, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('هرمية المشرفين', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          _buildHierarchyTree(textColor, mutedColor, borderColor, cardColor),
        ],
      ),
    );
  }

  Widget _buildHierarchyTree(Color textColor, Color mutedColor, Color borderColor, Color cardColor) {
    final Map<String, List<AppUser>> _supervisorMap = {};
    for (final emp in _employees) {
      if (emp.supervisorName != null && emp.supervisorName!.isNotEmpty) {
        _supervisorMap.putIfAbsent(emp.supervisorName!, () => []);
        _supervisorMap[emp.supervisorName!]!.add(emp);
      }
    }

    final supervisors = _employees.where((e) => e.role == 'supervisor' || e.role == 'manager' || e.role == 'branch_manager').toList();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: supervisors.map((sup) {
        final subordinates = _supervisorMap[sup.name] ?? [];
        final hasSubordinates = subordinates.isNotEmpty;
        return Theme(
          data: ThemeData().copyWith(expandableTileTheme: ExpandableTileThemeData(
            headerPadding: const EdgeInsets.symmetric(horizontal: 8),
          )),
          child: ExpansionTile(
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: _roleColor(sup.role).withOpacity(0.15),
              child: Icon(_roleIcon(sup.role), size: 12, color: _roleColor(sup.role)),
            ),
            title: Text(sup.name, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
            subtitle: Text(_roleLabel(sup.role), style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
            childrenPadding: const EdgeInsets.only(left: 24, bottom: 8),
            children: hasSubordinates
                ? subordinates.map((rep) {
                    final perf = _performanceMap[rep.name];
                    final salesPct = perf?.salesPercentage ?? 0;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        radius: 10,
                        backgroundColor: AppTheme.primaryGold.withOpacity(0.15),
                        child: const Icon(Icons.person, size: 10, color: AppTheme.primaryGold),
                      ),
                      title: Text(rep.name, style: GoogleFonts.cairo(fontSize: 11, color: textColor)),
                      subtitle: Text('${rep.branchName}', style: GoogleFonts.cairo(fontSize: 9, color: mutedColor)),
                      trailing: perf != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _pctColor(salesPct).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${salesPct.toStringAsFixed(0)}%',
                                  style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: _pctColor(salesPct))),
                            )
                          : const SizedBox.shrink(),
                    );
                  }).toList()
                : [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('لا يوجد مندوبين تحت إشرافه',
                          style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
                    ),
                  ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmployeeCard(AppUser emp, Color cardColor, Color textColor, Color mutedColor, Color borderColor, bool isDark) {
    final roleColor = _roleColor(emp.role);

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor, width: 0.3),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: roleColor.withOpacity(0.15),
          backgroundImage: emp.avatar != null ? NetworkImage(emp.avatar!) : null,
          child: emp.avatar == null
              ? Icon(Icons.person, color: roleColor, size: 20)
              : null,
        ),
        title: Row(
          children: [
            Text(emp.name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
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
                  Icon(_roleIcon(emp.role), size: 10, color: roleColor),
                  const SizedBox(width: 2),
                  Text(_roleLabel(emp.role),
                      style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor)),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${emp.username} • ${emp.branchName}',
                style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(emp.isActive ? Icons.check_circle : Icons.cancel, size: 10,
                    color: emp.isActive ? AppTheme.emeraldGreen : AppTheme.errorRed),
                const SizedBox(width: 4),
                Text(emp.isActive ? 'نشط' : 'غير نشط',
                    style: GoogleFonts.cairo(fontSize: 9,
                        color: emp.isActive ? AppTheme.emeraldGreen : AppTheme.errorRed)),
                if (emp.supervisorName != null)
                  Text(' • مشرف: ${emp.supervisorName!}',
                      style: GoogleFonts.cairo(fontSize: 9, color: mutedColor)),
                const SizedBox(width: 4),
                if (emp.role == 'sales_rep') ...[
                  Builder(
                    builder: (context) {
                      final level = _performanceLevel(emp);
                      if (level.isEmpty) return const SizedBox.shrink();
                      final color = _performanceColor(level);
                      return Text(' • $level', style: GoogleFonts.cairo(fontSize: 9, color: color, fontWeight: FontWeight.bold));
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
            PopupMenuItem(value: 'edit', child: Text('تعديل', style: GoogleFonts.cairo())),
            if (rbac.isAdmin)
              PopupMenuItem(value: 'change_branch', child: Text('تغيير الفرع', style: GoogleFonts.cairo())),
            if (rbac.isAdmin && emp.role == 'sales_rep')
              PopupMenuItem(value: 'change_supervisor', child: Text('تعيين مشرف', style: GoogleFonts.cairo())),
            if (emp.isActive)
              PopupMenuItem(value: 'deactivate', child: Text('إيقاف التفعيل', style: GoogleFonts.cairo())),
            if (!emp.isActive)
              PopupMenuItem(value: 'activate', child: Text('تفعيل', style: GoogleFonts.cairo())),
            PopupMenuItem(value: 'reset_password', child: Text('إعادة تعيين كلمة المرور', style: GoogleFonts.cairo())),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, AppUser emp) async {
    switch (action) {
      case 'edit':
        _showEditEmployeeDialog(emp);
        break;
      case 'change_branch':
        _showChangeBranchDialog(emp);
        break;
      case 'change_supervisor':
        _showChangeSupervisorDialog(emp);
        break;
      case 'deactivate':
        await SupabaseService.instance.updateUserStatus(emp.id, false);
        _loadData();
        break;
      case 'activate':
        await SupabaseService.instance.updateUserStatus(emp.id, true);
        _loadData();
        break;
      case 'reset_password':
        _showResetPasswordDialog(emp);
        break;
    }
  }

  void _showAddEmployeeDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'sales_rep';
    String selectedBranch = widget.currentUser.branchName;
    String? selectedSupervisor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.person_add, color: AppTheme.primaryGold, size: 24),
            const SizedBox(width: 8),
            Text('إضافة موظف جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  validator: (v) => v == null || v.isEmpty ? 'الاسم مطلوب' : null,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  validator: (v) => v == null || v.isEmpty ? 'اسم المستخدم مطلوب' : null,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  validator: (v) => v == null || v.isEmpty ? 'الهاتف مطلوب' : null,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : null,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: 'الدور', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('مدير عام')),
                    DropdownMenuItem(value: 'manager', child: Text('مدير إدارة')),
                    DropdownMenuItem(value: 'branch_manager', child: Text('مدير فرع')),
                    DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
                    DropdownMenuItem(value: 'sales_rep', child: Text('مندوب مبيعات')),
                    DropdownMenuItem(value: 'developer', child: Text('مطور')),
                  ],
                  onChanged: (v) => setState(() => selectedRole = v ?? 'sales_rep'),
                  dropdownColor: Theme.of(context).cardColor,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBranch,
                  decoration: InputDecoration(labelText: 'الفرع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  items: _branches.map((b) => DropdownMenuItem(value: b.name, child: Text(b.name))).toList(),
                  onChanged: (v) => setState(() => selectedBranch = v ?? widget.currentUser.branchName),
                  dropdownColor: Theme.of(context).cardColor,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                if (selectedRole == 'sales_rep')
                  DropdownButtonFormField<String>(
                    value: selectedSupervisor,
                    decoration: InputDecoration(labelText: 'المشرف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('بدون مشرف')),
                      ..._employees.where((e) => e.role == 'supervisor' || e.role == 'manager').map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => selectedSupervisor = v),
                    dropdownColor: Theme.of(context).cardColor,
                    style: GoogleFonts.cairo(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('إلغاء', style: GoogleFonts.cairo())),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                final success = await SupabaseService.instance.createUser(
                  nameController.text.trim(),
                  usernameController.text.trim(),
                  passwordController.text,
                  selectedRole,
                  selectedBranch,
                  phoneController.text.trim(),
                  emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                  selectedSupervisor,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('تم إضافة الموظف', style: GoogleFonts.cairo()),
                    backgroundColor: AppTheme.emeraldGreen,
                  ));
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('فشل إضافة الموظف', style: GoogleFonts.cairo()),
                    backgroundColor: AppTheme.errorRed,
                  ));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.darkSlate),
            child: Text('إضافة', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(AppUser emp) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: emp.name);
    final emailController = TextEditingController(text: emp.email ?? '');
    final phoneController = TextEditingController(text: emp.phone);
    String selectedRole = emp.role;
    String selectedBranch = emp.branchName;
    String? selectedSupervisor = emp.supervisorName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppTheme.infoBlue, size: 24),
            const SizedBox(width: 8),
            Text('تعديل الموظف: ${emp.name}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'الاسم', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                if (rbac.isAdmin)
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(labelText: 'الدور', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('مدير عام')),
                      DropdownMenuItem(value: 'manager', child: Text('مدير إدارة')),
                      DropdownMenuItem(value: 'branch_manager', child: Text('مدير فرع')),
                      DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
                      DropdownMenuItem(value: 'sales_rep', child: Text('مندوب مبيعات')),
                      DropdownMenuItem(value: 'developer', child: Text('مطور')),
                    ],
                    onChanged: (v) => setState(() => selectedRole = v ?? emp.role),
                    dropdownColor: Theme.of(context).cardColor,
                    style: GoogleFonts.cairo(),
                  ),
                const SizedBox(height: 12),
                if (rbac.isAdmin)
                  DropdownButtonFormField<String>(
                    value: selectedBranch,
                    decoration: InputDecoration(labelText: 'الفرع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                    items: _branches.map((b) => DropdownMenuItem(value: b.name, child: Text(b.name))).toList(),
                    onChanged: (v) => setState(() => selectedBranch = v ?? emp.branchName),
                    dropdownColor: Theme.of(context).cardColor,
                    style: GoogleFonts.cairo(),
                  ),
                const SizedBox(height: 12),
                if (selectedRole == 'sales_rep' && rbac.isAdmin)
                  DropdownButtonFormField<String>(
                    value: selectedSupervisor,
                    decoration: InputDecoration(labelText: 'المشرف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('بدون مشرف')),
                      ..._employees.where((e) => (e.role == 'supervisor' || e.role == 'manager') && e.id != emp.id).map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => selectedSupervisor = v),
                    dropdownColor: Theme.of(context).cardColor,
                    style: GoogleFonts.cairo(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('إلغاء', style: GoogleFonts.cairo())),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (rbac.isAdmin) {
                if (selectedRole != emp.role) {
                  await SupabaseService.instance.updateUserRole(emp.id, selectedRole);
                }
                if (selectedBranch != emp.branchName) {
                  await SupabaseService.instance.updateUserBranch(emp.id, selectedBranch);
                }
              }
              await SupabaseService.instance.updateUserSupervisor(emp.id, selectedSupervisor);

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('تم تحديث بيانات الموظف', style: GoogleFonts.cairo()),
                backgroundColor: AppTheme.infoBlue,
              ));
              _loadData();
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.darkSlate),
            child: Text('حفظ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showChangeBranchDialog(AppUser emp) {
    String selectedBranch = emp.branchName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('تغيير فرع ${emp.name}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: DropdownButtonFormField<String>(
          value: selectedBranch,
          items: _branches.map((b) => DropdownMenuItem(value: b.name, child: Text(b.name))).toList(),
          onChanged: (v) => setState(() => selectedBranch = v ?? emp.branchName),
          dropdownColor: Theme.of(context).cardColor,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SupabaseService.instance.updateUserBranch(emp.id, selectedBranch);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.darkSlate),
            child: Text('حفظ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showChangeSupervisorDialog(AppUser emp) {
    String? selectedSupervisor = emp.supervisorName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('تعيين مشرف لـ ${emp.name}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: DropdownButtonFormField<String>(
          value: selectedSupervisor,
          items: [
            const DropdownMenuItem(value: null, child: Text('بدون مشرف')),
            ..._employees.where((e) => (e.role == 'supervisor' || e.role == 'manager') && e.id != emp.id).map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
          ],
          onChanged: (v) => setState(() => selectedSupervisor = v),
          dropdownColor: Theme.of(context).cardColor,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SupabaseService.instance.updateUserSupervisor(emp.id, selectedSupervisor);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.darkSlate),
            child: Text('حفظ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(AppUser emp) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إعادة تعيين كلمة المرور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          obscureText: true,
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                await SupabaseService.instance.updateUserPassword(emp.id, controller.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم تحديث كلمة المرور', style: GoogleFonts.cairo()),
                  backgroundColor: AppTheme.infoBlue,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.darkSlate),
            child: Text('حفظ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showAddTargetDialog() {
    final formKey = GlobalKey<FormState>();
    final salesTargetController = TextEditingController();
    final collectionTargetController = TextEditingController();
    String selectedRep = '';
    String selectedBranch = widget.currentUser.branchName;
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    final repNames = _allActiveEmployees.where((e) => e.role == 'sales_rep').map((e) => e.name).toSet().toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.add_chart, color: AppTheme.primaryGold, size: 24),
            const SizedBox(width: 8),
            Text('إضافة هدف جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRep.isEmpty ? null : selectedRep,
                  decoration: InputDecoration(labelText: 'المندوب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  items: repNames.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => selectedRep = v ?? ''),
                  dropdownColor: Theme.of(context).cardColor,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBranch,
                  decoration: InputDecoration(labelText: 'الفرع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  items: _branches.map((b) => DropdownMenuItem(value: b.name, child: Text(b.name))).toList(),
                  onChanged: (v) => setState(() => selectedBranch = v ?? widget.currentUser.branchName),
                  dropdownColor: Theme.of(context).cardColor,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: salesTargetController,
                  decoration: InputDecoration(labelText: 'هدف المبيعات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: collectionTargetController,
                  decoration: InputDecoration(labelText: 'هدف التحصيل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: InputDecoration(labelText: 'الشهر', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                        items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(m.toString(), style: GoogleFonts.cairo()))).toList(),
                        onChanged: (v) => setState(() => selectedMonth = v ?? DateTime.now().month),
                        dropdownColor: Theme.of(context).cardColor,
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: TextEditingController(text: selectedYear.toString()),
                        decoration: InputDecoration(labelText: 'السنة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => selectedYear = int.tryParse(v) ?? DateTime.now().year,
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('إلغاء', style: GoogleFonts.cairo())),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                final target = TargetRecord(
                  id: '',
                  branch: selectedBranch,
                  repName: selectedRep,
                  salesTarget: double.tryParse(salesTargetController.text) ?? 0,
                  salesAchieved: 0,
                  salesPercentage: 0,
                  collectionTarget: double.tryParse(collectionTargetController.text) ?? 0,
                  collectionAchieved: 0,
                  collectionPercentage: 0,
                  date: DateTime(selectedYear, selectedMonth, 1).toIso8601String().substring(0, 10),
                  month: selectedMonth,
                  year: selectedYear,
                  quarter: 'Q${((selectedMonth - 1) ~/ 3) + 1}',
                  remainingSales: double.tryParse(salesTargetController.text) ?? 0,
                  remainingCollection: double.tryParse(collectionTargetController.text) ?? 0,
                );
                final success = await SupabaseService.instance.insertTarget(target);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('تم إضافة الهدف', style: GoogleFonts.cairo()),
                    backgroundColor: AppTheme.emeraldGreen,
                  ));
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('فشل إضافة الهدف', style: GoogleFonts.cairo()),
                    backgroundColor: AppTheme.errorRed,
                  ));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: AppTheme.darkSlate),
            child: Text('حفظ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}
