import React, { useState, useMemo } from 'react';
import { 
  ClipboardCheck, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  RotateCcw, 
  AlertTriangle, 
  FileText, 
  Printer, 
  Search, 
  Filter, 
  User, 
  Building2, 
  Boxes, 
  TrendingUp, 
  ShieldCheck, 
  ChevronRight, 
  Eye, 
  Check, 
  X,
  Phone,
  Calendar,
  Layers
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Invoice, OrderStatus } from '../types';

export const AdminWorkflowReviewHub: React.FC = () => {
  const { invoices, approveInvoice, rejectInvoice, currentUser, customers } = useApp();
  const [selectedStatus, setSelectedStatus] = useState<string>('الكل');
  const [searchQuery, setSearchQuery] = useState('');
  const [activeInvoice, setActiveInvoice] = useState<Invoice | null>(null);
  const [reviewNote, setReviewNote] = useState('');
  const [actionSuccessMsg, setActionSuccessMsg] = useState<string | null>(null);

  // Status filters
  const statusOptions = ['الكل', 'قيد مراجعة المشرف', 'معتمدة ومصروفة من المخزن', 'مرفوضة'];

  const filteredInvoices = useMemo(() => {
    return invoices.filter((inv) => {
      const matchStatus = selectedStatus === 'الكل' || inv.status === selectedStatus;
      const q = searchQuery.toLowerCase().trim();
      const matchQuery =
        !q ||
        inv.invoiceNumber.toLowerCase().includes(q) ||
        inv.customerName.toLowerCase().includes(q) ||
        inv.salesRepName.toLowerCase().includes(q) ||
        inv.customerCode.toLowerCase().includes(q);
      return matchStatus && matchQuery;
    });
  }, [invoices, selectedStatus, searchQuery]);

  // Summary counts
  const pendingCount = invoices.filter((i) => i.status === 'قيد مراجعة المشرف').length;
  const approvedTotal = invoices
    .filter((i) => i.status === 'معتمدة ومصروفة من المخزن')
    .reduce((acc, i) => acc + i.totalAmount, 0);

  const handleApprove = (inv: Invoice) => {
    approveInvoice(inv.id, reviewNote || 'تمت المراجعة والاعتماد الفوري من الإدارة');
    setActionSuccessMsg(`تم اعتماد الفاتورة (${inv.invoiceNumber}) بنجاح وتحويلها لصرف المخزن ✅`);
    setActiveInvoice(null);
    setReviewNote('');
    setTimeout(() => setActionSuccessMsg(null), 5000);
  };

  const handleReject = (inv: Invoice) => {
    rejectInvoice(inv.id, reviewNote || 'يرجى مراجعة الكميات أو التسعير مع العميل');
    setActionSuccessMsg(`تم إرجاع الفاتورة (${inv.invoiceNumber}) للمندوب للتعديل ↩️`);
    setActiveInvoice(null);
    setReviewNote('');
    setTimeout(() => setActionSuccessMsg(null), 5000);
  };

  return (
    <div className="w-full max-w-6xl mx-auto p-3 sm:p-6 space-y-6">
      {/* Top Banner: Administrative Workflow Focus (No consumer catalog!) */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950/40 to-slate-900 border border-slate-800 rounded-3xl p-5 shadow-2xl">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-xs font-bold text-indigo-400 mb-1">
              <ShieldCheck className="w-4 h-4" />
              لوحة الإدارة والتحكم المركزي • مجموعة الطنطاوي
            </div>
            <h1 className="text-xl sm:text-2xl font-black text-white">
              مركز مراجعة واعتماد طلبيات وفواتير المندوبين 📋
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              واجهة مخصصة للمشرفين ومديري الفروع والإدارة العامة لفحص وتدقيق الفواتير قبل الصرف من المخازن.
            </p>
          </div>

          {/* Quick Metrics */}
          <div className="flex items-center gap-3">
            <div className="bg-slate-950/80 border border-amber-500/40 px-4 py-2.5 rounded-2xl">
              <span className="text-[10px] text-amber-400 font-bold block">بانتظار مراجعة المشرف</span>
              <span className="text-xl font-black text-amber-300">{pendingCount} طلبيات</span>
            </div>
            <div className="bg-slate-950/80 border border-emerald-500/40 px-4 py-2.5 rounded-2xl">
              <span className="text-[10px] text-emerald-400 font-bold block">إجمالي المبيعات المعتمدة</span>
              <span className="text-xl font-black text-emerald-400">
                {approvedTotal.toLocaleString('ar-EG')} ج.م
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Success notification */}
      {actionSuccessMsg && (
        <div className="bg-emerald-950/90 border border-emerald-500/60 p-4 rounded-2xl text-emerald-300 text-sm font-bold flex items-center justify-between shadow-lg">
          <span>{actionSuccessMsg}</span>
          <button onClick={() => setActionSuccessMsg(null)} className="text-xs text-emerald-400 underline">
            إغلاق
          </button>
        </div>
      )}

      {/* Role Hierarchy Overview */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
        <div className="bg-slate-900/80 border border-slate-800 p-3 rounded-2xl">
          <span className="text-[10px] text-blue-400 block font-bold">1. مندوب مبيعات</span>
          <p className="text-slate-300 text-[11px] mt-0.5">تسجيل الزيارات وإنشاء الطلبيات والتحويل للمراجعة</p>
        </div>
        <div className="bg-slate-900/80 border border-slate-800 p-3 rounded-2xl">
          <span className="text-[10px] text-indigo-400 block font-bold">2. مشرف مبيعات</span>
          <p className="text-slate-300 text-[11px] mt-0.5">مراجعة أسعار الأصناف، والتحقق من رصيد العميل</p>
        </div>
        <div className="bg-slate-900/80 border border-slate-800 p-3 rounded-2xl">
          <span className="text-[10px] text-amber-400 block font-bold">3. مدير فرع</span>
          <p className="text-slate-300 text-[11px] mt-0.5">اعتماد استثناءات السقف الائتماني وتوجيه الصرف</p>
        </div>
        <div className="bg-slate-900/80 border border-slate-800 p-3 rounded-2xl">
          <span className="text-[10px] text-emerald-400 block font-bold">4. مدير عام / إدارة</span>
          <p className="text-slate-300 text-[11px] mt-0.5">تقارير الأرباح الشاملة، ومتابعة التحصيلات المركزية</p>
        </div>
      </div>

      {/* Filters & Search Bar */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-slate-900 p-3 rounded-2xl border border-slate-800">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="ابحث برقم الفاتورة، العميل، أو المندوب..."
            className="w-full pr-10 pl-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
          />
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
          {statusOptions.map((st) => (
            <button
              key={st}
              onClick={() => setSelectedStatus(st)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition ${
                selectedStatus === st
                  ? 'bg-indigo-600 text-white shadow'
                  : 'bg-slate-950 text-slate-400 hover:text-white border border-slate-800'
              }`}
            >
              {st}
            </button>
          ))}
        </div>
      </div>

      {/* Invoices List / Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-xl">
        <div className="p-4 border-b border-slate-800 flex items-center justify-between">
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <ClipboardCheck className="w-4 h-4 text-indigo-400" />
            طلبيات المبيعات الواردة ({filteredInvoices.length})
          </h3>
          <span className="text-xs text-slate-400">مرتبة حسب الأحدث</span>
        </div>

        <div className="divide-y divide-slate-800/80">
          {filteredInvoices.length === 0 ? (
            <div className="p-10 text-center text-slate-500 text-xs">
              لا توجد طلبيات مطابقة للبحث أو التصفية الحالية.
            </div>
          ) : (
            filteredInvoices.map((inv) => {
              const isPending = inv.status === 'قيد مراجعة المشرف';
              const isApproved = inv.status === 'معتمدة ومصروفة من المخزن';
              const isRejected = inv.status === 'مرفوضة';

              return (
                <div
                  key={inv.id}
                  className="p-4 hover:bg-slate-850/50 transition flex flex-col md:flex-row md:items-center justify-between gap-4"
                >
                  <div className="flex items-start gap-3.5">
                    <div
                      className={`w-10 h-10 rounded-2xl flex items-center justify-center shrink-0 border ${
                        isPending
                          ? 'bg-amber-500/20 text-amber-400 border-amber-500/30'
                          : isApproved
                          ? 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30'
                          : 'bg-rose-500/20 text-rose-400 border-rose-500/30'
                      }`}
                    >
                      {isPending ? (
                        <Clock className="w-5 h-5" />
                      ) : isApproved ? (
                        <CheckCircle2 className="w-5 h-5" />
                      ) : (
                        <XCircle className="w-5 h-5" />
                      )}
                    </div>

                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-mono font-bold text-white">{inv.invoiceNumber}</span>
                        <span
                          className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                            isPending
                              ? 'bg-amber-950 text-amber-400 border border-amber-700/50'
                              : isApproved
                              ? 'bg-emerald-950 text-emerald-400 border border-emerald-700/50'
                              : 'bg-rose-950 text-rose-400 border border-rose-700/50'
                          }`}
                        >
                          {inv.status}
                        </span>
                      </div>

                      <div className="text-sm font-bold text-slate-200 mt-1">{inv.customerName}</div>

                      <div className="flex flex-wrap items-center gap-3 text-xs text-slate-400 mt-1">
                        <span>المندوب: <strong className="text-slate-300">{inv.salesRepName}</strong></span>
                        <span>•</span>
                        <span>{inv.date} {inv.time}</span>
                        <span>•</span>
                        <span>{inv.totalCartons} كرتونة ({inv.totalPieces} قطعة)</span>
                      </div>

                      {inv.notes && (
                        <div className="text-[11px] text-amber-400/90 mt-1">
                          ملاحظة المندوب: {inv.notes}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Actions & Price */}
                  <div className="flex items-center justify-between md:justify-end gap-3 pt-2 md:pt-0 border-t md:border-t-0 border-slate-800">
                    <div className="text-right md:text-left">
                      <span className="text-[10px] text-slate-400 block">إجمالي الفاتورة</span>
                      <span className="text-base font-black text-emerald-400">
                        {inv.totalAmount.toLocaleString('ar-EG')} ج.م
                      </span>
                    </div>

                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => setActiveInvoice(inv)}
                        className="px-3 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold flex items-center gap-1 transition"
                      >
                        <Eye className="w-3.5 h-3.5" />
                        <span>فحص الفاتورة</span>
                      </button>

                      {isPending && (
                        <>
                          <button
                            onClick={() => handleApprove(inv)}
                            className="px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold flex items-center gap-1 shadow-lg shadow-emerald-600/20 transition"
                          >
                            <Check className="w-3.5 h-3.5" />
                            <span>اعتماد وصرف</span>
                          </button>
                          <button
                            onClick={() => handleReject(inv)}
                            className="p-2 rounded-xl bg-rose-600/20 hover:bg-rose-600/40 text-rose-300 border border-rose-500/30 transition"
                            title="إرجاع للمندوب للتعديل"
                          >
                            <RotateCcw className="w-3.5 h-3.5" />
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Invoice Detail & Approval Modal */}
      {activeInvoice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-slate-950/85 backdrop-blur-md animate-in fade-in">
          <div className="w-full max-w-3xl bg-slate-900 border border-slate-700 rounded-3xl shadow-2xl p-6 flex flex-col max-h-[92vh]">
            <div className="flex items-center justify-between pb-4 border-b border-slate-800">
              <div>
                <span className="text-xs text-slate-400">مراجعة تفاصيل الطلبية</span>
                <h3 className="text-lg font-bold text-white flex items-center gap-2">
                  <span>{activeInvoice.invoiceNumber}</span>
                  <span className="text-xs bg-slate-800 text-indigo-400 px-2 py-0.5 rounded-full font-mono">
                    {activeInvoice.customerCode}
                  </span>
                </h3>
              </div>
              <button
                onClick={() => setActiveInvoice(null)}
                className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Invoice Meta Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 py-4 text-xs border-b border-slate-800">
              <div>
                <span className="text-slate-400 block text-[10px]">العميل:</span>
                <span className="font-bold text-white">{activeInvoice.customerName}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px]">المندوب المسؤول:</span>
                <span className="font-bold text-slate-200">{activeInvoice.salesRepName}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px]">تاريخ ووقت الإنشاء:</span>
                <span className="text-slate-200">{activeInvoice.date} {activeInvoice.time}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px]">طريقة الدفع:</span>
                <span className="font-bold text-amber-400">{activeInvoice.paymentMethod}</span>
              </div>
            </div>

            {/* Line Items Table */}
            <div className="py-4 overflow-y-auto flex-1">
              <h4 className="text-xs font-bold text-slate-300 mb-2">أصناف الطلبية:</h4>
              <table className="w-full text-right text-xs">
                <thead>
                  <tr className="text-slate-400 border-b border-slate-800 pb-2">
                    <th className="py-2">الصنف</th>
                    <th className="py-2 text-center">الكراتين</th>
                    <th className="py-2 text-center">القطع</th>
                    <th className="py-2">سعر الكرتونة</th>
                    <th className="py-2 text-left">الإجمالي</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {activeInvoice.items.map((item, idx) => (
                    <tr key={idx} className="hover:bg-slate-800/30">
                      <td className="py-2.5">
                        <span className="font-bold text-white block">{item.productName}</span>
                        <span className="text-[10px] text-slate-500 font-mono">{item.productCode}</span>
                      </td>
                      <td className="py-2.5 text-center font-bold text-slate-200">{item.quantityCartons}</td>
                      <td className="py-2.5 text-center text-slate-400">{item.totalPieces}</td>
                      <td className="py-2.5 text-slate-300">{item.cartonPrice.toLocaleString('ar-EG')} ج.م</td>
                      <td className="py-2.5 text-left font-bold text-emerald-400">
                        {item.total.toLocaleString('ar-EG')} ج.م
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Total Summary */}
            <div className="p-3 bg-slate-950/70 border border-slate-800 rounded-2xl flex items-center justify-between text-xs mb-4">
              <div>
                <span className="text-slate-400">إجمالي الكراتين: </span>
                <strong className="text-white">{activeInvoice.totalCartons} كرتونة</strong>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-slate-300 font-bold">صافي الفاتورة:</span>
                <span className="text-lg font-black text-emerald-400">
                  {activeInvoice.totalAmount.toLocaleString('ar-EG')} ج.م
                </span>
              </div>
            </div>

            {/* Supervisor Notes & Actions */}
            {activeInvoice.status === 'قيد مراجعة المشرف' && (
              <div className="space-y-3 pt-2">
                <input
                  type="text"
                  value={reviewNote}
                  onChange={(e) => setReviewNote(e.target.value)}
                  placeholder="أدخل ملاحظات الاعتماد أو سبب الإرجاع للمندوب..."
                  className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
                />

                <div className="flex items-center gap-3">
                  <button
                    onClick={() => handleApprove(activeInvoice)}
                    className="flex-1 py-3 rounded-2xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-lg shadow-emerald-600/30 transition"
                  >
                    <Check className="w-4 h-4" />
                    اعتماد وصرف من المخزن ✅
                  </button>
                  <button
                    onClick={() => handleReject(activeInvoice)}
                    className="py-3 px-5 rounded-2xl bg-rose-600/20 hover:bg-rose-600/30 text-rose-300 border border-rose-500/40 font-bold text-xs flex items-center justify-center gap-1.5 transition"
                  >
                    <RotateCcw className="w-4 h-4" />
                    إرجاع للمندوب للتعديل ↩️
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
