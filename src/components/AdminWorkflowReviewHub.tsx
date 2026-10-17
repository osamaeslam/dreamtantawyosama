import React, { useState, useMemo } from 'react';
import {
  Users,
  ShieldCheck,
  Receipt,
  CheckCircle2,
  XCircle,
  Clock,
  RotateCcw,
  AlertTriangle,
  ArrowRight,
  TrendingUp,
  Boxes,
  Building2,
  Printer,
  FileSpreadsheet,
  Download,
  Search,
  Filter,
  Check,
  Sparkles,
  Info,
  ChevronDown,
  UserCheck,
  UserCog,
  Briefcase,
  Layers,
  ShoppingBag,
  ExternalLink
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { formatCurrency, formatArabicDate } from '../services/invoiceService';
import { Invoice, OrderStatus, UserRole } from '../types';

interface AdminWorkflowReviewHubProps {
  onSwitchToRepView?: () => void;
  onOpenNewOrder?: () => void;
}

export const AdminWorkflowReviewHub: React.FC<AdminWorkflowReviewHubProps> = ({
  onSwitchToRepView,
  onOpenNewOrder,
}) => {
  const {
    invoices,
    currentUser,
    users,
    customers,
    branches,
    approveOrder,
    forwardOrderToManager,
    rejectOrder,
    updateOrderStatus,
    loginAs,
    getVisibleInvoices,
  } = useApp();

  const [activeTab, setActiveTab] = useState<'review_workflow' | 'roles_hierarchy' | 'financial_summary'>('review_workflow');
  const [statusFilter, setStatusFilter] = useState<string>('قيد مراجعة المشرف');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null);
  const [rejectReasonModal, setRejectReasonModal] = useState<string | null>(null);
  const [reasonInput, setReasonInput] = useState('يرجى مراجعة الكميات وسقف الائتمان مع العميل');
  const [actionSuccessNotice, setActionSuccessNotice] = useState<string | null>(null);

  // إحصائيات دورة الفواتير
  const pendingSupervisorCount = invoices.filter(
    (i) => i.status === 'قيد مراجعة المشرف' || i.status === 'قيد المراجعة' || i.status === 'معلقة بانتظار اعتماد الفرع'
  ).length;

  const approvedCount = invoices.filter(
    (i) => i.status === 'معتمدة' || i.status === 'معتمدة ومصروفة من المخزن'
  ).length;

  const rejectedCount = invoices.filter(
    (i) => i.status === 'مرفوضة / ملغاة' || i.status === 'ملغاة'
  ).length;

  // الفواتير المصفاة
  const filteredInvoices = useMemo(() => {
    let list = invoices;
    if (statusFilter !== 'الكل') {
      if (statusFilter === 'قيد مراجعة المشرف') {
        list = list.filter(
          (i) => i.status === 'قيد مراجعة المشرف' || i.status === 'قيد المراجعة' || i.status === 'معلقة بانتظار اعتماد الفرع'
        );
      } else {
        list = list.filter((i) => i.status === statusFilter);
      }
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      list = list.filter(
        (i) =>
          i.customerName?.toLowerCase().includes(q) ||
          i.invoiceNumber?.toLowerCase().includes(q) ||
          i.repName?.toLowerCase().includes(q) ||
          i.branchName?.toLowerCase().includes(q)
      );
    }
    return list;
  }, [invoices, statusFilter, searchQuery]);

  // تنفيذ الاعتماد من المشرف
  const handleSupervisorApprove = (invoice: Invoice) => {
    const res = forwardOrderToManager(invoice.id, 'تمت مراجعة الطلبية واعتمادها من المشرف، محولة للحسابات');
    if (res.success) {
      setActionSuccessNotice(`تم اعتماد طلبية العميل (${invoice.customerName}) بنجاح وتحويلها للإدارة والحسابات ✅`);
      setTimeout(() => setActionSuccessNotice(null), 3000);
    }
  };

  // تنفيذ الاعتماد النهائي من الإدارة
  const handleFinalAdminApprove = (invoice: Invoice) => {
    const res = approveOrder(invoice.id, 'معتمدة نهائياً من الإدارة العامة، جاهزة للصرف من المخزن المركزي');
    if (res.success) {
      setActionSuccessNotice(`تم الاعتماد النهائي للفاتورة #${invoice.invoiceNumber} وصرف إذن المخزن 🏛️`);
      setTimeout(() => setActionSuccessNotice(null), 3000);
    }
  };

  // رفض أو إرجاع للمندوب للتعديل
  const handleRejectOrReturn = () => {
    if (!rejectReasonModal) return;
    const res = rejectOrder(rejectReasonModal, reasonInput);
    if (res.success) {
      setActionSuccessNotice('تم إرجاع الطلبية للمندوب مع تسجيل ملاحظة التعديل ↩️');
      setRejectReasonModal(null);
      setTimeout(() => setActionSuccessNotice(null), 3000);
    }
  };

  return (
    <div className="space-y-5">
      {/* 1. الترويسة الإدارية الاحترافية */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-850 to-indigo-950 text-white p-5 sm:p-6 rounded-3xl border-2 border-indigo-500/40 shadow-2xl flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div className="flex items-center gap-3.5">
          <div className="w-13 h-13 rounded-2xl bg-indigo-500/20 border border-indigo-400/50 flex items-center justify-center text-indigo-400 shrink-0 shadow-inner">
            <Building2 className="w-7 h-7" />
          </div>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="text-lg sm:text-xl font-black text-white">
                منظومة الإدارة والمراجعة الرقابية — مجموعة الطنطاوي
              </h2>
              <span className="bg-indigo-500 text-white text-[10px] font-black px-2.5 py-0.5 rounded-full shadow-sm">
                Management Portal
              </span>
            </div>
            <p className="text-xs text-slate-300 mt-1 max-w-2xl leading-relaxed">
              بوابة مخصصة للإدارة والمشرفين لمراجعة فواتير المناديب، الاعتماد المالي، وتحديد الصلاحيات من المندوب إلى مدير الإدارة (بدون شاشة الكتالوج الاستهلاكية).
            </p>
          </div>
        </div>

        {/* أزرار التجربة الفورية للأدوار */}
        <div className="bg-slate-900/90 p-2 rounded-2xl border border-slate-700 space-y-1.5 w-full md:w-auto">
          <div className="text-[10px] text-slate-400 font-bold px-1">تجربة دور فورية بنقرة واحدة:</div>
          <div className="flex items-center gap-1.5 flex-wrap">
            <button
              onClick={() => {
                const repUser = users.find((u) => u.role === 'sales_rep');
                if (repUser) loginAs(repUser.id);
                if (onSwitchToRepView) onSwitchToRepView();
              }}
              className="px-2.5 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold transition flex items-center gap-1 cursor-pointer shadow-xs"
              title="التبديل لدور مندوب مبيعات لفتح تطبيق الموبايل وكتالوج أمازون"
            >
              <Briefcase className="w-3.5 h-3.5" />
              <span>المندوب (كتالوج الموبايل)</span>
            </button>

            <button
              onClick={() => {
                const supUser = users.find((u) => u.role === 'supervisor');
                if (supUser) loginAs(supUser.id);
                setActiveTab('review_workflow');
              }}
              className="px-2.5 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold transition flex items-center gap-1 cursor-pointer shadow-xs"
              title="التبديل لدور مشرف المناديب لمراجعة واعتماد الفواتير"
            >
              <UserCheck className="w-3.5 h-3.5" />
              <span>مشرف المناديب</span>
            </button>

            <button
              onClick={() => {
                const adminUser = users.find((u) => u.role === 'admin' || u.role === 'developer');
                if (adminUser) loginAs(adminUser.id);
                setActiveTab('review_workflow');
              }}
              className="px-2.5 py-1.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-black transition flex items-center gap-1 cursor-pointer shadow-xs"
              title="التبديل لحساب مدير الإدارة"
            >
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>مدير الإدارة</span>
            </button>
          </div>
        </div>
      </div>

      {/* تبويبات لوحة الإدارة */}
      <div className="flex border-b border-slate-200 bg-white px-4 pt-2 gap-2 text-xs font-bold rounded-2xl shadow-xs">
        <button
          onClick={() => setActiveTab('review_workflow')}
          className={`px-4 py-3 rounded-t-xl transition cursor-pointer flex items-center gap-2 ${
            activeTab === 'review_workflow'
              ? 'bg-indigo-50 text-indigo-900 border-b-2 border-indigo-600 font-black'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          <Receipt className="w-4 h-4 text-indigo-600" />
          <span>مركز مراجعة واعتماد طلبيات وفواتير المناديب</span>
          {pendingSupervisorCount > 0 && (
            <span className="bg-amber-500 text-slate-950 text-[10px] font-black px-2 py-0.2 rounded-full">
              {pendingSupervisorCount} معلقة
            </span>
          )}
        </button>

        <button
          onClick={() => setActiveTab('roles_hierarchy')}
          className={`px-4 py-3 rounded-t-xl transition cursor-pointer flex items-center gap-2 ${
            activeTab === 'roles_hierarchy'
              ? 'bg-indigo-50 text-indigo-900 border-b-2 border-indigo-600 font-black'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          <UserCog className="w-4 h-4 text-indigo-600" />
          <span>تحديد الأدوار والصلاحيات من المندوب لمدير الإدارة</span>
        </button>

        <button
          onClick={() => setActiveTab('financial_summary')}
          className={`px-4 py-3 rounded-t-xl transition cursor-pointer flex items-center gap-2 ${
            activeTab === 'financial_summary'
              ? 'bg-indigo-50 text-indigo-900 border-b-2 border-indigo-600 font-black'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          <TrendingUp className="w-4 h-4 text-emerald-600" />
          <span>مؤشرات المبيعات وتحصيل العملاء</span>
        </button>
      </div>

      {/* إشعار النجاح */}
      {actionSuccessNotice && (
        <div className="bg-emerald-600 text-white p-4 rounded-2xl text-xs sm:text-sm font-bold flex items-center gap-2.5 shadow-lg animate-in fade-in">
          <CheckCircle2 className="w-5 h-5 shrink-0" />
          <span>{actionSuccessNotice}</span>
        </div>
      )}

      {/* المحتوى 1: مركز مراجعة واعتماد الفواتير */}
      {activeTab === 'review_workflow' && (
        <div className="space-y-4">
          {/* كروت الحالة السريعة */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3.5">
            <div
              onClick={() => setStatusFilter('قيد مراجعة المشرف')}
              className={`p-4 rounded-2xl border transition cursor-pointer flex items-center justify-between shadow-xs ${
                statusFilter === 'قيد مراجعة المشرف'
                  ? 'bg-amber-50 border-amber-400 ring-2 ring-amber-400/40'
                  : 'bg-white border-slate-200 hover:border-amber-300'
              }`}
            >
              <div>
                <span className="text-xs font-bold text-amber-900 block">
                  طلبيات قيد مراجعة المشرف
                </span>
                <span className="text-2xl font-black text-amber-600 mt-1 block">
                  {pendingSupervisorCount} طلبية
                </span>
                <span className="text-[10px] text-slate-500 font-semibold">
                  مرسلة عبر زر (حفظ وتحويل للمراجعة)
                </span>
              </div>
              <div className="w-11 h-11 rounded-2xl bg-amber-100 text-amber-700 flex items-center justify-center font-black">
                <Clock className="w-6 h-6" />
              </div>
            </div>

            <div
              onClick={() => setStatusFilter('معتمدة')}
              className={`p-4 rounded-2xl border transition cursor-pointer flex items-center justify-between shadow-xs ${
                statusFilter === 'معتمدة'
                  ? 'bg-emerald-50 border-emerald-400 ring-2 ring-emerald-400/40'
                  : 'bg-white border-slate-200 hover:border-emerald-300'
              }`}
            >
              <div>
                <span className="text-xs font-bold text-emerald-900 block">
                  فواتير معتمدة ومصروفة من المخزن
                </span>
                <span className="text-2xl font-black text-emerald-600 mt-1 block">
                  {approvedCount} فاتورة
                </span>
                <span className="text-[10px] text-slate-500 font-semibold">
                  معتمدة نهائياً برصيد المخزن
                </span>
              </div>
              <div className="w-11 h-11 rounded-2xl bg-emerald-100 text-emerald-700 flex items-center justify-center font-black">
                <CheckCircle2 className="w-6 h-6" />
              </div>
            </div>

            <div
              onClick={() => setStatusFilter('الكل')}
              className={`p-4 rounded-2xl border transition cursor-pointer flex items-center justify-between shadow-xs ${
                statusFilter === 'الكل'
                  ? 'bg-slate-100 border-slate-400 ring-2 ring-slate-400/40'
                  : 'bg-white border-slate-200 hover:border-slate-300'
              }`}
            >
              <div>
                <span className="text-xs font-bold text-slate-700 block">
                  إجمالي فواتير المنظومة
                </span>
                <span className="text-2xl font-black text-slate-900 mt-1 block">
                  {invoices.length} فاتورة
                </span>
                <span className="text-[10px] text-slate-500 font-semibold">
                  كافة الحركات المسجلة
                </span>
              </div>
              <div className="w-11 h-11 rounded-2xl bg-slate-100 text-slate-700 flex items-center justify-center font-black">
                <Receipt className="w-6 h-6" />
              </div>
            </div>
          </div>

          {/* بار البحث والفلترة */}
          <div className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-xs flex flex-col sm:flex-row items-center justify-between gap-3">
            <div className="relative w-full sm:w-96">
              <Search className="w-4 h-4 text-slate-400 absolute right-3 top-2.5" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="ابحث برقم الفاتورة، اسم المندوب، أو العميل..."
                className="w-full bg-slate-50 pr-9 pl-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:border-indigo-500 font-bold"
              />
            </div>

            <div className="flex items-center gap-2 w-full sm:w-auto">
              <span className="text-xs text-slate-500 font-bold whitespace-nowrap">الحالة:</span>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="bg-slate-50 border border-slate-200 text-xs font-bold rounded-xl px-3 py-2 text-slate-800 focus:outline-none focus:border-indigo-500 cursor-pointer"
              >
                <option value="الكل">كل الحالات ({invoices.length})</option>
                <option value="قيد مراجعة المشرف">قيد مراجعة المشرف ({pendingSupervisorCount})</option>
                <option value="معتمدة">معتمدة ({approvedCount})</option>
                <option value="مرفوضة / ملغاة">مرفوضة / معادة للتعديل ({rejectedCount})</option>
              </select>
            </div>
          </div>

          {/* جدول الفواتير المخصصة للمراجعة والاعتماد */}
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
            {filteredInvoices.length === 0 ? (
              <div className="text-center py-16 text-slate-400 space-y-2">
                <Receipt className="w-12 h-12 mx-auto text-slate-300" />
                <div className="font-bold text-xs">لا توجد طلبيات مطابقة للفلتر المحدد</div>
              </div>
            ) : (
              <div className="divide-y divide-slate-100">
                {filteredInvoices.map((inv) => {
                  const cust = customers.find((c) => c.name === inv.customerName || c.code === inv.customerCode);
                  const custBalance = cust?.balance || cust?.currentBalance || 0;
                  const custLimit = cust?.creditLimit || 50000;
                  const isLimitExceeded = custBalance > custLimit;

                  const isPendingSupervisor =
                    inv.status === 'قيد مراجعة المشرف' ||
                    inv.status === 'قيد المراجعة' ||
                    inv.status === 'معلقة بانتظار اعتماد الفرع';

                  return (
                    <div
                      key={inv.id}
                      className="p-4 sm:p-5 hover:bg-slate-50/70 transition flex flex-col lg:flex-row lg:items-center justify-between gap-4"
                    >
                      {/* تفاصيل الطلبية والعميل والمندوب */}
                      <div className="space-y-2 min-w-0 flex-1">
                        <div className="flex items-center gap-2 flex-wrap">
                          <span className="font-mono text-xs font-black bg-slate-900 text-amber-400 px-2.5 py-0.5 rounded-lg">
                            {inv.invoiceNumber}
                          </span>
                          <span className={`text-[10px] font-black px-2.5 py-0.5 rounded-full ${
                            isPendingSupervisor
                              ? 'bg-amber-100 text-amber-800 border border-amber-300'
                              : inv.status === 'معتمدة'
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                              : 'bg-rose-100 text-rose-800 border border-rose-300'
                          }`}>
                            {inv.status}
                          </span>
                          <span className="text-[11px] text-slate-500 font-semibold">
                            {formatArabicDate(inv.date)} {inv.time ? `• ${inv.time}` : ''}
                          </span>
                        </div>

                        <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4">
                          <div className="font-black text-sm text-slate-900 flex items-center gap-1.5">
                            <span>العميل:</span>
                            <span className="text-indigo-950 font-bold">{inv.customerName}</span>
                            {inv.customerCode && (
                              <span className="font-mono text-[10px] text-slate-500">
                                ({inv.customerCode})
                              </span>
                            )}
                          </div>

                          <div className="text-xs text-slate-600">
                            المندوب: <strong className="text-slate-900">{inv.repName || 'المندوب'}</strong> • الفرع: {inv.branchName}
                          </div>
                        </div>

                        {/* فحص سقف الائتمان وملاحظات الطلبية */}
                        <div className="flex items-center gap-3 text-[11px] flex-wrap">
                          <span className="text-slate-500">
                            المديونية الحالية: <strong className={isLimitExceeded ? 'text-rose-600 font-black' : 'text-slate-800'}>
                              {formatCurrency(custBalance)}
                            </strong> / سقف: {formatCurrency(custLimit)}
                          </span>

                          {isLimitExceeded && (
                            <span className="bg-rose-100 text-rose-800 px-2 py-0.2 rounded font-bold flex items-center gap-1">
                              <AlertTriangle className="w-3 h-3 text-rose-600" />
                              <span>تنبيه تجاوز الائتمان!</span>
                            </span>
                          )}

                          {inv.notes && (
                            <span className="text-slate-600 italic bg-slate-100 px-2 py-0.5 rounded">
                              ملاحظة: {inv.notes}
                            </span>
                          )}
                        </div>

                        {/* ملخص الأصناف */}
                        <div className="text-[11px] text-slate-500 pt-1">
                          الأصناف: {inv.items?.length || 0} صنف • إجمالي الكراتين: {inv.totalCartons || 0} كرتونة
                        </div>
                      </div>

                      {/* المبالغ وأزرار الاعتماد السريعة */}
                      <div className="flex flex-col sm:flex-row sm:items-center gap-3 shrink-0 pt-2 lg:pt-0 border-t lg:border-t-0 border-slate-100">
                        <div className="text-left sm:text-right pl-2">
                          <div className="text-[11px] text-slate-500 font-bold">الصافي المطلوب:</div>
                          <div className="text-base sm:text-lg font-black text-emerald-700">
                            {formatCurrency(inv.estimatedGrandTotal || (inv as any).totalAmount || 0)}
                          </div>
                          <div className="text-[10px] text-slate-400">{inv.paymentMethod || 'آجل'}</div>
                        </div>

                        <div className="flex items-center gap-1.5 flex-wrap">
                          {isPendingSupervisor && (
                            <>
                              {/* زر اعتماد المشرف */}
                              <button
                                onClick={() => handleSupervisorApprove(inv)}
                                className="px-3 py-2 rounded-xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-black flex items-center gap-1 transition shadow cursor-pointer"
                                title="اعتماد المشرف وتحويلها للإدارة والحسابات"
                              >
                                <Check className="w-3.5 h-3.5" />
                                <span>اعتماد المشرف ✅</span>
                              </button>

                              {/* زر الاعتماد النهائي للإدارة */}
                              <button
                                onClick={() => handleFinalAdminApprove(inv)}
                                className="px-3 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-black flex items-center gap-1 transition shadow cursor-pointer"
                                title="اعتماد نهائي وإذن صرف من المخزن"
                              >
                                <ShieldCheck className="w-3.5 h-3.5" />
                                <span>اعتماد نهائي 🏛️</span>
                              </button>

                              {/* زر إرجاع للمندوب للتعديل */}
                              <button
                                onClick={() => setRejectReasonModal(inv.id)}
                                className="px-2.5 py-2 rounded-xl bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold border border-rose-200 transition cursor-pointer"
                                title="إرجاع الطلبية للمندوب مع ملاحظة للتعديل"
                              >
                                <span>إرجاع للتعديل ↩️</span>
                              </button>
                            </>
                          )}

                          {inv.status === 'معتمدة' && (
                            <span className="text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-3 py-1.5 rounded-xl flex items-center gap-1">
                              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                              <span>معتمدة بالكامل</span>
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}

      {/* المحتوى 2: شجرة تحديد الأدوار والصلاحيات من المندوب لمدير الإدارة */}
      {activeTab === 'roles_hierarchy' && (
        <div className="space-y-4">
          <div className="bg-white p-5 rounded-3xl border border-slate-200 shadow-xs space-y-4">
            <div>
              <h3 className="font-black text-sm sm:text-base text-slate-900 flex items-center gap-2">
                <UserCog className="w-5 h-5 text-indigo-600" />
                <span>مصفوفة الأدوار والصلاحيات المعتمدة لمجموعة الطنطاوي:</span>
              </h3>
              <p className="text-xs text-slate-500 mt-1">
                تحديد دقيق لاختصاصات كل منصب من المندوب الميداني وحتى مدير الإدارة العامة:
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3.5">
              {/* الدور 1: مندوب مبيعات */}
              <div className="bg-slate-50 p-4 rounded-2xl border-2 border-emerald-500/40 space-y-3 flex flex-col justify-between">
                <div className="space-y-2">
                  <div className="w-9 h-9 rounded-xl bg-emerald-500 text-slate-950 flex items-center justify-center font-black">
                    <Briefcase className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-black text-sm text-slate-900">1. مندوب مبيعات (Sales Rep)</h4>
                    <span className="text-[10px] text-emerald-700 font-bold">واجهة الموبايل والكتالوج</span>
                  </div>
                  <ul className="text-[11px] text-slate-600 space-y-1.5 list-disc list-inside">
                    <li>تصفح كتالوج أمازون الذكي بأسعار الكرتونة والشدة.</li>
                    <li>البحث الذكي عن العملاء بالاسم والكود والباركود.</li>
                    <li>تسجيل الطلبيات والضغط على زر <strong>«حفظ وتحويل للمراجعة»</strong>.</li>
                    <li>تسجيل الحضور والزيارات الميدانية بالـ GPS.</li>
                    <li>طباعة البون الحراري السريع للعميل 80mm.</li>
                  </ul>
                </div>

                <button
                  onClick={() => {
                    const rep = users.find((u) => u.role === 'sales_rep');
                    if (rep) loginAs(rep.id);
                    if (onSwitchToRepView) onSwitchToRepView();
                  }}
                  className="w-full mt-3 py-2 bg-emerald-600 hover:bg-emerald-500 text-white font-bold rounded-xl text-xs transition cursor-pointer text-center"
                >
                  فتح واجهة المندوب ➔
                </button>
              </div>

              {/* الدور 2: مشرف مناديب */}
              <div className="bg-slate-50 p-4 rounded-2xl border-2 border-blue-500/40 space-y-3 flex flex-col justify-between">
                <div className="space-y-2">
                  <div className="w-9 h-9 rounded-xl bg-blue-600 text-white flex items-center justify-center font-black">
                    <UserCheck className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-black text-sm text-slate-900">2. مشرف المناديب (Supervisor)</h4>
                    <span className="text-[10px] text-blue-700 font-bold">المراجعة والاعتماد الميداني</span>
                  </div>
                  <ul className="text-[11px] text-slate-600 space-y-1.5 list-disc list-inside">
                    <li>مراجعة كافة طلبيات مناديب فريقه الواردة فوراً.</li>
                    <li>التحقق من الأسعار والخصومات ومديونية العميل.</li>
                    <li>زر <strong>«اعتماد المشرف وتحويل للإدارة»</strong>.</li>
                    <li>زر <strong>«إرجاع للمندوب للتعديل مع ملاحظة»</strong>.</li>
                    <li>متابعة تارجت المناديب ومسارات الزيارات.</li>
                  </ul>
                </div>

                <button
                  onClick={() => {
                    const sup = users.find((u) => u.role === 'supervisor');
                    if (sup) loginAs(sup.id);
                    setActiveTab('review_workflow');
                  }}
                  className="w-full mt-3 py-2 bg-blue-600 hover:bg-blue-500 text-white font-bold rounded-xl text-xs transition cursor-pointer text-center"
                >
                  تجربة دور المشرف ➔
                </button>
              </div>

              {/* الدور 3: مدير الفرع */}
              <div className="bg-slate-50 p-4 rounded-2xl border-2 border-purple-500/40 space-y-3 flex flex-col justify-between">
                <div className="space-y-2">
                  <div className="w-9 h-9 rounded-xl bg-purple-600 text-white flex items-center justify-center font-black">
                    <Building2 className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-black text-sm text-slate-900">3. مدير الفرع (Branch Manager)</h4>
                    <span className="text-[10px] text-purple-700 font-bold">الرقابة على الفرع والمخزون</span>
                  </div>
                  <ul className="text-[11px] text-slate-600 space-y-1.5 list-disc list-inside">
                    <li>الرقابة على رصيد المخزن المتاح بفرعه.</li>
                    <li>اعتماد تجاوزات الائتمان الاستثنائية للعملاء.</li>
                    <li>طلب توريد من مخزن 6 أكتوبر المركزي عند النواقص.</li>
                    <li>متابعة كشوفات حساب وتحصيل فواتير الفرع.</li>
                  </ul>
                </div>

                <button
                  onClick={() => {
                    const bm = users.find((u) => u.role === 'branch_manager');
                    if (bm) loginAs(bm.id);
                    setActiveTab('review_workflow');
                  }}
                  className="w-full mt-3 py-2 bg-purple-600 hover:bg-purple-500 text-white font-bold rounded-xl text-xs transition cursor-pointer text-center"
                >
                  تجربة دور مدير الفرع ➔
                </button>
              </div>

              {/* الدور 4: مدير الإدارة العامة */}
              <div className="bg-slate-50 p-4 rounded-2xl border-2 border-amber-500/50 space-y-3 flex flex-col justify-between">
                <div className="space-y-2">
                  <div className="w-9 h-9 rounded-xl bg-amber-400 text-slate-950 flex items-center justify-center font-black">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-black text-sm text-slate-900">4. مدير الإدارة / GM / Admin</h4>
                    <span className="text-[10px] text-amber-700 font-bold">القرارات والاعتماد المالي النهائي</span>
                  </div>
                  <ul className="text-[11px] text-slate-600 space-y-1.5 list-disc list-inside">
                    <li>لا يرى شاشة الكتالوج الاستهلاكية (واجهة إدارية خالصة).</li>
                    <li><strong>الاعتماد النهائي وترحيل الفواتير</strong> وإصدار إذن الصرف.</li>
                    <li>تقارير الأرباح، نسب التحصيل، والسيولة النقدية.</li>
                    <li>إدارة شيتات الإكسيل، حسابات المناديب والمشرفين.</li>
                  </ul>
                </div>

                <button
                  onClick={() => {
                    const adm = users.find((u) => u.role === 'admin' || u.role === 'developer');
                    if (adm) loginAs(adm.id);
                    setActiveTab('review_workflow');
                  }}
                  className="w-full mt-3 py-2 bg-amber-400 hover:bg-amber-300 text-slate-950 font-black rounded-xl text-xs transition cursor-pointer text-center"
                >
                  تجربة دور مدير الإدارة ➔
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* المحتوى 3: مؤشرات المبيعات وتحصيل العملاء */}
      {activeTab === 'financial_summary' && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
            <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
              <span className="text-[11px] text-slate-500 font-bold">إجمالي المبيعات المحققة</span>
              <div className="text-xl font-black text-slate-900 mt-1">
                {formatCurrency(
                  invoices.reduce((sum, i) => sum + (i.estimatedGrandTotal || (i as any).totalAmount || 0), 0)
                )}
              </div>
            </div>

            <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
              <span className="text-[11px] text-slate-500 font-bold">إجمالي مديونيات العملاء</span>
              <div className="text-xl font-black text-rose-600 mt-1">
                {formatCurrency(
                  customers.reduce((sum, c) => sum + (c.balance || c.currentBalance || 0), 0)
                )}
              </div>
            </div>

            <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
              <span className="text-[11px] text-slate-500 font-bold">عدد المناديب النشطين</span>
              <div className="text-xl font-black text-slate-900 mt-1">
                {users.filter((u) => u.role === 'sales_rep').length} مندوب
              </div>
            </div>

            <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
              <span className="text-[11px] text-slate-500 font-bold">عدد المشرفين الميدانيين</span>
              <div className="text-xl font-black text-slate-900 mt-1">
                {users.filter((u) => u.role === 'supervisor').length} مشرف
              </div>
            </div>
          </div>
        </div>
      )}

      {/* مودال إرجاع الطلبية للمندوب مع كتابة السبب */}
      {rejectReasonModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-rose-100 text-rose-700 flex items-center justify-center font-black">
                <RotateCcw className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-black text-sm text-slate-900">إرجاع الطلبية للمندوب للتعديل</h4>
                <p className="text-[11px] text-slate-500">سيتم إشعار المندوب فورا بملاحظتك لتعديل الطلبية</p>
              </div>
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1.5">
                ملاحظة التعديل أو سبب الرفض:
              </label>
              <textarea
                value={reasonInput}
                onChange={(e) => setReasonInput(e.target.value)}
                rows={3}
                className="w-full bg-slate-50 border border-slate-300 rounded-xl p-3 text-xs font-bold focus:outline-none focus:border-rose-500"
                placeholder="اكتب ملاحظتك للمندوب هنا..."
              />
            </div>

            <div className="flex items-center gap-2 pt-2">
              <button
                onClick={handleRejectOrReturn}
                className="flex-1 bg-rose-600 hover:bg-rose-500 text-white font-black py-2.5 rounded-xl text-xs transition cursor-pointer"
              >
                تأكيد الإرجاع للمندوب ↩️
              </button>
              <button
                onClick={() => setRejectReasonModal(null)}
                className="px-4 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs cursor-pointer"
              >
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
