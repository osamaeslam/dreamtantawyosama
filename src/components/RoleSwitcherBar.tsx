import React from 'react';
import { 
  ShoppingBag, 
  Users, 
  Boxes, 
  ClipboardCheck, 
  Database,
  LogOut,
  Target,
  DollarSign,
  MapPin,
  CheckCircle2,
  ShieldCheck,
  UserCheck,
  Building2,
  Crown
} from 'lucide-react';
import { useApp } from '../context/AppContext';

export const RoleSwitcherBar: React.FC = () => {
  const { 
    currentUser, 
    activeTab, 
    setActiveTab, 
    invoices,
    isOnline,
    logout
  } = useApp();

  const pendingReviewCount = invoices.filter((i) => i.status === 'قيد مراجعة المشرف').length;

  const roleMeta = {
    sales_rep: { label: 'مندوب مبيعات', icon: <UserCheck className="w-3.5 h-3.5" />, color: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30' },
    supervisor: { label: 'مشرف مبيعات', icon: <ShieldCheck className="w-3.5 h-3.5" />, color: 'bg-blue-500/10 text-blue-400 border-blue-500/30' },
    branch_manager: { label: 'مدير فرع', icon: <Building2 className="w-3.5 h-3.5" />, color: 'bg-amber-500/10 text-amber-400 border-amber-500/30' },
    admin: { label: 'الإدارة العامة', icon: <Crown className="w-3.5 h-3.5" />, color: 'bg-purple-500/10 text-purple-400 border-purple-500/30' },
    developer: { label: 'المطور التقني', icon: <Crown className="w-3.5 h-3.5" />, color: 'bg-cyan-500/10 text-cyan-400 border-cyan-500/30' }
  }[currentUser.role] || { label: currentUser.role, icon: null, color: 'bg-slate-800 text-slate-300' };

  const isManagement = currentUser.role === 'admin' || currentUser.role === 'branch_manager' || currentUser.role === 'developer';
  const isSupervisor = currentUser.role === 'supervisor';
  const isSalesRep = currentUser.role === 'sales_rep';

  return (
    <header className="sticky top-0 z-40 w-full bg-slate-950/95 border-b border-slate-800 backdrop-blur-md font-['Cairo',sans-serif]">
      <div className="max-w-7xl mx-auto px-3 sm:px-6 py-2.5 flex flex-col md:flex-row md:items-center justify-between gap-3">
        
        {/* Right Side: Clean Brand & User Identity */}
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-2xl bg-gradient-to-tr from-amber-500 to-amber-600 flex items-center justify-center text-slate-950 font-black text-lg shadow-md shadow-amber-500/20">
              ط
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-sm text-white">
                  مجموعة الطنطاوي
                </span>
                <span className={`text-[10px] px-2 py-0.5 rounded-full border font-bold flex items-center gap-1 ${roleMeta.color}`}>
                  {roleMeta.icon}
                  <span>{roleMeta.label}</span>
                </span>
              </div>
              <div className="text-[11px] text-slate-400">
                <span>المستخدم: <strong className="text-white">{currentUser.name}</strong></span>
                <span className="mx-1.5">•</span>
                <span className="text-slate-500">{currentUser.branchName}</span>
              </div>
            </div>
          </div>

          {/* Mobile logout button */}
          <button
            onClick={logout}
            className="md:hidden p-2 rounded-xl text-slate-400 hover:text-red-400 hover:bg-slate-900 border border-slate-800 transition"
            title="تسجيل الخروج"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>

        {/* Center: Clean Role-Tailored Navigation Tabs */}
        <nav className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-1 md:pb-0">
          
          {/* Sales Rep Specific Tabs */}
          {isSalesRep && (
            <>
              <button
                onClick={() => setActiveTab('rep_catalog')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'rep_catalog'
                    ? 'bg-amber-500 text-slate-950 shadow-md font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <ShoppingBag className="w-3.5 h-3.5" />
                <span>كتالوج المبيعات 📲</span>
              </button>

              <button
                onClick={() => setActiveTab('visits')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'visits'
                    ? 'bg-amber-500 text-slate-950 shadow-md font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <MapPin className="w-3.5 h-3.5" />
                <span>الزيارات الميدانية 📍</span>
              </button>

              <button
                onClick={() => setActiveTab('customers')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'customers'
                    ? 'bg-amber-500 text-slate-950 shadow-md font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <Users className="w-3.5 h-3.5" />
                <span>عملائي والأرصدة</span>
              </button>

              <button
                onClick={() => setActiveTab('target')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'target'
                    ? 'bg-amber-500 text-slate-950 shadow-md font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <Target className="w-3.5 h-3.5" />
                <span>تارجتي الشخصي 🎯</span>
              </button>

              <button
                onClick={() => setActiveTab('admin_review')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'admin_review'
                    ? 'bg-amber-500 text-slate-950 shadow-md font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <ClipboardCheck className="w-3.5 h-3.5" />
                <span>طلبياتي المحولة</span>
              </button>
            </>
          )}

          {/* Supervisor Specific Tabs */}
          {isSupervisor && (
            <>
              <button
                onClick={() => setActiveTab('admin_review')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'admin_review'
                    ? 'bg-blue-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
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
                onClick={() => setActiveTab('visits')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'visits'
                    ? 'bg-blue-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <MapPin className="w-3.5 h-3.5" />
                <span>زيارات مناديب الفرع 📍</span>
              </button>

              <button
                onClick={() => setActiveTab('customers')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'customers'
                    ? 'bg-blue-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <Users className="w-3.5 h-3.5" />
                <span>عملاء الفرع</span>
              </button>

              <button
                onClick={() => setActiveTab('target')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'target'
                    ? 'bg-blue-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <Target className="w-3.5 h-3.5" />
                <span>تارجت ومستهدفات الفرع 🎯</span>
              </button>

              <button
                onClick={() => setActiveTab('rep_catalog')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'rep_catalog'
                    ? 'bg-blue-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <ShoppingBag className="w-3.5 h-3.5" />
                <span>الكتالوج</span>
              </button>
            </>
          )}

          {/* Management (Branch Manager & Admin) Tabs */}
          {isManagement && (
            <>
              <button
                onClick={() => setActiveTab('admin_review')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'admin_review'
                    ? 'bg-purple-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
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
                onClick={() => setActiveTab('target')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'target'
                    ? 'bg-purple-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <Target className="w-3.5 h-3.5" />
                <span>التارجت والأهداف 🎯</span>
              </button>

              <button
                onClick={() => setActiveTab('forecast')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'forecast'
                    ? 'bg-purple-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <DollarSign className="w-3.5 h-3.5" />
                <span>متوقع التحصيل 💰</span>
              </button>

              <button
                onClick={() => setActiveTab('inventory')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'inventory'
                    ? 'bg-purple-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <Boxes className="w-3.5 h-3.5" />
                <span>المخزون</span>
              </button>

              <button
                onClick={() => setActiveTab('customers')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'customers'
                    ? 'bg-purple-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <Users className="w-3.5 h-3.5" />
                <span>العملاء</span>
              </button>

              <button
                onClick={() => setActiveTab('visits')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'visits'
                    ? 'bg-purple-600 text-white shadow font-black'
                    : 'text-slate-300 hover:text-white hover:bg-slate-900'
                }`}
              >
                <MapPin className="w-3.5 h-3.5" />
                <span>الزيارات</span>
              </button>

              <button
                onClick={() => setActiveTab('database_hub')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition whitespace-nowrap ${
                  activeTab === 'database_hub'
                    ? 'bg-emerald-600 text-white shadow font-black'
                    : 'text-emerald-400 hover:text-emerald-300 hover:bg-slate-900 border border-emerald-500/20'
                }`}
              >
                <Database className="w-3.5 h-3.5" />
                <span>قاعدة البيانات 🗄️</span>
              </button>
            </>
          )}

        </nav>

        {/* Left Side: Status & Logout */}
        <div className="hidden md:flex items-center gap-3">
          <div className="flex items-center gap-1.5 text-[11px] text-slate-400">
            <span className={`w-2 h-2 rounded-full ${isOnline ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'}`} />
            <span>{isOnline ? 'سيرفر Supabase متصل' : 'أوفلاين'}</span>
          </div>

          <button
            onClick={logout}
            className="text-xs text-slate-400 hover:text-red-400 px-3 py-1.5 rounded-xl hover:bg-slate-900 border border-slate-800 transition flex items-center gap-1.5 font-bold"
            title="تسجيل الخروج والرجوع لشاشة الدخول"
          >
            <LogOut className="w-3.5 h-3.5 text-red-400" />
            <span>تسجيل خروج</span>
          </button>
        </div>

      </div>
    </header>
  );
};
