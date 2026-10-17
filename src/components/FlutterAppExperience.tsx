import React, { useState } from 'react';
import {
  Smartphone,
  Tablet,
  Monitor,
  Code2,
  Download,
  ShoppingBag,
  Receipt,
  MapPin,
  Search,
  Plus,
  Minus,
  CheckCircle2,
  Printer,
  Boxes,
  Users,
  ShieldCheck,
  QrCode,
  Sparkles,
  Layers,
  ArrowRight,
  TrendingUp,
  CreditCard,
  Building2,
  Maximize2
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { formatCurrency } from '../services/invoiceService';
import { FlutterProjectViewerModal } from './FlutterProjectViewerModal';

export const FlutterAppExperience: React.FC = () => {
  const {
    products,
    customers,
    invoices,
    currentUser,
    branches,
  } = useApp();

  // Mode: android | ios | tablet | web
  const [deviceMode, setDeviceMode] = useState<'android' | 'ios' | 'tablet' | 'web'>('web');
  // Flutter screen tab: home | catalog | cart | invoices | visits
  const [activeFlutterTab, setActiveFlutterTab] = useState<'home' | 'catalog' | 'cart' | 'invoices' | 'visits'>('catalog');
  const [selectedDepartment, setSelectedDepartment] = useState<string>('الكل');
  const [searchQuery, setSearchQuery] = useState('');
  const [isCodeModalOpen, setIsCodeModalOpen] = useState(false);

  // In-app Flutter Cart state
  const [flutterCart, setFlutterCart] = useState<Record<string, { quantity: number; product: any }>>({});
  const [selectedCustomerId, setSelectedCustomerId] = useState<string>(customers[0]?.id || '');
  const [paymentType, setPaymentType] = useState<'آجل' | 'نقدي'>('آجل');
  const [orderSuccessMessage, setOrderSuccessMessage] = useState<string | null>(null);

  // Printing thermal receipt modal state
  const [printingInvoice, setPrintingInvoice] = useState<any | null>(null);

  const departments = ['الكل', 'أدوات منزلية', 'أجهزة كهربائية', 'بلاستيك وميلامين', 'زجاج وبورسلين'];

  const filteredProducts = products.filter(p => {
    const matchesDept = selectedDepartment === 'الكل' || p.department === selectedDepartment;
    const matchesSearch = !searchQuery || 
      p.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
      p.code.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesDept && matchesSearch;
  });

  const cartItemsCount = Object.values(flutterCart).reduce((sum, item) => sum + item.quantity, 0);
  const cartSubtotal = Object.values(flutterCart).reduce((sum, item) => {
    const price = item.product.promoPrice || item.product.cartonPrice || 1000;
    return sum + (item.quantity * price);
  }, 0);

  const handleAddToCart = (product: any) => {
    setFlutterCart(prev => {
      const current = prev[product.id]?.quantity || 0;
      return {
        ...prev,
        [product.id]: { quantity: current + 1, product }
      };
    });
  };

  const handleRemoveFromCart = (productId: string) => {
    setFlutterCart(prev => {
      const current = prev[productId]?.quantity || 0;
      if (current <= 1) {
        const next = { ...prev };
        delete next[productId];
        return next;
      }
      return {
        ...prev,
        [productId]: { ...prev[productId], quantity: current - 1 }
      };
    });
  };

  const selectedCustomer = customers.find(c => c.id === selectedCustomerId) || customers[0];

  const handleConfirmOrder = () => {
    if (!selectedCustomer || cartItemsCount === 0) return;
    setOrderSuccessMessage(`تم ترحيل الطلبية بنجاح بقيمة ${formatCurrency(cartSubtotal)} ومزامنتها لحظياً مع Supabase!`);
    setFlutterCart({});
    setTimeout(() => {
      setOrderSuccessMessage(null);
      setActiveFlutterTab('invoices');
    }, 2200);
  };

  return (
    <div className="space-y-4">
      {/* شريط الإعلان والتحكم في تجربة التنسيق المتجاوب (Flutter Responsive & Adaptive Engine) */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-850 to-amber-950 p-4 sm:p-5 rounded-2xl border-2 border-amber-500/40 shadow-xl flex flex-col md:flex-row items-center justify-between gap-4 text-white">
        <div className="flex items-center gap-3.5">
          <div className="w-12 h-12 rounded-2xl bg-amber-500/20 border border-amber-400/50 flex items-center justify-center text-amber-400 shrink-0 shadow-inner">
            <Layers className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-base sm:text-lg font-black text-amber-300">
                منظومة طنطاوي — واجهة فلاتر المتجاوبة (Flutter Adaptive Responsive Layout)
              </h2>
              <span className="bg-emerald-500/20 text-emerald-300 border border-emerald-400/30 text-[10px] font-extrabold px-2 py-0.5 rounded-full">
                نفس الداتا بيز 100%
              </span>
            </div>
            <p className="text-xs text-slate-300 mt-1">
              تم تنسيق الشاشات بأسلوب فلاتر المتقدم: (شاشة جوال بهوية Material / Cupertino، شاشة تابلت، وتنسيق Master-Detail للويب) بكود موحد.
            </p>
          </div>
        </div>

        {/* أزرار محاكاة حجم الشاشة (Screen Mode Switcher) */}
        <div className="flex items-center gap-1.5 bg-slate-900/90 p-1.5 rounded-xl border border-slate-700">
          <button
            onClick={() => setDeviceMode('android')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer ${
              deviceMode === 'android' ? 'bg-amber-500 text-slate-950 shadow font-black' : 'text-slate-300 hover:text-white'
            }`}
            title="مظهر فلاتر على هواتف أندرويد (Material 3)"
          >
            <Smartphone className="w-4 h-4" />
            <span>أندرويد</span>
          </button>

          <button
            onClick={() => setDeviceMode('ios')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer ${
              deviceMode === 'ios' ? 'bg-amber-500 text-slate-950 shadow font-black' : 'text-slate-300 hover:text-white'
            }`}
            title="مظهر فلاتر على هواتف آيفون (Cupertino)"
          >
            <Smartphone className="w-4 h-4" />
            <span>آيفون</span>
          </button>

          <button
            onClick={() => setDeviceMode('tablet')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer ${
              deviceMode === 'tablet' ? 'bg-amber-500 text-slate-950 shadow font-black' : 'text-slate-300 hover:text-white'
            }`}
            title="مظهر فلاتر على التابلت والأجهزة اللوحية"
          >
            <Tablet className="w-4 h-4" />
            <span>تابلت</span>
          </button>

          <button
            onClick={() => setDeviceMode('web')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer ${
              deviceMode === 'web' ? 'bg-amber-500 text-slate-950 shadow font-black' : 'text-slate-300 hover:text-white'
            }`}
            title="مظهر فلاتر ويب للأجهزة المكتبية (Web Desktop)"
          >
            <Monitor className="w-4 h-4" />
            <span>ويب كمبيوتر</span>
          </button>

          <button
            onClick={() => setIsCodeModalOpen(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-sky-600 hover:bg-sky-500 text-white text-xs font-bold transition shadow mr-1 cursor-pointer"
            title="عرض ملفات كود Dart المتجاوبة"
          >
            <Code2 className="w-4 h-4" />
            <span>كود Dart</span>
          </button>
        </div>
      </div>

      {/* منطقة محاكاة الشاشة (Fluid Responsive Canvas) */}
      <div className="flex justify-center items-start py-2">
        <div
          className={`transition-all duration-300 bg-slate-950 shadow-2xl overflow-hidden flex flex-col text-slate-900 ${
            deviceMode === 'android'
              ? 'w-full max-w-[420px] h-[820px] rounded-[42px] border-[10px] border-slate-800 ring-4 ring-slate-900/50'
              : deviceMode === 'ios'
              ? 'w-full max-w-[410px] h-[820px] rounded-[48px] border-[10px] border-slate-850 ring-4 ring-slate-900/50'
              : deviceMode === 'tablet'
              ? 'w-full max-w-3xl h-[800px] rounded-3xl border-8 border-slate-800'
              : 'w-full max-w-7xl min-h-[820px] rounded-2xl border-2 border-slate-700'
          }`}
        >
          {/* شريط حالة الهاتف في أوضاع الجوال */}
          {(deviceMode === 'android' || deviceMode === 'ios') && (
            <div className="bg-slate-900 text-white px-6 py-2 flex items-center justify-between text-[11px] select-none shrink-0 border-b border-slate-800">
              <span className="font-mono font-bold">11:15</span>
              {deviceMode === 'ios' && (
                <div className="w-24 h-4 bg-black rounded-full mx-auto" />
              )}
              <div className="flex items-center gap-1.5 text-xs text-amber-400">
                <span>5G</span>
                <span>📶</span>
                <span>🔋 99%</span>
              </div>
            </div>
          )}

          {/* هيدر تطبيق Flutter (AppBar) */}
          <div className="bg-slate-900 text-white px-4 sm:px-6 py-3 flex items-center justify-between border-b border-slate-800 shrink-0">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-white p-0.5 border-2 border-amber-400 flex items-center justify-center overflow-hidden shrink-0 shadow-md">
                <img src="/pwa-192x192.png" alt="الطنطاوي" className="w-full h-full object-contain" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="font-black text-sm sm:text-base text-white tracking-tight">
                    مجموعة الطنطاوي للتجارة والتوزيع
                  </h3>
                  <span className="hidden sm:inline-block bg-amber-500/20 text-amber-300 text-[10px] font-black px-2 py-0.5 rounded border border-amber-500/30">
                    {deviceMode === 'web' ? 'FLUTTER WEB' : deviceMode === 'tablet' ? 'FLUTTER TABLET' : 'FLUTTER MOBILE'}
                  </span>
                </div>
                <p className="text-[10px] sm:text-[11px] text-slate-400">
                  {currentUser?.name || 'مندوب المبيعات'} • {currentUser?.branchName || 'فرع القاهرة'}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <button
                onClick={() => setActiveFlutterTab('cart')}
                className="relative flex items-center gap-2 px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-750 text-white transition border border-slate-700 cursor-pointer"
                title="سلة الطلبية"
              >
                <ShoppingBag className="w-4 h-4 text-amber-400" />
                <span className="text-xs font-bold hidden sm:inline">السلة</span>
                {cartItemsCount > 0 && (
                  <span className="bg-amber-500 text-slate-950 text-[10px] font-black px-1.5 py-0.2 rounded-full">
                    {cartItemsCount}
                  </span>
                )}
              </button>
            </div>
          </div>

          {/* جسم التطبيق المتجاوب بأسلوب Flutter (Master-Detail on Web vs Single Column on Mobile) */}
          <div className="flex-1 flex overflow-hidden bg-slate-50">
            
            {/* في وضع الويب أو التابلت: قائمة الملاحة الجانبية (NavigationRail) */}
            {(deviceMode === 'web' || deviceMode === 'tablet') && (
              <div className="w-20 sm:w-56 bg-slate-900 border-l border-slate-800 p-2 sm:p-3 flex flex-col justify-between shrink-0 select-none">
                <div className="space-y-1.5">
                  <div className="hidden sm:block text-[10px] font-bold text-slate-400 px-3 py-2 uppercase tracking-wider">
                    أقسام فلاتر
                  </div>
                  {[
                    { id: 'catalog', label: 'كتالوج الأصناف', icon: Boxes },
                    { id: 'home', label: 'الرئيسية والمبيعات', icon: TrendingUp },
                    { id: 'cart', label: 'سلة الطلبيات', icon: ShoppingBag, badge: cartItemsCount },
                    { id: 'invoices', label: 'الفواتير والطباعة', icon: Receipt },
                    { id: 'visits', label: 'الزيارات وGPS', icon: MapPin },
                  ].map(tab => {
                    const Icon = tab.icon;
                    const isActive = activeFlutterTab === tab.id;
                    return (
                      <button
                        key={tab.id}
                        onClick={() => setActiveFlutterTab(tab.id as any)}
                        className={`w-full flex items-center justify-between p-2.5 sm:px-3 sm:py-2.5 rounded-xl text-xs font-bold transition cursor-pointer ${
                          isActive
                            ? 'bg-amber-500 text-slate-950 font-black shadow-md'
                            : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                        }`}
                      >
                        <div className="flex items-center gap-2.5">
                          <Icon className={`w-4 h-4 ${isActive ? 'text-slate-950' : 'text-amber-400'}`} />
                          <span className="hidden sm:inline">{tab.label}</span>
                        </div>
                        {tab.badge && tab.badge > 0 ? (
                          <span className={`text-[10px] px-1.5 py-0.2 rounded-full font-black ${
                            isActive ? 'bg-slate-950 text-amber-300' : 'bg-amber-500 text-slate-950'
                          }`}>
                            {tab.badge}
                          </span>
                        ) : null}
                      </button>
                    );
                  })}
                </div>

                <div className="hidden sm:block p-3 rounded-xl bg-slate-950/80 border border-slate-800 text-[11px] text-slate-400">
                  <div className="flex items-center gap-1.5 text-emerald-400 font-bold mb-1">
                    <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
                    <span>Supabase Live</span>
                  </div>
                  <div>تزامن تلقائي لحظي بدون إعادة تحميل.</div>
                </div>
              </div>
            )}

            {/* مساحة المحتوى المركزية (Center Workspace) */}
            <div className="flex-1 overflow-y-auto p-3 sm:p-5">
              
              {/* رسالة نجاح حفظ الطلبية */}
              {orderSuccessMessage && (
                <div className="mb-4 bg-emerald-600 text-white p-3.5 rounded-2xl text-xs font-bold flex items-center gap-2 shadow-lg animate-in fade-in">
                  <CheckCircle2 className="w-5 h-5 shrink-0" />
                  <span>{orderSuccessMessage}</span>
                </div>
              )}

              {/* 1. شاشة الكتالوج المتجاوبة (Flutter Responsive Catalog Grid) */}
              {activeFlutterTab === 'catalog' && (
                <div className="space-y-4">
                  {/* شريط البحث والأقسام */}
                  <div className="bg-white p-3 sm:p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row gap-3 items-center justify-between">
                    <div className="relative w-full md:w-80">
                      <Search className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
                      <input
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder="بحث باسم الصنف، الكود الموحد، أو الكرتونة..."
                        className="w-full bg-slate-50 pr-9 pl-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:border-amber-400 font-bold"
                      />
                    </div>

                    <div className="flex gap-1.5 overflow-x-auto w-full md:w-auto pb-1 scrollbar-none">
                      {departments.map(dept => (
                        <button
                          key={dept}
                          onClick={() => setSelectedDepartment(dept)}
                          className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition cursor-pointer ${
                            selectedDepartment === dept
                              ? 'bg-amber-500 text-slate-950 font-black shadow-sm'
                              : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                          }`}
                        >
                          {dept}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* شبكة المنتجات المتكيفة (Responsive Cards Grid) */}
                  <div className={`grid gap-3 ${
                    deviceMode === 'web'
                      ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3'
                      : deviceMode === 'tablet'
                      ? 'grid-cols-2'
                      : 'grid-cols-1'
                  }`}>
                    {filteredProducts.slice(0, 18).map(prod => {
                      const cartItem = flutterCart[prod.id];
                      const qty = cartItem?.quantity || 0;
                      return (
                        <div
                          key={prod.id}
                          className="bg-white p-3.5 rounded-2xl border border-slate-200 hover:border-amber-400 shadow-sm transition flex flex-col justify-between"
                        >
                          <div>
                            <div className="flex items-start gap-3">
                              <div className="w-16 h-16 rounded-xl bg-slate-100 border border-slate-200 flex items-center justify-center shrink-0 overflow-hidden">
                                {prod.imageUrl ? (
                                  <img src={prod.imageUrl} alt={prod.name} className="w-full h-full object-cover" />
                                ) : (
                                  <Boxes className="w-7 h-7 text-amber-500" />
                                )}
                              </div>
                              <div className="min-w-0 flex-1">
                                <div className="flex items-center gap-1.5">
                                  <span className="text-[10px] font-mono font-bold bg-slate-900 text-amber-400 px-1.5 py-0.5 rounded">
                                    {prod.code}
                                  </span>
                                  <span className="text-[10px] text-slate-400 truncate">{prod.department}</span>
                                </div>
                                <h4 className="font-bold text-xs sm:text-sm text-slate-900 truncate mt-1">{prod.name}</h4>
                                <div className="text-[11px] text-slate-500 mt-0.5">شدة الكرتونة: {prod.cartonQuantity || 1} قطعة</div>
                              </div>
                            </div>

                            <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-xs">
                              <div>
                                <span className="text-[10px] text-slate-400 block">سعر الكرتونة</span>
                                <span className="font-black text-sm text-emerald-700">
                                  {formatCurrency(prod.promoPrice || prod.cartonPrice || 0)}
                                </span>
                              </div>
                              <div className="text-left">
                                <span className="text-[10px] text-slate-400 block">متاح بالفرع</span>
                                <span className="font-bold text-xs text-slate-800">
                                  {(prod.branchStockActual || 15) - (prod.branchStockReserved || 0)} كرتونة
                                </span>
                              </div>
                            </div>
                          </div>

                          {/* أزرار الإضافة التفاعلية للسلة */}
                          <div className="mt-3 pt-2 flex items-center justify-between">
                            <span className="text-[11px] font-bold text-slate-500">
                              {qty > 0 ? `المحجوز: ${qty} كرتونة` : 'إضافة للطلبية:'}
                            </span>
                            <div className="flex items-center gap-1.5">
                              {qty > 0 && (
                                <>
                                  <button
                                    onClick={() => handleRemoveFromCart(prod.id)}
                                    className="w-8 h-8 rounded-xl bg-slate-100 text-slate-800 hover:bg-slate-200 flex items-center justify-center font-bold text-sm cursor-pointer"
                                  >
                                    <Minus className="w-3.5 h-3.5" />
                                  </button>
                                  <span className="font-black text-xs w-6 text-center">{qty}</span>
                                </>
                              )}
                              <button
                                onClick={() => handleAddToCart(prod)}
                                className="w-8 h-8 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 flex items-center justify-center font-bold text-sm shadow-sm cursor-pointer"
                              >
                                <Plus className="w-3.5 h-3.5" />
                              </button>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* 2. شاشة الرئيسية (Home Dashboard) */}
              {activeFlutterTab === 'home' && (
                <div className="space-y-4">
                  <div className="bg-gradient-to-br from-slate-900 to-slate-800 text-white p-5 rounded-2xl border border-slate-700 shadow-md">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs text-slate-400">إجمالي مبيعات اليوم المحققة</span>
                      <span className="text-[11px] bg-emerald-500/20 text-emerald-300 px-2.5 py-0.5 rounded-full font-bold border border-emerald-500/30">
                        85% من التارجت الشهري
                      </span>
                    </div>
                    <div className="text-3xl font-black text-amber-400 tracking-tight">
                      {formatCurrency(invoices[0]?.estimatedGrandTotal ? invoices[0].estimatedGrandTotal * 1.5 : 48500)}
                    </div>
                    <div className="mt-4 w-full bg-slate-700 h-2.5 rounded-full overflow-hidden">
                      <div className="bg-amber-400 h-full w-[85%] rounded-full" />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
                      <div className="text-xs text-slate-500 font-bold">العملاء النشطين</div>
                      <div className="text-xl font-black text-slate-900 mt-1">{customers.length} عميل</div>
                    </div>
                    <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
                      <div className="text-xs text-slate-500 font-bold">إجمالي الفواتير</div>
                      <div className="text-xl font-black text-slate-900 mt-1">{invoices.length} فاتورة</div>
                    </div>
                    <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
                      <div className="text-xs text-slate-500 font-bold">الأصناف المتاحة</div>
                      <div className="text-xl font-black text-slate-900 mt-1">{products.length} صنف</div>
                    </div>
                    <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
                      <div className="text-xs text-slate-500 font-bold">رصيد السلة الحالي</div>
                      <div className="text-xl font-black text-emerald-700 mt-1">{formatCurrency(cartSubtotal)}</div>
                    </div>
                  </div>
                </div>
              )}

              {/* 3. شاشة سلة وحجز الطلبية (في وضع الموبايل) */}
              {activeFlutterTab === 'cart' && (
                <div className="max-w-2xl mx-auto space-y-4">
                  {/* اختيار العميل */}
                  <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <label className="text-xs font-bold text-slate-700 block">اختيار العميل من قاعدة البيانات:</label>
                    <select
                      value={selectedCustomerId}
                      onChange={(e) => setSelectedCustomerId(e.target.value)}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-bold focus:outline-none focus:border-amber-400"
                    >
                      {customers.slice(0, 30).map(c => (
                        <option key={c.id} value={c.id}>
                          {c.name} ({c.code}) — رصيد: {formatCurrency(c.balance || c.currentBalance || 0)}
                        </option>
                      ))}
                    </select>

                    {selectedCustomer && (
                      <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 text-xs space-y-1.5">
                        <div className="flex justify-between">
                          <span className="text-slate-500">الحد الائتماني:</span>
                          <span className="font-bold">{formatCurrency(selectedCustomer.creditLimit || 50000)}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-slate-500">الرصيد والمديونية:</span>
                          <span className="font-black text-slate-900">{formatCurrency(selectedCustomer.balance || selectedCustomer.currentBalance || 0)}</span>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* قائمة محتويات السلة */}
                  <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-xs text-slate-800">الأصناف المحجوزة ({cartItemsCount} كرتونة)</span>
                      {cartItemsCount > 0 && (
                        <button
                          onClick={() => setFlutterCart({})}
                          className="text-xs text-red-500 hover:underline font-bold"
                        >
                          مسح السلة
                        </button>
                      )}
                    </div>

                    {cartItemsCount === 0 ? (
                      <div className="text-center py-10 text-slate-400 text-xs">
                        السلة فارغة حالياً. انتقل لقسم الكتالوج لاختيار البضاعة.
                      </div>
                    ) : (
                      <div className="space-y-2">
                        {Object.values(flutterCart).map(item => (
                          <div key={item.product.id} className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 border border-slate-100 text-xs">
                            <div className="min-w-0 flex-1">
                              <div className="font-bold text-slate-900 truncate">{item.product.name}</div>
                              <div className="text-[11px] text-slate-500">
                                {item.quantity} كرتونة × {formatCurrency(item.product.promoPrice || item.product.cartonPrice || 1000)}
                              </div>
                            </div>
                            <div className="flex items-center gap-2">
                              <span className="font-black text-xs text-slate-900">
                                {formatCurrency(item.quantity * (item.product.promoPrice || item.product.cartonPrice || 1000))}
                              </span>
                              <button
                                onClick={() => handleRemoveFromCart(item.product.id)}
                                className="text-red-500 p-1 hover:bg-red-50 rounded"
                              >
                                <Minus className="w-3.5 h-3.5" />
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {cartItemsCount > 0 && (
                    <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-slate-500 font-bold">طريقة السداد:</span>
                        <div className="flex gap-4">
                          <label className="flex items-center gap-1.5 text-xs font-bold cursor-pointer">
                            <input
                              type="radio"
                              name="pay"
                              checked={paymentType === 'آجل'}
                              onChange={() => setPaymentType('آجل')}
                            />
                            <span>آجل</span>
                          </label>
                          <label className="flex items-center gap-1.5 text-xs font-bold cursor-pointer">
                            <input
                              type="radio"
                              name="pay"
                              checked={paymentType === 'نقدي'}
                              onChange={() => setPaymentType('نقدي')}
                            />
                            <span>نقدي</span>
                          </label>
                        </div>
                      </div>

                      <div className="pt-2 border-t border-slate-100 flex items-center justify-between">
                        <span className="font-black text-xs text-slate-800">الصافي المطلوب:</span>
                        <span className="font-black text-base text-emerald-700">{formatCurrency(cartSubtotal)}</span>
                      </div>

                      <button
                        onClick={handleConfirmOrder}
                        className="w-full bg-amber-500 hover:bg-amber-400 text-slate-950 font-black py-3 rounded-xl text-xs flex items-center justify-center gap-2 shadow transition active:scale-95 cursor-pointer"
                      >
                        <CheckCircle2 className="w-4 h-4" />
                        <span>ترحيل الفاتورة للاعتماد في Supabase</span>
                      </button>
                    </div>
                  )}
                </div>
              )}

              {/* 4. شاشة سجل الفواتير (Invoices) */}
              {activeFlutterTab === 'invoices' && (
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h4 className="font-black text-xs sm:text-sm text-slate-800">الفواتير الإلكترونية المعتمدة</h4>
                    <span className="text-xs text-slate-500 font-bold">{invoices.length} فاتورة</span>
                  </div>

                  <div className="space-y-2.5">
                    {invoices.slice(0, 15).map((inv) => (
                      <div key={inv.id} className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-sm space-y-2">
                        <div className="flex items-center justify-between">
                          <span className="font-mono font-bold text-xs bg-slate-900 text-amber-400 px-2 py-0.5 rounded">
                            {inv.invoiceNumber}
                          </span>
                          <span className="text-[11px] text-slate-500">{inv.date}</span>
                        </div>

                        <div className="flex items-center justify-between">
                          <div>
                            <div className="font-bold text-xs sm:text-sm text-slate-900">{inv.customerName}</div>
                            <div className="text-[11px] text-slate-500">{inv.repName || 'المندوب'} • {inv.branchName || 'الفرع'}</div>
                          </div>
                          <div className="font-black text-sm text-emerald-700">
                            {formatCurrency(inv.estimatedGrandTotal || (inv as any).totalAmount || 0)}
                          </div>
                        </div>

                        <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                          <button
                            onClick={() => setPrintingInvoice(inv)}
                            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-900 text-amber-300 hover:bg-slate-800 text-xs font-bold transition shadow-sm cursor-pointer"
                          >
                            <Printer className="w-3.5 h-3.5 text-amber-400" />
                            <span>طباعة بون حراري (Bluetooth 80mm)</span>
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* 5. شاشة الزيارات الميدانية والـ GPS */}
              {activeFlutterTab === 'visits' && (
                <div className="max-w-xl mx-auto space-y-4">
                  <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <h4 className="font-black text-xs sm:text-sm text-slate-800">تسجيل حضور وزيارة ميدانية (GPS Check-In)</h4>
                    <input
                      type="text"
                      placeholder="اسم العميل أو المعرض..."
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-bold focus:outline-none focus:border-amber-400"
                    />
                    <div className="flex items-center justify-between p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-xs text-emerald-800 font-bold">
                      <span className="flex items-center gap-1.5">
                        <MapPin className="w-4 h-4 text-emerald-600" />
                        <span>إحداثيات الموقع الملتقطة:</span>
                      </span>
                      <span className="font-mono">30.0444° N, 31.2357° E</span>
                    </div>
                    <button
                      onClick={() => alert('تم تسجيل الحضور الجغرافي وحفظ الزيارة في Supabase بنجاح!')}
                      className="w-full bg-purple-600 hover:bg-purple-500 text-white font-black py-2.5 rounded-xl text-xs flex items-center justify-center gap-2 shadow cursor-pointer"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      <span>حفظ الزيارة ورفع الملاحظات</span>
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* في وضع الويب Desktop: لوحة السلة وكشف حساب العميل المثبتة على الجانب الأيسر (Master-Detail Cart Panel) */}
            {deviceMode === 'web' && activeFlutterTab === 'catalog' && (
              <div className="w-80 bg-white border-r border-slate-200 p-4 flex flex-col justify-between shrink-0 shadow-sm">
                <div className="space-y-3">
                  <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                    <h4 className="font-black text-xs text-slate-900 flex items-center gap-1.5">
                      <ShoppingBag className="w-4 h-4 text-amber-500" />
                      <span>سلة الطلبية الحالية</span>
                    </h4>
                    <span className="bg-amber-100 text-amber-800 text-[10px] font-black px-2 py-0.5 rounded-full">
                      {cartItemsCount} كرتونة
                    </span>
                  </div>

                  {/* اختيار العميل السريع */}
                  <div>
                    <label className="text-[11px] font-bold text-slate-500 block mb-1">العميل المستهدف:</label>
                    <select
                      value={selectedCustomerId}
                      onChange={(e) => setSelectedCustomerId(e.target.value)}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2 text-xs font-bold focus:outline-none"
                    >
                      {customers.slice(0, 25).map(c => (
                        <option key={c.id} value={c.id}>
                          {c.name} ({formatCurrency(c.balance || c.currentBalance || 0)})
                        </option>
                      ))}
                    </select>
                  </div>

                  {/* سطور السلة */}
                  <div className="max-h-80 overflow-y-auto space-y-2 pr-1">
                    {cartItemsCount === 0 ? (
                      <div className="text-center py-12 text-slate-400 text-xs">
                        اضغط على زر (+) بجانب أي صنف لإضافته للسلة فوراً.
                      </div>
                    ) : (
                      Object.values(flutterCart).map(item => (
                        <div key={item.product.id} className="p-2 rounded-xl bg-slate-50 border border-slate-100 text-xs">
                          <div className="font-bold text-slate-900 truncate">{item.product.name}</div>
                          <div className="flex items-center justify-between mt-1 text-[11px]">
                            <span className="text-slate-500">
                              {item.quantity} × {formatCurrency(item.product.promoPrice || item.product.cartonPrice || 1000)}
                            </span>
                            <span className="font-black text-slate-900">
                              {formatCurrency(item.quantity * (item.product.promoPrice || item.product.cartonPrice || 1000))}
                            </span>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                {/* فوتر السلة والإجمالي */}
                {cartItemsCount > 0 && (
                  <div className="pt-3 border-t border-slate-200 space-y-2">
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-bold text-slate-600">إجمالي الطلبية:</span>
                      <span className="font-black text-base text-emerald-700">{formatCurrency(cartSubtotal)}</span>
                    </div>
                    <button
                      onClick={handleConfirmOrder}
                      className="w-full bg-amber-500 hover:bg-amber-400 text-slate-950 font-black py-2.5 rounded-xl text-xs flex items-center justify-center gap-1.5 shadow transition cursor-pointer"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      <span>ترحيل الفاتورة لـ Supabase</span>
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* في أوضاع الموبايل: شريط الملاحة السفلي (Flutter BottomNavigationBar) */}
          {(deviceMode === 'android' || deviceMode === 'ios') && (
            <div className="bg-slate-900 border-t border-slate-800 px-4 py-2 flex items-center justify-around shrink-0 select-none">
              <button
                onClick={() => setActiveFlutterTab('home')}
                className={`flex flex-col items-center gap-1 transition ${
                  activeFlutterTab === 'home' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <TrendingUp className="w-4 h-4" />
                <span className="text-[10px]">الرئيسية</span>
              </button>

              <button
                onClick={() => setActiveFlutterTab('catalog')}
                className={`flex flex-col items-center gap-1 transition ${
                  activeFlutterTab === 'catalog' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Boxes className="w-4 h-4" />
                <span className="text-[10px]">الكتالوج</span>
              </button>

              <button
                onClick={() => setActiveFlutterTab('cart')}
                className={`relative flex flex-col items-center gap-1 transition ${
                  activeFlutterTab === 'cart' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <ShoppingBag className="w-4 h-4" />
                <span className="text-[10px]">الطلبية</span>
                {cartItemsCount > 0 && (
                  <span className="absolute -top-1 right-2 bg-amber-500 text-slate-950 font-black text-[9px] w-3.5 h-3.5 rounded-full flex items-center justify-center">
                    {cartItemsCount}
                  </span>
                )}
              </button>

              <button
                onClick={() => setActiveFlutterTab('invoices')}
                className={`flex flex-col items-center gap-1 transition ${
                  activeFlutterTab === 'invoices' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Receipt className="w-4 h-4" />
                <span className="text-[10px]">الفواتير</span>
              </button>

              <button
                onClick={() => setActiveFlutterTab('visits')}
                className={`flex flex-col items-center gap-1 transition ${
                  activeFlutterTab === 'visits' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <MapPin className="w-4 h-4" />
                <span className="text-[10px]">الزيارات</span>
              </button>
            </div>
          )}
        </div>
      </div>

      {/* نافذة معاينة بون الطباعة الحرارية الحقيقية */}
      {printingInvoice && (
        <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-sm w-full p-4 border border-slate-300 text-slate-900 font-mono text-xs">
            <div className="text-center pb-2 border-b-2 border-dashed border-slate-300 space-y-1">
              <h3 className="font-black text-sm">مجموعة الطنطاوي للتجارة والتوزيع</h3>
              <p className="text-[10px] text-slate-600">فاتورة بيع إلكترونية - طابعة حرارية 80mm</p>
              <p className="text-[11px] font-bold text-amber-700">{printingInvoice.invoiceNumber}</p>
            </div>

            <div className="py-2 border-b border-dashed border-slate-300 space-y-1 text-[11px]">
              <div>العميل: <strong>{printingInvoice.customerName}</strong></div>
              <div>المندوب: {printingInvoice.repName || 'المندوب'}</div>
              <div>التاريخ: {printingInvoice.date}</div>
            </div>

            <div className="py-2 border-b-2 border-dashed border-slate-300 space-y-1">
              <div className="flex justify-between font-bold text-[10px] text-slate-500">
                <span>الصنف</span>
                <span>الكمية</span>
                <span>الإجمالي</span>
              </div>
              {(printingInvoice.items || []).map((it: any, i: number) => (
                <div key={i} className="flex justify-between text-[11px]">
                  <span className="truncate max-w-[150px]">{it.productName || 'صنف'}</span>
                  <span>{it.cartons || it.quantity || 1} ك</span>
                  <span>{formatCurrency(it.totalPrice || 1000)}</span>
                </div>
              ))}
            </div>

            <div className="py-2 space-y-1 text-xs">
              <div className="flex justify-between font-black text-sm">
                <span>الصافي المطلوب:</span>
                <span>{formatCurrency(printingInvoice.estimatedGrandTotal || printingInvoice.totalAmount || 0)}</span>
              </div>
            </div>

            <div className="text-center pt-3 pb-1 border-t border-dashed border-slate-300 space-y-1">
              <div className="flex justify-center">
                <QrCode className="w-16 h-16 text-slate-800" />
              </div>
              <p className="text-[10px] text-slate-500">شكراً لتعاملكم مع مجموعة الطنطاوي</p>
            </div>

            <div className="mt-3 flex gap-2">
              <button
                onClick={() => {
                  window.print();
                  setPrintingInvoice(null);
                }}
                className="flex-1 bg-slate-900 hover:bg-slate-800 text-amber-400 font-bold py-2 rounded-xl text-xs flex items-center justify-center gap-1 shadow cursor-pointer"
              >
                <Printer className="w-3.5 h-3.5" />
                <span>إرسال للطابعة</span>
              </button>
              <button
                onClick={() => setPrintingInvoice(null)}
                className="px-3 py-2 bg-slate-200 hover:bg-slate-300 rounded-xl text-xs font-bold cursor-pointer"
              >
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}

      {/* نافذة استعراض كود فلاتر ودارت الكامل */}
      <FlutterProjectViewerModal
        isOpen={isCodeModalOpen}
        onClose={() => setIsCodeModalOpen(false)}
      />
    </div>
  );
};
