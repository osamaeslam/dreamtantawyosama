import React, { useState } from 'react';
import { 
  Lock, 
  User, 
  Key, 
  ShieldCheck, 
  Smartphone, 
  Building2, 
  Crown, 
  UserCheck, 
  ArrowRight, 
  CheckCircle2, 
  Sparkles,
  MapPin,
  ChevronLeft,
  Eye,
  EyeOff,
  Database,
  Radio,
  Layers
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { UserRole } from '../types';

export const LuxuryLoginPage: React.FC = () => {
  const { 
    currentUser, 
    login, 
    switchRole, 
    isLoggedIn, 
    setIsLoggedIn, 
    activeTab, 
    setActiveTab,
    users 
  } = useApp();

  const [username, setUsername] = useState(currentUser?.username || 'ahmed_rep');
  const [password, setPassword] = useState('••••••••');
  const [showPassword, setShowPassword] = useState(false);
  const [selectedBranch, setSelectedBranch] = useState('فرع القاهرة الكبرى');
  const [rememberMe, setRememberMe] = useState(true);
  const [loginError, setLoginError] = useState('');
  const [loginSuccess, setLoginSuccess] = useState(false);

  const branches = [
    'فرع القاهرة الكبرى (المركز الرئيسي)',
    'فرع الإسكندرية والساحل الشمالي',
    'فرع طنطا ووسط الدلتا',
    'فرع أسيوط ومحافظات الصعيد'
  ];

  const roleProfiles: { 
    role: UserRole; 
    name: string; 
    code: string; 
    title: string; 
    desc: string; 
    icon: React.ReactNode; 
    badgeColor: string; 
    gradient: string;
  }[] = [
    {
      role: 'sales_rep',
      name: 'أحمد علي النجار',
      code: 'REP-104',
      title: 'مندوب مبيعات ميداني',
      desc: 'كتالوج المنتجات، تسجيل الزيارات بالـ GPS، وتحرير الفواتير للعملاء',
      icon: <Smartphone className="w-5 h-5" />,
      badgeColor: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30',
      gradient: 'from-emerald-600/20 to-teal-900/30 border-emerald-700/50 hover:border-emerald-500'
    },
    {
      role: 'supervisor',
      name: 'محمود عبد الله',
      code: 'SUP-02',
      title: 'مشرف مبيعات وقطاعات',
      desc: 'مراجعة وتدقيق فواتير المناديب، متابعة خطوط السير والتحصيلات',
      icon: <UserCheck className="w-5 h-5" />,
      badgeColor: 'bg-blue-500/20 text-blue-300 border-blue-500/30',
      gradient: 'from-blue-600/20 to-indigo-900/30 border-blue-700/50 hover:border-blue-500'
    },
    {
      role: 'branch_manager',
      name: 'م. طارق الصاوي',
      code: 'MGR-01',
      title: 'مدير فرع ومستودعات',
      desc: 'إدارة مخزون الفرع، الائتمان، صلاحيات الصرف والتحويل للمخازن',
      icon: <Building2 className="w-5 h-5" />,
      badgeColor: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
      gradient: 'from-amber-600/20 to-orange-900/30 border-amber-700/50 hover:border-amber-500'
    },
    {
      role: 'admin',
      name: 'الحاج مصطفى الطنطاوي',
      code: 'ADM-01',
      title: 'رئيس مجلس الإدارة / GM',
      desc: 'التحكم الشامل، لوحة قيادة الأرباح والتحصيلات، وإدارة الصلاحيات',
      icon: <Crown className="w-5 h-5" />,
      badgeColor: 'bg-purple-500/20 text-purple-300 border-purple-500/30',
      gradient: 'from-purple-600/20 to-pink-900/30 border-purple-700/50 hover:border-purple-500'
    }
  ];

  const handleManualLogin = (e: React.FormEvent) => {
    e.preventDefault();
    setLoginError('');

    if (!username.trim()) {
      setLoginError('يرجى كتابة اسم المستخدم أو الكود الوظيفي');
      return;
    }

    const ok = login(username, password);
    if (ok) {
      setLoginSuccess(true);
      setTimeout(() => {
        setLoginSuccess(false);
        setIsLoggedIn(true);
        if (currentUser.role === 'sales_rep') {
          setActiveTab('rep_catalog');
        } else {
          setActiveTab('admin_review');
        }
      }, 500);
    } else {
      setLoginError('بيانات الدخول غير صحيحة، يمكنك الضغط على أي حساب تجريبي أدناه');
    }
  };

  const handleQuickRoleSelect = (role: UserRole) => {
    switchRole(role);
    setIsLoggedIn(true);
    setLoginSuccess(true);
    setTimeout(() => {
      setLoginSuccess(false);
      if (role === 'sales_rep') {
        setActiveTab('rep_catalog');
      } else {
        setActiveTab('admin_review');
      }
    }, 400);
  };

  return (
    <div className="min-h-[92vh] w-full bg-slate-950 relative overflow-hidden flex flex-col items-center justify-center p-3 sm:p-6 text-slate-100 font-['Cairo',sans-serif]">
      {/* Decorative luxury background glow */}
      <div className="absolute top-0 -left-40 w-96 h-96 bg-blue-600/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-0 -right-40 w-96 h-96 bg-indigo-600/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-4xl h-96 bg-amber-500/5 rounded-full blur-3xl pointer-events-none" />

      {/* Top Banner if previewing while logged in */}
      {isLoggedIn && activeTab === 'login_screen' && (
        <div className="w-full max-w-4xl mb-4 bg-blue-950/80 border border-blue-800/80 rounded-2xl p-3 px-4 flex items-center justify-between shadow-xl">
          <div className="flex items-center gap-2 text-xs">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
            <span className="text-slate-300">أنت مسجل حالياً في النظام باسم:</span>
            <strong className="text-white font-bold">{currentUser.name}</strong>
            <span className="text-blue-300">({currentUser.role})</span>
          </div>
          <button
            onClick={() => {
              if (currentUser.role === 'sales_rep') {
                setActiveTab('rep_catalog');
              } else {
                setActiveTab('admin_review');
              }
            }}
            className="text-xs bg-blue-600 hover:bg-blue-500 text-white font-bold px-3 py-1.5 rounded-xl transition flex items-center gap-1 shadow"
          >
            <span>العودة للوحة النظام</span>
            <ChevronLeft className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      <div className="w-full max-w-4xl z-10 space-y-6">
        
        {/* Header Branding */}
        <div className="text-center space-y-2">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-900 border border-slate-800 text-xs text-amber-400 font-bold shadow-sm">
            <Sparkles className="w-3.5 h-3.5" />
            <span>بوابة المبيعات والتوزيع المركزية • إصدار 2026</span>
          </div>

          <div className="flex items-center justify-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-blue-600 via-indigo-600 to-amber-500 flex items-center justify-center text-white font-black text-2xl shadow-xl shadow-blue-600/30">
              ط
            </div>
            <div className="text-right">
              <h1 className="text-2xl sm:text-3xl font-black text-white tracking-wide">
                مجموعة الطنطاوي للتجارة والتوزيع
              </h1>
              <p className="text-xs sm:text-sm text-slate-400 font-medium">
                بوابة الدخول الذكية الموحدة للمناديب والمشرفين ومديري الفروع
              </p>
            </div>
          </div>
        </div>

        {/* Main Grid: Login Box + Fast 1-Click Role Pass */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          
          {/* Left / Main Column: Login Form */}
          <div className="lg:col-span-6 bg-slate-900/90 border border-slate-800 rounded-3xl p-5 sm:p-7 shadow-2xl backdrop-blur-xl space-y-5">
            <div className="flex items-center justify-between border-b border-slate-800/80 pb-4">
              <div>
                <h2 className="text-lg font-bold text-white flex items-center gap-2">
                  <Lock className="w-4 h-4 text-blue-400" />
                  تسجيل الدخول للنظام
                </h2>
                <p className="text-xs text-slate-400 mt-0.5">
                  أدخل الكود الوظيفي أو اسم المستخدم للمتابعة
                </p>
              </div>
              <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-[11px] text-emerald-400 font-bold">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                <span>Supabase Live</span>
              </div>
            </div>

            {loginError && (
              <div className="bg-red-500/10 border border-red-500/30 text-red-300 text-xs p-3 rounded-2xl flex items-center gap-2">
                <span>⚠️ {loginError}</span>
              </div>
            )}

            {loginSuccess && (
              <div className="bg-emerald-500/15 border border-emerald-500/40 text-emerald-300 text-xs p-3 rounded-2xl flex items-center gap-2 font-bold animate-fadeIn">
                <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                <span>تم التحقق بنجاح! جاري توجيهك لشاشتك المخصصة...</span>
              </div>
            )}

            <form onSubmit={handleManualLogin} className="space-y-4">
              {/* Username / Employee Code */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-300 block">
                  اسم المستخدم أو الكود الوظيفي:
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 right-0 pr-3.5 flex items-center pointer-events-none text-slate-500">
                    <User className="w-4 h-4" />
                  </div>
                  <input
                    type="text"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="مثال: ahmed_rep أو REP-104 أو اسم المندوب"
                    className="w-full bg-slate-950 border border-slate-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 rounded-2xl pr-10 pl-3 py-2.5 text-xs text-white placeholder-slate-500 outline-none transition"
                  />
                </div>
              </div>

              {/* Password */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label className="text-xs font-bold text-slate-300">
                    كلمة المرور:
                  </label>
                  <span className="text-[10px] text-slate-500">
                    (أي كلمة مرور مقبولة في وضع التجربة)
                  </span>
                </div>
                <div className="relative">
                  <div className="absolute inset-y-0 right-0 pr-3.5 flex items-center pointer-events-none text-slate-500">
                    <Key className="w-4 h-4" />
                  </div>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full bg-slate-950 border border-slate-800 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 rounded-2xl pr-10 pl-10 py-2.5 text-xs text-white placeholder-slate-500 outline-none transition"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-500 hover:text-slate-300 transition"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* Branch Selector */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                  <MapPin className="w-3.5 h-3.5 text-amber-400" />
                  الفرع أو مستودع الانطلاق:
                </label>
                <select
                  value={selectedBranch}
                  onChange={(e) => setSelectedBranch(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 focus:border-blue-500 rounded-2xl px-3 py-2.5 text-xs text-slate-200 outline-none"
                >
                  {branches.map((b) => (
                    <option key={b} value={b}>
                      {b}
                    </option>
                  ))}
                </select>
              </div>

              {/* Remember Me */}
              <div className="flex items-center justify-between text-xs pt-1">
                <label className="flex items-center gap-2 cursor-pointer text-slate-400 hover:text-slate-200">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                    className="rounded bg-slate-950 border-slate-700 text-blue-600 focus:ring-blue-500"
                  />
                  <span>حفظ تسجيل الدخول على هذا الجهاز</span>
                </label>
                <span className="text-blue-400 text-[11px] hover:underline cursor-pointer">
                  دعم الفني والمساعدة؟
                </span>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                className="w-full bg-gradient-to-r from-blue-600 via-indigo-600 to-blue-700 hover:from-blue-500 hover:to-indigo-500 text-white font-black py-3 rounded-2xl text-xs sm:text-sm shadow-xl shadow-blue-600/30 transition transform active:scale-[0.99] flex items-center justify-center gap-2"
              >
                <span>دخول النظام الفوري</span>
                <ChevronLeft className="w-4 h-4" />
              </button>
            </form>

            <div className="pt-2 border-t border-slate-800/80 flex items-center justify-between text-[11px] text-slate-400">
              <span className="flex items-center gap-1">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
                اتصال آمن ومحمي 256-bit SSL
              </span>
              <span className="text-slate-500 font-mono">v2.6-enterprise</span>
            </div>
          </div>

          {/* Right Column: Quick Role Passports (1-Click Login & Explanation) */}
          <div className="lg:col-span-6 space-y-4">
            <div className="bg-slate-900/80 border border-slate-800 rounded-3xl p-5 shadow-xl">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <Layers className="w-4 h-4 text-amber-400" />
                  <h3 className="text-sm font-bold text-white">دخول سريع بنقرة واحدة (حسب الدور والصلاحية)</h3>
                </div>
                <span className="text-[10px] bg-slate-800 text-amber-300 px-2 py-0.5 rounded-full border border-slate-700 font-bold">
                  تجربة فورية
                </span>
              </div>
              <p className="text-xs text-slate-400 mb-4">
                اختر الحساب المطلوب لتسجيل الدخول فوراً ومشاهدة الواجهات والصلاحيات الخاصة بكل دور:
              </p>

              <div className="space-y-2.5">
                {roleProfiles.map((item) => {
                  const isCurrent = currentUser?.role === item.role;
                  return (
                    <button
                      key={item.role}
                      type="button"
                      onClick={() => handleQuickRoleSelect(item.role)}
                      className={`w-full text-right p-3.5 rounded-2xl border transition relative overflow-hidden flex items-start gap-3 bg-gradient-to-r ${item.gradient} ${
                        isCurrent ? 'ring-2 ring-blue-500' : ''
                      }`}
                    >
                      <div className="p-2.5 rounded-xl bg-slate-950/70 text-white shrink-0 shadow border border-slate-800">
                        {item.icon}
                      </div>

                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between gap-2">
                          <span className="font-bold text-xs sm:text-sm text-white truncate">
                            {item.name}
                          </span>
                          <span className={`text-[10px] px-2 py-0.5 rounded-full border font-bold ${item.badgeColor}`}>
                            {item.title}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-300 mt-0.5 line-clamp-1">
                          {item.desc}
                        </p>
                        <div className="flex items-center gap-3 mt-1.5 text-[10px] text-slate-400 font-mono">
                          <span>الكود: <strong className="text-slate-200">{item.code}</strong></span>
                          <span>•</span>
                          <span className="text-blue-300">تسجيل دخول مباشر ⬅️</span>
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Architecture Info Card */}
            <div className="bg-slate-900/60 border border-slate-800/80 rounded-2xl p-4 text-xs space-y-2">
              <div className="flex items-center gap-2 text-blue-400 font-bold text-xs">
                <Database className="w-3.5 h-3.5" />
                <span>كيف يعمل تسجيل الدخول والصلاحيات؟</span>
              </div>
              <p className="text-slate-400 text-[11px] leading-relaxed">
                كل مستخدم يرتبط بجدول <code className="text-blue-300 font-mono bg-slate-950 px-1 rounded">users</code> في قاعدة بيانات Supabase مع سياسات وصول (Row Level Security).
                المندوب يرى عملاءه وكتالوجه وزياراته فقط، بينما المشرف ومدير الفرع يتمتعان بصلاحيات اعتماد وتدقيق الفواتير الميدانية.
              </p>
            </div>

          </div>

        </div>

      </div>
    </div>
  );
};
