import React, { useState, useMemo } from 'react';
import { 
  Target, 
  TrendingUp, 
  DollarSign, 
  Calendar, 
  CheckCircle2, 
  AlertCircle, 
  Clock, 
  Filter, 
  Award, 
  Plus, 
  Edit3, 
  Building2, 
  Users, 
  ChevronRight, 
  ArrowUpRight, 
  Percent,
  Lock,
  Sparkles,
  BarChart3
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { TargetRecord } from '../types';

export const TargetPerformanceDashboard: React.FC = () => {
  const { currentUser, targets, setTargets, updateTarget } = useApp();

  const isSalesRep = currentUser.role === 'sales_rep';
  const isSupervisor = currentUser.role === 'supervisor';
  const isManager = currentUser.role === 'branch_manager' || currentUser.role === 'admin';

  // Filters
  const [selectedQuarter, setSelectedQuarter] = useState<string>('Q4');
  const [selectedBranch, setSelectedBranch] = useState<string>('all');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingTarget, setEditingTarget] = useState<TargetRecord | null>(null);

  // New/Edit form state
  const [formRepName, setFormRepName] = useState('أحمد علي النجار');
  const [formBranch, setFormBranch] = useState(currentUser.branchName || 'فرع القاهرة الكبرى');
  const [formSalesTarget, setFormSalesTarget] = useState('450000');
  const [formSalesAchieved, setFormSalesAchieved] = useState('382500');
  const [formCollectionTarget, setFormCollectionTarget] = useState('380000');
  const [formCollectionAchieved, setFormCollectionAchieved] = useState('342000');
  const [formNotes, setFormNotes] = useState('');

  // Strict RBAC: Sales Reps ONLY see their own targets!
  const visibleTargets = useMemo(() => {
    if (isSalesRep) {
      return targets.filter((t) => t.repName === currentUser.name || t.repId === currentUser.id);
    }
    if (isSupervisor) {
      return targets.filter((t) => !t.branch || t.branch === currentUser.branchName);
    }
    if (selectedBranch !== 'all') {
      return targets.filter((t) => t.branch === selectedBranch);
    }
    return targets;
  }, [targets, currentUser, isSalesRep, isSupervisor, selectedBranch]);

  // Calculations for Visible Scope
  const totalSalesTarget = visibleTargets.reduce((acc, t) => acc + (t.salesTarget || 0), 0);
  const totalSalesAchieved = visibleTargets.reduce((acc, t) => acc + (t.salesAchieved || 0), 0);
  const salesPercentage = totalSalesTarget > 0 ? Math.round((totalSalesAchieved / totalSalesTarget) * 100) : 0;
  const remainingSales = Math.max(0, totalSalesTarget - totalSalesAchieved);

  const totalCollTarget = visibleTargets.reduce((acc, t) => acc + (t.collectionTarget || 0), 0);
  const totalCollAchieved = visibleTargets.reduce((acc, t) => acc + (t.collectionAchieved || 0), 0);
  const collPercentage = totalCollTarget > 0 ? Math.round((totalCollAchieved / totalCollTarget) * 100) : 0;
  const remainingColl = Math.max(0, totalCollTarget - totalCollAchieved);

  // Calculate days remaining in the month (e.g. October 31 days)
  const today = new Date();
  const currentDay = today.getDate();
  const daysInMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
  const daysRemaining = Math.max(1, daysInMonth - currentDay);

  const dailyRequiredSales = remainingSales > 0 ? Math.round(remainingSales / daysRemaining) : 0;
  const dailyRequiredCollection = remainingColl > 0 ? Math.round(remainingColl / daysRemaining) : 0;

  const handleSaveTarget = (e: React.FormEvent) => {
    e.preventDefault();
    const st = Number(formSalesTarget) || 0;
    const sa = Number(formSalesAchieved) || 0;
    const ct = Number(formCollectionTarget) || 0;
    const ca = Number(formCollectionAchieved) || 0;

    const sPct = st > 0 ? Math.round((sa / st) * 100) : 0;
    const cPct = ct > 0 ? Math.round((ca / ct) * 100) : 0;

    if (editingTarget) {
      updateTarget(editingTarget.id, {
        repName: formRepName,
        branch: formBranch,
        salesTarget: st,
        salesAchieved: sa,
        salesPercentage: sPct,
        collectionTarget: ct,
        collectionAchieved: ca,
        collectionPercentage: cPct,
        remainingSales: Math.max(0, st - sa),
        remainingCollection: Math.max(0, ct - ca),
        notes: formNotes,
      });
      setEditingTarget(null);
    } else {
      const newTrg: TargetRecord = {
        id: `trg-${Date.now()}`,
        branch: formBranch,
        repName: formRepName,
        salesTarget: st,
        salesAchieved: sa,
        salesPercentage: sPct,
        collectionTarget: ct,
        collectionAchieved: ca,
        collectionPercentage: cPct,
        date: new Date().toISOString().split('T')[0],
        month: today.getMonth() + 1,
        year: today.getFullYear(),
        quarter: selectedQuarter,
        remainingSales: Math.max(0, st - sa),
        remainingCollection: Math.max(0, ct - ca),
        notes: formNotes || 'مستهدف بيعي وتحصيلي مسجل',
        updatedAt: new Date().toISOString(),
      };
      setTargets([newTrg, ...targets]);
    }

    setIsAddModalOpen(false);
  };

  const openEditModal = (target: TargetRecord) => {
    setEditingTarget(target);
    setFormRepName(target.repName);
    setFormBranch(target.branch);
    setFormSalesTarget(String(target.salesTarget));
    setFormSalesAchieved(String(target.salesAchieved));
    setFormCollectionTarget(String(target.collectionTarget));
    setFormCollectionAchieved(String(target.collectionAchieved));
    setFormNotes(target.notes || '');
    setIsAddModalOpen(true);
  };

  return (
    <div className="w-full max-w-7xl mx-auto p-3 sm:p-6 space-y-6 font-['Cairo',sans-serif]">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-900 to-amber-950/40 border border-slate-800 rounded-3xl p-5 shadow-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-bold text-amber-400 mb-1">
            <Target className="w-4 h-4 text-amber-400" />
            <span>نظام مراقبة الأهداف البيعية والتحصيلات (Target Performance)</span>
            <span className="text-[10px] bg-amber-500/10 text-amber-300 px-2 py-0.5 rounded-full border border-amber-500/20 font-mono">
              Q4 - 2026
            </span>
          </div>
          <h1 className="text-xl sm:text-2xl font-black text-white flex items-center gap-2">
            مستهدفات المبيعات والتحصيل المالي
            {isSalesRep && <span className="text-xs font-normal text-amber-300 bg-amber-950/60 px-2.5 py-1 rounded-xl border border-amber-500/30">محفظة المندوب الشخصية</span>}
          </h1>
          <p className="text-xs text-slate-400 mt-1 max-w-2xl">
            متابعة مستمرة لنسب تحقيق التارجت البيعي والسيولة النقدية المحصلة، مع حساب معدل الإنجاز اليومي المطلوب للإغلاق الشهري.
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2.5 flex-wrap">
          {isManager && (
            <button
              onClick={() => {
                setEditingTarget(null);
                setFormSalesTarget('450000');
                setFormSalesAchieved('0');
                setFormCollectionTarget('380000');
                setFormCollectionAchieved('0');
                setFormNotes('');
                setIsAddModalOpen(true);
              }}
              className="bg-amber-500 hover:bg-amber-400 text-slate-950 px-4 py-2 rounded-2xl text-xs font-black flex items-center gap-1.5 shadow-lg shadow-amber-500/20 transition"
            >
              <Plus className="w-4 h-4" />
              <span>إدراج مستهدف جديد</span>
            </button>
          )}

          <div className="bg-slate-950/90 border border-slate-800 px-3 py-1.5 rounded-2xl text-xs text-slate-300 flex items-center gap-2">
            <Clock className="w-3.5 h-3.5 text-blue-400" />
            <span>متبقي على نهاية الشهر: <strong className="text-white">{daysRemaining} يوم</strong></span>
          </div>
        </div>
      </div>

      {/* RBAC Confidentiality Banner */}
      <div className={`p-3.5 rounded-2xl border flex items-center justify-between gap-3 text-xs ${
        isSalesRep 
          ? 'bg-amber-950/30 border-amber-500/30 text-amber-200' 
          : 'bg-emerald-950/30 border-emerald-500/30 text-emerald-200'
      }`}>
        <div className="flex items-center gap-2.5">
          <Lock className="w-4 h-4 shrink-0 text-amber-400" />
          <span>
            {isSalesRep 
              ? `🔒 سرية البيانات مفعلة: تعرض شاشة التارجت أرقامك ومستهدفاتك الشخصية فقط (${currentUser.name})، لا يمكن لأي مندوب آخر الاطلاع على نسب تحقيقك أو عمولاتك.`
              : isSupervisor
              ? `🏢 رؤية إشرافية: تعرض مستهدفات مناديب فرعك (${currentUser.branchName}).`
              : `👑 رؤية الإدارة العامة: تحكم كامل بمستهدفات جميع الفروع وتعديل خطط التحصيل.`}
          </span>
        </div>
        <span className="font-bold bg-slate-900/80 px-2.5 py-1 rounded-xl text-[11px] whitespace-nowrap border border-slate-700">
          {visibleTargets.length} سجل مستهدف
        </span>
      </div>

      {/* Primary KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Sales Target Card */}
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl space-y-3 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-blue-500/5 rounded-full blur-2xl -mr-10 -mt-10"></div>
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-bold">هدف المبيعات المطلوب</span>
            <div className="w-8 h-8 rounded-xl bg-blue-500/15 text-blue-400 flex items-center justify-center font-bold">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-black text-white">
              {totalSalesTarget.toLocaleString('ar-EG')} <span className="text-xs font-normal text-slate-400">ج.م</span>
            </div>
            <div className="text-xs text-slate-400 mt-1 flex items-center justify-between">
              <span>المحقق فعلياً:</span>
              <strong className="text-blue-400 font-bold">{totalSalesAchieved.toLocaleString('ar-EG')} ج.م</strong>
            </div>
          </div>
          {/* Progress Bar */}
          <div className="space-y-1">
            <div className="flex items-center justify-between text-[11px]">
              <span className="text-slate-400">نسبة الإنجاز:</span>
              <span className="font-black text-blue-400">{salesPercentage}%</span>
            </div>
            <div className="w-full h-2 bg-slate-950 rounded-full overflow-hidden border border-slate-800">
              <div 
                className="h-full bg-gradient-to-r from-blue-600 to-cyan-400 rounded-full transition-all duration-500"
                style={{ width: `${Math.min(100, salesPercentage)}%` }}
              ></div>
            </div>
          </div>
          <div className="pt-2 border-t border-slate-800/80 text-[11px] text-slate-400 flex items-center justify-between">
            <span>المتبقي للهدف:</span>
            <span className="font-bold text-amber-300">{remainingSales.toLocaleString('ar-EG')} ج.م</span>
          </div>
        </div>

        {/* Collection Target Card */}
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl space-y-3 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-emerald-500/5 rounded-full blur-2xl -mr-10 -mt-10"></div>
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-bold">هدف التحصيل النقدي</span>
            <div className="w-8 h-8 rounded-xl bg-emerald-500/15 text-emerald-400 flex items-center justify-center font-bold">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-black text-emerald-400">
              {totalCollTarget.toLocaleString('ar-EG')} <span className="text-xs font-normal text-slate-400">ج.م</span>
            </div>
            <div className="text-xs text-slate-400 mt-1 flex items-center justify-between">
              <span>المحصل بالخزينة:</span>
              <strong className="text-emerald-300 font-bold">{totalCollAchieved.toLocaleString('ar-EG')} ج.م</strong>
            </div>
          </div>
          {/* Progress Bar */}
          <div className="space-y-1">
            <div className="flex items-center justify-between text-[11px]">
              <span className="text-slate-400">نسبة التحصيل:</span>
              <span className="font-black text-emerald-400">{collPercentage}%</span>
            </div>
            <div className="w-full h-2 bg-slate-950 rounded-full overflow-hidden border border-slate-800">
              <div 
                className="h-full bg-gradient-to-r from-emerald-600 to-teal-400 rounded-full transition-all duration-500"
                style={{ width: `${Math.min(100, collPercentage)}%` }}
              ></div>
            </div>
          </div>
          <div className="pt-2 border-t border-slate-800/80 text-[11px] text-slate-400 flex items-center justify-between">
            <span>متبقي تحصيله:</span>
            <span className="font-bold text-amber-300">{remainingColl.toLocaleString('ar-EG')} ج.م</span>
          </div>
        </div>

        {/* Required Daily Sales Run Rate */}
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl space-y-3 relative overflow-hidden">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-bold">المطلوب يومياً (مبيعات)</span>
            <div className="w-8 h-8 rounded-xl bg-amber-500/15 text-amber-400 flex items-center justify-center font-bold">
              <BarChart3 className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-black text-amber-300">
              {dailyRequiredSales.toLocaleString('ar-EG')} <span className="text-xs font-normal text-slate-400">ج.م / يوم</span>
            </div>
            <p className="text-[11px] text-slate-400 mt-1">
              معدل الفواتير الواجب اعتمادها يومياً للوصول إلى 100% قبل نهاية الشهر.
            </p>
          </div>
          <div className="pt-2 border-t border-slate-800/80 text-[11px] text-slate-400 flex items-center justify-between">
            <span>الحالة البيعية:</span>
            <span className={`font-bold ${salesPercentage >= 80 ? 'text-emerald-400' : 'text-amber-400'}`}>
              {salesPercentage >= 80 ? 'على وشك الإقفال 🚀' : 'بحاجة لزيادة الزيارات ⚠️'}
            </span>
          </div>
        </div>

        {/* Required Daily Collection Run Rate */}
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl space-y-3 relative overflow-hidden">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-bold">المطلوب يومياً (تحصيل)</span>
            <div className="w-8 h-8 rounded-xl bg-purple-500/15 text-purple-400 flex items-center justify-center font-bold">
              <Award className="w-4 h-4" />
            </div>
          </div>
          <div>
            <div className="text-2xl font-black text-purple-300">
              {dailyRequiredCollection.toLocaleString('ar-EG')} <span className="text-xs font-normal text-slate-400">ج.م / يوم</span>
            </div>
            <p className="text-[11px] text-slate-400 mt-1">
              المبالغ والشيكات الواجب توريدها للخزينة لسد العجز وتحقيق بونص الإغلاق.
            </p>
          </div>
          <div className="pt-2 border-t border-slate-800/80 text-[11px] text-slate-400 flex items-center justify-between">
            <span>حالة السيولة:</span>
            <span className={`font-bold ${collPercentage >= 85 ? 'text-emerald-400' : 'text-rose-400'}`}>
              {collPercentage >= 85 ? 'سيولة نقدية ممتازة 💎' : 'متأخرات قيد المتابعة ⚠️'}
            </span>
          </div>
        </div>
      </div>

      {/* Targets Table / Detailed Cards */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl">
        <div className="p-5 border-b border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-slate-950/40">
          <div>
            <h3 className="font-bold text-white text-base flex items-center gap-2">
              <Users className="w-4 h-4 text-amber-400" />
              <span>تفاصيل أهداف مناديب ومحافظ المبيعات</span>
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              مقارنة الإنجاز الفعلي مقابل المخطط لكل مندوب في فرعه المعتمد
            </p>
          </div>

          {/* Filters for management */}
          {!isSalesRep && (
            <div className="flex items-center gap-2">
              <select
                value={selectedBranch}
                onChange={(e) => setSelectedBranch(e.target.value)}
                className="bg-slate-900 border border-slate-800 text-xs text-slate-300 rounded-xl px-3 py-1.5 focus:outline-none"
              >
                <option value="all">جميع الفروع</option>
                <option value="فرع القاهرة الكبرى">فرع القاهرة الكبرى</option>
                <option value="فرع الدلتا">فرع الدلتا</option>
                <option value="فرع الإسكندرية والساحل">فرع الإسكندرية والساحل</option>
              </select>
            </div>
          )}
        </div>

        {/* Cards or Table based on screen */}
        <div className="divide-y divide-slate-800/80">
          {visibleTargets.map((trg) => {
            const isCompleted = trg.salesPercentage >= 90 && trg.collectionPercentage >= 90;
            return (
              <div
                key={trg.id}
                className="p-5 hover:bg-slate-800/30 transition flex flex-col lg:flex-row lg:items-center justify-between gap-4"
              >
                {/* Rep and Branch info */}
                <div className="space-y-1.5 min-w-[240px]">
                  <div className="flex items-center gap-2">
                    <span className="font-black text-white text-base">{trg.repName}</span>
                    <span className="text-[10px] bg-slate-800 text-slate-300 px-2 py-0.5 rounded-full border border-slate-700">
                      {trg.quarter} - شهر {trg.month}
                    </span>
                    {isCompleted && (
                      <span className="text-[10px] bg-emerald-950 text-emerald-400 border border-emerald-500/30 px-2 py-0.5 rounded-full font-bold flex items-center gap-1">
                        <CheckCircle2 className="w-3 h-3" />
                        حقق الهدف
                      </span>
                    )}
                  </div>
                  <div className="text-xs text-slate-400 flex items-center gap-1.5">
                    <Building2 className="w-3.5 h-3.5 text-slate-500" />
                    <span>{trg.branch}</span>
                  </div>
                  {trg.notes && (
                    <p className="text-xs text-slate-400 italic line-clamp-1 pt-0.5">
                      {trg.notes}
                    </p>
                  )}
                </div>

                {/* Sales achievement block */}
                <div className="bg-slate-950/60 p-3.5 rounded-2xl border border-slate-800/80 min-w-[220px] space-y-1.5">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-400">مبيعات:</span>
                    <span className="font-bold text-white">
                      {trg.salesAchieved.toLocaleString('ar-EG')} / {trg.salesTarget.toLocaleString('ar-EG')} ج.م
                    </span>
                  </div>
                  <div className="w-full h-2 bg-slate-900 rounded-full overflow-hidden">
                    <div 
                      className={`h-full rounded-full ${trg.salesPercentage >= 80 ? 'bg-blue-500' : 'bg-amber-500'}`}
                      style={{ width: `${Math.min(100, trg.salesPercentage)}%` }}
                    ></div>
                  </div>
                  <div className="flex items-center justify-between text-[11px] text-slate-400">
                    <span>نسبة الإنجاز: <strong className="text-blue-400">{trg.salesPercentage}%</strong></span>
                    <span>متبقي: {trg.remainingSales.toLocaleString('ar-EG')} ج.م</span>
                  </div>
                </div>

                {/* Collection achievement block */}
                <div className="bg-slate-950/60 p-3.5 rounded-2xl border border-slate-800/80 min-w-[220px] space-y-1.5">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-400">تحصيل:</span>
                    <span className="font-bold text-emerald-400">
                      {trg.collectionAchieved.toLocaleString('ar-EG')} / {trg.collectionTarget.toLocaleString('ar-EG')} ج.م
                    </span>
                  </div>
                  <div className="w-full h-2 bg-slate-900 rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-emerald-500 rounded-full"
                      style={{ width: `${Math.min(100, trg.collectionPercentage)}%` }}
                    ></div>
                  </div>
                  <div className="flex items-center justify-between text-[11px] text-slate-400">
                    <span>نسبة التحصيل: <strong className="text-emerald-400">{trg.collectionPercentage}%</strong></span>
                    <span>متبقي: {trg.remainingCollection.toLocaleString('ar-EG')} ج.م</span>
                  </div>
                </div>

                {/* Actions for managers */}
                {isManager && (
                  <div className="flex items-center gap-2 self-end lg:self-center">
                    <button
                      onClick={() => openEditModal(trg)}
                      className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl transition text-xs flex items-center gap-1"
                      title="تعديل الهدف"
                    >
                      <Edit3 className="w-3.5 h-3.5" />
                      <span>تعديل</span>
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Modal: Add or Edit Target */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-lg p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="font-bold text-white text-base flex items-center gap-2">
                <Target className="w-5 h-5 text-amber-400" />
                <span>{editingTarget ? 'تعديل مستهدف المندوب' : 'إدراج مستهدف بيعي وتحصيلي جديد'}</span>
              </h3>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="text-slate-400 hover:text-white"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSaveTarget} className="space-y-3.5 text-xs">
              <div>
                <label className="text-slate-300 font-bold block mb-1">اسم المندوب:</label>
                <input
                  type="text"
                  value={formRepName}
                  onChange={(e) => setFormRepName(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                  required
                />
              </div>

              <div>
                <label className="text-slate-300 font-bold block mb-1">الفرع المعتمد:</label>
                <select
                  value={formBranch}
                  onChange={(e) => setFormBranch(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                >
                  <option value="فرع القاهرة الكبرى">فرع القاهرة الكبرى</option>
                  <option value="فرع الدلتا">فرع الدلتا</option>
                  <option value="فرع الإسكندرية والساحل">فرع الإسكندرية والساحل</option>
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-slate-300 font-bold block mb-1">مستهدف المبيعات (ج.م):</label>
                  <input
                    type="number"
                    value={formSalesTarget}
                    onChange={(e) => setFormSalesTarget(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white font-mono outline-none"
                    required
                  />
                </div>
                <div>
                  <label className="text-slate-300 font-bold block mb-1">المحقق الفعلي (مبيعات):</label>
                  <input
                    type="number"
                    value={formSalesAchieved}
                    onChange={(e) => setFormSalesAchieved(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white font-mono outline-none"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-slate-300 font-bold block mb-1">مستهدف التحصيل (ج.م):</label>
                  <input
                    type="number"
                    value={formCollectionTarget}
                    onChange={(e) => setFormCollectionTarget(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white font-mono outline-none"
                    required
                  />
                </div>
                <div>
                  <label className="text-slate-300 font-bold block mb-1">المحصل الفعلي (خزينة):</label>
                  <input
                    type="number"
                    value={formCollectionAchieved}
                    onChange={(e) => setFormCollectionAchieved(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white font-mono outline-none"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="text-slate-300 font-bold block mb-1">ملاحظات وخطة العمل:</label>
                <textarea
                  value={formNotes}
                  onChange={(e) => setFormNotes(e.target.value)}
                  placeholder="ملاحظات وتوجيهات المشرف للإغلاق الشهري..."
                  rows={2}
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none resize-none"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="bg-slate-800 hover:bg-slate-700 text-slate-300 px-4 py-2 rounded-2xl font-bold transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="bg-amber-500 hover:bg-amber-400 text-slate-950 px-5 py-2 rounded-2xl font-black transition shadow-lg shadow-amber-500/20"
                >
                  حفظ المستهدف
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
