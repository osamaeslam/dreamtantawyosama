import React, { useState } from 'react';
import { 
  Lock, 
  User, 
  ArrowLeft, 
  Eye, 
  EyeOff, 
  Database,
  Sparkles,
  AlertCircle,
  ShieldCheck,
  Building2,
  CheckCircle2
} from 'lucide-react';
import { useApp } from '../context/AppContext';

export const LuxuryLoginPage: React.FC = () => {
  const { login, isOnline } = useApp();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    if (!username.trim()) {
      setErrorMessage('يرجى إدخال اسم المستخدم أو رقم الهاتف أو الكود الوظيفي');
      return;
    }

    if (!password) {
      setErrorMessage('يرجى إدخال كلمة المرور');
      return;
    }

    setIsLoading(true);

    setTimeout(() => {
      setIsLoading(false);
      const success = login(username.trim(), password);
      if (!success) {
        setErrorMessage('بيانات الدخول غير صحيحة، يرجى التحقق من اسم المستخدم أو كلمة المرور');
      }
    }, 400);
  };

  return (
    <div className="min-h-screen w-full bg-[#070b14] text-slate-100 flex flex-col items-center justify-center p-4 relative overflow-hidden font-['Cairo',sans-serif]">
      {/* Background Luxury Ambient Glows */}
      <div className="absolute top-1/4 -right-32 w-[500px] h-[500px] bg-amber-500/10 rounded-full blur-[130px] pointer-events-none" />
      <div className="absolute bottom-1/4 -left-32 w-[500px] h-[500px] bg-blue-600/10 rounded-full blur-[130px] pointer-events-none" />

      {/* Main Container */}
      <div className="w-full max-w-md relative z-10 space-y-6">
        
        {/* Company Header & Luxury Crest */}
        <div className="text-center space-y-3">
          <div className="inline-block relative">
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-tr from-amber-500 via-amber-400 to-amber-600 p-[2px] shadow-2xl shadow-amber-500/25 mx-auto">
              <div className="w-full h-full bg-[#0b1120] rounded-[22px] flex items-center justify-center">
                <span className="text-3xl font-black text-amber-400 font-serif">ط</span>
              </div>
            </div>
            <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-emerald-500 border-2 border-[#070b14] flex items-center justify-center text-[10px] text-white font-bold" title="Supabase متصل">
              ✓
            </div>
          </div>

          <div>
            <h1 className="text-2xl sm:text-3xl font-black text-white tracking-wide">
              مجموعة الطنطاوي للتجارة
            </h1>
            <p className="text-xs text-amber-400 font-bold tracking-widest mt-0.5 uppercase">
              TANTAWY GROUP • ENTERPRISE
            </p>
            <p className="text-xs text-slate-400 mt-1">
              بوابة تسجيل الدخول المركزية الموحدة
            </p>
          </div>

          {/* Supabase Realtime Connection Badge */}
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-slate-900/90 border border-slate-800 text-[11px] text-slate-300 shadow-sm">
            <Database className="w-3.5 h-3.5 text-emerald-400" />
            <span>خادم Supabase:</span>
            <span className="text-emerald-400 font-bold flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              {isOnline ? 'متصل ومؤمن (Live)' : 'أوفلاين (مؤقت)'}
            </span>
          </div>
        </div>

        {/* The Single Login Card */}
        <div className="bg-slate-900/90 border border-slate-800/90 rounded-3xl p-6 sm:p-8 shadow-2xl backdrop-blur-2xl space-y-5">
          
          <div className="border-b border-slate-800 pb-3">
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <Lock className="w-4 h-4 text-amber-400" />
              <span>تسجيل الدخول إلى حسابك</span>
            </h2>
            <p className="text-[11px] text-slate-400 mt-0.5">
              أدخل بيانات حسابك للمتابعة وفقاً للصلاحيات الممنوحة لك
            </p>
          </div>

          {/* Error Message */}
          {errorMessage && (
            <div className="p-3.5 rounded-2xl bg-red-950/50 border border-red-500/40 text-red-200 text-xs flex items-center gap-2.5">
              <AlertCircle className="w-4 h-4 text-red-400 shrink-0" />
              <span>{errorMessage}</span>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4 text-xs">
            <div>
              <label className="text-slate-300 font-bold block mb-1.5">
                اسم المستخدم / رقم الهاتف / الكود الوظيفي:
              </label>
              <div className="relative">
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="مثال: ahmed_rep أو 01012345678"
                  className="w-full bg-[#050914] border border-slate-800 focus:border-amber-500 focus:ring-1 focus:ring-amber-500 rounded-2xl pr-10 pl-3 py-3 text-white outline-none transition font-mono text-xs"
                  required
                />
                <User className="w-4 h-4 text-slate-500 absolute right-3.5 top-1/2 -translate-y-1/2" />
              </div>
            </div>

            <div>
              <label className="text-slate-300 font-bold block mb-1.5">
                كلمة المرور:
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-[#050914] border border-slate-800 focus:border-amber-500 focus:ring-1 focus:ring-amber-500 rounded-2xl pr-10 pl-10 py-3 text-white outline-none transition font-mono text-xs"
                  required
                />
                <Lock className="w-4 h-4 text-slate-500 absolute right-3.5 top-1/2 -translate-y-1/2" />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="text-slate-500 hover:text-slate-300 absolute left-3.5 top-1/2 -translate-y-1/2 p-1"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between text-[11px] text-slate-400 pt-0.5">
              <label className="flex items-center gap-2 cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="rounded accent-amber-500"
                />
                <span>تذكر بيانات الحساب</span>
              </label>
              <span className="text-slate-500 hover:text-amber-400 cursor-pointer transition">
                الدعم الفني للمنظومة
              </span>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-amber-500 via-amber-400 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-black text-sm transition shadow-lg shadow-amber-500/25 flex items-center justify-center gap-2 disabled:opacity-60 cursor-pointer"
            >
              {isLoading ? (
                <span className="inline-block w-4 h-4 border-2 border-slate-950 border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <span>تسجيل الدخول إلى النظام</span>
                  <ArrowLeft className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

        </div>

        {/* Footer */}
        <div className="text-center text-[11px] text-slate-600">
          مجموعة الطنطاوي للتجارة والتوزيع © 2026 • جميع الحقوق محفوظة
        </div>

      </div>
    </div>
  );
};
