import React, { useState, useMemo } from 'react';
import { 
  Search, 
  ShoppingBag, 
  User, 
  CheckCircle2, 
  Sparkles, 
  Plus, 
  Minus, 
  Trash2, 
  CreditCard, 
  DollarSign, 
  Maximize2, 
  SlidersHorizontal, 
  Tag, 
  Boxes, 
  Layers, 
  Smartphone, 
  Tablet, 
  Monitor, 
  Check, 
  AlertCircle,
  Clock,
  Send,
  Phone,
  MapPin,
  ChevronDown
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Product, Customer } from '../types';

export const SalesRepMobileApp: React.FC = () => {
  const { 
    products, 
    customers, 
    cart, 
    addToCart, 
    removeFromCart, 
    updateCartItem, 
    clearCart,
    selectedCustomer, 
    setSelectedCustomer,
    createOrder,
    currentUser,
    setSelectedLightboxProduct,
    setIsApkModalOpen,
    totalCartValue,
    totalCartItemsCount
  } = useApp();

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDept, setSelectedDept] = useState<string>('الكل');
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [isCustomerModalOpen, setIsCustomerModalOpen] = useState(false);
  const [customerSearch, setCustomerSearch] = useState('');
  const [orderNotes, setOrderNotes] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<'نقدي' | 'آجل'>('آجل');
  const [deviceFrame, setDeviceFrame] = useState<'full' | 'phone' | 'tablet'>('full');
  const [orderSuccessBanner, setOrderSuccessBanner] = useState<string | null>(null);

  // Departments list
  const departments = ['الكل', 'أطقم سفرة', 'زجاج وكريستال', 'أدوات مائدة', 'أواني طهي'];

  // Filter products
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchDept = selectedDept === 'الكل' || p.department === selectedDept;
      const matchQuery =
        !searchQuery.trim() ||
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.code.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (p.barcode && p.barcode.includes(searchQuery));
      return matchDept && matchQuery;
    });
  }, [products, selectedDept, searchQuery]);

  // Filter customers for selector
  const filteredCustomers = useMemo(() => {
    return customers.filter((c) => {
      if (!customerSearch.trim()) return true;
      const q = customerSearch.toLowerCase();
      return (
        c.name.toLowerCase().includes(q) ||
        c.code.toLowerCase().includes(q) ||
        c.phone.includes(q) ||
        c.branchName.toLowerCase().includes(q)
      );
    });
  }, [customers, customerSearch]);

  const handleSaveAndSubmit = () => {
    if (!selectedCustomer) {
      alert('برجاء اختيار العميل أولاً');
      return;
    }
    if (cart.length === 0) {
      alert('سلة الطلبيات فارغة! اختر أصنافاً أولاً');
      return;
    }

    const items = cart.map((item) => {
      const effectiveCartonPrice = item.product.promoPrice || item.product.cartonPrice;
      const sub = item.quantityCartons * effectiveCartonPrice + item.quantityPieces * item.product.piecePrice;
      return {
        productId: item.product.id,
        productCode: item.product.code,
        productName: item.product.name,
        unitPrice: item.product.piecePrice,
        cartonPrice: effectiveCartonPrice,
        quantityCartons: item.quantityCartons,
        quantityPieces: item.quantityPieces,
        factor: item.product.cartonQuantity,
        totalPieces: item.quantityCartons * item.product.cartonQuantity + item.quantityPieces,
        subtotal: sub,
        total: sub,
      };
    });

    const totalCartons = cart.reduce((acc, i) => acc + i.quantityCartons, 0);
    const totalPieces = cart.reduce((acc, i) => acc + (i.quantityCartons * i.product.cartonQuantity + i.quantityPieces), 0);

    const newOrder = createOrder({
      customerId: selectedCustomer.id,
      customerCode: selectedCustomer.code,
      customerName: selectedCustomer.name,
      customerPhone: selectedCustomer.phone,
      branchName: selectedCustomer.branchName,
      items,
      totalCartons,
      totalPieces,
      subtotal: totalCartValue,
      totalAmount: totalCartValue,
      paymentMethod,
      notes: orderNotes,
      status: 'قيد مراجعة المشرف',
    });

    setIsCartOpen(false);
    setOrderNotes('');
    setOrderSuccessBanner(`تم حفظ الطلبية بنجاح وتحويلها لمراجعة المشرف برقم (${newOrder.invoiceNumber}) 📋`);
    setTimeout(() => {
      setOrderSuccessBanner(null);
    }, 7000);
  };

  return (
    <div className="flex flex-col items-center w-full min-h-[calc(100vh-80px)] p-2 sm:p-4">
      {/* Top Device Frame Controls & Quick Info */}
      <div className="w-full max-w-6xl mb-3 flex flex-wrap items-center justify-between gap-3 bg-slate-900/80 border border-slate-800 p-3 rounded-2xl">
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
          <span className="text-xs font-bold text-white">كتالوج المبيعات الذكي (نمط أمازون ونون للمندوب)</span>
          <span className="text-[11px] bg-blue-900/60 text-blue-300 px-2 py-0.5 rounded-full border border-blue-700/50">
            {currentUser.name} ({currentUser.branchName})
          </span>
        </div>

        <div className="flex items-center gap-2">
          {/* Frame toggles */}
          <div className="flex items-center bg-slate-950 p-1 rounded-xl border border-slate-800 text-xs">
            <button
              onClick={() => setDeviceFrame('phone')}
              className={`p-1.5 rounded-lg flex items-center gap-1 transition ${
                deviceFrame === 'phone' ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white'
              }`}
              title="محاكي شاشة هاتف المندوب"
            >
              <Smartphone className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">موبايل</span>
            </button>
            <button
              onClick={() => setDeviceFrame('tablet')}
              className={`p-1.5 rounded-lg flex items-center gap-1 transition ${
                deviceFrame === 'tablet' ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white'
              }`}
              title="محاكي تابلت المشرف"
            >
              <Tablet className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">تابلت</span>
            </button>
            <button
              onClick={() => setDeviceFrame('full')}
              className={`p-1.5 rounded-lg flex items-center gap-1 transition ${
                deviceFrame === 'full' ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white'
              }`}
              title="شاشة كاملة عريضة"
            >
              <Monitor className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">كامل الشاشة</span>
            </button>
          </div>

          <button
            onClick={() => setIsApkModalOpen(true)}
            className="text-xs font-bold bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border border-emerald-500/40 px-3 py-1.5 rounded-xl flex items-center gap-1.5 transition"
          >
            <Smartphone className="w-3.5 h-3.5" />
            تحميل APK وتثبيت الموبايل
          </button>
        </div>
      </div>

      {/* Success Notification Banner */}
      {orderSuccessBanner && (
        <div className="w-full max-w-6xl mb-4 bg-emerald-950/80 border border-emerald-500/60 p-4 rounded-2xl flex items-center justify-between text-emerald-300 text-sm shadow-xl shadow-emerald-950/40 animate-in slide-in-from-top-4">
          <div className="flex items-center gap-3">
            <CheckCircle2 className="w-6 h-6 text-emerald-400 shrink-0" />
            <span className="font-bold">{orderSuccessBanner}</span>
          </div>
          <button
            onClick={() => setOrderSuccessBanner(null)}
            className="text-emerald-400 hover:text-white text-xs underline font-bold"
          >
            إغلاق
          </button>
        </div>
      )}

      {/* Main Container with Optional Phone Bezel Simulator */}
      <div
        className={`w-full transition-all duration-300 flex flex-col ${
          deviceFrame === 'phone'
            ? 'max-w-[420px] bg-slate-900 border-4 border-slate-700 rounded-[40px] shadow-2xl p-4 overflow-hidden my-4 ring-1 ring-slate-800'
            : deviceFrame === 'tablet'
            ? 'max-w-3xl bg-slate-900 border-4 border-slate-700 rounded-[32px] shadow-2xl p-4 overflow-hidden my-4'
            : 'max-w-6xl bg-transparent'
        }`}
      >
        {/* Customer Selector Card */}
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-3 sm:p-4 mb-4 shadow-lg">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl bg-blue-600/20 text-blue-400 flex items-center justify-center border border-blue-500/30">
                <User className="w-4 h-4" />
              </div>
              <div>
                <span className="text-[11px] text-slate-400 block">العميل المحدد للفاتورة:</span>
                <span className="text-sm font-bold text-white">
                  {selectedCustomer ? selectedCustomer.name : 'لم يتم اختيار عميل'}
                </span>
              </div>
            </div>

            <button
              onClick={() => setIsCustomerModalOpen(true)}
              className="px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 text-xs font-semibold flex items-center gap-1.5 transition"
            >
              <span>تغيير العميل</span>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
            </button>
          </div>

          {selectedCustomer && (
            <div className="mt-3 pt-3 border-t border-slate-800/80 flex flex-wrap items-center justify-between gap-2 text-xs">
              <div className="flex items-center gap-4">
                <div>
                  <span className="text-slate-400 block text-[10px]">كود العميل</span>
                  <span className="font-mono font-bold text-slate-200">{selectedCustomer.code}</span>
                </div>
                <div>
                  <span className="text-slate-400 block text-[10px]">الرصيد الحالي</span>
                  <span className="font-bold text-amber-400">
                    {selectedCustomer.currentBalance.toLocaleString('ar-EG')} ج.م
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block text-[10px]">السقف الائتماني</span>
                  <span className="font-bold text-slate-300">
                    {selectedCustomer.creditLimit.toLocaleString('ar-EG')} ج.م
                  </span>
                </div>
              </div>
              <div className="flex items-center gap-2 text-[11px] text-slate-400">
                <Phone className="w-3 h-3 text-slate-500" />
                <span>{selectedCustomer.phone}</span>
              </div>
            </div>
          )}
        </div>

        {/* Smart Search Bar (Amazon / Noon style) */}
        <div className="relative mb-3">
          <div className="absolute inset-y-0 right-0 pr-3.5 flex items-center pointer-events-none text-slate-400">
            <Search className="w-5 h-5 text-blue-400" />
          </div>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="ابحث بالاسم، كود الصنف (مثلاً DIN-68)، الباركود، أو الفئة..."
            className="w-full pr-11 pl-4 py-3.5 bg-slate-900 border border-slate-800 rounded-2xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 shadow-inner"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute inset-y-0 left-0 pl-3.5 flex items-center text-xs text-slate-400 hover:text-white"
            >
              مسح
            </button>
          )}
        </div>

        {/* Department Chips */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 mb-4 no-scrollbar">
          {departments.map((dept) => (
            <button
              key={dept}
              onClick={() => setSelectedDept(dept)}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                selectedDept === dept
                  ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30'
                  : 'bg-slate-900/90 text-slate-400 hover:text-slate-200 border border-slate-800'
              }`}
            >
              {dept}
            </button>
          ))}
        </div>

        {/* Products Grid (Amazon Cards) */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {filteredProducts.map((product) => {
            const effectiveCartonPrice = product.promoPrice || product.cartonPrice;
            const inCart = cart.find((i) => i.product.id === product.id);

            return (
              <div
                key={product.id}
                className="group relative bg-slate-900/95 border border-slate-800 hover:border-blue-500/50 rounded-3xl p-3.5 flex flex-col justify-between transition-all duration-200 shadow-xl hover:shadow-2xl hover:shadow-blue-950/20"
              >
                {/* Product Card Top: Badges & Code */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="bg-slate-800 text-blue-400 text-[10px] font-mono px-2 py-0.5 rounded-lg border border-slate-700/80">
                      {product.code}
                    </span>
                    {product.salesPriority === 'عرض خاص' ? (
                      <span className="bg-rose-600/20 text-rose-400 border border-rose-500/40 text-[10px] font-bold px-2 py-0.5 rounded-lg flex items-center gap-1">
                        <Tag className="w-2.5 h-2.5" />
                        عرض خاص
                      </span>
                    ) : (
                      <span className="text-[10px] text-slate-400">{product.department}</span>
                    )}
                  </div>

                  {/* Image container: Click to open full-screen Lightbox */}
                  <div
                    onClick={() => setSelectedLightboxProduct(product)}
                    className="relative w-full h-44 bg-slate-950/80 rounded-2xl overflow-hidden cursor-zoom-in mb-3 flex items-center justify-center group-hover:bg-slate-950 transition"
                    title="انقر لتكبير وفحص تفاصيل الصنف بالكامل"
                  >
                    <img
                      src={product.imageUrl}
                      alt={product.name}
                      className="w-full h-full object-contain p-2 group-hover:scale-105 transition duration-300 select-none"
                    />
                    <div className="absolute bottom-2 left-2 p-1.5 rounded-lg bg-slate-900/80 text-slate-300 opacity-0 group-hover:opacity-100 transition shadow">
                      <Maximize2 className="w-3.5 h-3.5" />
                    </div>
                  </div>

                  {/* Title */}
                  <h3
                    onClick={() => setSelectedLightboxProduct(product)}
                    className="text-sm font-bold text-white hover:text-blue-400 cursor-pointer line-clamp-2 mb-2 leading-snug"
                  >
                    {product.name}
                  </h3>

                  {/* Carton pack factor info */}
                  <div className="flex items-center gap-2 text-[11px] text-slate-400 mb-3">
                    <Boxes className="w-3.5 h-3.5 text-blue-400" />
                    <span>الكرتونة = {product.cartonQuantity} قطعة</span>
                    <span>•</span>
                    <span className="text-emerald-400">متاح {product.branchStockActual - product.branchStockReserved} كرتونة</span>
                  </div>

                  {/* Pricing Details */}
                  <div className="bg-slate-950/60 p-2.5 rounded-2xl border border-slate-800/80 mb-3">
                    <div className="flex items-baseline justify-between">
                      <span className="text-[10px] text-slate-400">سعر الكرتونة:</span>
                      <div className="flex items-baseline gap-1.5">
                        <span className="text-base font-extrabold text-emerald-400">
                          {effectiveCartonPrice.toLocaleString('ar-EG')} ج.م
                        </span>
                        {product.promoPrice && (
                          <span className="text-[10px] line-through text-slate-500">
                            {product.cartonPrice.toLocaleString('ar-EG')}
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="flex items-baseline justify-between text-[11px] text-slate-400 mt-1">
                      <span>سعر القطعة المفردة:</span>
                      <span className="font-semibold text-slate-300">
                        {product.piecePrice.toLocaleString('ar-EG')} ج.م
                      </span>
                    </div>
                  </div>
                </div>

                {/* Add to Cart / Quantity Controller */}
                <div>
                  {inCart ? (
                    <div className="bg-blue-950/40 border border-blue-600/40 rounded-2xl p-2 flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => updateCartItem(product.id, inCart.quantityCartons - 1, inCart.quantityPieces)}
                          className="w-7 h-7 rounded-lg bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center"
                        >
                          <Minus className="w-3.5 h-3.5" />
                        </button>
                        <span className="text-xs font-bold text-white min-w-5 text-center">
                          {inCart.quantityCartons} ك
                        </span>
                        <button
                          onClick={() => updateCartItem(product.id, inCart.quantityCartons + 1, inCart.quantityPieces)}
                          className="w-7 h-7 rounded-lg bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center"
                        >
                          <Plus className="w-3.5 h-3.5" />
                        </button>
                      </div>

                      <span className="text-xs font-bold text-emerald-400">
                        {(inCart.quantityCartons * effectiveCartonPrice).toLocaleString('ar-EG')} ج.م
                      </span>
                    </div>
                  ) : (
                    <button
                      onClick={() => addToCart(product, 1, 0)}
                      className="w-full py-2.5 rounded-2xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold flex items-center justify-center gap-1.5 shadow-lg shadow-blue-600/20 transition"
                    >
                      <Plus className="w-4 h-4" />
                      إضافة كرتونة للطلبية
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Floating Bottom Cart Bar for Rep */}
      {cart.length > 0 && (
        <div className="fixed bottom-4 left-1/2 -translate-x-1/2 z-40 w-[94%] max-w-xl bg-slate-900/95 border border-blue-500/50 rounded-3xl p-3 shadow-2xl backdrop-blur-md flex items-center justify-between gap-3 animate-in slide-in-from-bottom-5">
          <div className="flex items-center gap-3">
            <div className="relative w-11 h-11 rounded-2xl bg-blue-600 text-white flex items-center justify-center shadow-lg shadow-blue-500/30">
              <ShoppingBag className="w-5 h-5" />
              <span className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-rose-600 text-white text-[10px] font-bold flex items-center justify-center border-2 border-slate-900">
                {totalCartItemsCount}
              </span>
            </div>
            <div>
              <span className="text-[11px] text-slate-400 block">إجمالي طلبية المندوب:</span>
              <span className="text-base font-black text-emerald-400">
                {totalCartValue.toLocaleString('ar-EG')} ج.م
              </span>
            </div>
          </div>

          <button
            onClick={() => setIsCartOpen(true)}
            className="py-2.5 px-5 rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white text-xs font-bold flex items-center gap-1.5 shadow-lg shadow-blue-600/30 transition"
          >
            <span>مراجعة وحفظ الطلبية</span>
            <ChevronDown className="w-4 h-4 -rotate-90" />
          </button>
        </div>
      )}

      {/* Customer Selector Modal */}
      {isCustomerModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm">
          <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-2xl">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-bold text-white">اختر العميل</h3>
              <button
                onClick={() => setIsCustomerModalOpen(false)}
                className="text-slate-400 hover:text-white text-xs"
              >
                إلغاء
              </button>
            </div>

            <div className="relative mb-3">
              <Search className="w-4 h-4 text-slate-400 absolute right-3 top-3" />
              <input
                type="text"
                value={customerSearch}
                onChange={(e) => setCustomerSearch(e.target.value)}
                placeholder="ابحث باسم العميل، الكود أو الهاتف..."
                className="w-full pr-9 pl-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
              />
            </div>

            <div className="space-y-2 max-h-72 overflow-y-auto">
              {filteredCustomers.map((cust) => (
                <div
                  key={cust.id}
                  onClick={() => {
                    setSelectedCustomer(cust);
                    setIsCustomerModalOpen(false);
                  }}
                  className={`p-3 rounded-2xl border cursor-pointer transition ${
                    selectedCustomer?.id === cust.id
                      ? 'bg-blue-950/40 border-blue-500 text-white'
                      : 'bg-slate-950/50 border-slate-800 hover:bg-slate-800 text-slate-300'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-xs text-white">{cust.name}</span>
                    <span className="text-[10px] font-mono bg-slate-800 px-1.5 py-0.5 rounded text-blue-400">
                      {cust.code}
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-[11px] text-slate-400 mt-1">
                    <span>رصيد: {cust.currentBalance.toLocaleString('ar-EG')} ج.م</span>
                    <span>سقف: {cust.creditLimit.toLocaleString('ar-EG')} ج.م</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Cart Drawer / Modal with "حفظ وتحويل للمراجعة" */}
      {isCartOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-slate-950/85 backdrop-blur-md">
          <div className="w-full max-w-2xl bg-slate-900 border border-slate-700 rounded-3xl shadow-2xl p-5 flex flex-col max-h-[90vh]">
            <div className="flex items-center justify-between pb-4 border-b border-slate-800">
              <div className="flex items-center gap-2">
                <ShoppingBag className="w-5 h-5 text-blue-400" />
                <h3 className="text-base font-bold text-white">تفاصيل الطلبية الحالية</h3>
              </div>
              <button
                onClick={() => setIsCartOpen(false)}
                className="text-xs text-slate-400 hover:text-white"
              >
                إغلاق
              </button>
            </div>

            {/* Cart Items List */}
            <div className="py-4 overflow-y-auto space-y-3 flex-1">
              {cart.map((item) => {
                const effectiveCartonPrice = item.product.promoPrice || item.product.cartonPrice;
                const sub = item.quantityCartons * effectiveCartonPrice + item.quantityPieces * item.product.piecePrice;

                return (
                  <div
                    key={item.product.id}
                    className="bg-slate-950/70 border border-slate-800 p-3 rounded-2xl flex items-center justify-between gap-3"
                  >
                    <div className="flex items-center gap-3">
                      <img
                        src={item.product.imageUrl}
                        alt={item.product.name}
                        className="w-12 h-12 object-contain bg-slate-900 rounded-xl p-1"
                      />
                      <div>
                        <h4 className="text-xs font-bold text-white line-clamp-1">{item.product.name}</h4>
                        <span className="text-[10px] text-slate-400">
                          {effectiveCartonPrice.toLocaleString('ar-EG')} ج.م / كرتونة ({item.product.cartonQuantity} قطعة)
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <div className="flex items-center gap-1.5 bg-slate-900 p-1 rounded-xl border border-slate-800">
                        <button
                          onClick={() => updateCartItem(item.product.id, item.quantityCartons - 1, item.quantityPieces)}
                          className="w-6 h-6 rounded bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center text-xs"
                        >
                          -
                        </button>
                        <span className="text-xs font-bold text-white px-1.5">{item.quantityCartons} ك</span>
                        <button
                          onClick={() => updateCartItem(item.product.id, item.quantityCartons + 1, item.quantityPieces)}
                          className="w-6 h-6 rounded bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center text-xs"
                        >
                          +
                        </button>
                      </div>

                      <span className="text-xs font-bold text-emerald-400 min-w-16 text-left">
                        {sub.toLocaleString('ar-EG')} ج.م
                      </span>

                      <button
                        onClick={() => removeFromCart(item.product.id)}
                        className="text-slate-500 hover:text-rose-400 p-1"
                        title="حذف"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Order Settings & Notes */}
            <div className="pt-3 border-t border-slate-800 space-y-3">
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400">طريقة الدفع:</span>
                <div className="flex gap-2">
                  <button
                    onClick={() => setPaymentMethod('آجل')}
                    className={`px-3 py-1 rounded-xl font-bold ${
                      paymentMethod === 'آجل' ? 'bg-blue-600 text-white' : 'bg-slate-800 text-slate-400'
                    }`}
                  >
                    آجل (حساب العميل)
                  </button>
                  <button
                    onClick={() => setPaymentMethod('نقدي')}
                    className={`px-3 py-1 rounded-xl font-bold ${
                      paymentMethod === 'نقدي' ? 'bg-blue-600 text-white' : 'bg-slate-800 text-slate-400'
                    }`}
                  >
                    نقدي فوري
                  </button>
                </div>
              </div>

              <div>
                <input
                  type="text"
                  value={orderNotes}
                  onChange={(e) => setOrderNotes(e.target.value)}
                  placeholder="ملاحظات المندوب للمشرف (مثال: تسليم باكر، تسعير خاص...)"
                  className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-blue-500"
                />
              </div>

              <div className="flex items-center justify-between text-sm pt-2">
                <span className="text-slate-300 font-bold">الإجمالي النهائي:</span>
                <span className="text-xl font-black text-emerald-400">
                  {totalCartValue.toLocaleString('ar-EG')} ج.م
                </span>
              </div>

              {/* Exact button requested by user */}
              <button
                onClick={handleSaveAndSubmit}
                className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-extrabold text-sm flex items-center justify-center gap-2 shadow-xl shadow-emerald-950/40 transition"
              >
                <Send className="w-4 h-4" />
                حفظ وتحويل للمراجعة 📋
              </button>
              <p className="text-[10px] text-center text-slate-400">
                سيتم حفظ الطلبية في قاعدة البيانات وتوجيهها مباشرة إلى شاشة مراجعة المشرف والفرع.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
