import React from 'react';
import { 
  Smartphone, 
  ShieldCheck, 
  UserCheck, 
  Building2, 
  Crown, 
  ShoppingBag, 
  Users, 
  Boxes, 
  ClipboardCheck, 
  Download,
  Database,
  LogIn,
  KeyRound,
  LogOut,
  Target,
  DollarSign,
  Wifi,
  WifiOff
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { UserRole } from '../types';
import { PWAInstallButton } from './PWAInstallButton';

export const RoleSwitcherBar: React.FC = () => {
  const { 
    currentUser, 
    switchRole, 
    activeTab, 
    setActiveTab, 
    setIsApkModalOpen, 
    setIsLoginModalOpen,
    setIsDataModalOpen,
    invoices,
    isOnline,
    logout
  } = useApp();

  const pendingReviewCount = invoices.filter((i) => i.status === 'قيد مراجعة المشرف').length;

  const roles: { role: UserRole; label: string; icon: React.ReactNode; desc: string }[] = [
    { role: 'sales_rep', label: 'مندوب مبيعات', icon: <Smartphone className="w-3.5 h-3.5" />, desc: 'تطبيق الموبايل والكتالوج الذكي' },
    { role: 'supervisor', label: 'مشرف مبيعات', icon: <UserCheck className="w-3.5 h-3.5" />, desc: 'مراجعة وتدقيق الفواتير' },
    { role: 'branch_manager', label: 'مدير فرع', icon: <Building2 className="w-3.5 h-3.5" />, desc: 'إدارة المخزن والائتمان' },
    { role: 'admin', label: 'الإدارة العامة / GM', icon: <Crown className="w-3.5 h-3.5" />, desc: 'التحكم الشامل والتقارير' },
  ];

  const isManagementRole = currentUser.role !== 'sales_rep';

  return (
    <header className="sticky top-0 z-40 w-full bg-slate-950/95 border-b border-slate-800 backdrop-blur-md">
      <div className="max-w-7xl mx-auto px-3 sm:px-6 py-2.5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          
          {/* Logo & Current Active Identity */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center text-white font-black text-base shadow-lg shadow-blue-600/30">
                ط
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-extrabold text-sm text-white tracking-wide">
                    مجموعة الطنطاوي للتجارة
                  </span>
                  <span className="text-[10px] bg-slate-800 text-slate-300 px-2 py-0.5 rounded-full border border-slate-700">
                    نظام 2026
                  </span>
                </div>
                <div className="flex items-center gap-2 text-[11px] text-slate-400">
                  <span>المستخدم: <strong className="text-blue-400">{currentUser.name}</strong></span>
                  <span>•</span>
                  <button 
                    onClick={() => setIsLoginModalOpen(true)}
                    className="text-amber-400 hover:underline flex items-center gap-1 font-bold"
                  >
                    <KeyRound className="w-3 h-3 inline" />
                    <span>تغيير الحساب</span>
                  </button>
                </div>
              </div>
            </div>

            {/* Mobile Actions for small screens */}
            <div className="flex md:hidden items-center gap-1.5">
              <PWAInstallButton />
              <button
                onClick={() => setIsDataModalOpen(true)}
                className="p-2 rounded-xl bg-slate-800 text-emerald-400 border border-emerald-500/30"
                title="إدارة وتحديث البيانات"
              >
                <Database className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Role Switcher Pills (Testing multiple roles instantly) */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0 no-scrollbar">
            <span className="text-[11px] text-slate-400 font-bold whitespace-nowrap ml-1 hidden xl:inline">
              اختبار الأدوار:
            </span>
            {roles.map((r) => {
              const isActive = currentUser.role === r.role;
              return (
                <button
                  key={r.role}
                  onClick={() => switchRole(r.role)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                    isActive
                      ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30 ring-1 ring-blue-400'
                      : 'bg-slate-900 text-slate-400 hover:text-slate-200 hover:bg-slate-800 border border-slate-800'
                  }`}
                  title={r.desc}
                >
                  {r.icon}
                  <span>{r.label}</span>
                </button>
              );
            })}
          </div>

          {/* Quick Actions: PWA Install, Data Management & APK Modal */}
          <div className="hidden md:flex items-center gap-2">
            <PWAInstallButton />

            <button
              onClick={() => setIsDataModalOpen(true)}
              className="px-3.5 py-1.5 rounded-xl bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border border-emerald-500/40 text-xs font-bold flex items-center gap-1.5 transition shadow-sm"
              title="أين توجد البيانات وكيف يتم تحديثها"
            >
              <Database className="w-3.5 h-3.5" />
              <span>إدارة وتحديث البيانات</span>
            </button>

            <button
              onClick={() => setIsApkModalOpen(true)}
              className="px-3.5 py-1.5 rounded-xl bg-blue-600/20 hover:bg-blue-600/30 text-blue-400 border border-blue-500/40 text-xs font-bold flex items-center gap-1.5 transition shadow-sm"
            >
              <Download className="w-3.5 h-3.5" />
              <span>تحميل APK</span>
            </button>

            <button
              onClick={() => setIsLoginModalOpen(true)}
              className="p-1.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-400 hover:text-white border border-slate-800 transition"
              title="صفحة تسجيل الدخول والصلاحيات"
            >
              <LogIn className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Navigation Tabs Bar */}
        <div className="mt-2.5 pt-2 border-t border-slate-800/80 flex flex-col md:flex-row md:items-center justify-between gap-2">
          <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-1 md:pb-0">
            {/* 1. Visits Tab */}
            <button
              onClick={() => setActiveTab('visits')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                activeTab === 'visits'
                  ? 'bg-amber-500 text-slate-950 shadow-lg shadow-amber-500/20 font-black'
                  : 'text-amber-400 hover:text-amber-300 hover:bg-slate-900 border border-amber-500/30'
              }`}
            >
              <span>📍</span>
              <span>الزيارات الميدانية</span>
            </button>

            {/* 2. Target Performance Tab (Most Requested) */}
            <button
              onClick={() => setActiveTab('target')}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                activeTab === 'target'
                  ? 'bg-amber-500 text-slate-950 shadow-lg shadow-amber-500/20 font-black'
                  : 'text-amber-400 hover:text-white hover:bg-slate-900 border border-amber-500/20'
              }`}
            >
              <Target className="w-3.5 h-3.5" />
              <span>التارجت والأهداف 🎯</span>
            </button>

            {/* 3. Collection Forecast Tab (Most Requested) */}
            <button
              onClick={() => setActiveTab('forecast')}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                activeTab === 'forecast'
                  ? 'bg-emerald-500 text-slate-950 shadow-lg shadow-emerald-500/20 font-black'
                  : 'text-emerald-400 hover:text-white hover:bg-slate-900 border border-emerald-500/20'
              }`}
            >
              <DollarSign className="w-3.5 h-3.5" />
              <span>متوقع التحصيل 💰</span>
            </button>

            {/* 4. Catalog Tab */}
            <button
              onClick={() => setActiveTab('rep_catalog')}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                activeTab === 'rep_catalog'
                  ? 'bg-blue-600 text-white shadow'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <ShoppingBag className="w-3.5 h-3.5" />
              <span>كتالوج المبيعات 📲</span>
            </button>

            {/* 5. Customers Tab */}
            <button
              onClick={() => setActiveTab('customers')}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                activeTab === 'customers'
                  ? 'bg-blue-600 text-white shadow'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <Users className="w-3.5 h-3.5" />
              <span>دليل العملاء والأرصدة</span>
            </button>

            {isManagementRole ? (
              <>
                <button
                  onClick={() => setActiveTab('admin_review')}
                  className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                    activeTab === 'admin_review'
                      ? 'bg-indigo-600 text-white shadow'
                      : 'text-slate-400 hover:text-white'
                  }`}
                >
                  <ClipboardCheck className="w-3.5 h-3.5" />
                  <span>اعتماد الطلبيات</span>
                  {pendingReviewCount > 0 && (
                    <span className="w-4 h-4 rounded-full bg-amber-500 text-slate-950 font-black text-[10px] flex items-center justify-center">
                      {pendingReviewCount}
                    </span>
                  )}
                </button>

                <button
                  onClick={() => setActiveTab('inventory')}
                  className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                    activeTab === 'inventory'
                      ? 'bg-indigo-600 text-white shadow'
                      : 'text-slate-400 hover:text-white'
                  }`}
                >
                  <Boxes className="w-3.5 h-3.5" />
                  <span>المخزون</span>
                </button>

                {/* Database Hub Tab */}
                <button
                  onClick={() => setActiveTab('database_hub')}
                  className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                    activeTab === 'database_hub'
                      ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/20 font-black'
                      : 'text-blue-400 hover:text-blue-300 hover:bg-slate-900 border border-blue-500/20'
                  }`}
                >
                  <Database className="w-3.5 h-3.5" />
                  <span>قاعدة البيانات والمزامنة 🗄️</span>
                </button>
              </>
            ) : (
              <>
                <button
                  onClick={() => setActiveTab('admin_review')}
                  className={`px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                    activeTab === 'admin_review'
                      ? 'bg-blue-600 text-white shadow'
                      : 'text-slate-400 hover:text-white'
                  }`}
                >
                  <ClipboardCheck className="w-3.5 h-3.5" />
                  <span>طلبياتي المحولة</span>
                </button>
              </>
            )}

            {/* Dedicated Login Screen Tab */}
            <button
              onClick={() => setActiveTab('login_screen')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap border ${
                activeTab === 'login_screen'
                  ? 'bg-blue-600 border-blue-500 text-white shadow'
                  : 'bg-slate-900 border-slate-800 text-slate-300 hover:text-white hover:border-slate-700'
              }`}
            >
              <KeyRound className="w-3.5 h-3.5 text-amber-400" />
              <span>صفحة الدخول 🔑</span>
            </button>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={logout}
              className="text-[11px] text-slate-400 hover:text-red-400 px-2.5 py-1 rounded-lg hover:bg-slate-900 transition flex items-center gap-1"
              title="تسجيل الخروج والرجوع لشاشة الدخول"
            >
              <LogOut className="w-3.5 h-3.5 text-red-400" />
              <span className="hidden sm:inline font-bold">تسجيل خروج</span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};
