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
  ArrowLeft, 
  CheckCircle2, 
  Sparkles,
  Info
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { UserRole } from '../types';

interface Props {
  isOpen: boolean;
  onClose: () => void;
}

export const LoginModal: React.FC<Props> = ({ isOpen, onClose }) => {
  const { login, users, currentUser } = useApp();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [selectedRole, setSelectedRole] = useState<UserRole>('sales_rep');
  const [errorMsg, setErrorMsg] = useState('');
  const [isQuickMode, setIsQuickMode] = useState(true);

  if (!isOpen) return null;

  const handleManualLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!username.trim()) {
      setErrorMsg('برجاء إدخال اسم المستخدم أو كود المندوب');
      return;
    }
    const success = login(username, password);
    if (success) {
      setErrorMsg('');
      onClose();
    } else {
      setErrorMsg('اسم المستخدم أو كلمة المرور غير صحيحة');
    }
  };

  const handleQuickRoleSelect = (role: UserRole) => {
    const matched = users.find((u) => u.role === role);
    if (matched) {
      login(matched.username, '123456');
      onClose();
    }
  };

  const quickRoles = [
    {
      role: 'sales_rep' as UserRole,
      title: 'مندوب مبيعات',
      user: 'أحمد علي النجار (كود: REP-101)',
      desc: 'كتالوج الموبايل الذكي، تسجيل طلبيات، تكبير صور، وحفظ وتحويل للمراجعة',
      icon: <Smartphone className="w-5 h-5 text-blue-400" />,
      bg: 'hover:border-blue-500/50 hover:bg-blue-950/30'
    },
    {
      role: 'supervisor' as UserRole,
      title: 'مشرف مبيعات',
      user: 'محمود عبد الله (إشراف الجيزة والقاهرة)',
      desc: 'فحص فواتير المناديب، اعتماد الخصومات، والتحويل لأمر صرف مخزني',
      icon: <UserCheck className="w-5 h-5 text-emerald-400" />,
      bg: 'hover:border-emerald-500/50 hover:bg-emerald-950/30'
    },
    {
      role: 'branch_manager' as UserRole,
      title: 'مدير فرع ومخازن',
      user: 'م. طارق الصاوي (فرع القاهرة الكبرى)',
      desc: 'أرصدة الكراتين، تسليم الشحنات، وحسابات العملاء والحدود الائتمانية',
      icon: <Building2 className="w-5 h-5 text-purple-400" />,
      bg: 'hover:border-purple-500/50 hover:bg-purple-950/30'
    },
    {
      role: 'admin' as UserRole,
      title: 'مدير عام / مالك (GM)',
      user: 'الحاج مصطفى الطنطاوي (الإدارة العليا)',
      desc: 'صلاحيات شاملة، تقارير الأداء، تسعير المنتجات، والربط مع Supabase',
      icon: <Crown className="w-5 h-5 text-amber-400" />,
      bg: 'hover:border-amber-500/50 hover:bg-amber-950/30'
    }
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-md animate-in fade-in duration-200">
      <div className="relative w-full max-w-xl bg-slate-900 border border-slate-800 rounded-3xl shadow-2xl overflow-hidden">
        {/* Modal Header */}
        <div className="p-6 bg-gradient-to-r from-blue-950/50 via-slate-900 to-indigo-950/50 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center text-white shadow-lg shadow-blue-600/30 font-black text-xl">
              ط
            </div>
            <div>
              <h2 className="text-lg font-black text-white flex items-center gap-2">
                تسجيل الدخول وصلاحيات النظام
              </h2>
              <p className="text-xs text-slate-400">
                مجموعة الطنطاوي - بوابة المندوبين والإدارة 2026
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-white p-2 rounded-xl hover:bg-slate-800 transition"
          >
            ✕
          </button>
        </div>

        {/* Tab Switcher: Quick Switch vs Manual Credentials */}
        <div className="flex border-b border-slate-800 bg-slate-950/50 p-1.5">
          <button
            type="button"
            onClick={() => setIsQuickMode(true)}
            className={`flex-1 py-2 text-xs font-bold rounded-xl transition flex items-center justify-center gap-2 ${
              isQuickMode 
                ? 'bg-blue-600 text-white shadow-md' 
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Sparkles className="w-3.5 h-3.5" />
            <span>تسجيل دخول سريع حسب الدور (للتجربة)</span>
          </button>
          <button
            type="button"
            onClick={() => setIsQuickMode(false)}
            className={`flex-1 py-2 text-xs font-bold rounded-xl transition flex items-center justify-center gap-2 ${
              !isQuickMode 
                ? 'bg-blue-600 text-white shadow-md' 
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Key className="w-3.5 h-3.5" />
            <span>دخول يدوي (اسم المستخدم وكلمة المرور)</span>
          </button>
        </div>

        <div className="p-6 max-h-[75vh] overflow-y-auto">
          {isQuickMode ? (
            <div className="space-y-3">
              <div className="p-3 bg-blue-950/30 border border-blue-800/40 rounded-2xl flex items-start gap-2.5 text-xs text-blue-300">
                <Info className="w-4 h-4 shrink-0 text-blue-400 mt-0.5" />
                <span>
                  اختر أي دور لتجربة الشاشة والصلاحيات المناسبة له مباشرة (المندوب يفتح له الكتالوج، المشرف والمدير تفتح لهم لوحة الاعتماد والرقابة).
                </span>
              </div>

              <div className="grid grid-cols-1 gap-2.5">
                {quickRoles.map((qr) => {
                  const isCurrent = currentUser?.role === qr.role;
                  return (
                    <button
                      key={qr.role}
                      onClick={() => handleQuickRoleSelect(qr.role)}
                      className={`w-full text-right p-4 rounded-2xl border transition flex items-start gap-3.5 group ${
                        isCurrent
                          ? 'border-blue-500 bg-blue-950/40 ring-1 ring-blue-500/50'
                          : 'border-slate-800 bg-slate-900/80 ' + qr.bg
                      }`}
                    >
                      <div className="p-2.5 rounded-xl bg-slate-800 border border-slate-700/80 shrink-0 group-hover:scale-105 transition">
                        {qr.icon}
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center justify-between">
                          <h4 className="text-sm font-bold text-white group-hover:text-blue-400 transition">
                            {qr.title}
                          </h4>
                          {isCurrent && (
                            <span className="text-[10px] bg-blue-500/20 text-blue-300 px-2 py-0.5 rounded-full border border-blue-500/30 flex items-center gap-1 font-bold">
                              <CheckCircle2 className="w-3 h-3 text-blue-400" />
                              الحالي
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-slate-300 font-semibold mt-0.5">
                          {qr.user}
                        </p>
                        <p className="text-[11px] text-slate-400 mt-1 leading-relaxed">
                          {qr.desc}
                        </p>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          ) : (
            <form onSubmit={handleManualLogin} className="space-y-4">
              {errorMsg && (
                <div className="p-3 bg-rose-950/40 border border-rose-800/60 rounded-2xl text-xs text-rose-300">
                  {errorMsg}
                </div>
              )}

              <div>
                <label className="block text-xs font-bold text-slate-300 mb-1.5">
                  اسم المستخدم أو كود المندوب
                </label>
                <div className="relative">
                  <User className="w-4 h-4 absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                  <input
                    type="text"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="مثال: ahmed_rep أو admin أو REP-101"
                    className="w-full pl-4 pr-10 py-3 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white placeholder-slate-600 focus:outline-none focus:border-blue-500"
                  />
                </div>
                <div className="flex gap-2 mt-2">
                  <button
                    type="button"
                    onClick={() => setUsername('ahmed_rep')}
                    className="text-[11px] text-blue-400 hover:underline bg-slate-800/80 px-2 py-0.5 rounded-lg"
                  >
                    ahmed_rep (مندوب)
                  </button>
                  <button
                    type="button"
                    onClick={() => setUsername('mahmoud_sup')}
                    className="text-[11px] text-emerald-400 hover:underline bg-slate-800/80 px-2 py-0.5 rounded-lg"
                  >
                    mahmoud_sup (مشرف)
                  </button>
                  <button
                    type="button"
                    onClick={() => setUsername('admin')}
                    className="text-[11px] text-amber-400 hover:underline bg-slate-800/80 px-2 py-0.5 rounded-lg"
                  >
                    admin (مدير)
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-300 mb-1.5">
                  كلمة المرور
                </label>
                <div className="relative">
                  <Lock className="w-4 h-4 absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full pl-4 pr-10 py-3 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white placeholder-slate-600 focus:outline-none focus:border-blue-500"
                  />
                </div>
                <span className="text-[10px] text-slate-500 mt-1 block">
                  (للتجربة: كلمة المرور الافتراضية هي 123456 أو أي كلمة مرور)
                </span>
              </div>

              <button
                type="submit"
                className="w-full py-3.5 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white font-black text-sm rounded-2xl shadow-lg shadow-blue-600/30 transition flex items-center justify-center gap-2"
              >
                <Lock className="w-4 h-4" />
                <span>دخول النظام</span>
              </button>
            </form>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 bg-slate-950/80 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
          <div className="flex items-center gap-1.5">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>نظام مشفر ومحمي برقم سري لكل مندوب ومشرف</span>
          </div>
          <button
            onClick={onClose}
            className="text-xs text-slate-400 hover:text-white"
          >
            إغلاق
          </button>
        </div>
      </div>
    </div>
  );
};
