import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import '../services/role_access_controller.dart';
import '../theme/app_theme.dart';

class TasksRolesScreen extends StatefulWidget {
  final AppUser currentUser;
  const TasksRolesScreen({super.key, required this.currentUser});

  @override
  State<TasksRolesScreen> createState() => _TasksRolesScreenState();
}

class _TasksRolesScreenState extends State<TasksRolesScreen> {
  String _selectedRole = '';

  final List<_RoleTaskPage> _allPages = [
    _RoleTaskPage(
      title: 'الرئيسية',
      subtitle: 'لوحة المراجعة السريعة',
      description: 'مراجعة سريعة للمؤشرات الرئيسية والإشعارات العاجلة',
      icon: Icons.dashboard_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'الكتالوج',
      subtitle: 'تصفح المنتجات والأسعار',
      description: 'استعراض الأسعار والأرصدة الفورية، بحث وتصفية حسب القسم',
      icon: Icons.inventory_2_outlined,
      color: AppTheme.primaryGold,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'الطلبية',
      subtitle: 'إنشاء طلبية جديدة',
      description: 'إنشاء وتعديل طلبات العملاء مع دعم المتغيرات (اللون/الحجم)',
      icon: Icons.shopping_bag_outlined,
      color: AppTheme.primaryGold,
      roles: ['sales_rep'],
    ),
    _RoleTaskPage(
      title: 'الفواتير',
      subtitle: 'عرض وطباعة الفواتير',
      description: 'جميع الفواتير، حالتها، والقدرة على الطباعة والتصدير',
      icon: Icons.receipt_long_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'الزيارات',
      subtitle: 'تسجيل الزيارات وخط السير',
      description: 'تسجيل زيارات عملاء مع توثيق الموقع الجغرافي والنتيجة',
      icon: Icons.location_on_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'المخزون',
      subtitle: 'حركة المخزون اليومية',
      description: 'متابعة مصادر المخزون من المخزن الرئيسي والأكتوبر',
      icon: Icons.warehouse_outlined,
      color: AppTheme.emeraldGreen,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'التوقعات',
      subtitle: 'توقعات التحصيل الأسبوعية',
      description: 'تقدير التحصيل والمبيعات حسب الأسبوع، يمكن للإدارة تعديل أسابيع الشهر',
      icon: Icons.energy_savings_leaf_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'طابور المزامنة',
      subtitle: 'العناصر المعلقة',
      description: 'متابعة العناصر المعلقة ومعالجتها غير المتصلة',
      icon: Icons.cloud_sync_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'developer'],
    ),
    _RoleTaskPage(
      title: 'العروض',
      subtitle: 'العروض الترويجية والخصومات',
      description: 'عرض العروض النشطة والمنتهية مع تفاصيل الخصم والفترة',
      icon: Icons.local_offer_outlined,
      color: AppTheme.roseRed,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'الإشعارات',
      subtitle: 'التنبيهات والإشعارات',
      description: 'مراجعة الإشعارات المرتبطة بأنشطة العملاء والزيارات',
      icon: Icons.notifications_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'لوحة الإدارة',
      subtitle: 'ملخص الأداء والمؤشرات',
      description: 'لوحة تحكم تحليلية مع رسوم بيانية للمبيعات والتحصيل، للإدارة والمديرين',
      icon: Icons.dashboard_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'developer'],
    ),
    _RoleTaskPage(
      title: 'تحليلات العملاء',
      subtitle: 'أداء العملاء والأرصدة',
      description: 'تحليل شامل لعملاء حسب الفئة ومستوى المستحقات',
      icon: Icons.analytics_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'developer'],
    ),
    _RoleTaskPage(
      title: 'أداء المندوب',
      subtitle: 'الهدف والمحقق الشخصي',
      description: 'تفاصيل الأداء الشخصي للمندوب مع المؤشرات والإنجاز',
      icon: Icons.assessment_outlined,
      color: AppTheme.emeraldGreen,
      roles: ['sales_rep'],
    ),
    _RoleTaskPage(
      title: 'أهداف وإنجاز',
      subtitle: 'الهدف والمحقق',
      description: 'متابعة أهداف المبيعات والتحصيل حسب الربع والربع السنوي',
      icon: Icons.track_changes_outlined,
      color: AppTheme.emeraldGreen,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'المرتجعات',
      subtitle: 'إذن مرتجع المبيعات',
      description: 'إدارة مرتجعات المنتجات مع توثيق السبب والحالة',
      icon: Icons.assignment_return_outlined,
      color: AppTheme.roseRed,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
    _RoleTaskPage(
      title: 'مزامنة Google Sheets',
      subtitle: 'رفع ومزامنة البيانات',
      description: 'استيراد المنتجات والعروض من Google Sheets',
      icon: Icons.cloud_upload_outlined,
      color: AppTheme.emeraldGreen,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'developer'],
    ),
    _RoleTaskPage(
      title: 'إدارة الموظفين',
      subtitle: 'إدارة حسابات وأدوار الموظفين',
      description: 'إدارة حسابات الموظفين، تفعيلهم، وتغيير الأدوار (للإدارة العامة فقط)',
      icon: Icons.manage_accounts_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'developer'],
    ),
    _RoleTaskPage(
      title: 'نبذة عن البرنامج',
      subtitle: 'معلومات عن التطبيق والشركة',
      description: 'عرض معلومات الشركة، حقوق الطبع، وإعدادات التطبيق',
      icon: Icons.info_outlined,
      color: AppTheme.infoBlue,
      roles: ['admin', 'manager', 'branch_manager', 'supervisor', 'sales_rep', 'developer'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentUser.role;
  }

  List<_RoleTaskPage> get _filteredPages {
    return _allPages.where((page) => page.roles.contains(_selectedRole)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.backgroundLight;

    final rbac = RoleAccessController(widget.currentUser);
    final roleLabel = _roleLabel(widget.currentUser.role);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.darkSlate,
        title: Text('المهام والأدوار',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppTheme.primaryGold, size: 16),
                    const SizedBox(width: 4),
                    Text(roleLabel,
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Role selector
          Container(
            color: cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: DropdownButton<String>(
              value: _selectedRole,
              items: _allPages
                  .expand((p) => p.roles)
                  .toSet()
                  .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(
                        _roleLabel(r),
                        style: GoogleFonts.cairo(fontSize: 13),
                      )))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v ?? _selectedRole),
              style: GoogleFonts.cairo(color: textColor, fontSize: 13),
              dropdownColor: cardColor,
              underline: Container(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.borderColor),
              icon: const Icon(Icons.filter_alt_outlined, size: 18),
            ),
          ),
          const Divider(height: 1),

          // Sales Management team reference
          _buildTeamReference(cardColor, textColor, mutedColor, isDark),

          // Order status flow reference
          _buildStatusFlowReference(cardColor, textColor, mutedColor, isDark),

          // Pages list
          Expanded(
            child: _filteredPages.isEmpty
                ? Center(
                    child: Text('لا توجد صفحات متاحة لهذا الدور',
                        style: GoogleFonts.cairo(fontSize: 13, color: mutedColor)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPages.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final page = _filteredPages[index];
                      return _buildPageCard(page, cardColor, textColor, mutedColor, isDark, rbac);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageCard(
    _RoleTaskPage page,
    Color cardColor,
    Color textColor,
    Color mutedColor,
    bool isDark,
    RoleAccessController rbac,
  ) {
    return Card(
      color: cardColor,
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: page.color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(page.icon, color: page.color, size: 22),
        ),
        title: Text(page.title,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
        subtitle: Text(page.description,
            style: GoogleFonts.cairo(fontSize: 11, color: mutedColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوصف:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: mutedColor)),
                const SizedBox(height: 4),
                Text(page.description,
                    style: GoogleFonts.cairo(fontSize: 12, color: mutedColor)),
                const SizedBox(height: 8),
                Text('الأدوار المسموحة:',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: mutedColor)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: page.roles.map((role) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: page.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: GoogleFonts.cairo(fontSize: 10, color: page.color),
                        ),
                      )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamReference(Color cardColor, Color textColor, Color mutedColor, bool isDark) {
    final teamMembers = [
      {'name': 'أ محمد محمود', 'role': 'manager', 'position': 'مدير إدارة مبيعات'},
      {'name': 'أ احمد محمود', 'role': 'sales_rep', 'position': 'مندوب مبيعات'},
      {'name': 'أ اسامه اسلام', 'role': 'sales_rep', 'position': 'مندوب مبيعات'},
    ];

    return ExpansionTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryGold.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.group, color: AppTheme.primaryGold, size: 22),
      ),
      title: Text('فريق إدارة المبيعات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: teamMembers.map((member) {
              final roleColor = _roleColor(member['role']!);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: roleColor.withOpacity(0.15),
                      child: Icon(_roleIcon(member['role']!), size: 14, color: roleColor),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member['name']!,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
                        Text(member['position']!,
                            style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_roleLabel(member['role']!),
                          style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFlowReference(Color cardColor, Color textColor, Color mutedColor, bool isDark) {
    final statuses = NotificationService.getOrderStatuses();

    return ExpansionTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.infoBlue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.run_circle_outlined, color: AppTheme.infoBlue, size: 22),
      ),
      title: Text('تدفق حالة الطلبية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الخطوات من إنشاء الطلبية حتى التسليم:',
                  style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: statuses.length,
                separatorBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Container(height: 1, color: mutedColor.withOpacity(0.3))),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_downward, size: 14, color: mutedColor),
                    ],
                  ),
                ),
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final color = NotificationService.getStatusColor(status, isDark);
                  return Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(child: Text(NotificationService.getStatusIcon(status), style: GoogleFonts.cairo(fontSize: 10))),
                      ),
                      const SizedBox(width: 10),
                      Text(status,
                          style: GoogleFonts.cairo(fontSize: 11, color: textColor, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text(getStepDescription(index),
                          style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String getStepDescription(int index) {
    switch (index) {
      case 0:
        return '(مندوب المبيعات ينشئها)';
      case 1:
        return '(المشرف/المدير يوافق)';
      case 2:
        return '(المستودع يحضر الطلبية)';
      case 3:
        return '(تم جمع جميع الأصناف)';
      case 4:
        return '(في انتظار توصيلها)';
      case 5:
        return '(سائق التوصيل يسلّمها)';
      case 6:
        return '(العميل يتلقى البضاعة)';
      default:
        return '';
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
}

class _RoleTaskPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> roles;

  const _RoleTaskPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.roles,
  });
}
