import React, { useState, useMemo } from 'react';
import { 
  Users, 
  Search, 
  Phone, 
  MapPin, 
  CreditCard, 
  AlertCircle, 
  Building2, 
  ChevronRight,
  TrendingUp,
  Tag,
  ShieldCheck,
  Lock,
  UserCheck
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Customer } from '../types';

export const CustomerDirectoryView: React.FC = () => {
  const { customers, setSelectedCustomer, setActiveTab, currentUser } = useApp();
  const [searchQuery, setSearchQuery] = useState('');
  const [tierFilter, setTierFilter] = useState<string>('الكل');
  const [branchFilter, setBranchFilter] = useState<string>('الكل');

  // Strict RBAC customer isolation
  const isSalesRep = currentUser.role === 'sales_rep';
  const isSupervisor = currentUser.role === 'supervisor';
  const isManager = currentUser.role === 'branch_manager' || currentUser.role === 'admin';

  const roleFilteredCustomers = useMemo(() => {
    if (isSalesRep) {
      // Sales rep only sees their own assigned customers!
      return customers.filter((c) => c.repName === currentUser.name || !c.repName);
    }
    if (isSupervisor) {
      // Supervisor sees their branch's customers
      return customers.filter((c) => !c.branchName || c.branchName === currentUser.branchName);
    }
    // Admin / Branch Manager can see all or filter
    if (branchFilter !== 'الكل') {
      return customers.filter((c) => c.branchName === branchFilter);
    }
    return customers;
  }, [customers, currentUser, isSalesRep, isSupervisor, branchFilter]);

  const filteredCustomers = useMemo(() => {
    return roleFilteredCustomers.filter((c) => {
      const matchTier = tierFilter === 'الكل' || c.tier === tierFilter;
      const q = searchQuery.toLowerCase().trim();
      const matchQuery =
        !q ||
        c.name.toLowerCase().includes(q) ||
        c.code.toLowerCase().includes(q) ||
        (c.phone && c.phone.includes(q)) ||
        (c.address && c.address.toLowerCase().includes(q)) ||
        c.branchName.toLowerCase().includes(q) ||
        (c.repName && c.repName.toLowerCase().includes(q));
      return matchTier && matchQuery;
    });
  }, [roleFilteredCustomers, tierFilter, searchQuery]);

  return (
    <div className="w-full max-w-6xl mx-auto p-3 sm:p-6 space-y-6">
      {/* Header */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-bold text-blue-400 mb-1">
            <Users className="w-4 h-4" />
            دليل العملاء والأرصدة الائتمانية
          </div>
          <h2 className="text-xl font-bold text-white">إدارة حسابات معارض وتجار التجزئة</h2>
          <p className="text-xs text-slate-400 mt-1">
            متابعة الحدود الائتمانية وموقف المديونيات لتسهيل اتخاذ قرارات البيع والتوريد
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="bg-slate-950 px-4 py-2 rounded-2xl border border-slate-800 text-xs">
            <span className="text-slate-400 block text-[10px]">
              {isSalesRep ? 'عملاء محفظتي:' : 'العملاء المتاحون:'}
            </span>
            <span className="text-base font-bold text-white">{roleFilteredCustomers.length} عميل</span>
          </div>
        </div>
      </div>

      {/* Role Privacy Notice */}
      <div className={`p-3.5 rounded-2xl border flex items-center justify-between gap-3 text-xs ${
        isSalesRep 
          ? 'bg-amber-950/30 border-amber-500/30 text-amber-200' 
          : isSupervisor
          ? 'bg-blue-950/30 border-blue-500/30 text-blue-200'
          : 'bg-emerald-950/30 border-emerald-500/30 text-emerald-200'
      }`}>
        <div className="flex items-center gap-2.5">
          <Lock className="w-4 h-4 shrink-0 text-amber-400" />
          <span>
            {isSalesRep 
              ? `🔒 سرية البيانات مفعلة: أنت تشاهد فقط عملاء محفظتك البيعية (${currentUser.name}) لحماية سرية العملاء وأرقام الهواتف الخاصة بزملائك.`
              : isSupervisor
              ? `🏢 رؤية إشرافية: تعرض عملاء فرعك المعتمد (${currentUser.branchName}).`
              : `👑 رؤية الإدارة العامة: تحكم كامل في عملاء كافة الفروع مع حماية بيانات التواصل بين المناديب.`}
          </span>
        </div>
        <span className="font-bold bg-slate-900/80 px-2.5 py-1 rounded-xl text-[11px] whitespace-nowrap border border-slate-700">
          {currentUser.role === 'sales_rep' ? 'محفظة المندوب' : currentUser.role === 'supervisor' ? 'محفظة الفرع' : 'كافة الفروع'}
        </span>
      </div>

      {/* Search & Filter */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-slate-900 p-3 rounded-2xl border border-slate-800">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="ابحث باسم المعرض، كود العميل، أو المحافظة..."
            className="w-full pr-10 pl-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-blue-500"
          />
        </div>

        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar w-full sm:w-auto">
          {isManager && (
            <select
              value={branchFilter}
              onChange={(e) => setBranchFilter(e.target.value)}
              className="bg-slate-950 border border-slate-800 text-xs text-slate-300 rounded-xl px-2.5 py-1.5 focus:outline-none"
            >
              <option value="الكل">كل الفروع</option>
              <option value="فرع القاهرة الكبرى">فرع القاهرة الكبرى</option>
              <option value="فرع الدلتا">فرع الدلتا</option>
              <option value="فرع الإسكندرية والساحل">فرع الإسكندرية والساحل</option>
            </select>
          )}

          <span className="text-xs text-slate-400 whitespace-nowrap">التصنيف:</span>
          {['الكل', 'VIP', 'A', 'B'].map((t) => (
            <button
              key={t}
              onClick={() => setTierFilter(t)}
              className={`px-3 py-1 rounded-xl text-xs font-bold transition whitespace-nowrap ${
                tierFilter === t ? 'bg-blue-600 text-white' : 'bg-slate-950 text-slate-400 hover:text-white border border-slate-800'
              }`}
            >
              {t}
            </button>
          ))}
        </div>
      </div>

      {/* Customer Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredCustomers.map((cust) => {
          const isOverLimit = cust.currentBalance > cust.creditLimit;
          const usagePercent = Math.min(100, Math.round((cust.currentBalance / cust.creditLimit) * 100));

          return (
            <div
              key={cust.id}
              className="bg-slate-900 border border-slate-800 hover:border-blue-500/50 rounded-3xl p-5 shadow-lg flex flex-col justify-between transition"
            >
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-[10px] font-mono font-bold bg-slate-800 text-blue-400 px-2 py-0.5 rounded-lg">
                    {cust.code}
                  </span>
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                      cust.tier === 'VIP'
                        ? 'bg-amber-950 text-amber-400 border border-amber-600/40'
                        : 'bg-blue-950 text-blue-400 border border-blue-600/40'
                    }`}
                  >
                    فئة {cust.tier}
                  </span>
                </div>

                <h3 className="text-sm font-bold text-white mb-1">{cust.name}</h3>
                <p className="text-xs text-slate-400 flex items-center gap-1 mb-3">
                  <MapPin className="w-3.5 h-3.5 text-slate-500 shrink-0" />
                  <span className="line-clamp-1">{cust.address || cust.branchName}</span>
                </p>

                {/* Balance Progress Bar */}
                <div className="bg-slate-950 p-3 rounded-2xl border border-slate-800/80 mb-3 space-y-2">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-400">الرصيد القائم:</span>
                    <span className={`font-bold ${isOverLimit ? 'text-rose-400' : 'text-amber-400'}`}>
                      {cust.currentBalance.toLocaleString('ar-EG')} ج.م
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-[11px] text-slate-400">
                    <span>السقف المعتمد:</span>
                    <span>{cust.creditLimit.toLocaleString('ar-EG')} ج.م</span>
                  </div>
                  {/* Progress track */}
                  <div className="w-full h-1.5 bg-slate-800 rounded-full overflow-hidden">
                    <div
                      style={{ width: `${usagePercent}%` }}
                      className={`h-full rounded-full ${isOverLimit ? 'bg-rose-500' : 'bg-blue-500'}`}
                    ></div>
                  </div>
                </div>

                {cust.notes && (
                  <p className="text-[11px] text-slate-400 italic mb-3 line-clamp-2">
                    {cust.notes}
                  </p>
                )}
              </div>

              {/* Action Buttons */}
              <div className="pt-3 border-t border-slate-800 flex items-center justify-between gap-2">
                <a
                  href={`tel:${cust.phone}`}
                  className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold flex items-center gap-1.5 transition"
                >
                  <Phone className="w-3.5 h-3.5" />
                  <span>اتصال</span>
                </a>

                <button
                  onClick={() => {
                    setSelectedCustomer(cust);
                    setActiveTab('rep_catalog');
                  }}
                  className="px-3 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold flex items-center gap-1 shadow transition"
                >
                  <span>إنشاء طلبية</span>
                  <ChevronRight className="w-3.5 h-3.5 -scale-x-100" />
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
