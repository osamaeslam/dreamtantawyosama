import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'rep_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'sales_rep';

  void _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    // إنشاء مستخدم افتراضي للتجربة الفورية
    final user = AppUser(
      id: 'usr_001',
      name: _usernameController.text.isNotEmpty ? _usernameController.text : 'مندوب الطنطاوي الميداني',
      username: _usernameController.text.isNotEmpty ? _usernameController.text : 'rep_user',
      role: _selectedRole,
      branchName: 'فرع القاهرة الكبرى',
      phone: '01012345678',
      supervisorName: 'أ/ محمد المشرف',
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RepDashboardScreen(currentUser: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkSlate,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الشعار والرمز
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.storefront_rounded, size: 48, color: AppTheme.darkSlate),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'مجموعة الطنطاوي للتجارة والتوزيع',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.secondaryGold,
                  ),
                ),
                Text(
                  'منظومة المبيعات وإدارة المخازن الموحدة',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.slate.shade400,
                  ),
                ),
                const SizedBox(height: 32),

                // بطاقة تسجيل الدخول
                Card(
                  color: AppTheme.cardSlate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.borderSlate),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'تسجيل الدخول للمنظومة',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // اختيار الدور
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          dropdownColor: AppTheme.cardSlate,
                          style: GoogleFonts.cairo(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'نوع الحساب / الصلاحية',
                            labelStyle: GoogleFonts.cairo(color: Colors.slate.shade400),
                            prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primaryGold),
                            filled: true,
                            fillColor: AppTheme.darkSlate,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'sales_rep', child: Text('مندوب مبيعات خارجي')),
                            DropdownMenuItem(value: 'supervisor', child: Text('مشرف مبيعات القطاع')),
                            DropdownMenuItem(value: 'branch_manager', child: Text('مدير الفرع')),
                            DropdownMenuItem(value: 'admin', child: Text('الإدارة العامة / الأدمن')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRole = val);
                          },
                        ),
                        const SizedBox(height: 14),

                        // اسم المستخدم
                        TextField(
                          controller: _usernameController,
                          style: GoogleFonts.cairo(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'اسم المستخدم أو كود الموظف',
                            labelStyle: GoogleFonts.cairo(color: Colors.slate.shade400),
                            prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryGold),
                            filled: true,
                            fillColor: AppTheme.darkSlate,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // كلمة المرور
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: GoogleFonts.cairo(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            labelStyle: GoogleFonts.cairo(color: Colors.slate.shade400),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGold),
                            filled: true,
                            fillColor: AppTheme.darkSlate,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // زر الدخول
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login_rounded),
                                    const SizedBox(width: 8),
                                    Text('دخول للمنظومة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'نسخة Multiplatform تعمل على الويب، أندرويد و iOS بتزامن لحظي',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.slate.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
extension on Colors {
  static get slate => _SlatePalette();
}
class _SlatePalette {
  final shade400 = const Color(0xFF94A3B8);
  final shade500 = const Color(0xFF64748B);
}
