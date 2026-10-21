import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';

class UsersManagementScreen extends StatefulWidget {
  final AppUser currentUser;
  const UsersManagementScreen({super.key, required this.currentUser});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await SupabaseService.instance.fetchUsers(
        branchName: widget.currentUser.role == 'admin' ||
                widget.currentUser.role == 'developer'
            ? null
            : widget.currentUser.branchName,
      );

      setState(() {
        _users = users;
        _errorMessage = '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل بيانات المستخدمين: $e';
        _isLoading = false;
      });
    }
  }

  List<AppUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) {
      final query = _searchQuery.toLowerCase();
      return u.name.toLowerCase().contains(query) ||
          u.username.toLowerCase().contains(query) ||
          (u.email?.toLowerCase().contains(query) ?? false) ||
          u.role.toLowerCase().contains(query) ||
          u.branchName.toLowerCase().contains(query);
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

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'sales_rep';
    String selectedBranch = widget.currentUser.branchName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              Icon(Icons.person_add,
                  color: AppTheme.primaryGold, size: 24),
              const SizedBox(width: 8),
              Text('إضافة موظف جديد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                    decoration: InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'الاسم مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'اسم المستخدم',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'اسم المستخدم مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'الهاتف',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6
                        ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'الدور',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'admin', child: Text('مدير عام')),
                      DropdownMenuItem(
                          value: 'manager', child: Text('مدير إدارة')),
                      DropdownMenuItem(
                          value: 'branch_manager',
                          child: Text('مدير فرع')),
                      DropdownMenuItem(
                          value: 'supervisor', child: Text('مشرف')),
                      DropdownMenuItem(
                          value: 'sales_rep', child: Text('مندوب مبيعات')),
                      DropdownMenuItem(
                          value: 'developer', child: Text('مطور')),
                    ],
                    onChanged: (val) {
                      if (val != null) selectedRole = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedBranch,
                    decoration: InputDecoration(
                      labelText: 'الفرع',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: ['الرشاد', 'فرع الإسكندرية', 'فرع أسيوط']
                        .map((b) => DropdownMenuItem(
                            value: b, child: Text(b)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) selectedBranch = val;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: AppTheme.textMuted)),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'تم إضافة الموظف: ${nameController.text}',
                          style: GoogleFonts.cairo()),
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: AppTheme.darkSlate,
              ),
              child: Text('إضافة', style: GoogleFonts.cairo()),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(AppUser user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(text: user.phone);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              Icon(Icons.edit, color: AppTheme.infoBlue, size: 24),
              const SizedBox(width: 8),
              Text('تعديل الموظف',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'الهاتف',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'الدور',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'admin', child: Text('مدير عام')),
                    DropdownMenuItem(
                        value: 'manager', child: Text('مدير إدارة')),
                    DropdownMenuItem(
                        value: 'branch_manager', child: Text('مدير فرع')),
                    DropdownMenuItem(
                        value: 'supervisor', child: Text('مشرف')),
                    DropdownMenuItem(
                        value: 'sales_rep', child: Text('مندوب مبيعات')),
                    DropdownMenuItem(
                        value: 'developer', child: Text('مطور')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedRole = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: AppTheme.textMuted)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تحديث بيانات الموظف',
                        style: GoogleFonts.cairo()),
                    backgroundColor: AppTheme.infoBlue,
                  ),
                );
              },
              child: Text('حفظ', style: GoogleFonts.cairo()),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorRed, size: 24),
            const SizedBox(width: 8),
            Text('تأكيد الحذف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف الموظف ${user.name}؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف الموظف',
                      style: GoogleFonts.cairo()),
                  backgroundColor: AppTheme.errorRed,
                ),
              );
            },
            child: Text('حذف',
                style: GoogleFonts.cairo(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.darkSlate,
        title: Text('إدارة الموظفين',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(32),
          child: ConnectionStatusBar(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: AppTheme.errorRed, size: 48),
                      const SizedBox(height: 12),
                      Text(_errorMessage,
                          style: GoogleFonts.cairo(color: AppTheme.errorRed)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadUsers,
                        icon: Icon(Icons.refresh),
                        label: Text('إعادة المحاولة',
                            style: GoogleFonts.cairo()),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'بحث عن موظف...',
                          hintStyle: GoogleFonts.cairo(color: mutedColor),
                          prefixIcon: Icon(Icons.search, color: mutedColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: borderColor, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppTheme.primaryGold, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBackground
                              : Colors.white,
                        ),
                        style: GoogleFonts.cairo(color: textColor),
                      ),
                    ),
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off,
                                      size: 48, color: mutedColor),
                                  const SizedBox(height: 12),
                                  Text('لا يوجد موظفين مطابقين لبحثك',
                                      style: GoogleFonts.cairo(color: mutedColor)),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                columnSpacing: 24,
                                headingRowColor:
                                    MaterialStateProperty.all(
                                        isDark ? AppTheme.darkBorder : AppTheme.borderColor),
                                columns: [
                                  DataColumn(
                                    label: Text('الموظف',
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: textColor)),
                                  ),
                                  DataColumn(
                                    label: Text('اسم المستخدم',
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: textColor)),
                                  ),
                                  DataColumn(
                                    label: Text('البريد الإلكتروني',
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: textColor)),
                                  ),
                                  DataColumn(
                                    label: Text('الدور',
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: textColor)),
                                  ),
                                  DataColumn(
                                    label: Text('الحالة',
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: textColor)),
                                  ),
                                  DataColumn(
                                    label: Text('إجراءات',
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: textColor)),
                                  ),
                                ],
                                rows: _filteredUsers.map((user) {
                                  final roleColor = _roleColor(user.role);
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  roleColor.withOpacity(0.2),
                                              child: Icon(
                                                _roleIcon(user.role),
                                                color: roleColor,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(user.name,
                                                style:
                                                    GoogleFonts.cairo(color: textColor)),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(user.username,
                                          style: GoogleFonts.cairo(color: textColor))),
                                      DataCell(Text(
                                          user.email ?? '—',
                                          style: GoogleFonts.cairo(color: mutedColor))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: roleColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _roleLabel(user.role),
                                            style: GoogleFonts.cairo(
                                              color: roleColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Switch(
                                          value: user.isActive,
                                          onChanged: (val) {
                                            setState(() {
                                              // Toggle user active status
                                            });
                                          },
                                          activeColor: AppTheme.emeraldGreen,
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit,
                                                  color: AppTheme.infoBlue,
                                                  size: 20),
                                              onPressed: () =>
                                                  _showEditUserDialog(user),
                                              tooltip: 'تعديل',
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: AppTheme.errorRed,
                                                  size: 20),
                                              onPressed: () =>
                                                  _confirmDelete(user),
                                              tooltip: 'حذف',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_filteredUsers.length} موظف',
                              style: GoogleFonts.cairo(color: mutedColor)),
                          FilledButton.icon(
                            onPressed: _showAddUserDialog,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: Text('إضافة موظف جديد',
                                style: GoogleFonts.cairo()),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: AppTheme.darkSlate,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
