import React, { useState, useMemo, useEffect } from 'react';
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
  Maximize2,
  Minimize2,
  Star,
  Truck,
  Percent,
  Flame,
  Check,
  Settings,
  Info,
  ChevronDown,
  X,
  PhoneCall,
  SlidersHorizontal,
  ExternalLink,
  ShieldAlert,
  Share2,
  Copy,
  Eye,
  Grid,
  List,
  Phone,
  MessageCircle,
  HelpCircle,
  AlertTriangle,
  BadgePercent,
  Zap,
  Tag
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { formatCurrency } from '../services/invoiceService';
import { ProductLightboxModal } from './ProductLightboxModal';
import { ApkDistributionModal } from './ApkDistributionModal';

// دالة تطبيع الحروف العربية للبحث الذكي الفائق (Fuzzy Arabic Normalizer)
const normalizeArabic = (text: string): string => {
  if (!text) return '';
  return text
    .toString()
    .toLowerCase()
    .replace(/[إأآا]/g, 'ا')
    .replace(/[ة]/g, 'ه')
    .replace(/[ىي]/g, 'ي')
    .replace(/[\u064B-\u065F]/g, '') // إزالة التشكيل
    .trim();
};

export const FlutterAppExperience: React.FC = () => {
  const {
    products,
    customers,
    invoices,
    currentUser,
    branches,
    users,
    triggerInstallPrompt,
    installPromptEvent,
    createOrder,
  } = useApp();

  // Mode: android | ios | tablet | web
  const [deviceMode, setDeviceMode] = useState<'android' | 'ios' | 'tablet' | 'web'>('web');
  // Phone bezel simulator vs fluid full-width mode
  const [isFramedSimulator, setIsFramedSimulator] = useState(false);
  // Flutter screen tab: catalog | home | cart | invoices | visits | settings
  const [activeFlutterTab, setActiveFlutterTab] = useState<'catalog' | 'home' | 'cart' | 'invoices' | 'visits' | 'settings'>('catalog');
  // Amazon Catalog view mode: grid (شبكة أمازون الفخمة) vs list (قائمة مدمجة للمناديب)
  const [catalogViewMode, setCatalogViewMode] = useState<'grid' | 'list'>('grid');
  
  const [selectedDepartment, setSelectedDepartment] = useState<string>('الكل');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<'recommended' | 'price_low' | 'price_high' | 'discount'>('recommended');
  const [isApkModalOpen, setIsApkModalOpen] = useState(false);
  const [selectedProductDetails, setSelectedProductDetails] = useState<any | null>(null);

  // In-app Flutter Cart state
  const [flutterCart, setFlutterCart] = useState<Record<string, { quantity: number; product: any }>>({});
  
  // Smart Customer Selector Search State (البحث الذكي بالاسم أو الكود)
  const [customerSearchQuery, setCustomerSearchQuery] = useState('');
  const [isCustomerDropdownOpen, setIsCustomerDropdownOpen] = useState(false);
  const [selectedCustomerId, setSelectedCustomerId] = useState<string>(customers[0]?.id || '');
  const [paymentType, setPaymentType] = useState<'آجل' | 'نقدي'>('آجل');
  const [orderNotes, setOrderNotes] = useState('');
  const [orderSuccessMessage, setOrderSuccessMessage] = useState<string | null>(null);

  // Printing thermal receipt modal state
  const [printingInvoice, setPrintingInvoice] = useState<any | null>(null);
  const [copiedLink, setCopiedLink] = useState(false);

  // Client device detection for installation guidance
  const [clientPlatform, setClientPlatform] = useState<'android' | 'ios' | 'desktop'>('desktop');
  const [isStandaloneApp, setIsStandaloneApp] = useState(false);

  // Catalog Settings Toggles (في شاشة الإعدادات)
  const [showBestSellerBadge, setShowBestSellerBadge] = useState(true);
  const [showSavingsBadge, setShowSavingsBadge] = useState(true);
  const [showPieceBreakdown, setShowPieceBreakdown] = useState(true);
  const [showCentralStock, setShowCentralStock] = useState(true);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const ua = window.navigator.userAgent.toLowerCase();
      if (/iphone|ipad|ipod/.test(ua)) {
        setClientPlatform('ios');
      } else if (/android/.test(ua)) {
        setClientPlatform('android');
      } else {
        setClientPlatform('desktop');
      }

      const standalone =
        window.matchMedia('(display-mode: standalone)').matches ||
        (window.navigator as any).standalone === true ||
        document.referrer.includes('android-app://');
      setIsStandaloneApp(!!standalone);
    }
  }, []);

  const departments = ['الكل', 'أدوات منزلية', 'أجهزة كهربائية', 'بلاستيك وميلامين', 'زجاج وبورسلين', 'عروض ترويجية'];

  // البحث الذكي عن المنتجات بأسلوب أمازون
  const filteredProducts = useMemo(() => {
    const qNorm = normalizeArabic(searchQuery);
    let list = products.filter(p => {
      const matchesDept = selectedDepartment === 'الكل' || 
        (selectedDepartment === 'عروض ترويجية' ? (p.promoPrice && p.promoPrice > 0) : p.department === selectedDepartment);
      
      if (!qNorm) return matchesDept;

      const nameNorm = normalizeArabic(p.name || '');
      const codeNorm = normalizeArabic(p.code || '');
      const deptNorm = normalizeArabic(p.department || '');
      const catNorm = normalizeArabic(p.category || '');
      const unifiedNorm = normalizeArabic(p.unifiedCode || '');
      const barcodeNorm = (p.barcode || '').trim().toLowerCase();

      const matchesSearch = 
        nameNorm.includes(qNorm) || 
        codeNorm.includes(qNorm) || 
        deptNorm.includes(qNorm) || 
        catNorm.includes(qNorm) || 
        unifiedNorm.includes(qNorm) ||
        barcodeNorm.includes(qNorm);

      return matchesDept && matchesSearch;
    });

    // الترتيب والفلاتر بأسلوب أمازون
    if (sortBy === 'price_low') {
      list.sort((a, b) => (a.promoPrice || a.cartonPrice || 0) - (b.promoPrice || b.cartonPrice || 0));
    } else if (sortBy === 'price_high') {
      list.sort((a, b) => (b.promoPrice || b.cartonPrice || 0) - (a.promoPrice || a.cartonPrice || 0));
    } else if (sortBy === 'discount') {
      list.sort((a, b) => ((b.promoPrice ? 1 : 0) - (a.promoPrice ? 1 : 0)));
    }
    return list;
  }, [products, selectedDepartment, searchQuery, sortBy]);

  // البحث الذكي عن العملاء بالاسم، الكود، المحل، أو رقم الهاتف
  const filteredCustomers = useMemo(() => {
    const q = normalizeArabic(customerSearchQuery);
    if (!q) return customers.slice(0, 30);
    return customers.filter(c => {
      const name = normalizeArabic(c.name || '');
      const code = normalizeArabic(c.code || '');
      const store = normalizeArabic(c.storeName || '');
      const phone = (c.phone || '').trim();
      const city = normalizeArabic(c.region || c.governorate || c.branchName || '');
      return name.includes(q) || code.includes(q) || store.includes(q) || phone.includes(q) || city.includes(q);
    }).slice(0, 30);
  }, [customers, customerSearchQuery]);

  const selectedCustomer = customers.find(c => c.id === selectedCustomerId) || customers[0];

  const cartItemsCount = Object.values(flutterCart).reduce((sum, item) => sum + item.quantity, 0);
  const cartSubtotal = Object.values(flutterCart).reduce((sum, item) => {
    const price = item.product.promoPrice || item.product.cartonPrice || 1000;
    return sum + (item.quantity * price);
  }, 0);

  // حساب الحالة الائتمانية للعميل
  const customerBalance = selectedCustomer?.balance || selectedCustomer?.currentBalance || 0;
  const customerCreditLimit = selectedCustomer?.creditLimit || 50000;
  const remainingCredit = Math.max(0, customerCreditLimit - customerBalance);
  const isCreditExceeded = customerBalance > customerCreditLimit;
  const isCreditNearLimit = !isCreditExceeded && customerBalance > (customerCreditLimit * 0.8);

  const handleAddToCart = (product: any, delta = 1) => {
    setFlutterCart(prev => {
      const current = prev[product.id]?.quantity || 0;
      const newQty = current + delta;
      if (newQty <= 0) {
        const next = { ...prev };
        delete next[product.id];
        return next;
      }
      return {
        ...prev,
        [product.id]: { quantity: newQty, product }
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

  const handleConfirmOrder = () => {
    if (!selectedCustomer || cartItemsCount === 0) return;
    
    const newInvoiceId = `inv-${Date.now()}`;
    const invNum = `INV-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const nowStr = new Date().toISOString();

    const invoiceItems = Object.values(flutterCart).map(item => {
      const p = item.product;
      const cartonPrice = p.promoPrice || p.cartonPrice || 1000;
      const factor = p.cartonQuantity || p.factor || 12;
      return {
        productId: p.id,
        productCode: p.code,
        productName: p.name,
        category: p.department || p.category || 'عام',
        cartonQuantity: factor,
        cartons: item.quantity,
        cartonCount: item.quantity,
        pieces: 0,
        pieceCount: 0,
        totalPieces: item.quantity * factor,
        cartonPrice: cartonPrice,
        unitPrice: cartonPrice,
        totalPrice: item.quantity * cartonPrice,
      };
    });

    createOrder({
      id: newInvoiceId,
      invoiceNumber: invNum,
      customerName: selectedCustomer.name,
      customerCode: selectedCustomer.code,
      customerPhone: selectedCustomer.phone || '',
      customerAddress: selectedCustomer.address || selectedCustomer.region || '',
      customerTaxNumber: selectedCustomer.taxNumber || '',
      date: nowStr.slice(0, 10),
      time: nowStr.slice(11, 19),
      repId: currentUser?.id || 'u-rep',
      repName: currentUser?.name || 'مندوب المبيعات',
      supervisorName: currentUser?.supervisorId ? (users.find(u => u.id === currentUser.supervisorId)?.name || 'مشرف المناديب') : 'مشرف المناديب',
      branchName: currentUser?.branchName || selectedCustomer.branchName || 'الفرع الرئيسي',
      items: invoiceItems as any,
      totalCartons: cartItemsCount,
      totalPieces: invoiceItems.reduce((sum, it) => sum + it.totalPieces, 0),
      subtotal: cartSubtotal,
      discountPercentage: 0,
      discountAmount: 0,
      estimatedGrandTotal: cartSubtotal,
      paymentMethod: paymentType === 'نقدي' ? 'نقدي (كاش)' : 'آجل (30 يوم)',
      status: 'قيد مراجعة المشرف',
      notes: orderNotes ? `${orderNotes} (حفظ وتحويل للمراجعة من كتالوج الموبايل)` : 'طلبية مسجلة من كتالوج الموبايل (حفظ وتحويل للمراجعة)',
      syncedToAccounting: false,
    });

    setOrderSuccessMessage(`تم حفظ وتحويل الطلبية للمراجعة بنجاح برقم (${invNum}) للعميل (${selectedCustomer.name}) بقيمة ${formatCurrency(cartSubtotal)}! ووصلت فوراً لمشرفك للاعتماد.`);
    setFlutterCart({});
    setTimeout(() => {
      setOrderSuccessMessage(null);
      setActiveFlutterTab('invoices');
    }, 2500);
  };

  const copyAppInstallLink = () => {
    navigator.clipboard.writeText(window.location.href);
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2000);
  };

  return (
    <div className="space-y-4">
      {/* 1. الشريط العلوي الذكي: محاكي الأجهزة وتنسيق الشاشات وتثبيت التطبيق */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-850 to-amber-950 p-4 sm:p-5 rounded-3xl border-2 border-amber-500/40 shadow-2xl flex flex-col lg:flex-row items-center justify-between gap-4 text-white">
        <div className="flex items-center gap-3.5">
          <div className="w-12 h-12 rounded-2xl bg-amber-500/20 border border-amber-400/50 flex items-center justify-center text-amber-400 shrink-0 shadow-inner">
            <Sparkles className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="text-base sm:text-lg font-black text-amber-300">
                منظومة طنطاوي — كتالوج أمازون الذكي & تطبيق فلاتر الموحد
              </h2>
              <span className="bg-amber-400 text-slate-950 text-[10px] font-black px-2 py-0.5 rounded-full shadow-sm flex items-center gap-1">
                <Flame className="w-3 h-3 text-slate-950 fill-slate-950" />
                <span>Amazon Experience</span>
              </span>
              {isStandaloneApp && (
                <span className="bg-emerald-500 text-slate-950 text-[10px] font-black px-2 py-0.5 rounded-full shadow-sm flex items-center gap-1">
                  <CheckCircle2 className="w-3 h-3" />
                  <span>تطبيق مثبت أصلي (Standalone)</span>
                </span>
              )}
            </div>
            <p className="text-xs text-slate-300 mt-1 leading-relaxed">
              تصميم كروت المبيعات بأسلوب أمازون، بحث فوري للعملاء والأصناف بالاسم والكود، وتثبيت التطبيق للأندرويد والآيفون بدون علامة المتصفح.
            </p>
          </div>
        </div>

        {/* أزرار محاكاة حجم الشاشة والتنسيق لكل جهاز */}
        <div className="flex items-center gap-1.5 bg-slate-900/90 p-1.5 rounded-2xl border border-slate-700 shrink-0 flex-wrap justify-center">
          <button
            onClick={() => {
              setDeviceMode('android');
              setIsFramedSimulator(true);
            }}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer ${
              deviceMode === 'android' ? 'bg-amber-500 text-slate-950 shadow font-black' : 'text-slate-300 hover:text-white'
            }`}
            title="مظهر فلاتر على هواتف أندرويد (Material 3)"
          >
            <Smartphone className="w-4 h-4" />
            <span>أندرويد</span>
          </button>

          <button
            onClick={() => {
              setDeviceMode('ios');
              setIsFramedSimulator(true);
            }}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer ${
              deviceMode === 'ios' ? 'bg-amber-500 text-slate-950 shadow font-black' : 'text-slate-300 hover:text-white'
            }`}
            title="مظهر فلاتر على هواتف آيفون (Cupertino)"
          >
            <Smartphone className="w-4 h-4" />
            <span>آيفون</span>
          </button>

          <button
            onClick={() => {
              setDeviceMode('tablet');
              setIsFramedSimulator(false);
            }}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer ${
              deviceMode === 'tablet' ? 'bg-amber-500 text-slate-950 shadow font-black' : 'text-slate-300 hover:text-white'
            }`}
            title="مظهر فلاتر على التابلت والأجهزة اللوحية"
          >
            <Tablet className="w-4 h-4" />
            <span>تابلت</span>
          </button>

          <button
            onClick={() => {
              setDeviceMode('web');
              setIsFramedSimulator(false);
            }}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer ${
              deviceMode === 'web' ? 'bg-amber-500 text-slate-950 shadow font-black' : 'text-slate-300 hover:text-white'
            }`}
            title="مظهر فلاتر ويب للأجهزة المكتبية (Web Desktop)"
          >
            <Monitor className="w-4 h-4" />
            <span>ويب كمبيوتر</span>
          </button>

          {/* تبديل إطار الهاتف / الشاشة الكاملة */}
          {(deviceMode === 'android' || deviceMode === 'ios') && (
            <button
              onClick={() => setIsFramedSimulator(!isFramedSimulator)}
              className="p-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-amber-300 text-xs font-bold border border-slate-600 transition cursor-pointer"
              title={isFramedSimulator ? 'عرض كشاشة كاملة متجاوبة' : 'عرض داخل إطار الهاتف'}
            >
              {isFramedSimulator ? <Maximize2 className="w-4 h-4" /> : <Minimize2 className="w-4 h-4" />}
            </button>
          )}

          <button
            onClick={() => setActiveFlutterTab('settings')}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition shadow cursor-pointer mr-1 ${
              activeFlutterTab === 'settings'
                ? 'bg-emerald-500 text-slate-950 font-black'
                : 'bg-emerald-600 hover:bg-emerald-500 text-white'
            }`}
            title="الإعدادات ومركز تحميل وتثبيت التطبيق بدون شريط المتصفح"
          >
            <Settings className="w-4 h-4" />
            <span>الإعدادات والتحميل 📲</span>
          </button>
        </div>
      </div>

      {/* 2. مساحة المحاكاة والعرض المتجاوب لكل شاشة */}
      <div className="flex justify-center items-start py-1">
        <div
          className={`transition-all duration-300 bg-slate-950 shadow-2xl overflow-hidden flex flex-col text-slate-900 w-full ${
            isFramedSimulator && deviceMode === 'android'
              ? 'max-w-[420px] h-[850px] rounded-[42px] border-[10px] border-slate-800 ring-4 ring-slate-900/50'
              : isFramedSimulator && deviceMode === 'ios'
              ? 'max-w-[410px] h-[850px] rounded-[48px] border-[10px] border-slate-850 ring-4 ring-slate-900/50'
              : deviceMode === 'tablet'
              ? 'max-w-4xl min-h-[820px] rounded-3xl border-4 border-slate-800'
              : 'max-w-full min-h-[820px] rounded-2xl border-2 border-slate-700'
          }`}
        >
          {/* شريط حالة الهاتف في وضع الإطار */}
          {isFramedSimulator && (
            <div className="bg-slate-900 text-white px-6 py-2 flex items-center justify-between text-[11px] select-none shrink-0 border-b border-slate-800">
              <span className="font-mono font-bold">11:30</span>
              {deviceMode === 'ios' && (
                <div className="w-24 h-4 bg-black rounded-full mx-auto" />
              )}
              <div className="flex items-center gap-1.5 text-xs text-amber-400">
                <span>5G</span>
                <span>📶</span>
                <span>🔋 100%</span>
              </div>
            </div>
          )}

          {/* هيدر تطبيق Flutter مع شريط بحث أمازون واختيار العميل */}
          <div className="bg-slate-900 text-white px-4 sm:px-6 py-3 border-b border-slate-800 shrink-0 space-y-2.5">
            <div className="flex items-center justify-between gap-3">
              <div className="flex items-center gap-3 min-w-0">
                <div className="w-10 h-10 rounded-2xl bg-white p-0.5 border-2 border-amber-400 flex items-center justify-center overflow-hidden shrink-0 shadow-md">
                  <img src="/pwa-192x192.png" alt="الطنطاوي" className="w-full h-full object-contain" />
                </div>
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-black text-sm sm:text-base text-white tracking-tight truncate">
                      مجموعة الطنطاوي للتجارة والتوزيع
                    </h3>
                    <span className="bg-amber-400 text-slate-950 text-[10px] font-black px-2 py-0.5 rounded shrink-0">
                      TANTAWY
                    </span>
                  </div>
                  <p className="text-[10px] sm:text-[11px] text-slate-400 truncate">
                    {currentUser?.name || 'مندوب المبيعات'} • {currentUser?.branchName || 'فرع القاهرة'}
                  </p>
                </div>
              </div>

              {/* أزرار الإجراءات السريعة في الهيدر */}
              <div className="flex items-center gap-2 shrink-0">
                <button
                  onClick={() => setActiveFlutterTab('settings')}
                  className="p-2 rounded-xl bg-slate-800 hover:bg-slate-750 text-slate-300 hover:text-white transition border border-slate-700 cursor-pointer"
                  title="الإعدادات ومركز تحميل وتثبيت التطبيق"
                >
                  <Settings className="w-4 h-4 text-emerald-400" />
                </button>

                <button
                  onClick={() => setActiveFlutterTab('cart')}
                  className="relative flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 transition font-black text-xs cursor-pointer shadow-sm"
                  title="سلة الطلبية"
                >
                  <ShoppingBag className="w-4 h-4 text-slate-950" />
                  <span className="hidden sm:inline">السلة</span>
                  {cartItemsCount > 0 && (
                    <span className="bg-slate-950 text-amber-400 text-[10px] font-black px-1.5 py-0.2 rounded-full">
                      {cartItemsCount}
                    </span>
                  )}
                </button>
              </div>
            </div>

            {/* شريط بحث أمازون الموحد في الهيدر (البحث الذكي بالاسم والكود) */}
            {activeFlutterTab === 'catalog' && (
              <div className="relative">
                <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="ابحث في الكتالوج الذكي بالاسم، كود الصنف، الباركود، الكود الموحد (#)، أو الشدة..."
                  className="w-full bg-slate-800 text-slate-100 pr-10 pl-9 py-2.5 text-xs sm:text-sm rounded-xl border border-slate-700 focus:outline-none focus:border-amber-400 font-bold placeholder:text-slate-400 shadow-inner"
                />
                {searchQuery && (
                  <button
                    onClick={() => setSearchQuery('')}
                    className="absolute left-3 top-2.5 text-slate-400 hover:text-white cursor-pointer"
                  >
                    <X className="w-4 h-4" />
                  </button>
                )}
              </div>
            )}
          </div>

          {/* جسم التطبيق المتجاوب بأسلوب Flutter */}
          <div className="flex-1 flex overflow-hidden bg-slate-100">
            
            {/* في وضع الويب أو التابلت: قائمة الملاحة الجانبية (NavigationRail) */}
            {(!isFramedSimulator || deviceMode === 'web' || deviceMode === 'tablet') && (
              <div className="w-16 sm:w-56 bg-slate-900 border-l border-slate-800 p-2 sm:p-3 flex flex-col justify-between shrink-0 select-none">
                <div className="space-y-1.5">
                  <div className="hidden sm:block text-[10px] font-bold text-slate-400 px-3 py-2 uppercase tracking-wider">
                    أقسام المنظومة
                  </div>
                  {[
                    { id: 'catalog', label: 'كتالوج أمازون', icon: Boxes },
                    { id: 'home', label: 'الرئيسية والمبيعات', icon: TrendingUp },
                    { id: 'cart', label: 'سلة الطلبيات', icon: ShoppingBag, badge: cartItemsCount },
                    { id: 'invoices', label: 'الفواتير والطباعة', icon: Receipt },
                    { id: 'visits', label: 'الزيارات وGPS', icon: MapPin },
                    { id: 'settings', label: 'الإعدادات والتحميل', icon: Settings },
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

                <div className="hidden sm:block p-3 rounded-2xl bg-slate-950/80 border border-slate-800 text-[11px] text-slate-400 space-y-1">
                  <div className="flex items-center gap-1.5 text-emerald-400 font-bold">
                    <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
                    <span>Supabase Live</span>
                  </div>
                  <div>قاعدة البيانات متصلة ومزامنة.</div>
                </div>
              </div>
            )}

            {/* مساحة المحتوى المركزية (Center Workspace) */}
            <div className="flex-1 overflow-y-auto p-3 sm:p-5 space-y-4">
              
              {/* رسالة نجاح حفظ الطلبية */}
              {orderSuccessMessage && (
                <div className="bg-emerald-600 text-white p-4 rounded-2xl text-xs sm:text-sm font-bold flex items-center gap-3 shadow-lg animate-in fade-in">
                  <CheckCircle2 className="w-6 h-6 shrink-0" />
                  <span>{orderSuccessMessage}</span>
                </div>
              )}

              {/* 1. شاشة الكتالوج بأسلوب ومبيعات أمازون مع شريط اختيار العميل المباشر */}
              {activeFlutterTab === 'catalog' && (
                <div className="space-y-4">
                  
                  {/* شريط اختيار العميل والبحث الذكي بالاسم أو الكود (Customer Smart Selector Bar) */}
                  <div className="bg-white p-3.5 sm:p-4 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <Users className="w-4 h-4 text-amber-500" />
                        <span className="text-xs font-black text-slate-900">
                          العميل المخصص للطلبية (بحث فوري بالاسم أو الكود أو المحل):
                        </span>
                      </div>
                      <span className="text-[11px] text-slate-500 font-semibold">
                        {customers.length} عميل مسجل في قاعدة البيانات
                      </span>
                    </div>

                    {/* حقل البحث الذكي الفوري عن العميل بالاسم أو الكود */}
                    <div className="relative">
                      <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
                      <input
                        type="text"
                        value={customerSearchQuery}
                        onChange={(e) => {
                          setCustomerSearchQuery(e.target.value);
                          setIsCustomerDropdownOpen(true);
                        }}
                        onFocus={() => setIsCustomerDropdownOpen(true)}
                        placeholder="ابحث بالاسم (مثال: الأمل)، أو الكود (CUST-001)، أو اسم المحل، أو الموبايل..."
                        className="w-full bg-slate-50 pr-10 pl-9 py-2.5 text-xs sm:text-sm rounded-xl border border-slate-300 focus:outline-none focus:border-amber-400 font-bold"
                      />
                      {customerSearchQuery && (
                        <button
                          onClick={() => {
                            setCustomerSearchQuery('');
                            setIsCustomerDropdownOpen(false);
                          }}
                          className="absolute left-3 top-2.5 text-slate-400 hover:text-slate-600 cursor-pointer"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      )}
                    </div>

                    {/* قائمة نتائج البحث السريعة للعملاء المنسدلة */}
                    {isCustomerDropdownOpen && (
                      <div className="max-h-60 overflow-y-auto border border-slate-200 rounded-xl bg-white shadow-xl divide-y divide-slate-100 z-20 relative">
                        {filteredCustomers.length === 0 ? (
                          <div className="p-4 text-center text-xs text-slate-400">
                            لا يوجد عميل مطابق لكلمة البحث
                          </div>
                        ) : (
                          filteredCustomers.map(c => (
                            <div
                              key={c.id}
                              onClick={() => {
                                setSelectedCustomerId(c.id);
                                setIsCustomerDropdownOpen(false);
                                setCustomerSearchQuery('');
                              }}
                              className={`p-3 text-xs hover:bg-amber-50 transition cursor-pointer flex items-center justify-between ${
                                selectedCustomerId === c.id ? 'bg-amber-50/90 font-bold' : ''
                              }`}
                            >
                              <div className="min-w-0 pr-1">
                                <div className="font-black text-slate-900 flex items-center gap-2">
                                  <span className="truncate">{c.name}</span>
                                  <span className="font-mono text-[10px] bg-slate-900 text-amber-400 px-1.5 py-0.2 rounded font-bold">
                                    {c.code}
                                  </span>
                                  {c.tier && (
                                    <span className="text-[10px] bg-slate-100 text-slate-600 px-1.5 py-0.2 rounded">
                                      {c.tier}
                                    </span>
                                  )}
                                </div>
                                <div className="text-[11px] text-slate-500 mt-0.5 truncate">
                                  المحل: {c.storeName || 'معرض تجاري'} • الهاتف: {c.phone || '—'} • الفرع: {c.branchName || 'الرئيسي'}
                                </div>
                              </div>
                              <div className="text-left shrink-0 pl-1">
                                <div className="text-[10px] text-slate-400">المديونية:</div>
                                <div className="font-black text-xs text-slate-900">
                                  {formatCurrency(c.balance || c.currentBalance || 0)}
                                </div>
                              </div>
                            </div>
                          ))
                        )}
                      </div>
                    )}

                    {/* بطاقة العميل المختار الشاملة (Customer Credit Card) */}
                    {selectedCustomer && (
                      <div className="p-3.5 rounded-2xl bg-gradient-to-r from-slate-50 via-amber-50/30 to-slate-50 border border-amber-300/80 text-xs space-y-2">
                        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className={`w-2.5 h-2.5 rounded-full ${
                              isCreditExceeded ? 'bg-red-500 animate-pulse' : isCreditNearLimit ? 'bg-amber-500' : 'bg-emerald-500'
                            }`} />
                            <span className="font-black text-sm text-slate-900">{selectedCustomer.name}</span>
                            <span className="font-mono text-xs bg-slate-900 text-amber-400 px-2 py-0.2 rounded font-bold">
                              {selectedCustomer.code}
                            </span>
                            <span className="text-[11px] text-slate-600 font-semibold">
                              ({selectedCustomer.storeName || 'معرض تجاري'})
                            </span>
                          </div>

                          <div className="flex items-center gap-2">
                            {selectedCustomer.phone && (
                              <a
                                href={`tel:${selectedCustomer.phone}`}
                                className="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-emerald-600 text-white text-[11px] font-bold hover:bg-emerald-500 transition"
                                title="اتصال هاتفي"
                              >
                                <Phone className="w-3 h-3" />
                                <span>اتصال</span>
                              </a>
                            )}
                            <button
                              onClick={() => setIsCustomerDropdownOpen(true)}
                              className="px-2.5 py-1 rounded-lg bg-slate-200 hover:bg-slate-300 text-slate-800 text-[11px] font-bold transition cursor-pointer"
                            >
                              تغيير العميل 🔄
                            </button>
                          </div>
                        </div>

                        {/* مؤشرات الحد الائتماني والمديونية */}
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-2 border-t border-slate-200 text-[11px]">
                          <div>
                            <span className="text-slate-500 block">الحد الائتماني:</span>
                            <span className="font-black text-slate-900">{formatCurrency(customerCreditLimit)}</span>
                          </div>
                          <div>
                            <span className="text-slate-500 block">المديونية الحالية:</span>
                            <span className={`font-black ${isCreditExceeded ? 'text-red-600' : 'text-slate-900'}`}>
                              {formatCurrency(customerBalance)}
                            </span>
                          </div>
                          <div>
                            <span className="text-slate-500 block">المتبقي المتاح:</span>
                            <span className="font-black text-emerald-700">{formatCurrency(remainingCredit)}</span>
                          </div>
                          <div>
                            <span className="text-slate-500 block">حالة الائتمان:</span>
                            <span className={`font-black ${
                              isCreditExceeded ? 'text-red-600' : isCreditNearLimit ? 'text-amber-600' : 'text-emerald-700'
                            }`}>
                              {isCreditExceeded ? '⚠️ تجاوز الحد' : isCreditNearLimit ? 'قريب من الحد' : 'سليم ومسموح'}
                            </span>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* شريط الأقسام والفرز وطريقة العرض بأسلوب أمازون */}
                  <div className="bg-white p-3 sm:p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-3 items-center justify-between">
                    {/* أقسام المنتجات (Department Slicer) */}
                    <div className="flex gap-1.5 overflow-x-auto w-full sm:w-auto pb-1 scrollbar-none">
                      {departments.map(dept => (
                        <button
                          key={dept}
                          onClick={() => setSelectedDepartment(dept)}
                          className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition cursor-pointer ${
                            selectedDepartment === dept
                              ? 'bg-amber-500 text-slate-950 font-black shadow-sm'
                              : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                          }`}
                        >
                          {dept === 'عروض ترويجية' ? '🔥 عروض ترويجية' : dept}
                        </button>
                      ))}
                    </div>

                    {/* أدوات الترتيب وطريقة العرض (شبكة أمازون vs قائمة مدمجة) */}
                    <div className="flex items-center gap-2.5 w-full sm:w-auto justify-end text-xs">
                      {/* زر تبديل العرض شبكة / قائمة */}
                      <div className="flex items-center bg-slate-100 p-1 rounded-xl border border-slate-200">
                        <button
                          onClick={() => setCatalogViewMode('grid')}
                          className={`p-1.5 rounded-lg transition cursor-pointer ${
                            catalogViewMode === 'grid' ? 'bg-amber-400 text-slate-950 shadow-xs' : 'text-slate-500 hover:text-slate-900'
                          }`}
                          title="عرض شبكة كروت أمازون الفخمة"
                        >
                          <Grid className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => setCatalogViewMode('list')}
                          className={`p-1.5 rounded-lg transition cursor-pointer ${
                            catalogViewMode === 'list' ? 'bg-amber-400 text-slate-950 shadow-xs' : 'text-slate-500 hover:text-slate-900'
                          }`}
                          title="عرض قائمة مدمجة وسريعة للمناديب"
                        >
                          <List className="w-4 h-4" />
                        </button>
                      </div>

                      <div className="flex items-center gap-1.5">
                        <SlidersHorizontal className="w-3.5 h-3.5 text-slate-400" />
                        <span className="text-slate-500 font-bold hidden sm:inline">ترتيب:</span>
                        <select
                          value={sortBy}
                          onChange={(e) => setSortBy(e.target.value as any)}
                          className="bg-slate-50 border border-slate-200 rounded-xl py-1 px-2 text-xs font-bold focus:outline-none"
                        >
                          <option value="recommended">⭐ المقترحة والأكثر طلباً</option>
                          <option value="discount">🔥 أكبر نسبة خصم</option>
                          <option value="price_low">💰 السعر: من الأقل للأعلى</option>
                          <option value="price_high">💎 السعر: من الأعلى للأقل</option>
                        </select>
                      </div>
                    </div>
                  </div>

                  {/* عدد النتائج المتاحة */}
                  <div className="flex items-center justify-between text-xs text-slate-500 font-bold px-1">
                    <span>عرض {filteredProducts.length} صنف متاح للطلب الفوري</span>
                    <span>مخزن أكتوبر الرئيسي + رصيد الفروع الحية</span>
                  </div>

                  {/* 1.A عرض شبكة كروت أمازون الفاخرة (Amazon Grid View) */}
                  {catalogViewMode === 'grid' && (
                    <div className={`grid gap-3.5 ${
                      deviceMode === 'web'
                        ? 'grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4'
                        : deviceMode === 'tablet'
                        ? 'grid-cols-2 lg:grid-cols-3'
                        : 'grid-cols-1 sm:grid-cols-2'
                    }`}>
                      {filteredProducts.slice(0, 36).map((prod, idx) => {
                        const cartItem = flutterCart[prod.id];
                        const qty = cartItem?.quantity || 0;
                        const hasPromo = prod.promoPrice && prod.promoPrice < prod.cartonPrice;
                        const discountPct = hasPromo 
                          ? Math.round(((prod.cartonPrice - prod.promoPrice) / prod.cartonPrice) * 100) 
                          : (idx % 3 === 0 ? 15 : null);
                        const originalPrice = prod.cartonPrice || 1200;
                        const effectivePrice = prod.promoPrice || (discountPct ? originalPrice * (1 - discountPct/100) : originalPrice);
                        const savings = originalPrice - effectivePrice;
                        const isBestSeller = idx % 4 === 0;

                        return (
                          <div
                            key={prod.id}
                            className="bg-white rounded-2xl border border-slate-200 hover:border-amber-400 hover:shadow-xl transition-all duration-200 flex flex-col justify-between overflow-hidden group relative"
                          >
                            <div>
                              {/* شارات أمازون وصورة الصنف */}
                              <div className="relative bg-slate-50 p-3 flex items-center justify-center min-h-[170px] border-b border-slate-100">
                                {/* شارة الأكثر مبيعاً */}
                                {showBestSellerBadge && isBestSeller && (
                                  <div className="absolute top-2.5 right-2.5 bg-gradient-to-r from-amber-600 to-amber-500 text-white text-[10px] font-black px-2 py-0.5 rounded shadow-sm flex items-center gap-1 z-10">
                                    <Flame className="w-3 h-3 text-yellow-200 fill-yellow-200" />
                                    <span>الأكثر مبيعاً #1</span>
                                  </div>
                                )}

                                {/* شارة الخصم % */}
                                {showSavingsBadge && discountPct && (
                                  <div className="absolute top-2.5 left-2.5 bg-rose-600 text-white text-[10px] font-black px-2 py-0.5 rounded shadow-sm z-10">
                                    خصم {discountPct}%
                                  </div>
                                )}

                                {/* صورة الصنف مع إمكانية التكبير والمعاينة */}
                                <div
                                  onClick={() => setSelectedProductDetails(prod)}
                                  className="w-32 h-32 flex items-center justify-center overflow-hidden transition-transform duration-300 group-hover:scale-105 cursor-pointer"
                                  title="اضغط لمعاينة الصنف وتفاصيل الشدة"
                                >
                                  {prod.imageUrl ? (
                                    <img src={prod.imageUrl} alt={prod.name} className="w-full h-full object-contain" />
                                  ) : (
                                    <Boxes className="w-20 h-20 text-amber-500/80" />
                                  )}
                                </div>

                                {/* زر المعاينة السريعة */}
                                <button
                                  onClick={() => setSelectedProductDetails(prod)}
                                  className="absolute bottom-2 left-2 p-1.5 rounded-lg bg-white/90 hover:bg-white text-slate-700 shadow-sm border border-slate-200 text-[10px] font-bold flex items-center gap-1 cursor-pointer"
                                >
                                  <Eye className="w-3 h-3" />
                                  <span>تفاصيل</span>
                                </button>
                              </div>

                              {/* تفاصيل الصنف بأسلوب أمازون */}
                              <div className="p-3.5 space-y-2">
                                {/* الكود والتصنيف */}
                                <div className="flex items-center gap-1.5 flex-wrap">
                                  <span className="text-[10px] font-mono font-black bg-slate-900 text-amber-400 px-1.5 py-0.5 rounded">
                                    {prod.code}
                                  </span>
                                  <span className="text-[11px] text-slate-500 font-semibold truncate">
                                    {prod.department} • {prod.category || 'عام'}
                                  </span>
                                </div>

                                {/* اسم الصنف */}
                                <h4
                                  onClick={() => setSelectedProductDetails(prod)}
                                  className="font-black text-xs sm:text-sm text-slate-900 line-clamp-2 leading-snug cursor-pointer hover:text-amber-600 transition"
                                >
                                  {prod.name}
                                </h4>

                                {/* التقييم بالنجوم بأسلوب أمازون */}
                                <div className="flex items-center gap-1 text-[11px]">
                                  <div className="flex text-amber-400">
                                    {[...Array(5)].map((_, i) => (
                                      <Star key={i} className="w-3 h-3 fill-amber-400 text-amber-400" />
                                    ))}
                                  </div>
                                  <span className="font-bold text-slate-700">4.9</span>
                                  <span className="text-slate-400 text-[10px]">({(idx * 17 + 42)} طلبية)</span>
                                </div>

                                {/* الأسعار ونسبة الوفر */}
                                <div className="pt-1 space-y-0.5">
                                  <div className="flex items-baseline gap-2 flex-wrap">
                                    <span className="text-base sm:text-lg font-black text-slate-950">
                                      {formatCurrency(effectivePrice)}
                                    </span>
                                    {savings > 0 && (
                                      <span className="text-xs text-slate-400 line-through">
                                        {formatCurrency(originalPrice)}
                                      </span>
                                    )}
                                    <span className="text-[11px] text-slate-500 font-bold">/ كرتونة</span>
                                  </div>

                                  {showSavingsBadge && savings > 0 && (
                                    <div className="text-[11px] font-bold text-emerald-700 flex items-center gap-1">
                                      <Tag className="w-3 h-3" />
                                      <span>وفرت: {formatCurrency(savings)} بالكرتونة</span>
                                    </div>
                                  )}

                                  {showPieceBreakdown && (
                                    <div className="text-[10px] text-slate-500">
                                      شدة الكرتونة: <strong>{prod.cartonQuantity || 1} قطعة</strong> (سعر القطعة: {formatCurrency(effectivePrice / (prod.cartonQuantity || 1))})
                                    </div>
                                  )}
                                </div>

                                {/* شارة التوفر والشحن الفوري */}
                                <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[11px]">
                                  {showCentralStock && (
                                    <div className="flex items-center gap-1 text-emerald-700 font-bold">
                                      <Truck className="w-3.5 h-3.5 text-emerald-600" />
                                      <span>مخزن أكتوبر فوري</span>
                                    </div>
                                  )}
                                  <span className="text-[10px] text-slate-500 font-semibold">
                                    الفرع: {(prod.branchStockActual || 15) - (prod.branchStockReserved || 0)} ك
                                  </span>
                                </div>
                              </div>
                            </div>

                            {/* زر الإضافة للسلة بأسلوب أمازون الكهرماني مع عداد الكمية */}
                            <div className="p-3 pt-0">
                              {qty === 0 ? (
                                <button
                                  onClick={() => handleAddToCart(prod)}
                                  className="w-full bg-amber-400 hover:bg-amber-300 active:bg-amber-500 text-slate-950 font-black py-2 rounded-xl text-xs flex items-center justify-center gap-1.5 shadow-sm transition active:scale-98 cursor-pointer border border-amber-500/30"
                                >
                                  <Plus className="w-4 h-4" />
                                  <span>أضف للطلبية 🛒</span>
                                </button>
                              ) : (
                                <div className="flex items-center justify-between bg-amber-50 border border-amber-300 p-1.5 rounded-xl">
                                  <span className="text-xs font-black text-amber-950 pr-2">
                                    {qty} كرتونة بالسلة
                                  </span>
                                  <div className="flex items-center gap-1.5">
                                    <button
                                      onClick={() => handleRemoveFromCart(prod.id)}
                                      className="w-7 h-7 rounded-lg bg-white text-slate-800 hover:bg-slate-100 flex items-center justify-center font-bold shadow-xs cursor-pointer"
                                      title="إنقاص كرتونة"
                                    >
                                      <Minus className="w-3.5 h-3.5" />
                                    </button>
                                    <button
                                      onClick={() => handleAddToCart(prod)}
                                      className="w-7 h-7 rounded-lg bg-amber-400 hover:bg-amber-300 text-slate-950 flex items-center justify-center font-bold shadow-xs cursor-pointer"
                                      title="زيادة كرتونة"
                                    >
                                      <Plus className="w-3.5 h-3.5" />
                                    </button>
                                  </div>
                                </div>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}

                  {/* 1.B عرض قائمة مدمجة للمناديب (Compact Row View) */}
                  {catalogViewMode === 'list' && (
                    <div className="space-y-2">
                      {filteredProducts.slice(0, 40).map((prod) => {
                        const cartItem = flutterCart[prod.id];
                        const qty = cartItem?.quantity || 0;
                        const price = prod.promoPrice || prod.cartonPrice || 1000;

                        return (
                          <div
                            key={prod.id}
                            className="bg-white p-3 rounded-2xl border border-slate-200 hover:border-amber-400 shadow-xs flex items-center justify-between gap-3"
                          >
                            <div className="flex items-center gap-3 min-w-0">
                              <div
                                onClick={() => setSelectedProductDetails(prod)}
                                className="w-14 h-14 rounded-xl bg-slate-50 border border-slate-100 p-1 flex items-center justify-center shrink-0 cursor-pointer"
                              >
                                {prod.imageUrl ? (
                                  <img src={prod.imageUrl} alt={prod.name} className="w-full h-full object-contain" />
                                ) : (
                                  <Boxes className="w-8 h-8 text-amber-500" />
                                )}
                              </div>
                              <div className="min-w-0">
                                <div className="flex items-center gap-2">
                                  <span className="font-mono text-[10px] bg-slate-900 text-amber-400 px-1.5 py-0.2 rounded font-bold">
                                    {prod.code}
                                  </span>
                                  <span className="text-[11px] text-slate-500 truncate">{prod.department}</span>
                                </div>
                                <h4
                                  onClick={() => setSelectedProductDetails(prod)}
                                  className="font-bold text-xs sm:text-sm text-slate-900 truncate cursor-pointer hover:text-amber-600"
                                >
                                  {prod.name}
                                </h4>
                                <div className="text-[11px] text-slate-500">
                                  سعر الكرتونة: <strong className="text-slate-900">{formatCurrency(price)}</strong> • الشدة: {prod.cartonQuantity || 1} ق
                                </div>
                              </div>
                            </div>

                            <div className="flex items-center gap-2 shrink-0">
                              {qty === 0 ? (
                                <button
                                  onClick={() => handleAddToCart(prod)}
                                  className="px-3 py-1.5 rounded-xl bg-amber-400 hover:bg-amber-300 text-slate-950 font-bold text-xs flex items-center gap-1 shadow-xs cursor-pointer"
                                >
                                  <Plus className="w-3.5 h-3.5" />
                                  <span>طلب</span>
                                </button>
                              ) : (
                                <div className="flex items-center gap-1.5 bg-amber-50 border border-amber-300 px-2 py-1 rounded-xl">
                                  <button
                                    onClick={() => handleRemoveFromCart(prod.id)}
                                    className="w-6 h-6 rounded bg-white text-slate-800 flex items-center justify-center font-bold text-xs cursor-pointer"
                                  >
                                    -
                                  </button>
                                  <span className="font-black text-xs px-1 text-amber-950">{qty}</span>
                                  <button
                                    onClick={() => handleAddToCart(prod)}
                                    className="w-6 h-6 rounded bg-amber-400 text-slate-950 flex items-center justify-center font-bold text-xs cursor-pointer"
                                  >
                                    +
                                  </button>
                                </div>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}

                  {/* شريط الإشعار العائم بأسفل الشاشة عند وجود أصناف بالسلة للموبايل */}
                  {cartItemsCount > 0 && (
                    <div className="sticky bottom-2 z-20 bg-slate-900/95 backdrop-blur-md text-white p-3.5 rounded-2xl border border-amber-400/50 shadow-2xl flex items-center justify-between gap-3">
                      <div className="flex items-center gap-2.5">
                        <div className="w-9 h-9 rounded-xl bg-amber-400 text-slate-950 flex items-center justify-center font-black">
                          <ShoppingBag className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-xs font-black text-amber-300">
                            {cartItemsCount} كرتونة محجوزة
                          </div>
                          <div className="text-sm font-black text-white">
                            الصافي: {formatCurrency(cartSubtotal)}
                          </div>
                        </div>
                      </div>

                      <button
                        onClick={() => setActiveFlutterTab('cart')}
                        className="bg-amber-400 hover:bg-amber-300 text-slate-950 font-black px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow transition cursor-pointer"
                      >
                        <span>مراجعة وتأكيد الطلبية ➔</span>
                      </button>
                    </div>
                  )}
                </div>
              )}

              {/* 2. شاشة سلة وحجز الطلبية مع البحث الذكي الفائق للعميل والتأكيد */}
              {activeFlutterTab === 'cart' && (
                <div className="max-w-3xl mx-auto space-y-4">
                  {/* صندوق اختيار العميل الذكي بالاسم أو الكود */}
                  <div className="bg-white p-4 sm:p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <div className="flex items-center justify-between">
                      <label className="text-xs font-black text-slate-900 flex items-center gap-1.5">
                        <Users className="w-4 h-4 text-amber-500" />
                        <span>العميل المستهدف للطلبية (بحث بالاسم أو الكود):</span>
                      </label>
                      <span className="text-[11px] text-slate-500 font-bold">
                        {customers.length} عميل
                      </span>
                    </div>

                    {/* حقل البحث الذكي عن العميل */}
                    <div className="relative">
                      <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
                      <input
                        type="text"
                        value={customerSearchQuery}
                        onChange={(e) => {
                          setCustomerSearchQuery(e.target.value);
                          setIsCustomerDropdownOpen(true);
                        }}
                        onFocus={() => setIsCustomerDropdownOpen(true)}
                        placeholder="ابحث بالاسم (مثال: الأمل)، أو الكود (CUST-001)، أو اسم المحل، أو الموبايل..."
                        className="w-full bg-slate-50 pr-10 pl-9 py-2.5 text-xs rounded-xl border border-slate-300 focus:outline-none focus:border-amber-400 font-bold"
                      />
                      {customerSearchQuery && (
                        <button
                          onClick={() => {
                            setCustomerSearchQuery('');
                            setIsCustomerDropdownOpen(false);
                          }}
                          className="absolute left-3 top-2.5 text-slate-400 hover:text-slate-600"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      )}
                    </div>

                    {/* نتائج البحث المنسدلة */}
                    {isCustomerDropdownOpen && (
                      <div className="max-h-56 overflow-y-auto border border-slate-200 rounded-xl bg-white shadow-xl divide-y divide-slate-100 z-10 relative">
                        {filteredCustomers.length === 0 ? (
                          <div className="p-3 text-center text-xs text-slate-400">
                            لا يوجد عميل مطابق لكلمة البحث
                          </div>
                        ) : (
                          filteredCustomers.map(c => (
                            <div
                              key={c.id}
                              onClick={() => {
                                setSelectedCustomerId(c.id);
                                setIsCustomerDropdownOpen(false);
                                setCustomerSearchQuery('');
                              }}
                              className={`p-2.5 text-xs hover:bg-amber-50 transition cursor-pointer flex items-center justify-between ${
                                selectedCustomerId === c.id ? 'bg-amber-50/80 font-bold' : ''
                              }`}
                            >
                              <div>
                                <div className="font-black text-slate-900 flex items-center gap-1.5">
                                  <span>{c.name}</span>
                                  <span className="font-mono text-[10px] bg-slate-900 text-amber-400 px-1.5 py-0.2 rounded">
                                    {c.code}
                                  </span>
                                </div>
                                <div className="text-[10px] text-slate-500 mt-0.5">
                                  المحل: {c.storeName || 'معرض'} • الهاتف: {c.phone || '—'}
                                </div>
                              </div>
                              <div className="text-left">
                                <div className="text-[10px] text-slate-400">الرصيد:</div>
                                <div className="font-black text-xs text-slate-900">
                                  {formatCurrency(c.balance || c.currentBalance || 0)}
                                </div>
                              </div>
                            </div>
                          ))
                        )}
                      </div>
                    )}

                    {/* بطاقة العميل المختار والتحقق من الحد الائتماني */}
                    {selectedCustomer && (
                      <div className="p-3.5 rounded-2xl bg-gradient-to-r from-slate-50 to-amber-50/40 border border-amber-200/80 text-xs space-y-2">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <span className={`w-2.5 h-2.5 rounded-full ${isCreditExceeded ? 'bg-red-500' : 'bg-emerald-500'}`} />
                            <span className="font-black text-sm text-slate-900">{selectedCustomer.name}</span>
                            <span className="font-mono text-xs bg-slate-900 text-amber-400 px-2 py-0.2 rounded font-bold">
                              {selectedCustomer.code}
                            </span>
                          </div>
                          <span className="text-[11px] text-slate-500 font-bold">{selectedCustomer.branchName || 'فرع القاهرة'}</span>
                        </div>

                        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 pt-2 border-t border-slate-200 text-[11px]">
                          <div>
                            <span className="text-slate-500 block">الحد الائتماني:</span>
                            <span className="font-black text-slate-900">{formatCurrency(customerCreditLimit)}</span>
                          </div>
                          <div>
                            <span className="text-slate-500 block">المديونية الحالية:</span>
                            <span className={`font-black ${isCreditExceeded ? 'text-red-600' : 'text-slate-900'}`}>
                              {formatCurrency(customerBalance)}
                            </span>
                          </div>
                          <div>
                            <span className="text-slate-500 block">المتبقي المتاح:</span>
                            <span className="font-black text-emerald-700">{formatCurrency(remainingCredit)}</span>
                          </div>
                        </div>

                        {isCreditExceeded && (
                          <div className="p-2 rounded-xl bg-red-100 text-red-800 text-[11px] font-bold flex items-center gap-1.5">
                            <ShieldAlert className="w-4 h-4 text-red-600 shrink-0" />
                            <span>تنبيه: مديونية العميل تجاوزت الحد الائتماني المسموح به!</span>
                          </div>
                        )}
                      </div>
                    )}
                  </div>

                  {/* قائمة محتويات السلة */}
                  <div className="bg-white p-4 sm:p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="font-black text-xs text-slate-900">الأصناف المحجوزة بالطلبية ({cartItemsCount} كرتونة)</span>
                      {cartItemsCount > 0 && (
                        <button
                          onClick={() => setFlutterCart({})}
                          className="text-xs text-red-500 hover:underline font-bold cursor-pointer"
                        >
                          مسح السلة
                        </button>
                      )}
                    </div>

                    {cartItemsCount === 0 ? (
                      <div className="text-center py-12 text-slate-400 text-xs space-y-2">
                        <ShoppingBag className="w-12 h-12 mx-auto text-slate-300" />
                        <div>السلة فارغة حالياً. انتقل لقسم الكتالوج لاختيار البضاعة.</div>
                        <button
                          onClick={() => setActiveFlutterTab('catalog')}
                          className="px-4 py-2 bg-amber-400 text-slate-950 font-bold rounded-xl text-xs inline-block cursor-pointer shadow-sm"
                        >
                          فتح الكتالوج الآن
                        </button>
                      </div>
                    ) : (
                      <div className="space-y-2.5">
                        {Object.values(flutterCart).map(item => (
                          <div key={item.product.id} className="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-100 text-xs gap-2">
                            <div className="min-w-0 flex-1">
                              <div className="font-bold text-slate-900 truncate">{item.product.name}</div>
                              <div className="text-[11px] text-slate-500">
                                {item.quantity} كرتونة × {formatCurrency(item.product.promoPrice || item.product.cartonPrice || 1000)}
                              </div>
                            </div>
                            <div className="flex items-center gap-2 shrink-0">
                              <span className="font-black text-xs text-slate-900">
                                {formatCurrency(item.quantity * (item.product.promoPrice || item.product.cartonPrice || 1000))}
                              </span>
                              <div className="flex items-center gap-1">
                                <button
                                  onClick={() => handleRemoveFromCart(item.product.id)}
                                  className="w-6 h-6 rounded bg-slate-200 hover:bg-slate-300 text-slate-800 flex items-center justify-center font-bold cursor-pointer"
                                >
                                  -
                                </button>
                                <span className="font-bold px-1">{item.quantity}</span>
                                <button
                                  onClick={() => handleAddToCart(item.product)}
                                  className="w-6 h-6 rounded bg-amber-400 hover:bg-amber-300 text-slate-950 flex items-center justify-center font-bold cursor-pointer"
                                >
                                  +
                                </button>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* خيارات السداد والملاحظات والترحيل */}
                  {cartItemsCount > 0 && (
                    <div className="bg-white p-4 sm:p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-slate-700 font-bold">طريقة السداد:</span>
                        <div className="flex gap-4">
                          <label className="flex items-center gap-1.5 text-xs font-bold cursor-pointer">
                            <input
                              type="radio"
                              name="pay"
                              checked={paymentType === 'آجل'}
                              onChange={() => setPaymentType('آجل')}
                            />
                            <span>آجل (على الحساب)</span>
                          </label>
                          <label className="flex items-center gap-1.5 text-xs font-bold cursor-pointer">
                            <input
                              type="radio"
                              name="pay"
                              checked={paymentType === 'نقدي'}
                              onChange={() => setPaymentType('نقدي')}
                            />
                            <span>نقدي (كاش فوري)</span>
                          </label>
                        </div>
                      </div>

                      <div>
                        <label className="text-[11px] font-bold text-slate-600 block mb-1">ملاحظات الطلبية / شروط التسليم:</label>
                        <input
                          type="text"
                          value={orderNotes}
                          onChange={(e) => setOrderNotes(e.target.value)}
                          placeholder="مثال: تسليم سيارة الغد، فحص الكراتين بالمعرض..."
                          className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2.5 text-xs font-medium focus:outline-none focus:border-amber-400"
                        />
                      </div>

                      <div className="pt-2 border-t border-slate-100 flex items-center justify-between">
                        <span className="font-black text-xs text-slate-800">الصافي المطلوب:</span>
                        <span className="font-black text-lg text-emerald-700">{formatCurrency(cartSubtotal)}</span>
                      </div>

                      <button
                        onClick={handleConfirmOrder}
                        className="w-full bg-amber-400 hover:bg-amber-300 text-slate-950 font-black py-3 rounded-xl text-xs sm:text-sm flex items-center justify-center gap-2 shadow-md transition active:scale-98 cursor-pointer border border-amber-500/40"
                      >
                        <CheckCircle2 className="w-5 h-5" />
                        <span>حفظ وتحويل للمراجعة 📋</span>
                      </button>
                    </div>
                  )}
                </div>
              )}

              {/* 3. شاشة الإعدادات ومركز تحميل وتثبيت التطبيق للأندرويد والآيفون (Settings & Mobile Hub) */}
              {activeFlutterTab === 'settings' && (
                <div className="max-w-3xl mx-auto space-y-4">
                  {/* كارت التثبيت المباشر للأندرويد والآيفون بدون علامة المتصفح وبأيقونة أصلية */}
                  <div className="bg-gradient-to-br from-slate-900 via-slate-850 to-amber-950 text-white p-5 sm:p-6 rounded-3xl border-2 border-amber-400/50 shadow-2xl space-y-5">
                    <div className="flex items-center gap-3.5">
                      <div className="w-14 h-14 rounded-2xl bg-amber-400 text-slate-950 flex items-center justify-center font-black shadow-lg">
                        <Smartphone className="w-7 h-7" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2 flex-wrap">
                          <h3 className="font-black text-base sm:text-lg text-amber-300">
                            تثبيت التطبيق على الهواتف (أندرويد وآيفون) بأيقونة أصلية
                          </h3>
                          <span className="bg-emerald-500 text-slate-950 text-[10px] font-black px-2 py-0.5 rounded-full">
                            PWA Standalone 100%
                          </span>
                        </div>
                        <p className="text-xs text-slate-300 mt-1 leading-relaxed">
                          تطبيق حقيقي يفتح بملء الشاشة وبدون أي شريط للمتصفح وبدون علامة جوجل كروم أو سفاري.
                        </p>
                      </div>
                    </div>

                    {/* كشف نوع الجهاز تلقائياً */}
                    <div className="p-3 rounded-2xl bg-slate-950/80 border border-slate-700 flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2">
                        <Info className="w-4 h-4 text-amber-400" />
                        <span>جهازك الحالي: <strong>{
                          clientPlatform === 'android' ? 'هاتف أندرويد (Android)' :
                          clientPlatform === 'ios' ? 'هاتف آيفون / آيباد (Apple iOS)' : 'جهاز كمبيوتر / ويب'
                        }</strong></span>
                      </div>
                      <span className={`px-2 py-0.5 rounded font-black text-[10px] ${
                        isStandaloneApp ? 'bg-emerald-500 text-slate-950' : 'bg-amber-500 text-slate-950'
                      }`}>
                        {isStandaloneApp ? 'مثبت كـ Standalone ✅' : 'جاهز للتثبيت 📲'}
                      </span>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 pt-1">
                      {/* بطاقة التثبيت للأندرويد */}
                      <div className="bg-slate-950/90 p-4 rounded-2xl border border-slate-700 space-y-3">
                        <div className="flex items-center gap-2 text-amber-400 font-bold text-xs">
                          <Smartphone className="w-4 h-4" />
                          <span>تثبيت مباشر للأندرويد (Android WebAPK)</span>
                        </div>
                        <p className="text-[11px] text-slate-300 leading-relaxed">
                          يتم تثبيته كتطبيق أندرويد أصلي بأيقونة مجموعة الطنطاوي الذهبية النظيفة ويعمل بكامل الشاشة وبدون اتصال.
                        </p>
                        
                        {/* شرح إزالة علامة كروم */}
                        <div className="bg-amber-950/40 border border-amber-500/30 rounded-xl p-2.5 text-[11px] text-slate-300 space-y-1">
                          <div className="font-bold text-amber-300 flex items-center gap-1">
                            <AlertTriangle className="w-3.5 h-3.5" />
                            <span>سر الأيقونة الصافية بدون علامة كروم:</span>
                          </div>
                          <div>احذف أي اختصار قديم، ثم اضغط زر "تثبيت" الرسمي بالأسفل واختر "تثبيت" وليس "إضافة للشاشة".</div>
                        </div>

                        <button
                          onClick={() => {
                            if (triggerInstallPrompt) {
                              triggerInstallPrompt();
                            } else {
                              alert('اضغط على خيارات المتصفح (⋮) في أعلى كروم ثم اختر: "تثبيت التطبيق" أو "Install App"');
                            }
                          }}
                          className="w-full bg-amber-400 hover:bg-amber-300 text-slate-950 font-black py-2.5 rounded-xl text-xs flex items-center justify-center gap-2 shadow cursor-pointer transition active:scale-98"
                        >
                          <Download className="w-4 h-4" />
                          <span>تثبيت التطبيق للأندرويد فوراً 📲</span>
                        </button>
                      </div>

                      {/* خطوات التثبيت للآيفون Safari */}
                      <div className="bg-slate-950/90 p-4 rounded-2xl border border-slate-700 space-y-3">
                        <div className="flex items-center gap-2 text-sky-400 font-bold text-xs">
                          <Smartphone className="w-4 h-4" />
                          <span>تثبيت للآيفون (Apple iOS Safari)</span>
                        </div>
                        <p className="text-[11px] text-slate-300 leading-relaxed">
                          يعمل كتطبيق iOS كامل الشاشة بدون شريط سفاري. اتبع الـ 3 خطوات التالية:
                        </p>

                        <div className="bg-slate-900 rounded-xl p-2.5 border border-slate-700 text-[11px] space-y-1.5 text-slate-300">
                          <div className="flex items-center gap-2">
                            <span className="w-4 h-4 rounded-full bg-sky-500 text-slate-950 flex items-center justify-center font-black text-[10px]">1</span>
                            <span>افتح هذا الرابط داخل متصفح <strong>Safari</strong>.</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="w-4 h-4 rounded-full bg-sky-500 text-slate-950 flex items-center justify-center font-black text-[10px]">2</span>
                            <span>اضغط على زر المشاركة <strong>(Share ⎋)</strong> بالأسفل.</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="w-4 h-4 rounded-full bg-sky-500 text-slate-950 flex items-center justify-center font-black text-[10px]">3</span>
                            <span>اختر <strong>«إضافة إلى الصفحة الرئيسية ⊞»</strong> ثم إضافة.</span>
                          </div>
                        </div>

                        <button
                          onClick={copyAppInstallLink}
                          className="w-full bg-slate-800 hover:bg-slate-700 text-white font-bold py-2.5 rounded-xl text-xs flex items-center justify-center gap-1.5 border border-slate-600 cursor-pointer transition"
                        >
                          {copiedLink ? <Check className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
                          <span>{copiedLink ? 'تم نسخ الرابط بنجاح!' : 'نسخ رابط التثبيت للآيفون'}</span>
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* تخصيص واجهة الكتالوج ونمط أمازون (Amazon Catalog Preferences) */}
                  <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-4">
                    <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                      <div className="flex items-center gap-2 font-black text-xs sm:text-sm text-slate-900">
                        <Boxes className="w-4 h-4 text-amber-500" />
                        <span>تخصيص شاشات ومبيعات كتالوج أمازون</span>
                      </div>
                      <span className="text-[11px] text-slate-500 font-bold">تفضيلات العرض</span>
                    </div>

                    <div className="space-y-3 text-xs">
                      <label className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-slate-100 transition cursor-pointer">
                        <div className="flex items-center gap-2">
                          <Flame className="w-4 h-4 text-amber-500" />
                          <span className="font-bold text-slate-800">إظهار شارة (الأكثر مبيعاً #1) على الأصناف الرائجة</span>
                        </div>
                        <input
                          type="checkbox"
                          checked={showBestSellerBadge}
                          onChange={(e) => setShowBestSellerBadge(e.target.checked)}
                          className="w-4 h-4 accent-amber-500 cursor-pointer"
                        />
                      </label>

                      <label className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-slate-100 transition cursor-pointer">
                        <div className="flex items-center gap-2">
                          <Tag className="w-4 h-4 text-emerald-600" />
                          <span className="font-bold text-slate-800">إظهار شارة الخصم % ومقدار الوفر المالي بالكرتونة</span>
                        </div>
                        <input
                          type="checkbox"
                          checked={showSavingsBadge}
                          onChange={(e) => setShowSavingsBadge(e.target.checked)}
                          className="w-4 h-4 accent-amber-500 cursor-pointer"
                        />
                      </label>

                      <label className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-slate-100 transition cursor-pointer">
                        <div className="flex items-center gap-2">
                          <Boxes className="w-4 h-4 text-blue-600" />
                          <span className="font-bold text-slate-800">إظهار تفاصيل الشدة وسعر القطعة الواحدة داخل الكرتونة</span>
                        </div>
                        <input
                          type="checkbox"
                          checked={showPieceBreakdown}
                          onChange={(e) => setShowPieceBreakdown(e.target.checked)}
                          className="w-4 h-4 accent-amber-500 cursor-pointer"
                        />
                      </label>

                      <label className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-slate-100 transition cursor-pointer">
                        <div className="flex items-center gap-2">
                          <Truck className="w-4 h-4 text-emerald-600" />
                          <span className="font-bold text-slate-800">إظهار شارة الشحن الفوري من مخزن أكتوبر المركزي</span>
                        </div>
                        <input
                          type="checkbox"
                          checked={showCentralStock}
                          onChange={(e) => setShowCentralStock(e.target.checked)}
                          className="w-4 h-4 accent-amber-500 cursor-pointer"
                        />
                      </label>
                    </div>
                  </div>

                  {/* إعدادات الطباعة الحرارية عبر البلوتوث للطابعات المحمولة 80mm */}
                  <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2 font-black text-xs sm:text-sm text-slate-900">
                        <Printer className="w-4 h-4 text-amber-500" />
                        <span>إعدادات الطابعة الحرارية المحمولة (Bluetooth 80mm)</span>
                      </div>
                      <span className="bg-emerald-100 text-emerald-800 text-[10px] font-bold px-2 py-0.5 rounded-full">
                        ESC/POS جاهزة
                      </span>
                    </div>
                    <p className="text-xs text-slate-500 leading-relaxed">
                      طباعة فورية لفواتير وإيصالات المبيعات للمناديب وسيارات التوزيع مع باركود الـ QR واللغة العربية الكاملة.
                    </p>
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 font-bold text-slate-700">
                        عرض الورق: <strong>80 مم (قياسي)</strong>
                      </div>
                      <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 font-bold text-slate-700">
                        الباركود: <strong>QR Code إلكتروني</strong>
                      </div>
                    </div>
                  </div>

                  {/* إعدادات قاعدة البيانات والتزامن مع Supabase */}
                  <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2 font-black text-xs sm:text-sm text-slate-900">
                        <ShieldCheck className="w-4 h-4 text-emerald-500" />
                        <span>حالة الربط السحابي مع Supabase</span>
                      </div>
                      <span className="bg-emerald-500 text-white text-[10px] font-black px-2 py-0.5 rounded-full">
                        متصل ومزامن 🟢
                      </span>
                    </div>
                    <div className="text-xs text-slate-600 space-y-1.5">
                      <div>المستخدم الحالي: <strong>{currentUser?.name} ({currentUser?.role})</strong></div>
                      <div>الفرع المخصص: <strong>{currentUser?.branchName}</strong></div>
                      <div>عدد الأصناف المتزامنة: <strong>{products.length} صنف</strong></div>
                      <div>عدد العملاء المسجلين: <strong>{customers.length} عميل</strong></div>
                    </div>
                  </div>

                  {/* زر مركز تجهيز وتنزيل ملفات APK للمناديب */}
                  <button
                    onClick={() => setIsApkModalOpen(true)}
                    className="w-full p-4 rounded-2xl bg-gradient-to-r from-slate-900 via-slate-850 to-amber-950 hover:to-amber-900 text-white font-bold text-xs flex items-center justify-between border-2 border-amber-500/40 shadow-lg cursor-pointer transition"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-amber-400 text-slate-950 flex items-center justify-center font-black">
                        <Smartphone className="w-5 h-5" />
                      </div>
                      <div className="text-right">
                        <span className="font-black text-sm text-amber-300 block">
                          مركز تجهيز وتنزيل ملفات APK وتشغيلها للمناديب 📲
                        </span>
                        <span className="text-[11px] text-slate-300">
                          تحميل ملف الـ APK المباشر، رابط التثبيت لواتساب، ودليل تشغيل المندوب
                        </span>
                      </div>
                    </div>
                    <span className="bg-amber-400 text-slate-950 font-black px-3 py-1.5 rounded-xl text-xs shrink-0 mr-2">
                      فتح المركز ➔
                    </span>
                  </button>
                </div>
              )}

              {/* 4. شاشة الفواتير والطباعة (Invoices) */}
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

              {/* 5. شاشة الرئيسية (Home Dashboard) */}
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

              {/* 6. شاشة الزيارات الميدانية والـ GPS */}
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
            {(!isFramedSimulator && (deviceMode === 'web' || deviceMode === 'tablet')) && activeFlutterTab === 'catalog' && (
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

                  {/* كارت ملخص العميل النشط بالسلة */}
                  {selectedCustomer && (
                    <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs space-y-1">
                      <div className="text-[10px] text-slate-500">العميل المعتمد:</div>
                      <div className="font-black text-slate-900 truncate">{selectedCustomer.name}</div>
                      <div className="flex justify-between text-[11px] text-slate-600">
                        <span>المديونية:</span>
                        <span className="font-bold">{formatCurrency(customerBalance)}</span>
                      </div>
                    </div>
                  )}

                  {/* سطور السلة */}
                  <div className="max-h-80 overflow-y-auto space-y-2 pr-1">
                    {cartItemsCount === 0 ? (
                      <div className="text-center py-12 text-slate-400 text-xs">
                        اضغط على زر (أضف للطلبية) بجانب أي صنف لإضافته للسلة فوراً.
                      </div>
                    ) : (
                      Object.values(flutterCart).map(item => (
                        <div key={item.product.id} className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 text-xs">
                          <div className="font-bold text-slate-900 truncate">{item.product.name}</div>
                          <div className="flex items-center justify-between mt-1 text-[11px]">
                            <span className="text-slate-500">
                              {item.quantity} ك × {formatCurrency(item.product.promoPrice || item.product.cartonPrice || 1000)}
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
                      className="w-full bg-amber-400 hover:bg-amber-300 text-slate-950 font-black py-2.5 rounded-xl text-xs flex items-center justify-center gap-1.5 shadow transition cursor-pointer border border-amber-500/30"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      <span>حفظ وتحويل للمراجعة 📋</span>
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* في أوضاع الموبايل: شريط الملاحة السفلي (Flutter BottomNavigationBar) */}
          {(isFramedSimulator || deviceMode === 'android' || deviceMode === 'ios') && (
            <div className="bg-slate-900 border-t border-slate-800 px-3 py-2 flex items-center justify-around shrink-0 select-none">
              <button
                onClick={() => setActiveFlutterTab('catalog')}
                className={`flex flex-col items-center gap-1 transition cursor-pointer ${
                  activeFlutterTab === 'catalog' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Boxes className="w-4 h-4" />
                <span className="text-[10px]">الكتالوج</span>
              </button>

              <button
                onClick={() => setActiveFlutterTab('cart')}
                className={`relative flex flex-col items-center gap-1 transition cursor-pointer ${
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
                className={`flex flex-col items-center gap-1 transition cursor-pointer ${
                  activeFlutterTab === 'invoices' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Receipt className="w-4 h-4" />
                <span className="text-[10px]">الفواتير</span>
              </button>

              <button
                onClick={() => setActiveFlutterTab('visits')}
                className={`flex flex-col items-center gap-1 transition cursor-pointer ${
                  activeFlutterTab === 'visits' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <MapPin className="w-4 h-4" />
                <span className="text-[10px]">الزيارات</span>
              </button>

              <button
                onClick={() => setActiveFlutterTab('settings')}
                className={`flex flex-col items-center gap-1 transition cursor-pointer ${
                  activeFlutterTab === 'settings' ? 'text-amber-400 font-black' : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                <Settings className="w-4 h-4" />
                <span className="text-[10px]">الإعدادات</span>
              </button>
            </div>
          )}
        </div>
      </div>

      {/* 3. نافذة تفاصيل ومعاينة الصنف بأسلوب أمازون (Amazon Product Quick View Modal) */}
      {selectedProductDetails && (
        <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-3 sm:p-4 animate-in fade-in">
          <div className="bg-white rounded-3xl max-w-lg w-full overflow-hidden shadow-2xl border border-slate-300 text-slate-900 space-y-4 max-h-[90vh] overflow-y-auto">
            <div className="relative bg-slate-50 p-6 flex items-center justify-center border-b border-slate-200">
              <button
                onClick={() => setSelectedProductDetails(null)}
                className="absolute top-4 left-4 p-2 rounded-full bg-white shadow-sm border border-slate-200 text-slate-600 hover:text-slate-900 cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>

              <div className="w-48 h-48 flex items-center justify-center">
                {selectedProductDetails.imageUrl ? (
                  <img src={selectedProductDetails.imageUrl} alt={selectedProductDetails.name} className="w-full h-full object-contain" />
                ) : (
                  <Boxes className="w-24 h-24 text-amber-500" />
                )}
              </div>
            </div>

            <div className="p-5 space-y-3">
              <div className="flex items-center gap-2">
                <span className="font-mono text-xs bg-slate-900 text-amber-400 px-2 py-0.5 rounded font-black">
                  {selectedProductDetails.code}
                </span>
                <span className="text-xs text-slate-500 font-bold">
                  {selectedProductDetails.department} • {selectedProductDetails.category || 'عام'}
                </span>
              </div>

              <h3 className="font-black text-base text-slate-900">{selectedProductDetails.name}</h3>

              {/* الأسعار */}
              <div className="p-3 rounded-2xl bg-slate-50 border border-slate-200 space-y-1">
                <div className="flex items-baseline gap-2">
                  <span className="text-xl font-black text-slate-950">
                    {formatCurrency(selectedProductDetails.promoPrice || selectedProductDetails.cartonPrice || 1000)}
                  </span>
                  <span className="text-xs text-slate-500">/ كرتونة</span>
                </div>
                <div className="text-xs text-slate-600">
                  عدد القطع بالكرتونة: <strong>{selectedProductDetails.cartonQuantity || 1} قطعة</strong> (سعر القطعة: {formatCurrency((selectedProductDetails.promoPrice || selectedProductDetails.cartonPrice || 1000) / (selectedProductDetails.cartonQuantity || 1))})
                </div>
              </div>

              {/* رصيد المخازن */}
              <div className="grid grid-cols-2 gap-2 text-xs">
                <div className="p-2.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 font-bold">
                  مخزن أكتوبر المركزي: متوفر للشحن
                </div>
                <div className="p-2.5 rounded-xl bg-blue-50 border border-blue-200 text-blue-800 font-bold">
                  رصيد الفرع: {(selectedProductDetails.branchStockActual || 20) - (selectedProductDetails.branchStockReserved || 0)} كرتونة
                </div>
              </div>

              <div className="pt-2 flex gap-2">
                <button
                  onClick={() => {
                    handleAddToCart(selectedProductDetails);
                    setSelectedProductDetails(null);
                  }}
                  className="flex-1 bg-amber-400 hover:bg-amber-300 text-slate-950 font-black py-3 rounded-xl text-xs flex items-center justify-center gap-2 shadow cursor-pointer"
                >
                  <Plus className="w-4 h-4" />
                  <span>إضافة للطلبية الآن 🛒</span>
                </button>
                <button
                  onClick={() => setSelectedProductDetails(null)}
                  className="px-4 py-3 bg-slate-100 hover:bg-slate-200 font-bold rounded-xl text-xs cursor-pointer"
                >
                  إغلاق
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 4. نافذة معاينة بون الطباعة الحرارية الحقيقية */}
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

      {/* 3. نافذة تفاصيل وتكبير صورة الصنف عالية الدقة بأسلوب أمازون */}
      <ProductLightboxModal
        product={selectedProductDetails}
        isOpen={!!selectedProductDetails}
        onClose={() => setSelectedProductDetails(null)}
        onAddToCart={(prod, qty) => {
          handleAddToCart(prod, qty);
          setSelectedProductDetails(null);
        }}
        currentCartQty={selectedProductDetails ? (flutterCart[selectedProductDetails.id]?.quantity || 0) : 0}
      />

      {/* 4. نافذة مركز تجهيز وتنزيل ملفات الـ APK للأندرويد وتشغيلها للمناديب */}
      <ApkDistributionModal
        isOpen={isApkModalOpen}
        onClose={() => setIsApkModalOpen(false)}
      />
    </div>
  );
};
