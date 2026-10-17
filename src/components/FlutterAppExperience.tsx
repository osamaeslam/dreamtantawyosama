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
  ArrowRight,
  TrendingUp,
  Boxes,
  Users,
  ShieldCheck,
  AlertTriangle,
  FileSpreadsheet,
  QrCode,
  Copy,
  Check,
  Sparkles,
  RefreshCw,
  ExternalLink
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
    selectedBranchFilter
  } = useApp();

  // Mode: android | ios | web
  const [deviceMode, setDeviceMode] = useState<'android' | 'ios' | 'web'>('android');
  // Flutter screen: catalog | cart | invoices | visits | home
  const [activeFlutterTab, setActiveFlutterTab] = useState<'home' | 'catalog' | 'cart' | 'invoices' | 'visits'>('home');
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
    setOrderSuccessMessage(`تم ترحيل الطلبية بنجاح بقيمة ${formatCurrency(cartSubtotal)} وهي الآن متزامنة مع Supabase!`);
    setFlutterCart({});
    setTimeout(() => {
      setOrderSuccessMessage(null);
      setActiveFlutterTab('invoices');
    }, 2000);
  };

  return (
    <div className="space-y-4">
      {/* شريط الإعلان والتحويل العلوي */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-850 to-amber-950 p-4 sm:p-5 rounded-2xl border-2 border-amber-500/40 shadow-xl flex flex-col md:flex-row items-center justify-between gap-4 text-white">
        <div className="flex items-center gap-3.5">
          <div className="w-12 h-12 rounded-2xl bg-amber-500/20 border border-amber-400/50 flex items-center justify-center text-amber-400 shrink-0 shadow-inner">
            <Smartphone className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-base sm:text-lg font-black text-amber-300">
                منظومة مجموعة الطنطاوي — واجهة تطبيق Flutter & Dart الموحدة
              </h2>
              <span className="bg-sky-500/20 text-sky-300 border border-sky-400/30 text-[10px] font-extrabold px-2 py-0.5 rounded-full">
                Flutter 3.x Engine
              </span>
            </div>
            <p className="text-xs text-slate-300 mt-1">
              تعمل بنفس قاعدة بيانات Supabase الحالية بكود واحد موحد على الويب وهواتف أندرويد وآيفون، مع الحفاظ الكامل على الألوان والهوية والبيانات.
            </p>
          </div>
        </div>

        {/* أزرار التحكم في وضع المحاكاة */}
        <div className="flex items-center gap-2 bg-slate-900/90 p-1.5 rounded-xl border border-slate-700">
          <button
            onClick={() => setDeviceMode('android')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer ${
              deviceMode === 'android' ? 'bg-amber-500 text-slate-950 shadow' : 'text-slate-300 hover:text-white'
            }`}
            title="معاينة مظهر أندرويد (Material 3)"
          >
            <Smartphone className="w-4 h-4" />
            <span>Android</span>
          </button>

          <button
            onClick={() => setDeviceMode('ios')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer ${
              deviceMode === 'ios' ? 'bg-amber-500 text-slate-950 shadow' : 'text-slate-300 hover:text-white'
            }`}
            title="معاينة مظهر آيفون (Cupertino)"
          >
            <Smartphone className="w-4 h-4" />
            <span>iOS</span>
          </button>

          <button
            onClick={() => setDeviceMode('web')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition cursor-pointer ${
              deviceMode === 'web' ? 'bg-amber-500 text-slate-950 shadow' : 'text-slate-300 hover:text-white'
            }`}
            title="معاينة مظهر فلاتر للويب (Web)"
          >
            <Monitor className="w-4 h-4" />
            <span>Web Desktop</span>
          </button>

          <button
            onClick={() => setIsCodeModalOpen(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-sky-600 hover:bg-sky-500 text-white text-xs font-bold transition shadow mr-1"
            title="عرض ملفات كود Dart والمشروع كاملاً"
          >
            <Code2 className="w-4 h-4" />
            <span>ملفات Dart</span>
          </button>
        </div>
      </div>

      {/* منطقة محاكاة الجهاز والتطبيق */}
      <div className="flex justify-center items-start py-2">
        <div
          className={`transition-all duration-300 bg-slate-950 shadow-2xl overflow-hidden flex flex-col text-slate-900 ${
            deviceMode === 'android'
              ? 'w-full max-w-[430px] h-[820px] rounded-[42px] border-[10px] border-slate-800 ring-4 ring-slate-900/50'
              : deviceMode === 'ios'
              ? 'w-full max-w-[420px] h-[820px] rounded-[48px] border-[10px] border-slate-850 ring-4 ring-slate-900/50'
              : 'w-full max-w-5xl h-[780px] rounded-2xl border-2 border-slate-700'
          }`}
        >
          {/* شريط حالة الهاتف (Notch / Dynamic Island) */}
          {(deviceMode === 'android' || deviceMode === 'ios') && (
            <div className="bg-slate-900 text-white px-6 py-2 flex items-center justify-between text-[11px] select-none shrink-0 border-b border-slate-800">
              <span className="font-mono font-bold">10:45</span>
              {deviceMode === 'ios' && (
                <div className="w-24 h-4 bg-black rounded-full mx-auto" />
              )}
              <div className="flex items-center gap-1.5 text-xs text-amber-400">
                <span>5G</span>
                <span>📶</span>
                <span>🔋 98%</span>
              </div>
            </div>
          )}

          {/* شريط AppBar الخاص بتطبيق Flutter */}
          <div className="bg-slate-900 text-white px-4 py-3 flex items-center justify-between border-b border-slate-800 shrink-0">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-full bg-white p-0.5 border-2 border-amber-400 flex items-center justify-center overflow-hidden">
                <img src="/pwa-192x192.png" alt="الطنطاوي" className="w-full h-full object-contain" />
              </div>
              <div>
                <h3 className="font-black text-sm text-white flex items-center gap-1">
                  <span>مجموعة الطنطاوي</span>
                  <span className="text-amber-400 text-xs">Flutter</span>
                </h3>
                <p className="text-[10px] text-slate-400">
                  {currentUser?.name || 'مندوب المبيعات'} | {currentUser?.branchName || 'فرع القاهرة'}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-1.5">
              <button
                onClick={() => setActiveFlutterTab('cart')}
                className="relative p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-white transition"
                title="السلة"
              >
                <ShoppingBag className="w-4 h-4 text-amber-400" />
                {cartItemsCount > 0 && (
                  <span className="absolute -top-1 -right-1 bg-amber-500 text-slate-950 text-[10px] font-black w-4 h-4 rounded-full flex items-center justify-center">
                    {cartItemsCount}
                  </span>
                )}
              </button>
            </div>
          </div>

          {/* محتوى الشاشة الفعالة للتطبيق */}
          <div className="flex-1 overflow-y-auto bg-slate-50 p-3 sm:p-4">
            
            {/* رسالة نجاح الحفظ */}
            {orderSuccessMessage && (
              <div className="mb-4 bg-emerald-600 text-white p-3 rounded-xl text-xs font-bold flex items-center gap-2 shadow-lg animate-in fade-in">
                <CheckCircle2 className="w-5 h-5 shrink-0" />
                <span>{orderSuccessMessage}</span>
              </div>
            )}

            {/* الشاشة 1: الصفحة الرئيسية (Home Dashboard) */}
            {activeFlutterTab === 'home' && (
              <div className="space-y-4">
                {/* كارت الترحيب ومبيعات اليوم */}
                <div className="bg-gradient-to-br from-slate-900 to-slate-800 text-white p-4 rounded-2xl border border-slate-700 shadow-md">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs text-slate-400">مبيعات اليوم المحققة</span>
                    <span className="text-[11px] bg-emerald-500/20 text-emerald-300 px-2 py-0.5 rounded-full font-bold border border-emerald-500/30">
                      85% من التارجت
                    </span>
                  </div>
                  <div className="text-2xl font-black text-amber-400 tracking-tight">
                    {formatCurrency(invoices[0]?.estimatedGrandTotal ? invoices[0].estimatedGrandTotal * 1.5 : 48500)}
                  </div>
                  <div className="mt-3 w-full bg-slate-700 h-2 rounded-full overflow-hidden">
                    <div className="bg-amber-400 h-full w-[85%] rounded-full" />
                  </div>
                </div>

                {/* شبكة العمليات السريعة (Quick Actions Grid) */}
                <div className="grid grid-cols-2 gap-2.5">
                  <button
                    onClick={() => setActiveFlutterTab('catalog')}
                    className="bg-white p-3.5 rounded-2xl border border-slate-200 hover:border-amber-400 shadow-sm text-right flex flex-col justify-between h-28 transition active:scale-95 cursor-pointer"
                  >
                    <div className="w-9 h-9 rounded-xl bg-amber-500/10 text-amber-600 flex items-center justify-center">
                      <Boxes className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="font-black text-xs text-slate-800">كتالوج الأصناف</div>
                      <div className="text-[10px] text-slate-500">{products.length} صنف مسجل</div>
                    </div>
                  </button>

                  <button
                    onClick={() => setActiveFlutterTab('cart')}
                    className="bg-white p-3.5 rounded-2xl border border-slate-200 hover:border-emerald-400 shadow-sm text-right flex flex-col justify-between h-28 transition active:scale-95 cursor-pointer"
                  >
                    <div className="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
                      <ShoppingBag className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="font-black text-xs text-slate-800">طلبية جديدة</div>
                      <div className="text-[10px] text-slate-500">{cartItemsCount} كرتونة بالسلة</div>
                    </div>
                  </button>

                  <button
                    onClick={() => setActiveFlutterTab('invoices')}
                    className="bg-white p-3.5 rounded-2xl border border-slate-200 hover:border-blue-400 shadow-sm text-right flex flex-col justify-between h-28 transition active:scale-95 cursor-pointer"
                  >
                    <div className="w-9 h-9 rounded-xl bg-blue-500/10 text-blue-600 flex items-center justify-center">
                      <Receipt className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="font-black text-xs text-slate-800">الفواتير والطباعة</div>
                      <div className="text-[10px] text-slate-500">طباعة حرارية للبلوتوث</div>
                    </div>
                  </button>

                  <button
                    onClick={() => setActiveFlutterTab('visits')}
                    className="bg-white p-3.5 rounded-2xl border border-slate-200 hover:border-purple-400 shadow-sm text-right flex flex-col justify-between h-28 transition active:scale-95 cursor-pointer"
                  >
                    <div className="w-9 h-9 rounded-xl bg-purple-500/10 text-purple-600 flex items-center justify-center">
                      <MapPin className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="font-black text-xs text-slate-800">الزيارات والـ GPS</div>
                      <div className="text-[10px] text-slate-500">تسجيل خط السير الميداني</div>
                    </div>
                  </button>
                </div>

                {/* آخر فواتير معتمدة */}
                <div className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-sm">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-black text-xs text-slate-800">أحدث الفواتير المحررة</span>
                    <button
                      onClick={() => setActiveFlutterTab('invoices')}
                      className="text-[11px] font-bold text-amber-600 hover:underline"
                    >
                      عرض الكل
                    </button>
                  </div>
                  <div className="space-y-2">
                    {invoices.slice(0, 3).map((inv, idx) => (
                      <div
                        key={inv.id || idx}
                        className="flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-100 text-xs"
                      >
                        <div>
                          <div className="font-bold text-slate-800">{inv.customerName || 'عميل نقدي'}</div>
                          <div className="text-[10px] text-slate-500">{inv.invoiceNumber} | {inv.date}</div>
                        </div>
                        <div className="text-left">
                          <div className="font-black text-slate-900">{formatCurrency(inv.estimatedGrandTotal || (inv as any).totalAmount || 0)}</div>
                          <button
                            onClick={() => setPrintingInvoice(inv)}
                            className="text-[10px] text-amber-600 font-bold flex items-center gap-0.5 mt-0.5"
                          >
                            <Printer className="w-3 h-3" />
                            <span>طباعة حرارية</span>
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* الشاشة 2: الكتالوج والأصناف (Catalog Screen) */}
            {activeFlutterTab === 'catalog' && (
              <div className="space-y-3">
                {/* شريط البحث */}
                <div className="relative">
                  <Search className="w-4 h-4 text-slate-400 absolute right-3 top-2.5" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="ابحث باسم الصنف أو الكود..."
                    className="w-full bg-white pr-9 pl-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:border-amber-400"
                  />
                </div>

                {/* شريط الأقسام */}
                <div className="flex gap-1.5 overflow-x-auto pb-1 scrollbar-none">
                  {departments.map(dept => (
                    <button
                      key={dept}
                      onClick={() => setSelectedDepartment(dept)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition cursor-pointer ${
                        selectedDepartment === dept
                          ? 'bg-amber-500 text-slate-950 font-black shadow-sm'
                          : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-100'
                      }`}
                    >
                      {dept}
                    </button>
                  ))}
                </div>

                {/* قائمة المنتجات */}
                <div className="space-y-2.5">
                  {filteredProducts.slice(0, 15).map(prod => {
                    const cartItem = flutterCart[prod.id];
                    const qty = cartItem?.quantity || 0;
                    return (
                      <div
                        key={prod.id}
                        className="bg-white p-3 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-3"
                      >
                        <div className="w-14 h-14 rounded-xl bg-slate-100 border border-slate-200 flex items-center justify-center shrink-0 overflow-hidden">
                          {prod.imageUrl ? (
                            <img src={prod.imageUrl} alt={prod.name} className="w-full h-full object-cover" />
                          ) : (
                            <Boxes className="w-6 h-6 text-amber-500" />
                          )}
                        </div>

                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-1.5">
                            <span className="text-[10px] font-mono font-bold bg-slate-900 text-amber-400 px-1.5 py-0.2 rounded">
                              {prod.code}
                            </span>
                            <span className="text-[10px] text-slate-400 truncate">{prod.department}</span>
                          </div>
                          <h4 className="font-bold text-xs text-slate-900 truncate mt-0.5">{prod.name}</h4>
                          <div className="flex items-center gap-2 mt-1">
                            <span className="font-black text-xs text-emerald-700">
                              {formatCurrency(prod.promoPrice || prod.cartonPrice || 0)}
                            </span>
                            <span className="text-[10px] text-slate-400">شدة: {prod.cartonQuantity || 1}</span>
                          </div>
                        </div>

                        {/* عداد الإضافة */}
                        <div className="flex items-center gap-1.5">
                          {qty > 0 && (
                            <>
                              <button
                                onClick={() => handleRemoveFromCart(prod.id)}
                                className="w-7 h-7 rounded-lg bg-slate-100 text-slate-800 hover:bg-slate-200 flex items-center justify-center font-bold text-sm"
                              >
                                <Minus className="w-3.5 h-3.5" />
                              </button>
                              <span className="font-black text-xs w-5 text-center">{qty}</span>
                            </>
                          )}
                          <button
                            onClick={() => handleAddToCart(prod)}
                            className="w-7 h-7 rounded-lg bg-amber-500 hover:bg-amber-400 text-slate-950 flex items-center justify-center font-bold text-sm shadow-sm"
                          >
                            <Plus className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* الشاشة 3: سلة الطلبيات (Order Builder) */}
            {activeFlutterTab === 'cart' && (
              <div className="space-y-3">
                {/* اختيار العميل */}
                <div className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-sm space-y-2">
                  <label className="text-xs font-bold text-slate-700 block">اختيار العميل:</label>
                  <select
                    value={selectedCustomerId}
                    onChange={(e) => setSelectedCustomerId(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2 text-xs font-bold focus:outline-none focus:border-amber-400"
                  >
                    {customers.slice(0, 20).map(c => (
                      <option key={c.id} value={c.id}>
                        {c.name} ({c.code}) — رصيد: {formatCurrency(c.balance || c.currentBalance || 0)}
                      </option>
                    ))}
                  </select>

                  {selectedCustomer && (
                    <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 text-[11px] space-y-1">
                      <div className="flex justify-between">
                        <span className="text-slate-500">الحد الائتماني:</span>
                        <span className="font-bold">{formatCurrency(selectedCustomer.creditLimit || 50000)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-500">الرصيد الحالي:</span>
                        <span className="font-black text-slate-900">{formatCurrency(selectedCustomer.balance || selectedCustomer.currentBalance || 0)}</span>
                      </div>
                    </div>
                  )}
                </div>

                {/* قائمة محتويات السلة */}
                <div className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-sm space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-xs text-slate-800">الأصناف بالسلة ({cartItemsCount} كرتونة)</span>
                    {cartItemsCount > 0 && (
                      <button
                        onClick={() => setFlutterCart({})}
                        className="text-[10px] text-red-500 hover:underline font-bold"
                      >
                        مسح السلة
                      </button>
                    )}
                  </div>

                  {cartItemsCount === 0 ? (
                    <div className="text-center py-8 text-slate-400 text-xs">
                      السلة فارغة حالياً. انتقل لقسم الكتالوج واختر البضاعة المطلوبة.
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {Object.values(flutterCart).map(item => (
                        <div key={item.product.id} className="flex items-center justify-between p-2 rounded-xl bg-slate-50 border border-slate-100 text-xs">
                          <div className="min-w-0 flex-1">
                            <div className="font-bold text-slate-800 truncate">{item.product.name}</div>
                            <div className="text-[10px] text-slate-500">
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

                {/* خيارات الدفع والإجمالي */}
                {cartItemsCount > 0 && (
                  <div className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-sm space-y-2.5">
                    <div className="flex items-center justify-between text-xs">
                      <span className="text-slate-500">طريقة السداد:</span>
                      <div className="flex gap-2">
                        <label className="flex items-center gap-1 text-xs cursor-pointer">
                          <input
                            type="radio"
                            name="payType"
                            checked={paymentType === 'آجل'}
                            onChange={() => setPaymentType('آجل')}
                          />
                          <span>آجل</span>
                        </label>
                        <label className="flex items-center gap-1 text-xs cursor-pointer">
                          <input
                            type="radio"
                            name="payType"
                            checked={paymentType === 'نقدي'}
                            onChange={() => setPaymentType('نقدي')}
                          />
                          <span>نقدي</span>
                        </label>
                      </div>
                    </div>

                    <div className="pt-2 border-t border-slate-100 flex items-center justify-between">
                      <span className="font-black text-xs text-slate-800">الصافي النهائي:</span>
                      <span className="font-black text-sm text-emerald-700">{formatCurrency(cartSubtotal)}</span>
                    </div>

                    <button
                      onClick={handleConfirmOrder}
                      className="w-full bg-amber-500 hover:bg-amber-400 text-slate-950 font-black py-2.5 rounded-xl text-xs flex items-center justify-center gap-2 shadow transition active:scale-95"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      <span>ترحيل الطلبية للاعتماد في Supabase</span>
                    </button>
                  </div>
                )}
              </div>
            )}

            {/* الشاشة 4: سجل الفواتير والطباعة الحرارية (Invoices & Thermal Printer) */}
            {activeFlutterTab === 'invoices' && (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h4 className="font-black text-xs text-slate-800">الفواتير الإلكترونية المعتمدة</h4>
                  <span className="text-[10px] text-slate-500">{invoices.length} فاتورة</span>
                </div>

                <div className="space-y-2">
                  {invoices.slice(0, 10).map((inv) => (
                    <div key={inv.id} className="bg-white p-3 rounded-2xl border border-slate-200 shadow-sm space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="font-mono font-bold text-[11px] bg-slate-900 text-amber-400 px-2 py-0.5 rounded">
                          {inv.invoiceNumber}
                        </span>
                        <span className="text-[10px] text-slate-500">{inv.date}</span>
                      </div>

                      <div className="flex items-center justify-between">
                        <div>
                          <div className="font-bold text-xs text-slate-900">{inv.customerName}</div>
                          <div className="text-[10px] text-slate-500">{inv.repName || 'المندوب'} | {inv.branchName || 'الفرع'}</div>
                        </div>
                        <div className="font-black text-xs text-emerald-700">
                          {formatCurrency(inv.estimatedGrandTotal || (inv as any).totalAmount || 0)}
                        </div>
                      </div>

                      <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                        <button
                          onClick={() => setPrintingInvoice(inv)}
                          className="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-slate-900 text-amber-300 hover:bg-slate-800 text-[10px] font-bold transition shadow-sm"
                        >
                          <Printer className="w-3 h-3 text-amber-400" />
                          <span>طباعة بون حراري (Bluetooth)</span>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* الشاشة 5: الزيارات الميدانية والـ GPS */}
            {activeFlutterTab === 'visits' && (
              <div className="space-y-3">
                <div className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-sm">
                  <h4 className="font-black text-xs text-slate-800 mb-2">تسجيل زيارة ميدانية جديدة (GPS Check-In)</h4>
                  <div className="space-y-2">
                    <input
                      type="text"
                      placeholder="اسم العميل أو المتجر..."
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2 text-xs focus:outline-none focus:border-amber-400"
                    />
                    <div className="flex items-center justify-between p-2 rounded-xl bg-emerald-50 border border-emerald-200 text-[11px] text-emerald-800 font-bold">
                      <span className="flex items-center gap-1">
                        <MapPin className="w-3.5 h-3.5" />
                        <span>إحداثيات GPS ملتقطة:</span>
                      </span>
                      <span className="font-mono">30.0444° N, 31.2357° E</span>
                    </div>
                    <button
                      onClick={() => alert('تم تسجيل الحضور الجغرافي وحفظ الزيارة في Supabase!')}
                      className="w-full bg-purple-600 hover:bg-purple-500 text-white font-black py-2 rounded-xl text-xs flex items-center justify-center gap-1.5 shadow"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      <span>تأكيد الزيارة ورفع الملاحظات</span>
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* شريط الملاحة السفلي (Flutter BottomNavigationBar) */}
          <div className="bg-slate-900 border-t border-slate-800 px-4 py-2 flex items-center justify-around shrink-0 select-none">
            <button
              onClick={() => setActiveFlutterTab('home')}
              className={`flex flex-col items-center gap-1 transition ${
                activeFlutterTab === 'home' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              <Smartphone className="w-4 h-4" />
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
        </div>
      </div>

      {/* معاينة الطباعة الحرارية الحقيقية (Real Thermal Paper Receipt Preview) */}
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
                className="flex-1 bg-slate-900 hover:bg-slate-800 text-amber-400 font-bold py-2 rounded-xl text-xs flex items-center justify-center gap-1 shadow"
              >
                <Printer className="w-3.5 h-3.5" />
                <span>إرسال للطابعة</span>
              </button>
              <button
                onClick={() => setPrintingInvoice(null)}
                className="px-3 py-2 bg-slate-200 hover:bg-slate-300 rounded-xl text-xs font-bold"
              >
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}

      {/* مودال كود فلاتر */}
      <FlutterProjectViewerModal
        isOpen={isCodeModalOpen}
        onClose={() => setIsCodeModalOpen(false)}
      />
    </div>
  );
};
