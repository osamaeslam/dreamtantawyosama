import React, { useState, useMemo } from 'react';
import { 
  DollarSign, 
  TrendingUp, 
  Calendar, 
  CheckCircle2, 
  AlertCircle, 
  Clock, 
  Plus, 
  Edit3, 
  Filter, 
  Lock, 
  Building2, 
  Users, 
  FileText, 
  ArrowUpRight, 
  Check, 
  X,
  CreditCard,
  Sparkles,
  PieChart
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { CollectionForecastRecord, ForecastStatus } from '../types';

export const CollectionForecastView: React.FC = () => {
  const { 
    currentUser, 
    forecasts, 
    addForecast, 
    updateForecast, 
    customers 
  } = useApp();

  const isSalesRep = currentUser.role === 'sales_rep';
  const isSupervisor = currentUser.role === 'supervisor';
  const isManager = currentUser.role === 'branch_manager' || currentUser.role === 'admin';

  // Filters
  const [selectedWeek, setSelectedWeek] = useState<number | 'all'>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);

  // Accessible customers for this user
  const accessibleCustomers = useMemo(() => {
    if (isSalesRep) {
      return customers.filter((c) => c.repName === currentUser.name || !c.repName);
    }
    if (isSupervisor) {
      return customers.filter((c) => !c.branchName || c.branchName === currentUser.branchName);
    }
    return customers;
  }, [customers, currentUser, isSalesRep, isSupervisor]);

  // Form State
  const [formCustId, setFormCustId] = useState(accessibleCustomers[0]?.id || '');
  const [formWeek, setFormWeek] = useState<number>(1);
  const [formCollAmount, setFormCollAmount] = useState('35000');
  const [formSalesAmount, setFormSalesAmount] = useState('50000');
  const [formExpectedDate, setFormExpectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [formNotes, setFormNotes] = useState('');

  // Strict RBAC: Sales Reps ONLY see their own customers' forecasts!
  const visibleForecasts = useMemo(() => {
    return forecasts.filter((f) => {
      if (isSalesRep && f.repName !== currentUser.name && f.repId !== currentUser.id) {
        return false;
      }
      if (isSupervisor && f.branchName && f.branchName !== currentUser.branchName) {
        return false;
      }
      const matchWeek = selectedWeek === 'all' || f.weekIndex === selectedWeek;
      const matchStatus = selectedStatus === 'all' || f.status === selectedStatus;
      return matchWeek && matchStatus;
    });
  }, [forecasts, currentUser, isSalesRep, isSupervisor, selectedWeek, selectedStatus]);

  // Calculations
  const totalForecasted = visibleForecasts.reduce((sum, f) => sum + (f.collectionForecast || 0), 0);
  const totalActualCollected = visibleForecasts.reduce((sum, f) => sum + (f.actualCollected || 0), 0);
  const totalRemaining = Math.max(0, totalForecasted - totalActualCollected);
  const collectionPercentage = totalForecasted > 0 ? Math.round((totalActualCollected / totalForecasted) * 100) : 0;

  // Breakdown by Week
  const weekBreakdown = useMemo(() => {
    const weeks = [1, 2, 3, 4];
    return weeks.map((w) => {
      const weekRecords = visibleForecasts.filter((f) => f.weekIndex === w);
      const target = weekRecords.reduce((sum, f) => sum + (f.collectionForecast || 0), 0);
      const actual = weekRecords.reduce((sum, f) => sum + (f.actualCollected || 0), 0);
      return {
        week: w,
        target,
        actual,
        pct: target > 0 ? Math.round((actual / target) * 100) : 0,
        count: weekRecords.length,
      };
    });
  }, [visibleForecasts]);

  const handleCreateForecast = (e: React.FormEvent) => {
    e.preventDefault();
    const customer = accessibleCustomers.find((c) => c.id === formCustId) || accessibleCustomers[0];
    if (!customer) return;

    addForecast({
      monthKey: '2026-10',
      weekIndex: Number(formWeek),
      repId: currentUser.id,
      repName: currentUser.name,
      branchName: currentUser.branchName,
      customerId: customer.id,
      customerCode: customer.code,
      customerName: customer.name,
      collectionForecast: Number(formCollAmount) || 0,
      salesForecast: Number(formSalesAmount) || 0,
      actualCollected: 0,
      status: 'submitted',
      expectedDate: formExpectedDate,
      notes: formNotes || 'توقع تحصيل مسجل من المندوب',
    });

    setIsAddModalOpen(false);
    setFormNotes('');
  };

  const handleMarkAsCollected = (forecast: CollectionForecastRecord) => {
    const entered = prompt(
      `تأكيد تحصيل المبلغ من ${forecast.customerName}:\nأدخل المبلغ المحصل فعلياً (ج.م):`,
      String(forecast.collectionForecast)
    );
    if (entered !== null) {
      const val = Number(entered) || 0;
      updateForecast(forecast.id, {
        actualCollected: val,
        status: 'collected',
      });
    }
  };

  const getStatusBadge = (status: ForecastStatus) => {
    switch (status) {
      case 'collected':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
            <CheckCircle2 className="w-3 h-3" />
            تم التحصيل
          </span>
        );
      case 'approved':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-blue-500/15 text-blue-400 border border-blue-500/30">
            معتمد من المشرف
          </span>
        );
      case 'submitted':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-amber-500/15 text-amber-400 border border-amber-500/30">
            قيد المتابعة
          </span>
        );
      case 'delayed':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-rose-500/15 text-rose-400 border border-rose-500/30">
            مؤجل / متعثر
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-slate-500/15 text-slate-400">
            مسودة
          </span>
        );
    }
  };

  return (
    <div className="w-full max-w-7xl mx-auto p-3 sm:p-6 space-y-6 font-['Cairo',sans-serif]">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-900 to-emerald-950/40 border border-slate-800 rounded-3xl p-5 shadow-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-bold text-emerald-400 mb-1">
            <DollarSign className="w-4 h-4 text-emerald-400" />
            <span>نظام تخطيط وتوقع السيولة النقدية (Collection Forecast)</span>
            <span className="text-[10px] bg-emerald-500/10 text-emerald-300 px-2 py-0.5 rounded-full border border-emerald-500/20 font-mono">
              أكتوبر 2026
            </span>
          </div>
          <h1 className="text-xl sm:text-2xl font-black text-white flex items-center gap-2">
            خطة متوقع التحصيل والتدفقات النقدية
            {isSalesRep && (
              <span className="text-xs font-normal text-amber-300 bg-amber-950/60 px-2.5 py-1 rounded-xl border border-amber-500/30">
                محفظة المندوب الشخصية
              </span>
            )}
          </h1>
          <p className="text-xs text-slate-400 mt-1 max-w-2xl">
            جدولة استحقاقات المعارض وتجار الجملة أسبوعياً لتوقع السيولة الداخلة للخزينة وضمان انتظام دورة رأس المال.
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2.5 flex-wrap">
          <button
            onClick={() => {
              if (accessibleCustomers.length > 0) {
                setFormCustId(accessibleCustomers[0].id);
              }
              setIsAddModalOpen(true);
            }}
            className="bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2 rounded-2xl text-xs font-black flex items-center gap-1.5 shadow-lg shadow-emerald-600/30 transition"
          >
            <Plus className="w-4 h-4" />
            <span>إضافة توقع تحصيل لعميل</span>
          </button>
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
              ? `🔒 سرية البيانات مفعلة: تعرض شاشة متوقع التحصيل عملاء محفظتك فقط (${currentUser.name})، لا يمكنك الاطلاع على شيكات أو توقعات المناديب الآخرين.`
              : isSupervisor
              ? `🏢 رؤية إشرافية: تعرض توقعات تحصيل فرعك المعتمد (${currentUser.branchName}).`
              : `👑 رؤية الإدارة العامة: رؤية شاملة للسيولة النقدية المتوقعة لكافة الفروع والعملاء.`}
          </span>
        </div>
        <span className="font-bold bg-slate-900/80 px-2.5 py-1 rounded-xl text-[11px] whitespace-nowrap border border-slate-700">
          {visibleForecasts.length} بند تحصيل
        </span>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl space-y-2 relative overflow-hidden">
          <span className="text-xs text-slate-400 font-bold block">إجمالي المتوقع تحصيله</span>
          <div className="text-2xl font-black text-white">
            {totalForecasted.toLocaleString('ar-EG')} <span className="text-xs font-normal text-slate-400">ج.م</span>
          </div>
          <p className="text-[11px] text-slate-400">
            إجمالي الشيكات والنقدية المتفق عليها لهذا الشهر
          </p>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl space-y-2 relative overflow-hidden">
          <span className="text-xs text-slate-400 font-bold block">تم تحصيله فعلياً بالخزينة</span>
          <div className="text-2xl font-black text-emerald-400">
            {totalActualCollected.toLocaleString('ar-EG')} <span className="text-xs font-normal text-slate-400">ج.م</span>
          </div>
          <div className="flex items-center justify-between text-[11px] text-slate-400 pt-1">
            <span>نسبة التحقق:</span>
            <strong className="text-emerald-400">{collectionPercentage}%</strong>
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl space-y-2 relative overflow-hidden">
          <span className="text-xs text-slate-400 font-bold block">متبقي قيد المتابعة</span>
          <div className="text-2xl font-black text-amber-300">
            {totalRemaining.toLocaleString('ar-EG')} <span className="text-xs font-normal text-slate-400">ج.م</span>
          </div>
          <p className="text-[11px] text-slate-400">
            مواعيد استحقاق جارية خلال الأسابيع القادمة
          </p>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl space-y-2 relative overflow-hidden">
          <span className="text-xs text-slate-400 font-bold block">جاهزية السيولة النقدية</span>
          <div className="text-2xl font-black text-blue-400">
            {collectionPercentage >= 75 ? 'ممتازة ⚡' : 'متوسطة ⚠️'}
          </div>
          <p className="text-[11px] text-slate-400">
            تغطي التزامات الموردين والمصانع بنجاح
          </p>
        </div>
      </div>

      {/* 4-Weeks Forecast Timeline Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {weekBreakdown.map((wb) => {
          const isSelected = selectedWeek === wb.week;
          return (
            <button
              key={wb.week}
              onClick={() => setSelectedWeek(isSelected ? 'all' : wb.week)}
              className={`p-4 rounded-3xl border text-right transition flex flex-col justify-between ${
                isSelected 
                  ? 'bg-emerald-950/40 border-emerald-500 shadow-xl' 
                  : 'bg-slate-900 border-slate-800 hover:border-slate-700'
              }`}
            >
              <div className="flex items-center justify-between w-full mb-2">
                <span className="text-xs font-bold text-white">
                  الأسبوع {wb.week}
                </span>
                <span className="text-[10px] bg-slate-800 px-2 py-0.5 rounded-full text-slate-300 font-mono">
                  {wb.count} عملاء
                </span>
              </div>
              <div className="text-lg font-black text-emerald-400">
                {wb.target.toLocaleString('ar-EG')} <span className="text-xs font-normal text-slate-400">ج.م</span>
              </div>
              <div className="w-full bg-slate-950 h-1.5 rounded-full overflow-hidden my-2">
                <div 
                  className="bg-emerald-500 h-full rounded-full"
                  style={{ width: `${Math.min(100, wb.pct)}%` }}
                ></div>
              </div>
              <div className="flex items-center justify-between text-[11px] text-slate-400 w-full">
                <span>المحصل: {wb.actual.toLocaleString('ar-EG')} ج.م</span>
                <span className="font-bold text-emerald-400">{wb.pct}%</span>
              </div>
            </button>
          );
        })}
      </div>

      {/* Forecast Items Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl">
        <div className="p-5 border-b border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-slate-950/40">
          <div>
            <h3 className="font-bold text-white text-base flex items-center gap-2">
              <Calendar className="w-4 h-4 text-emerald-400" />
              <span>جدول استحقاقات وتوقعات تحصيل العملاء</span>
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              مواعيد سداد الشيكات والدفعات النقدية مع إمكانية التحديث الفوري
            </p>
          </div>

          {/* Filter by Status */}
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-400">الحالة:</span>
            {['all', 'submitted', 'collected', 'delayed'].map((st) => (
              <button
                key={st}
                onClick={() => setSelectedStatus(st)}
                className={`px-3 py-1 rounded-xl text-xs font-bold transition ${
                  selectedStatus === st
                    ? 'bg-emerald-600 text-white'
                    : 'bg-slate-800 text-slate-400 hover:text-white'
                }`}
              >
                {st === 'all' ? 'الكل' : st === 'submitted' ? 'قيد المتابعة' : st === 'collected' ? 'تم التحصيل' : 'مؤجل'}
              </button>
            ))}
          </div>
        </div>

        {/* List of Forecast Records */}
        <div className="divide-y divide-slate-800/80">
          {visibleForecasts.length === 0 ? (
            <div className="p-8 text-center text-slate-400 text-xs">
              لا توجد بنود تحصيل مسجلة تطابق التصفية الحالية.
            </div>
          ) : (
            visibleForecasts.map((fc) => (
              <div
                key={fc.id}
                className="p-5 hover:bg-slate-800/30 transition flex flex-col lg:flex-row lg:items-center justify-between gap-4"
              >
                {/* Customer Details */}
                <div className="space-y-1 min-w-[260px]">
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-white text-sm">{fc.customerName}</span>
                    <span className="text-[10px] font-mono bg-slate-800 text-blue-400 px-2 py-0.5 rounded-lg">
                      {fc.customerCode}
                    </span>
                    {getStatusBadge(fc.status)}
                  </div>
                  <div className="text-xs text-slate-400 flex items-center gap-2">
                    <span>المندوب: <strong className="text-slate-300">{fc.repName}</strong></span>
                    <span>•</span>
                    <span className="bg-slate-800/60 px-2 py-0.5 rounded-md text-[11px]">الأسبوع {fc.weekIndex}</span>
                  </div>
                  {fc.notes && (
                    <p className="text-xs text-slate-400 italic mt-1">
                      {fc.notes}
                    </p>
                  )}
                </div>

                {/* Amounts block */}
                <div className="bg-slate-950/60 p-3 rounded-2xl border border-slate-800/80 flex items-center gap-4 text-xs">
                  <div>
                    <span className="text-slate-400 block text-[10px]">المبلغ المتوقع:</span>
                    <strong className="text-emerald-400 text-sm font-mono font-black">
                      {fc.collectionForecast.toLocaleString('ar-EG')} ج.م
                    </strong>
                  </div>
                  <div className="border-r border-slate-800 pr-4">
                    <span className="text-slate-400 block text-[10px]">المحصل فعلياً:</span>
                    <strong className="text-white text-sm font-mono font-bold">
                      {(fc.actualCollected || 0).toLocaleString('ar-EG')} ج.م
                    </strong>
                  </div>
                  {fc.expectedDate && (
                    <div className="border-r border-slate-800 pr-4">
                      <span className="text-slate-400 block text-[10px]">تاريخ الاستحقاق:</span>
                      <span className="text-slate-300 text-xs font-mono">{fc.expectedDate}</span>
                    </div>
                  )}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2 self-end lg:self-center">
                  {fc.status !== 'collected' && (
                    <button
                      onClick={() => handleMarkAsCollected(fc)}
                      className="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold flex items-center gap-1 shadow transition"
                    >
                      <Check className="w-3.5 h-3.5" />
                      <span>تسجيل تحصيل</span>
                    </button>
                  )}
                  {isManager && fc.status !== 'delayed' && (
                    <button
                      onClick={() => updateForecast(fc.id, { status: 'delayed' })}
                      className="px-2.5 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs transition"
                    >
                      تأجيل
                    </button>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Add Forecast Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-lg p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="font-bold text-white text-base flex items-center gap-2">
                <Plus className="w-5 h-5 text-emerald-400" />
                <span>إدراج توقع تحصيل نقدي لعميل</span>
              </h3>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="text-slate-400 hover:text-white"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateForecast} className="space-y-3.5 text-xs">
              <div>
                <label className="text-slate-300 font-bold block mb-1">اختر العميل:</label>
                <select
                  value={formCustId}
                  onChange={(e) => setFormCustId(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                  required
                >
                  {accessibleCustomers.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name} ({c.code}) - الرصيد: {c.currentBalance.toLocaleString()} ج.م
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-slate-300 font-bold block mb-1">الأسبوع المستهدف:</label>
                  <select
                    value={formWeek}
                    onChange={(e) => setFormWeek(Number(e.target.value))}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                  >
                    <option value={1}>الأسبوع الأول (1 - 7)</option>
                    <option value={2}>الأسبوع الثاني (8 - 14)</option>
                    <option value={3}>الأسبوع الثالث (15 - 21)</option>
                    <option value={4}>الأسبوع الرابع (22 - 31)</option>
                  </select>
                </div>
                <div>
                  <label className="text-slate-300 font-bold block mb-1">تاريخ الاستحقاق المتوقع:</label>
                  <input
                    type="date"
                    value={formExpectedDate}
                    onChange={(e) => setFormExpectedDate(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-slate-300 font-bold block mb-1">المبلغ المتوقع تحصيله (ج.م):</label>
                  <input
                    type="number"
                    value={formCollAmount}
                    onChange={(e) => setFormCollAmount(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white font-mono outline-none"
                    required
                  />
                </div>
                <div>
                  <label className="text-slate-300 font-bold block mb-1">قيمة المبيعات المتوقعة (ج.م):</label>
                  <input
                    type="number"
                    value={formSalesAmount}
                    onChange={(e) => setFormSalesAmount(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white font-mono outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="text-slate-300 font-bold block mb-1">طريقة السداد / ملاحظات الشيك:</label>
                <textarea
                  value={formNotes}
                  onChange={(e) => setFormNotes(e.target.value)}
                  placeholder="شيك بنكي مقبول الدفع / سداد نقدي عند التوريد..."
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
                  className="bg-emerald-600 hover:bg-emerald-500 text-white px-5 py-2 rounded-2xl font-black transition shadow-lg shadow-emerald-600/30"
                >
                  حفظ في الخطة
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
