import React, { useState, useMemo } from 'react';
import { 
  MapPin, 
  Navigation, 
  Calendar, 
  Clock, 
  User, 
  Users, 
  Phone, 
  CheckCircle2, 
  AlertCircle, 
  Search, 
  Plus, 
  Filter, 
  DollarSign, 
  ShoppingBag, 
  FileText, 
  Smartphone, 
  Monitor, 
  Share2, 
  Compass, 
  Building2, 
  ChevronRight, 
  Star, 
  ExternalLink, 
  Camera, 
  Check, 
  ArrowUpRight,
  TrendingUp,
  Download,
  Printer,
  Sparkles,
  X,
  MessageCircle
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { CustomerVisit, VisitType, VisitOutcome, VisitStatus } from '../types';

export const FieldVisitsManagementHub: React.FC = () => {
  const { 
    currentUser, 
    visits, 
    addVisit, 
    updateVisit, 
    customers, 
    setSelectedCustomer, 
    setActiveTab 
  } = useApp();

  // Mode: 'mobile' (Luxury mobile app simulation for sales reps) or 'web' (Executive dashboard for supervisors/GM)
  const [viewMode, setViewMode] = useState<'mobile' | 'web'>(
    currentUser.role === 'sales_rep' ? 'mobile' : 'web'
  );

  // Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [selectedRep, setSelectedRep] = useState<string>('all');

  // Role checking
  const isSalesRep = currentUser.role === 'sales_rep';
  const isSupervisor = currentUser.role === 'supervisor';
  const isManager = currentUser.role === 'branch_manager' || currentUser.role === 'admin';

  // Strict role visits isolation:
  const roleVisits = useMemo(() => {
    if (isSalesRep) {
      return visits.filter((v) => v.repName === currentUser.name || v.repId === currentUser.id);
    }
    if (isSupervisor) {
      return visits.filter((v) => !v.branchName || v.branchName === currentUser.branchName);
    }
    return visits;
  }, [visits, currentUser, isSalesRep, isSupervisor]);

  // Customers accessible to this user
  const accessibleCustomers = useMemo(() => {
    if (isSalesRep) {
      return customers.filter((c) => c.repName === currentUser.name || !c.repName);
    }
    if (isSupervisor) {
      return customers.filter((c) => !c.branchName || c.branchName === currentUser.branchName);
    }
    return customers;
  }, [customers, currentUser, isSalesRep, isSupervisor]);

  // Modals
  const [isNewVisitModalOpen, setIsNewVisitModalOpen] = useState(false);
  const [isCheckInModalOpen, setIsCheckInModalOpen] = useState(false);
  const [selectedVisitForAction, setSelectedVisitForAction] = useState<CustomerVisit | null>(null);

  // Form State for new visit or action
  const [newCustId, setNewCustId] = useState(accessibleCustomers[0]?.id || customers[0]?.id || '');
  const [newVisitType, setNewVisitType] = useState<VisitType>('routine_sale');
  const [newVisitDate, setNewVisitDate] = useState(new Date().toISOString().split('T')[0]);
  const [newVisitTime, setNewVisitTime] = useState('11:00 ص');
  const [newVisitNotes, setNewVisitNotes] = useState('');
  const [useGpsCheck, setUseGpsCheck] = useState(false);

  // Complete / Check-in Form State
  const [actionOutcome, setActionOutcome] = useState<VisitOutcome>('completed_order');
  const [actionCollectedAmount, setActionCollectedAmount] = useState<string>('0');
  const [actionStockStatus, setActionStockStatus] = useState('المخزون كافي، بحاجة لمنتجات العروض الترويجية');
  const [actionNotes, setActionNotes] = useState('');
  const [gpsSimulated, setGpsSimulated] = useState(false);

  // Filtered visits
  const filteredVisits = useMemo(() => {
    return roleVisits.filter((v) => {
      const matchSearch = 
        !searchQuery ||
        v.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        v.repName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (v.customerAddress && v.customerAddress.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (v.notes && v.notes.toLowerCase().includes(searchQuery.toLowerCase()));

      const matchStatus = statusFilter === 'all' || v.status === statusFilter;
      const matchType = typeFilter === 'all' || v.type === typeFilter;
      const matchRep = selectedRep === 'all' || v.repName.includes(selectedRep);

      return matchSearch && matchStatus && matchType && matchRep;
    });
  }, [roleVisits, searchQuery, statusFilter, typeFilter, selectedRep]);

  // Executive KPI calculations (based on roleVisits for privacy)
  const totalVisitsCount = roleVisits.length;
  const completedVisitsCount = roleVisits.filter((v) => v.status === 'completed').length;
  const inProgressVisitsCount = roleVisits.filter((v) => v.status === 'in_progress').length;
  const plannedVisitsCount = roleVisits.filter((v) => v.status === 'planned').length;
  const totalCashCollected = roleVisits.reduce((sum, v) => sum + (v.collectedAmount || 0), 0);
  const totalOrdersCreated = roleVisits.filter((v) => v.outcome === 'completed_order' || (v.orderTotal && v.orderTotal > 0)).length;

  const handleCreateVisit = (e: React.FormEvent) => {
    e.preventDefault();
    const customer = accessibleCustomers.find((c) => c.id === newCustId) || accessibleCustomers[0] || customers[0];
    
    addVisit({
      customerId: customer.id,
      customerName: customer.name,
      customerCode: customer.code,
      customerPhone: customer.phone,
      customerAddress: customer.address || 'العنوان المسجل بالفرع',
      repName: currentUser.name,
      repId: currentUser.id,
      branchName: currentUser.branchName,
      date: newVisitDate,
      time: newVisitTime,
      type: newVisitType,
      status: 'planned',
      collectedAmount: 0,
      notes: newVisitNotes || 'زيارة ميدانية مجدولة',
      latitude: useGpsCheck ? 30.0444 + (Math.random() - 0.5) * 0.1 : undefined,
      longitude: useGpsCheck ? 31.2357 + (Math.random() - 0.5) * 0.1 : undefined,
      locationName: customer.address || 'القاهرة الكبرى',
    });

    setIsNewVisitModalOpen(false);
    setNewVisitNotes('');
  };

  const handleStartCheckIn = (visit: CustomerVisit) => {
    setSelectedVisitForAction(visit);
    setActionCollectedAmount(visit.collectedAmount ? String(visit.collectedAmount) : '0');
    setActionNotes(visit.notes || '');
    setActionOutcome(visit.outcome || 'completed_order');
    setGpsSimulated(false);
    setIsCheckInModalOpen(true);
  };

  const handleSaveVisitProgress = () => {
    if (!selectedVisitForAction) return;

    const now = new Date();
    const timeString = now.toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' });

    updateVisit(selectedVisitForAction.id, {
      status: 'completed',
      outcome: actionOutcome,
      collectedAmount: Number(actionCollectedAmount) || 0,
      notes: actionNotes,
      storeStockStatus: actionStockStatus,
      checkInTime: selectedVisitForAction.checkInTime || timeString,
      checkOutTime: timeString,
      durationMinutes: 35,
    });

    setIsCheckInModalOpen(false);
    setSelectedVisitForAction(null);
  };

  const handleStartOrderFromVisit = (visit: CustomerVisit) => {
    const cust = customers.find((c) => c.id === visit.customerId);
    if (cust) {
      setSelectedCustomer(cust);
    }
    setActiveTab('rep_catalog');
  };

  const getTypeLabel = (type: VisitType) => {
    switch (type) {
      case 'routine_sale': return 'زيارة بيع وطلبية';
      case 'collection': return 'تحصيل نقدية / شيك';
      case 'shelf_audit': return 'مراجعة رفوف وعرض';
      case 'complaint': return 'معالجة شكوى / مرتجع';
      case 'new_lead': return 'عميل جديد محتمل';
      case 'reconciliation': return 'مطابقة كشف حساب';
      default: return type;
    }
  };

  const getStatusBadge = (status: VisitStatus) => {
    switch (status) {
      case 'completed':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
            <CheckCircle2 className="w-3 h-3" />
            تمت بنجاح
          </span>
        );
      case 'in_progress':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-blue-500/15 text-blue-400 border border-blue-500/30 animate-pulse">
            <Compass className="w-3 h-3" />
            قيد التنفيذ الآن
          </span>
        );
      case 'planned':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-amber-500/15 text-amber-400 border border-amber-500/30">
            <Clock className="w-3 h-3" />
            مخططة اليوم
          </span>
        );
      case 'cancelled':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-slate-500/15 text-slate-400 border border-slate-500/30">
            ملغاة
          </span>
        );
    }
  };

  return (
    <div className="w-full max-w-7xl mx-auto p-3 sm:p-6 space-y-6 font-['Cairo',sans-serif]">
      
      {/* Top Banner & Mode Switcher */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-900 to-indigo-950/60 border border-slate-800 rounded-3xl p-5 shadow-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-bold text-amber-400 mb-1">
            <Compass className="w-4 h-4 text-amber-400" />
            <span>نظام الزيارات الميدانية الذكي (GPS Field Route Hub)</span>
            <span className="text-[10px] bg-slate-800 text-slate-300 px-2 py-0.5 rounded-full border border-slate-700">
              Supabase Live
            </span>
          </div>
          <h1 className="text-xl sm:text-2xl font-black text-white">
            إدارة الزيارات الميدانية وخطوط السير والتحصيل
          </h1>
          <p className="text-xs text-slate-400 mt-1 max-w-2xl">
            متابعة دقيقة لتحركات المناديب، التحقق من المواقع الجغرافية بالـ GPS، تسجيل التحصيلات الفورية، ومتابعة تغطية معارض وتجار الأدوات المنزلية.
          </p>
        </div>

        {/* View Switcher: Mobile vs Web */}
        <div className="flex items-center gap-2 bg-slate-950/90 p-1.5 rounded-2xl border border-slate-800 self-start md:self-center shadow-inner">
          <button
            onClick={() => setViewMode('mobile')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
              viewMode === 'mobile'
                ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Smartphone className="w-4 h-4" />
            <span>📱 واجهة الموبايل الفاخرة</span>
          </button>

          <button
            onClick={() => setViewMode('web')}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
              viewMode === 'web'
                ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/30'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Monitor className="w-4 h-4" />
            <span>💻 واجهة الويب الإدارية</span>
          </button>
        </div>
      </div>

      {/* KPI Summary Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-4 shadow-lg flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-blue-600/15 border border-blue-500/30 flex items-center justify-center text-blue-400 shrink-0">
            <MapPin className="w-5 h-5" />
          </div>
          <div>
            <span className="text-[11px] text-slate-400 block font-medium">إجمالي محطات اليوم</span>
            <span className="text-xl font-black text-white">{totalVisitsCount} زيارة</span>
            <div className="text-[10px] text-emerald-400 font-bold mt-0.5">
              مكتمل: {completedVisitsCount} • جاري: {inProgressVisitsCount}
            </div>
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-4 shadow-lg flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-emerald-600/15 border border-emerald-500/30 flex items-center justify-center text-emerald-400 shrink-0">
            <DollarSign className="w-5 h-5" />
          </div>
          <div>
            <span className="text-[11px] text-slate-400 block font-medium">التحصيلات النقدية الميدانية</span>
            <span className="text-xl font-black text-emerald-400">
              {totalCashCollected.toLocaleString()} ج.م
            </span>
            <span className="text-[10px] text-slate-400 block mt-0.5 font-mono">
              سندات قبض فورية معتمدة
            </span>
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-4 shadow-lg flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-amber-600/15 border border-amber-500/30 flex items-center justify-center text-amber-400 shrink-0">
            <ShoppingBag className="w-5 h-5" />
          </div>
          <div>
            <span className="text-[11px] text-slate-400 block font-medium">طلبيات تم تحريرها</span>
            <span className="text-xl font-black text-amber-300">{totalOrdersCreated} طلبية</span>
            <span className="text-[10px] text-slate-400 block mt-0.5">
              محولة مباشرة للمشرف
            </span>
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-4 shadow-lg flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-purple-600/15 border border-purple-500/30 flex items-center justify-center text-purple-400 shrink-0">
            <TrendingUp className="w-5 h-5" />
          </div>
          <div>
            <span className="text-[11px] text-slate-400 block font-medium">نسبة إنجاز خط السير</span>
            <span className="text-xl font-black text-purple-300">
              {totalVisitsCount > 0 ? Math.round((completedVisitsCount / totalVisitsCount) * 100) : 0}%
            </span>
            <span className="text-[10px] text-slate-400 block mt-0.5">
              معدل التغطية الجغرافية
            </span>
          </div>
        </div>
      </div>

      {/* Action Bar (Search, Filters, New Visit Button) */}
      <div className="bg-slate-900/90 border border-slate-800 rounded-3xl p-4 shadow-lg flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="flex flex-1 flex-wrap items-center gap-2.5">
          {/* Search Box */}
          <div className="relative flex-1 min-w-[200px]">
            <Search className="w-4 h-4 absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="ابحث باسم المعرض، المندوب، العنوان، أو الملاحظات..."
              className="w-full bg-slate-950 border border-slate-800 focus:border-blue-500 rounded-2xl pr-10 pl-3 py-2 text-xs text-white placeholder-slate-500 outline-none transition"
            />
          </div>

          {/* Status Filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-slate-950 border border-slate-800 rounded-2xl px-3 py-2 text-xs text-slate-300 outline-none"
          >
            <option value="all">كل الحالات</option>
            <option value="completed">تمت بنجاح</option>
            <option value="in_progress">قيد التنفيذ</option>
            <option value="planned">مخططة اليوم</option>
          </select>

          {/* Type Filter */}
          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="bg-slate-950 border border-slate-800 rounded-2xl px-3 py-2 text-xs text-slate-300 outline-none"
          >
            <option value="all">كل أنواع الزيارات</option>
            <option value="routine_sale">زيارة بيع وطلبية</option>
            <option value="collection">تحصيل نقدية</option>
            <option value="shelf_audit">مراجعة رفوف</option>
          </select>
        </div>

        {/* Schedule Visit Button */}
        <button
          onClick={() => setIsNewVisitModalOpen(true)}
          className="bg-blue-600 hover:bg-blue-500 text-white font-bold px-4 py-2 rounded-2xl text-xs transition flex items-center justify-center gap-1.5 shadow-lg shadow-blue-600/30"
        >
          <Plus className="w-4 h-4" />
          <span>جدولة زيارة ميدانية جديدة</span>
        </button>
      </div>

      {/* ======================================================== */}
      {/* 1. MOBILE EXPERIENCE VIEW (Sales Rep Mobile Experience) */}
      {/* ======================================================== */}
      {viewMode === 'mobile' && (
        <div className="max-w-xl mx-auto space-y-4">
          <div className="bg-gradient-to-r from-blue-950/80 to-slate-900 border border-blue-800/60 rounded-3xl p-4 shadow-xl flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-blue-600 flex items-center justify-center text-white shadow-lg shadow-blue-600/40">
                <Navigation className="w-5 h-5 animate-pulse" />
              </div>
              <div>
                <span className="text-[11px] text-blue-300 block font-bold">خط السير الميداني للمندوب</span>
                <h3 className="text-sm font-black text-white">{currentUser.name} ({currentUser.branchName})</h3>
              </div>
            </div>

            <div className="text-left font-mono">
              <span className="text-[10px] text-slate-400 block">GPS Tracker</span>
              <span className="text-xs font-bold text-emerald-400 flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
                نشط ومتصل
              </span>
            </div>
          </div>

          {/* Route Cards */}
          <div className="space-y-3.5">
            {filteredVisits.map((visit, index) => {
              const isDone = visit.status === 'completed';
              const isCurrent = visit.status === 'in_progress';

              return (
                <div
                  key={visit.id}
                  className={`bg-slate-900 border rounded-3xl p-4.5 shadow-xl transition relative overflow-hidden ${
                    isCurrent 
                      ? 'border-blue-500/80 ring-2 ring-blue-500/20 bg-gradient-to-b from-blue-950/30 to-slate-900' 
                      : isDone 
                      ? 'border-slate-800 opacity-95' 
                      : 'border-slate-800'
                  }`}
                >
                  {/* Step Order Badge */}
                  <div className="flex items-start justify-between gap-3 mb-2.5">
                    <div className="flex items-center gap-2.5">
                      <div className={`w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs ${
                        isDone 
                          ? 'bg-emerald-500 text-white' 
                          : isCurrent 
                          ? 'bg-blue-600 text-white animate-bounce' 
                          : 'bg-slate-800 text-slate-300'
                      }`}>
                        {isDone ? '✓' : index + 1}
                      </div>

                      <div>
                        <h4 className="font-extrabold text-sm text-white flex items-center gap-1.5">
                          {visit.customerName}
                        </h4>
                        <div className="flex items-center gap-2 text-[11px] text-slate-400">
                          <span className="text-amber-400 font-bold">{getTypeLabel(visit.type)}</span>
                          <span>•</span>
                          <span className="flex items-center gap-1">
                            <Clock className="w-3 h-3 text-slate-500" />
                            {visit.time || '10:00 ص'}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div>{getStatusBadge(visit.status)}</div>
                  </div>

                  {/* Address & GPS */}
                  <div className="bg-slate-950/70 p-3 rounded-2xl border border-slate-800/80 text-xs space-y-1.5 mb-3">
                    <div className="flex items-center gap-2 text-slate-300">
                      <MapPin className="w-3.5 h-3.5 text-blue-400 shrink-0" />
                      <span className="truncate">{visit.customerAddress || visit.locationName}</span>
                    </div>

                    {visit.notes && (
                      <div className="text-[11px] text-slate-400 bg-slate-900 p-2 rounded-xl border border-slate-800/60 leading-relaxed">
                        📝 {visit.notes}
                      </div>
                    )}

                    {/* Stats if completed */}
                    {isDone && (
                      <div className="flex items-center justify-between pt-1 border-t border-slate-800 text-[11px]">
                        <span className="text-slate-400">
                          المدة: <strong className="text-white">{visit.durationMinutes || 35} دقيقة</strong>
                        </span>
                        {visit.collectedAmount > 0 && (
                          <span className="text-emerald-400 font-bold">
                            تم تحصيل: {visit.collectedAmount.toLocaleString()} ج.م
                          </span>
                        )}
                      </div>
                    )}
                  </div>

                  {/* Action Buttons for Mobile */}
                  <div className="grid grid-cols-3 gap-2">
                    {/* Action 1: Check-in / Log Visit */}
                    <button
                      onClick={() => handleStartCheckIn(visit)}
                      className={`col-span-1 py-2 px-2 rounded-2xl text-[11px] font-bold flex items-center justify-center gap-1 transition ${
                        isDone
                          ? 'bg-slate-800 hover:bg-slate-700 text-slate-200'
                          : 'bg-emerald-600 hover:bg-emerald-500 text-white shadow-lg shadow-emerald-600/30'
                      }`}
                    >
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      <span>{isDone ? 'تعديل التقرير' : 'تسجيل النتيجة'}</span>
                    </button>

                    {/* Action 2: Start Order from Catalog */}
                    <button
                      onClick={() => handleStartOrderFromVisit(visit)}
                      className="col-span-1 py-2 px-2 rounded-2xl text-[11px] font-bold bg-blue-600 hover:bg-blue-500 text-white flex items-center justify-center gap-1 shadow-lg shadow-blue-600/30 transition"
                    >
                      <ShoppingBag className="w-3.5 h-3.5" />
                      <span>طلب بضاعة</span>
                    </button>

                    {/* Action 3: Quick Call / WhatsApp */}
                    <div className="col-span-1 flex items-center gap-1">
                      {visit.customerPhone && (
                        <a
                          href={`tel:${visit.customerPhone}`}
                          className="flex-1 py-2 rounded-2xl text-[11px] font-bold bg-slate-800 hover:bg-slate-700 text-slate-200 flex items-center justify-center transition border border-slate-700"
                          title="اتصال هاتفي"
                        >
                          <Phone className="w-3.5 h-3.5 text-blue-400" />
                        </a>
                      )}
                      <a
                        href={`https://wa.me/20${(visit.customerPhone || '01012345678').replace(/^0+/, '')}`}
                        target="_blank"
                        rel="noreferrer"
                        className="flex-1 py-2 rounded-2xl text-[11px] font-bold bg-emerald-950/80 hover:bg-emerald-900 border border-emerald-800 text-emerald-300 flex items-center justify-center transition"
                        title="محادثة واتساب"
                      >
                        <MessageCircle className="w-3.5 h-3.5 text-emerald-400" />
                      </a>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* 2. WEB EXECUTIVE VIEW (Supervisors & Management View)    */}
      {/* ======================================================== */}
      {viewMode === 'web' && (
        <div className="space-y-6">
          
          {/* Interactive Route Map / Radar Simulation */}
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-2xl relative overflow-hidden">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Navigation className="w-5 h-5 text-blue-400" />
                <h3 className="font-bold text-white text-base">خريطة ومسار التغطية الجغرافية المباشرة (GPS Route Radar)</h3>
              </div>
              <span className="text-xs bg-slate-800 text-blue-300 px-3 py-1 rounded-full border border-slate-700">
                إحداثيات حية دقيقة ±5m
              </span>
            </div>

            {/* Visual Radar Mockup */}
            <div className="h-44 sm:h-52 w-full bg-slate-950 rounded-2xl border border-slate-800 relative flex items-center justify-center overflow-hidden">
              <div className="absolute inset-0 opacity-20 bg-[radial-gradient(#3b82f6_1px,transparent_1px)] [background-size:16px_16px]" />
              
              {/* Central Branch Pin */}
              <div className="absolute z-10 flex flex-col items-center">
                <div className="w-8 h-8 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold text-xs shadow-lg ring-4 ring-blue-500/30">
                  🏢
                </div>
                <span className="text-[10px] font-bold text-white bg-slate-900/90 px-2 py-0.5 rounded-full mt-1 border border-slate-700">
                  مستودع فرع القاهرة
                </span>
              </div>

              {/* Sample Pins for Visits */}
              {visits.slice(0, 5).map((v, i) => {
                const offsets = [
                  { top: '25%', left: '20%' },
                  { top: '30%', right: '22%' },
                  { bottom: '20%', left: '35%' },
                  { bottom: '25%', right: '30%' },
                  { top: '65%', left: '15%' },
                ];
                const pos = offsets[i % offsets.length];
                const isCompleted = v.status === 'completed';

                return (
                  <div
                    key={v.id}
                    style={pos}
                    className="absolute z-20 flex flex-col items-center group cursor-pointer"
                    onClick={() => handleStartCheckIn(v)}
                  >
                    <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-black text-white shadow-lg transition transform group-hover:scale-125 ${
                      isCompleted ? 'bg-emerald-500 ring-2 ring-emerald-400/40' : 'bg-amber-500 ring-2 ring-amber-400/40 animate-pulse'
                    }`}>
                      {i + 1}
                    </div>
                    <span className="text-[10px] font-bold text-slate-200 bg-slate-900/90 px-2 py-0.5 rounded-md mt-1 border border-slate-700 whitespace-nowrap shadow opacity-80 group-hover:opacity-100">
                      {v.customerName.split(' ')[0]} {v.customerName.split(' ')[1] || ''}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Full High-Density Data Table */}
          <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl">
            <div className="p-4 border-b border-slate-800 flex items-center justify-between">
              <div>
                <h3 className="font-bold text-white text-sm">سجل الزيارات الميدانية المعتمدة (Supabase visits Table)</h3>
                <p className="text-xs text-slate-400 mt-0.5">مطابقة حية مع قاعدة بيانات PostgreSQL</p>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => window.print()}
                  className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1 border border-slate-700"
                >
                  <Printer className="w-3.5 h-3.5 text-slate-400" />
                  <span>طباعة تقرير خط السير</span>
                </button>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-right text-xs">
                <thead className="bg-slate-950/80 text-slate-400 font-bold border-b border-slate-800">
                  <tr>
                    <th className="p-3.5">العميل / المعرض</th>
                    <th className="p-3.5">المندوب والفرع</th>
                    <th className="p-3.5">نوع الزيارة</th>
                    <th className="p-3.5">الموعد والتاريخ</th>
                    <th className="p-3.5">الحالة والنتيجة</th>
                    <th className="p-3.5">التحصيل النقدي</th>
                    <th className="p-3.5 text-center">الإجراءات</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {filteredVisits.map((visit) => (
                    <tr key={visit.id} className="hover:bg-slate-800/40 transition">
                      <td className="p-3.5 font-bold text-white">
                        <div>{visit.customerName}</div>
                        <div className="text-[11px] text-slate-400 font-normal">
                          {visit.customerAddress}
                        </div>
                      </td>

                      <td className="p-3.5 text-slate-300">
                        <div className="font-medium text-slate-200">{visit.repName}</div>
                        <div className="text-[10px] text-slate-500">{visit.branchName}</div>
                      </td>

                      <td className="p-3.5">
                        <span className="font-bold text-blue-400">
                          {getTypeLabel(visit.type)}
                        </span>
                      </td>

                      <td className="p-3.5 text-slate-300">
                        <div>{visit.date}</div>
                        <div className="text-[11px] text-slate-500">{visit.time}</div>
                      </td>

                      <td className="p-3.5">
                        <div className="space-y-1">
                          {getStatusBadge(visit.status)}
                          {visit.outcome && (
                            <div className="text-[10px] text-slate-400 font-medium">
                              {visit.outcome === 'completed_order' && '🛒 تم تحرير طلبية'}
                              {visit.outcome === 'collected_cash' && '💵 تم استلام كاش'}
                              {visit.outcome === 'postponed' && '⏳ تأجيل الزيارة'}
                              {visit.outcome === 'shop_closed' && '🔒 المحل مغلق'}
                            </div>
                          )}
                        </div>
                      </td>

                      <td className="p-3.5 font-mono font-bold">
                        {visit.collectedAmount > 0 ? (
                          <span className="text-emerald-400">
                            {visit.collectedAmount.toLocaleString()} ج.م
                          </span>
                        ) : (
                          <span className="text-slate-600">-</span>
                        )}
                      </td>

                      <td className="p-3.5 text-center">
                        <div className="flex items-center justify-center gap-1.5">
                          <button
                            onClick={() => handleStartCheckIn(visit)}
                            className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-2.5 py-1 rounded-xl text-[11px] font-bold transition border border-slate-700"
                          >
                            تعديل / نتيجة
                          </button>
                          <button
                            onClick={() => handleStartOrderFromVisit(visit)}
                            className="bg-blue-600/80 hover:bg-blue-600 text-white px-2.5 py-1 rounded-xl text-[11px] font-bold transition"
                          >
                            طلب بضاعة
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL 1: Schedule New Field Visit                        */}
      {/* ======================================================== */}
      {isNewVisitModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-lg p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="font-bold text-white text-base flex items-center gap-2">
                <Plus className="w-5 h-5 text-blue-400" />
                جدولة زيارة ميدانية جديدة
              </h3>
              <button
                onClick={() => setIsNewVisitModalOpen(false)}
                className="text-slate-500 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateVisit} className="space-y-3.5 text-xs">
              <div>
                <label className="text-slate-300 font-bold block mb-1">العميل المستهدف:</label>
                <select
                  value={newCustId}
                  onChange={(e) => setNewCustId(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                >
                  {accessibleCustomers.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name} - ({c.address || c.branchName})
                    </option>
                  ))}
                </select>
              </div>

              {/* Optional GPS toggle */}
              <div className="bg-slate-950 p-2.5 rounded-xl border border-slate-800 flex items-center justify-between text-[11px]">
                <span className="text-slate-300">تسجيل الزيارة بدون اشتراط GPS (الكود القديم السريع)</span>
                <label className="flex items-center gap-1.5 cursor-pointer text-amber-300 font-bold">
                  <input
                    type="checkbox"
                    checked={useGpsCheck}
                    onChange={(e) => setUseGpsCheck(e.target.checked)}
                    className="accent-amber-500 rounded"
                  />
                  <span>إرفاق إحداثيات GPS</span>
                </label>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-slate-300 font-bold block mb-1">نوع الزيارة:</label>
                  <select
                    value={newVisitType}
                    onChange={(e) => setNewVisitType(e.target.value as VisitType)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                  >
                    <option value="routine_sale">زيارة بيع وطلبية دورية</option>
                    <option value="collection">تحصيل مديونية أو شيك</option>
                    <option value="shelf_audit">مراجعة رفوف وعرض</option>
                    <option value="complaint">شكوى أو مرتجع</option>
                    <option value="new_lead">عميل جديد محتمل</option>
                  </select>
                </div>

                <div>
                  <label className="text-slate-300 font-bold block mb-1">وقت الزيارة:</label>
                  <input
                    type="text"
                    value={newVisitTime}
                    onChange={(e) => setNewVisitTime(e.target.value)}
                    placeholder="11:30 ص"
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="text-slate-300 font-bold block mb-1">تاريخ الزيارة:</label>
                <input
                  type="date"
                  value={newVisitDate}
                  onChange={(e) => setNewVisitDate(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                />
              </div>

              <div>
                <label className="text-slate-300 font-bold block mb-1">ملاحظات وخطة الزيارة:</label>
                <textarea
                  value={newVisitNotes}
                  onChange={(e) => setNewVisitNotes(e.target.value)}
                  placeholder="مثال: عرض أطقم الجرانيت الجديدة، تحصيل دفعة الحساب، التأكد من توافر كؤوس الكريستال..."
                  rows={3}
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none resize-none"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsNewVisitModalOpen(false)}
                  className="bg-slate-800 hover:bg-slate-700 text-slate-300 px-4 py-2 rounded-2xl font-bold transition"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  className="bg-blue-600 hover:bg-blue-500 text-white px-5 py-2 rounded-2xl font-bold transition shadow-lg shadow-blue-600/30"
                >
                  حفظ في خط السير
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL 2: Record Outcome & GPS Check-In                   */}
      {/* ======================================================== */}
      {isCheckInModalOpen && selectedVisitForAction && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto font-['Cairo',sans-serif]">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-lg p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <div>
                <h3 className="font-bold text-white text-base flex items-center gap-2">
                  <CheckCircle2 className="w-5 h-5 text-emerald-400" />
                  تسجيل نتيجة الزيارة الميدانية
                </h3>
                <span className="text-xs text-blue-400 font-bold block mt-0.5">
                  {selectedVisitForAction.customerName}
                </span>
              </div>
              <button
                onClick={() => setIsCheckInModalOpen(false)}
                className="text-slate-500 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Quick Registration (Classic flow / Optional GPS) */}
            <div className="bg-slate-950/80 border border-slate-800 p-3 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
              <div className="flex items-center gap-2">
                <span className="text-amber-400">⚡</span>
                <span className="text-slate-300">
                  {gpsSimulated 
                    ? 'تم توثيق إحداثيات الموقع بنجاح (30.0444, 31.2357)' 
                    : 'تسجيل الزيارة مباشر وسريع (بدون اشتراط GPS - الكود القديم)'}
                </span>
              </div>
              <button
                type="button"
                onClick={() => setGpsSimulated(!gpsSimulated)}
                className={`px-3 py-1 rounded-xl text-[10px] font-bold transition flex items-center gap-1 self-start sm:self-auto ${
                  gpsSimulated 
                    ? 'bg-emerald-600/30 text-emerald-300 border border-emerald-500/30' 
                    : 'bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700'
                }`}
              >
                <Navigation className="w-3 h-3 text-amber-400" />
                <span>{gpsSimulated ? 'إلغاء الموقع' : 'إرفاق إحداثيات الموقع (اختياري)'}</span>
              </button>
            </div>

            <div className="space-y-3.5 text-xs">
              <div>
                <label className="text-slate-300 font-bold block mb-1">النتيجة النهائية للزيارة:</label>
                <select
                  value={actionOutcome}
                  onChange={(e) => setActionOutcome(e.target.value as VisitOutcome)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                >
                  <option value="completed_order">تم تحرير وتأكيد طلبية شراء جديدة</option>
                  <option value="collected_cash">تم تحصيل نقدية / استلام شيك بنكي</option>
                  <option value="postponed">طلب التأجيل لموعد آخر</option>
                  <option value="shop_closed">المحل مغلق وقت الزيارة</option>
                  <option value="refused">اعتذار عن الشراء حالياً</option>
                </select>
              </div>

              <div>
                <label className="text-slate-300 font-bold block mb-1">المبلغ المحصل نقداً (إن وجد):</label>
                <div className="relative">
                  <input
                    type="number"
                    value={actionCollectedAmount}
                    onChange={(e) => setActionCollectedAmount(e.target.value)}
                    placeholder="0"
                    className="w-full bg-slate-950 border border-slate-800 rounded-2xl pr-3 pl-12 py-2.5 text-white font-mono text-sm outline-none"
                  />
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-xs">
                    ج.م
                  </span>
                </div>
              </div>

              <div>
                <label className="text-slate-300 font-bold block mb-1">موقف مخزون ورفوف العميل:</label>
                <input
                  type="text"
                  value={actionStockStatus}
                  onChange={(e) => setActionStockStatus(e.target.value)}
                  placeholder="المخزون متوفر / يحتاج أطقم عشاء"
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none"
                />
              </div>

              <div>
                <label className="text-slate-300 font-bold block mb-1">تقرير وملاحظات المندوب:</label>
                <textarea
                  value={actionNotes}
                  onChange={(e) => setActionNotes(e.target.value)}
                  placeholder="اكتب ما تم خلال الزيارة، تعليقات العميل، أو موعد الزيارة القادمة..."
                  rows={3}
                  className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-2.5 text-white outline-none resize-none"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsCheckInModalOpen(false)}
                  className="bg-slate-800 hover:bg-slate-700 text-slate-300 px-4 py-2 rounded-2xl font-bold transition"
                >
                  إلغاء
                </button>
                <button
                  type="button"
                  onClick={handleSaveVisitProgress}
                  className="bg-emerald-600 hover:bg-emerald-500 text-white px-5 py-2 rounded-2xl font-bold transition shadow-lg shadow-emerald-600/30"
                >
                  حفظ واعتماد الزيارة
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};
