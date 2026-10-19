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
  Tag, 
  Boxes, 
  AlertCircle,
  Phone, 
  MapPin, 
  ChevronDown,
  Building2,
  Warehouse,
  TrendingUp,
  Maximize2,
  Check,
  Send,
  SlidersHorizontal,
  X
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
    totalCartValue,
    totalCartItemsCount
  } = useApp();

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDept, setSelectedDept] = useState<string>('الكل');
  const [smartFilter, setSmartFilter] = useState<'all' | 'popular' | 'promotions' | 'branchOnly' | 'octoberOnly'>('all');
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [isCustomerModalOpen, setIsCustomerModalOpen] = useState(false);
  const [customerSearch, setCustomerSearch] = useState('');
  const [orderNotes, setOrderNotes] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<'آجل' | 'نقدي'>('آجل');
  const [fulfillmentWarehouse, setFulfillmentWarehouse] = useState<'branch' | 'october'>('branch');
  const [orderSuccessBanner, setOrderSuccessBanner] = useState<string | null>(null);

  // Departments list
  const departments = ['الكل', 'أطقم سفرة', 'زجاج وكريستال', 'أدوات مائدة', 'أواني طهي'];

  // 1. Strict Customer Isolation: Rep sees only their assigned customers
  const repAccessibleCustomers = useMemo(() => {
    if (currentUser.role === 'sales_rep') {
      return customers.filter((c) => c.repName === currentUser.name || !c.repName);
    }
    if (currentUser.role === 'supervisor') {
      return customers.filter((c) => !c.branchName || c.branchName === currentUser.branchName);
    }
    return customers;
  }, [customers, currentUser]);

  // Active customer helper
  const activeCustomer = selectedCustomer || repAccessibleCustomers[0] || null;

  // Credit calculation
  const creditLimit = activeCustomer?.creditLimit || 0;
  const currentBalance = activeCustomer?.currentBalance || 0;
  const remainingCredit = Math.max(0, creditLimit - currentBalance);
  const projectedBalance = currentBalance + totalCartValue;
  const isCreditExceeded = projectedBalance > creditLimit;

  // Filter products by search, department, and smart sales filters
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchDept = selectedDept === 'الكل' || p.department === selectedDept;
      
      const matchQuery =
        !searchQuery.trim() ||
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.code.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (p.barcode && p.barcode.includes(searchQuery));

      let matchSmart = true;
      if (smartFilter === 'promotions') {
        matchSmart = p.salesPriority === 'عرض خاص' || Boolean(p.promoPrice);
      } else if (smartFilter === 'popular') {
        matchSmart = p.salesPriority === 'مرتفع' || p.department === 'أطقم سفرة';
      } else if (smartFilter === 'branchOnly') {
        matchSmart = (p.branchStockActual - p.branchStockReserved) > 0;
      } else if (smartFilter === 'octoberOnly') {
        matchSmart = p.mainWarehouseStock > 0;
      }

      return matchDept && matchQuery && matchSmart;
    });
  }, [products, selectedDept, searchQuery, smartFilter]);

  // Filter customers for modal
  const modalCustomersList = useMemo(() => {
    return repAccessibleCustomers.filter((c) => {
      if (!customerSearch.trim()) return true;
      const q = customerSearch.toLowerCase();
      return (
        c.name.toLowerCase().includes(q) ||
        c.code.toLowerCase().includes(q) ||
        c.phone.includes(q) ||
        (c.storeName && c.storeName.toLowerCase().includes(q))
      );
    });
  }, [repAccessibleCustomers, customerSearch]);

  const handleSaveAndSubmit = () => {
    if (!activeCustomer) {
      alert('برجاء اختيار العميل أولاً من قاعدة العملاء');
      return;
    }
    if (cart.length === 0) {
      alert('سلة الطلبيات فارغة! اختر أصنافاً أولاً لإنشاء الطلبية');
      return;
    }

    const items = cart.map((i) => ({
      productId: i.product.id,
      productCode: i.product.code,
      productName: i.product.name,
      unitPrice: i.product.piecePrice,
      cartonPrice: i.product.promoPrice || i.product.cartonPrice,
      quantityCartons: i.quantityCartons,
      quantityPieces: i.quantityPieces,
      factor: i.product.cartonQuantity,
      totalPieces: i.quantityCartons * i.product.cartonQuantity + i.quantityPieces,
      subtotal: i.quantityCartons * (i.product.promoPrice || i.product.cartonPrice) + i.quantityPieces * i.product.piecePrice,
    }));

    const totalCartons = cart.reduce((acc, i) => acc + i.quantityCartons, 0);
    const totalPieces = cart.reduce((acc, i) => acc + (i.quantityCartons * i.product.cartonQuantity + i.quantityPieces), 0);

    const warehouseLabel = fulfillmentWarehouse === 'branch' 
      ? `مخزن فرع ${currentUser.branchName}` 
      : 'مخزن أكتوبر المركزي (الرئيسي)';

    const newOrder = createOrder({
      customerId: activeCustomer.id,
      customerCode: activeCustomer.code,
      customerName: activeCustomer.name,
      customerPhone: activeCustomer.phone,
      branchName: activeCustomer.branchName,
      items,
      totalCartons,
      totalPieces,
      subtotal: totalCartValue,
      totalAmount: totalCartValue,
      paymentMethod,
      notes: `${orderNotes ? orderNotes + ' • ' : ''}جهة الصرف: [${warehouseLabel}]`,
      status: 'قيد مراجعة المشرف',
    });

    setIsCartOpen(false);
    setOrderNotes('');
    setOrderSuccessBanner(`تم حفظ وتأكيد الطلبية للعميل (${activeCustomer.name}) بنجاح برقم (${newOrder.invoiceNumber})، وتم توجيهها لموافقة المشرف وصرف المخزون.`);
    setTimeout(() => {
      setOrderSuccessBanner(null);
    }, 7000);
  };

  return (
    <div className="w-full max-w-7xl mx-auto p-3 sm:p-6 space-y-4 font-['Cairo',sans-serif]">
      
      {/* ======================================================== */}
      {/* 1. STICKY SMART CUSTOMER INTELLIGENCE BAR                */}
      {/* ======================================================== */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-900 to-blue-950/60 border border-slate-800 rounded-3xl p-4 sm:p-5 shadow-2xl relative overflow-hidden">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          
          {/* Customer Main Info */}
          <div className="flex items-start sm:items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-400 shrink-0 shadow-inner">
              <User className="w-6 h-6" />
            </div>

            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <span className="text-[10px] bg-blue-500/10 text-blue-300 px-2 py-0.5 rounded-lg border border-blue-500/20 font-mono font-bold">
                  {activeCustomer?.code || 'CUST-000'}
                </span>
                <span className="text-base sm:text-lg font-black text-white">
                  {activeCustomer?.name || 'اختر عميل من قائمة العملاء'}
                </span>
                {activeCustomer?.storeName && (
                  <span className="text-xs text-amber-400 font-bold bg-amber-500/10 px-2 py-0.5 rounded-full border border-amber-500/20">
                    {activeCustomer.storeName}
                  </span>
                )}
                {activeCustomer?.tier && (
                  <span className="text-[10px] font-black bg-purple-500/20 text-purple-300 border border-purple-500/40 px-2 py-0.5 rounded-md">
                    فئة {activeCustomer.tier}
                  </span>
                )}
              </div>

              <div className="flex items-center gap-3 text-xs text-slate-400 mt-1 flex-wrap">
                <span className="flex items-center gap-1">
                  <Phone className="w-3.5 h-3.5 text-slate-500" />
                  <strong className="text-slate-300 font-mono">{activeCustomer?.phone}</strong>
                </span>
                <span>•</span>
                <span className="flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5 text-slate-500" />
                  <span>{activeCustomer?.address || activeCustomer?.branchName}</span>
                </span>
                <span>•</span>
                <span className="text-emerald-400 font-bold">
                  المندوب المسند: {activeCustomer?.repName || currentUser.name}
                </span>
              </div>
            </div>
          </div>

          {/* Credit & Change Customer Button */}
          <div className="flex flex-col sm:flex-row sm:items-center gap-3 bg-slate-950/70 border border-slate-800/90 p-3 rounded-2xl self-stretch lg:self-auto">
            <div className="text-xs space-y-1 min-w-[200px]">
              <div className="flex items-center justify-between text-[11px]">
                <span className="text-slate-400">الحد الائتماني:</span>
                <span className="font-bold text-white font-mono">{creditLimit.toLocaleString('ar-EG')} ج.م</span>
              </div>
              <div className="flex items-center justify-between text-[11px]">
                <span className="text-slate-400">الرصيد القائم:</span>
                <span className="font-bold text-amber-400 font-mono">{currentBalance.toLocaleString('ar-EG')} ج.م</span>
              </div>
              <div className="flex items-center justify-between text-[11px] pt-1 border-t border-slate-800">
                <span className="font-bold text-slate-300">المتبقي المتاح:</span>
                <span className={`font-mono font-black ${isCreditExceeded ? 'text-red-400' : 'text-emerald-400'}`}>
                  {(creditLimit - projectedBalance).toLocaleString('ar-EG')} ج.م
                </span>
              </div>
            </div>

            <button
              onClick={() => setIsCustomerModalOpen(true)}
              className="px-4 py-2.5 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white text-xs font-bold flex items-center justify-center gap-2 transition shadow-md shadow-blue-600/20 whitespace-nowrap"
            >
              <User className="w-4 h-4" />
              <span>تغيير العميل ({repAccessibleCustomers.length} عميل مربوط)</span>
              <ChevronDown className="w-3.5 h-3.5" />
            </button>
          </div>

        </div>
      </div>

      {/* Success Notification Banner */}
      {orderSuccessBanner && (
        <div className="bg-emerald-950/90 border border-emerald-500/60 p-4 rounded-3xl flex items-center justify-between text-emerald-200 text-xs sm:text-sm shadow-xl shadow-emerald-950/40 animate-in fade-in">
          <div className="flex items-center gap-3">
            <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
            <span className="font-bold">{orderSuccessBanner}</span>
          </div>
          <button
            onClick={() => setOrderSuccessBanner(null)}
            className="text-emerald-400 hover:text-white underline font-bold text-xs"
          >
            إغلاق
          </button>
        </div>
      )}

      {/* ======================================================== */}
      {/* 2. SEARCH & SMART SALES FILTERS                          */}
      {/* ======================================================== */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl p-4 shadow-xl space-y-3">
        
        {/* Search Input */}
        <div className="relative">
          <Search className="w-5 h-5 text-slate-400 absolute right-4 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="ابحث بالاسم، كود الصنف (مثلاً PLT-06 أو BOWL-04)، الباركود، أو الفئة..."
            className="w-full bg-slate-950 border border-slate-800 rounded-2xl pr-12 pl-4 py-3 text-white text-xs sm:text-sm outline-none focus:border-amber-500 transition shadow-inner font-sans"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute left-4 top-1/2 -translate-y-1/2 text-xs text-slate-400 hover:text-white"
            >
              مسح
            </button>
          )}
        </div>

        {/* Smart Filters Row */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pt-1">
          <button
            onClick={() => setSmartFilter('all')}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition flex items-center gap-1.5 ${
              smartFilter === 'all'
                ? 'bg-amber-500 text-slate-950 shadow-md font-black'
                : 'bg-slate-950 text-slate-400 hover:text-white border border-slate-800'
            }`}
          >
            <span>جميع الأصناف ({products.length})</span>
          </button>

          <button
            onClick={() => setSmartFilter('promotions')}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition flex items-center gap-1.5 ${
              smartFilter === 'promotions'
                ? 'bg-rose-600 text-white shadow-md font-black'
                : 'bg-slate-950 text-rose-400 hover:bg-slate-800 border border-rose-500/20'
            }`}
          >
            <Tag className="w-3.5 h-3.5" />
            <span>🔥 العروض والخصومات</span>
          </button>

          <button
            onClick={() => setSmartFilter('popular')}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition flex items-center gap-1.5 ${
              smartFilter === 'popular'
                ? 'bg-blue-600 text-white shadow-md font-black'
                : 'bg-slate-950 text-blue-400 hover:bg-slate-800 border border-blue-500/20'
            }`}
          >
            <Sparkles className="w-3.5 h-3.5 text-amber-400" />
            <span>⭐ الأكثر طلباً للعملاء</span>
          </button>

          <button
            onClick={() => setSmartFilter('branchOnly')}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition flex items-center gap-1.5 ${
              smartFilter === 'branchOnly'
                ? 'bg-emerald-600 text-white shadow-md font-black'
                : 'bg-slate-950 text-emerald-400 hover:bg-slate-800 border border-emerald-500/20'
            }`}
          >
            <Building2 className="w-3.5 h-3.5" />
            <span>📦 متوفر بمخزن الفرع (تسليم فوري)</span>
          </button>

          <button
            onClick={() => setSmartFilter('octoberOnly')}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition flex items-center gap-1.5 ${
              smartFilter === 'octoberOnly'
                ? 'bg-purple-600 text-white shadow-md font-black'
                : 'bg-slate-950 text-purple-400 hover:bg-slate-800 border border-purple-500/20'
            }`}
          >
            <Warehouse className="w-3.5 h-3.5" />
            <span>🏭 متوفر بمخزن أكتوبر الرئيسي</span>
          </button>
        </div>

        {/* Departments Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pt-1 border-t border-slate-800/80">
          {departments.map((dept) => (
            <button
              key={dept}
              onClick={() => setSelectedDept(dept)}
              className={`px-3 py-1 rounded-lg text-[11px] font-bold whitespace-nowrap transition ${
                selectedDept === dept
                  ? 'bg-slate-800 text-white border border-slate-700'
                  : 'text-slate-400 hover:text-slate-300'
              }`}
            >
              {dept}
            </button>
          ))}
        </div>
      </div>

      {/* ======================================================== */}
      {/* 3. PRODUCTS GRID WITH DUAL STOCK & SMART CARDS           */}
      {/* ======================================================== */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {filteredProducts.map((product) => {
          const effectiveCartonPrice = product.promoPrice || product.cartonPrice;
          const inCart = cart.find((i) => i.product.id === product.id);
          const availableInBranch = Math.max(0, product.branchStockActual - product.branchStockReserved);
          const availableInOctober = product.mainWarehouseStock || 0;

          return (
            <div
              key={product.id}
              className="bg-slate-900 border border-slate-800 hover:border-slate-700 rounded-3xl p-4 flex flex-col justify-between shadow-xl transition space-y-3 group"
            >
              <div>
                {/* Top: Code & Priority Badge */}
                <div className="flex items-center justify-between mb-2 text-[10px]">
                  <span className="bg-slate-950 text-blue-400 font-mono px-2 py-0.5 rounded-lg border border-slate-800 font-bold">
                    {product.code}
                  </span>
                  
                  {product.salesPriority === 'عرض خاص' || product.promoPrice ? (
                    <span className="bg-rose-500/10 text-rose-400 border border-rose-500/30 px-2 py-0.5 rounded-md font-bold flex items-center gap-1">
                      <Tag className="w-2.5 h-2.5" />
                      عرض ترويجي
                    </span>
                  ) : (
                    <span className="text-slate-400 bg-slate-950 px-2 py-0.5 rounded border border-slate-800">
                      {product.department}
                    </span>
                  )}
                </div>

                {/* Product Image */}
                <div
                  onClick={() => setSelectedLightboxProduct(product)}
                  className="relative w-full h-44 bg-slate-950 rounded-2xl overflow-hidden cursor-zoom-in mb-3 flex items-center justify-center border border-slate-800/80"
                  title="انقر لتكبير ومعاينة تفاصيل الصنف"
                >
                  <img
                    src={product.imageUrl}
                    alt={product.name}
                    className="w-full h-full object-contain p-2 group-hover:scale-105 transition duration-300"
                  />
                  <div className="absolute bottom-2 left-2 p-1.5 rounded-lg bg-slate-900/80 text-slate-300 opacity-0 group-hover:opacity-100 transition shadow">
                    <Maximize2 className="w-3.5 h-3.5" />
                  </div>
                </div>

                {/* Name */}
                <h3
                  onClick={() => setSelectedLightboxProduct(product)}
                  className="text-xs sm:text-sm font-bold text-white hover:text-amber-400 cursor-pointer line-clamp-2 leading-snug mb-2"
                >
                  {product.name}
                </h3>

                {/* Carton Factor Info */}
                <div className="text-[11px] text-slate-400 flex items-center gap-2 mb-3 bg-slate-950/60 p-2 rounded-xl border border-slate-800">
                  <Boxes className="w-3.5 h-3.5 text-amber-400" />
                  <span>معامل الكرتونة: <strong className="text-white">{product.cartonQuantity} قطعة</strong></span>
                </div>

                {/* DUAL WAREHOUSE STOCK (The Key Requirement) */}
                <div className="bg-slate-950 p-2.5 rounded-2xl border border-slate-800 space-y-1.5 text-[11px] mb-3">
                  <div className="flex items-center justify-between">
                    <span className="text-slate-400 flex items-center gap-1">
                      <Building2 className="w-3 h-3 text-emerald-400" />
                      <span>مخزن الفرع:</span>
                    </span>
                    <span className={`font-mono font-bold ${availableInBranch > 0 ? 'text-emerald-400' : 'text-slate-500'}`}>
                      {availableInBranch > 0 ? `${availableInBranch} كرتونة جاهزة` : 'غير متوفر بالفرع'}
                    </span>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="text-slate-400 flex items-center gap-1">
                      <Warehouse className="w-3 h-3 text-purple-400" />
                      <span>مخزن أكتوبر الرئيسي:</span>
                    </span>
                    <span className="font-mono font-bold text-purple-300">
                      {availableInOctober} كرتونة
                    </span>
                  </div>

                  {/* Smart Stock Source Pill */}
                  <div className="pt-1 border-t border-slate-900 text-[10px]">
                    {availableInBranch >= 5 ? (
                      <span className="text-emerald-400 font-bold">🟢 تسليم فوري من مخزن الفرع</span>
                    ) : availableInOctober > 0 ? (
                      <span className="text-amber-400 font-bold">🚚 متاح للشحن المباشر من مخزن أكتوبر المركزي (24h)</span>
                    ) : (
                      <span className="text-red-400 font-bold">⚠️ كمية محدودة جداً</span>
                    )}
                  </div>
                </div>

                {/* Pricing Box */}
                <div className="bg-slate-950/80 p-2.5 rounded-2xl border border-slate-800 mb-3 space-y-1">
                  <div className="flex items-baseline justify-between">
                    <span className="text-[11px] text-slate-400 font-bold">سعر الكرتونة:</span>
                    <div className="flex items-baseline gap-1.5">
                      <span className="text-sm font-black text-amber-400 font-mono">
                        {effectiveCartonPrice.toLocaleString('ar-EG')} ج.م
                      </span>
                      {product.promoPrice && (
                        <span className="text-[10px] line-through text-slate-500 font-mono">
                          {product.cartonPrice.toLocaleString('ar-EG')}
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="flex items-baseline justify-between text-[10px] text-slate-400">
                    <span>سعر القطعة المفردة:</span>
                    <span className="font-bold text-slate-300 font-mono">{product.piecePrice.toLocaleString('ar-EG')} ج.م</span>
                  </div>
                </div>
              </div>

              {/* Action: Smart Quantity & Quick Add Buttons */}
              <div className="space-y-2 pt-2 border-t border-slate-800/80">
                {inCart ? (
                  <div className="bg-slate-950 border border-amber-500/40 rounded-2xl p-2 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => updateCartItem(product.id, inCart.quantityCartons - 1, inCart.quantityPieces)}
                        className="w-7 h-7 rounded-xl bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center font-bold"
                      >
                        <Minus className="w-3.5 h-3.5" />
                      </button>
                      <span className="text-xs font-bold text-white min-w-6 text-center font-mono">
                        {inCart.quantityCartons} ك
                      </span>
                      <button
                        onClick={() => updateCartItem(product.id, inCart.quantityCartons + 1, inCart.quantityPieces)}
                        className="w-7 h-7 rounded-xl bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center font-bold"
                      >
                        <Plus className="w-3.5 h-3.5" />
                      </button>
                    </div>

                    <span className="text-xs font-black text-emerald-400 font-mono">
                      {(inCart.quantityCartons * effectiveCartonPrice).toLocaleString('ar-EG')} ج.م
                    </span>
                  </div>
                ) : (
                  <button
                    onClick={() => addToCart(product, 1, 0)}
                    className="w-full py-2.5 rounded-2xl bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-black flex items-center justify-center gap-1.5 shadow-lg shadow-amber-500/20 transition cursor-pointer"
                  >
                    <Plus className="w-4 h-4" />
                    <span>إضافة كرتونة للطلبية</span>
                  </button>
                )}

                {/* Quick Add Pills: +1 / +5 / +10 */}
                <div className="flex items-center gap-1 text-[10px]">
                  <span className="text-slate-500 text-[10px] ml-1">إضافة سريعة:</span>
                  <button
                    onClick={() => addToCart(product, 1, 0)}
                    className="flex-1 py-1 bg-slate-950 hover:bg-slate-800 text-slate-300 rounded-lg border border-slate-800 text-center font-mono transition"
                  >
                    +1ك
                  </button>
                  <button
                    onClick={() => addToCart(product, 5, 0)}
                    className="flex-1 py-1 bg-slate-950 hover:bg-slate-800 text-slate-300 rounded-lg border border-slate-800 text-center font-mono transition"
                  >
                    +5ك
                  </button>
                  <button
                    onClick={() => addToCart(product, 10, 0)}
                    className="flex-1 py-1 bg-slate-950 hover:bg-slate-800 text-amber-400 rounded-lg border border-amber-500/20 text-center font-mono transition font-bold"
                  >
                    +10ك
                  </button>
                </div>
              </div>

            </div>
          );
        })}
      </div>

      {/* ======================================================== */}
      {/* 4. FLOATING BOTTOM CART BAR FOR INSTANT ORDERING        */}
      {/* ======================================================== */}
      {cart.length > 0 && (
        <div className="fixed bottom-4 left-1/2 -translate-x-1/2 z-40 w-[94%] max-w-xl bg-slate-900/95 border border-amber-500/50 rounded-3xl p-3.5 shadow-2xl backdrop-blur-xl flex items-center justify-between gap-3 animate-in slide-in-from-bottom-5">
          <div className="flex items-center gap-3">
            <div className="relative w-12 h-12 rounded-2xl bg-amber-500 text-slate-950 flex items-center justify-center shadow-lg shadow-amber-500/30 font-black">
              <ShoppingBag className="w-6 h-6" />
              <span className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-red-600 text-white text-[10px] font-bold flex items-center justify-center border-2 border-slate-900">
                {totalCartItemsCount}
              </span>
            </div>
            <div>
              <span className="text-[11px] text-slate-400 block">
                طلبية: <strong className="text-white">{activeCustomer?.name}</strong>
              </span>
              <span className="text-base font-black text-emerald-400 font-mono">
                {totalCartValue.toLocaleString('ar-EG')} ج.م
              </span>
            </div>
          </div>

          <button
            onClick={() => setIsCartOpen(true)}
            className="py-2.5 px-5 rounded-2xl bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 text-xs font-black flex items-center gap-2 shadow-lg shadow-amber-500/20 transition cursor-pointer"
          >
            <span>مراجعة وتأكيد الطلبية</span>
            <ChevronDown className="w-4 h-4 -rotate-90" />
          </button>
        </div>
      )}

      {/* ======================================================== */}
      {/* 5. CUSTOMER PICKER MODAL (BOUND TO REP'S CUSTOMERS ONLY)  */}
      {/* ======================================================== */}
      {isCustomerModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/85 backdrop-blur-md">
          <div className="w-full max-w-lg bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-2xl space-y-4">
            
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <div>
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <User className="w-4 h-4 text-amber-400" />
                  <span>قاعدة العملاء التابعين للمندوب</span>
                </h3>
                <p className="text-xs text-slate-400 mt-0.5">
                  العملاء المربوطين بحسابك فقط في قاعدة بيانات Supabase
                </p>
              </div>
              <button
                onClick={() => setIsCustomerModalOpen(false)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Search */}
            <div className="relative">
              <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={customerSearch}
                onChange={(e) => setCustomerSearch(e.target.value)}
                placeholder="ابحث باسم العميل، كود المعرض، أو رقم الهاتف..."
                className="w-full pr-10 pl-3 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white outline-none focus:border-amber-500 transition"
              />
            </div>

            {/* Customers List */}
            <div className="space-y-2.5 max-h-80 overflow-y-auto pr-1">
              {modalCustomersList.map((cust) => {
                const isSelected = activeCustomer?.id === cust.id;
                const custAvailableCredit = Math.max(0, cust.creditLimit - cust.currentBalance);

                return (
                  <div
                    key={cust.id}
                    onClick={() => {
                      setSelectedCustomer(cust);
                      setIsCustomerModalOpen(false);
                    }}
                    className={`p-3.5 rounded-2xl border cursor-pointer transition flex flex-col justify-between space-y-2 ${
                      isSelected
                        ? 'bg-amber-500/10 border-amber-500/40 text-white'
                        : 'bg-slate-950/70 border-slate-800 hover:bg-slate-800/60 text-slate-300'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-xs text-white">{cust.name}</span>
                        {cust.storeName && (
                          <span className="text-[10px] bg-slate-800 text-slate-300 px-2 py-0.5 rounded">
                            {cust.storeName}
                          </span>
                        )}
                      </div>
                      <span className="text-[10px] font-mono bg-blue-500/10 text-blue-400 px-2 py-0.5 rounded border border-blue-500/20 font-bold">
                        {cust.code}
                      </span>
                    </div>

                    <div className="flex items-center justify-between text-[11px] text-slate-400">
                      <span>الرصيد: <strong className="text-amber-400 font-mono">{cust.currentBalance.toLocaleString('ar-EG')} ج.م</strong></span>
                      <span>سقف الائتمان: <strong className="text-white font-mono">{cust.creditLimit.toLocaleString('ar-EG')} ج.م</strong></span>
                      <span className="text-emerald-400 font-bold">المتاح: {custAvailableCredit.toLocaleString('ar-EG')} ج.م</span>
                    </div>
                  </div>
                );
              })}

              {modalCustomersList.length === 0 && (
                <div className="text-center py-8 text-xs text-slate-500">
                  لا توجد نتائج مطابقة في قاعدة العملاء المسندة لك
                </div>
              )}
            </div>

          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* 6. ORDER REVIEW DRAWER (WITH SOURCE WAREHOUSE CHOICE)     */}
      {/* ======================================================== */}
      {isCartOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-slate-950/85 backdrop-blur-md">
          <div className="w-full max-w-2xl bg-slate-900 border border-slate-800 rounded-3xl shadow-2xl p-5 flex flex-col max-h-[90vh] space-y-4">
            
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <div className="flex items-center gap-2.5">
                <ShoppingBag className="w-5 h-5 text-amber-400" />
                <div>
                  <h3 className="text-base font-bold text-white">تفاصيل وحفظ الطلبية</h3>
                  <span className="text-xs text-slate-400">العميل: <strong className="text-white">{activeCustomer?.name}</strong></span>
                </div>
              </div>
              <button
                onClick={() => setIsCartOpen(false)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Warehouse Fulfillment Source Switcher */}
            <div className="bg-slate-950 p-3 rounded-2xl border border-slate-800 space-y-2">
              <span className="text-xs text-slate-300 font-bold block">
                تحديد مصدر صرف الطلبية (مخزن الصرف):
              </span>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                <button
                  type="button"
                  onClick={() => setFulfillmentWarehouse('branch')}
                  className={`p-2.5 rounded-xl border flex items-center gap-2 transition ${
                    fulfillmentWarehouse === 'branch'
                      ? 'bg-emerald-600/20 border-emerald-500/50 text-emerald-300 font-bold'
                      : 'bg-slate-900 border-slate-800 text-slate-400'
                  }`}
                >
                  <Building2 className="w-4 h-4 text-emerald-400" />
                  <span>مخزن فرع {currentUser.branchName} (تسليم فوري)</span>
                </button>

                <button
                  type="button"
                  onClick={() => setFulfillmentWarehouse('october')}
                  className={`p-2.5 rounded-xl border flex items-center gap-2 transition ${
                    fulfillmentWarehouse === 'october'
                      ? 'bg-purple-600/20 border-purple-500/50 text-purple-300 font-bold'
                      : 'bg-slate-900 border-slate-800 text-slate-400'
                  }`}
                >
                  <Warehouse className="w-4 h-4 text-purple-400" />
                  <span>مخزن أكتوبر المركزي (شحن مباشر)</span>
                </button>
              </div>
            </div>

            {/* Cart Items List */}
            <div className="overflow-y-auto space-y-2.5 flex-1 pr-1">
              {cart.map((item) => {
                const effectiveCartonPrice = item.product.promoPrice || item.product.cartonPrice;
                const sub = item.quantityCartons * effectiveCartonPrice + item.quantityPieces * item.product.piecePrice;

                return (
                  <div
                    key={item.product.id}
                    className="bg-slate-950 border border-slate-800 p-3 rounded-2xl flex items-center justify-between gap-3 text-xs"
                  >
                    <div className="flex items-center gap-3">
                      <img
                        src={item.product.imageUrl}
                        alt={item.product.name}
                        className="w-12 h-12 object-contain bg-slate-900 rounded-xl p-1"
                      />
                      <div>
                        <h4 className="font-bold text-white line-clamp-1">{item.product.name}</h4>
                        <span className="text-[11px] text-slate-400">
                          {effectiveCartonPrice.toLocaleString('ar-EG')} ج.م / كرتونة ({item.product.cartonQuantity} قطعة)
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <div className="flex items-center gap-1.5 bg-slate-900 p-1 rounded-xl border border-slate-800">
                        <button
                          onClick={() => updateCartItem(item.product.id, item.quantityCartons - 1, item.quantityPieces)}
                          className="w-6 h-6 rounded bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center font-bold"
                        >
                          -
                        </button>
                        <span className="font-bold text-white px-1.5 font-mono">{item.quantityCartons} ك</span>
                        <button
                          onClick={() => updateCartItem(item.product.id, item.quantityCartons + 1, item.quantityPieces)}
                          className="w-6 h-6 rounded bg-slate-800 hover:bg-slate-700 text-white flex items-center justify-center font-bold"
                        >
                          +
                        </button>
                      </div>

                      <span className="font-black text-emerald-400 font-mono min-w-16 text-left">
                        {sub.toLocaleString('ar-EG')} ج.م
                      </span>

                      <button
                        onClick={() => removeFromCart(item.product.id)}
                        className="text-slate-500 hover:text-red-400 p-1"
                        title="حذف"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Credit Limit Alert if Exceeded */}
            {isCreditExceeded && (
              <div className="p-3 bg-amber-950/40 border border-amber-500/40 rounded-2xl text-xs text-amber-300 flex items-center gap-2">
                <AlertCircle className="w-4 h-4 text-amber-400 shrink-0" />
                <span>
                  تنبيه ائتماني: قيمة الطلبية الحالية ستتجاوز الحد الائتماني للعميل بمبلغ {(projectedBalance - creditLimit).toLocaleString('ar-EG')} ج.م، وستتطلب موافقة المشرف المباشر.
                </span>
              </div>
            )}

            {/* Notes & Payment Method */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              <div>
                <label className="text-slate-400 block mb-1 font-bold">طريقة السداد المعتمدة:</label>
                <select
                  value={paymentMethod}
                  onChange={(e) => setPaymentMethod(e.target.value as any)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2.5 text-white outline-none"
                >
                  <option value="آجل">آجل (خصم من الرصيد والحد الائتماني)</option>
                  <option value="نقدي">نقدي فوري عند الاستلام</option>
                </select>
              </div>

              <div>
                <label className="text-slate-400 block mb-1 font-bold">ملاحظات تسليم الطلبية للمستودع:</label>
                <input
                  type="text"
                  value={orderNotes}
                  onChange={(e) => setOrderNotes(e.target.value)}
                  placeholder="مثال: تسليم خلال يومين، برجاء الاهتمام بسلامة الزجاج..."
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2.5 text-white outline-none"
                />
              </div>
            </div>

            {/* Bottom Actions */}
            <div className="pt-3 border-t border-slate-800 flex items-center justify-between gap-3">
              <div>
                <span className="text-[11px] text-slate-400 block">إجمالي قيمة الفاتورة:</span>
                <span className="text-lg font-black text-emerald-400 font-mono">
                  {totalCartValue.toLocaleString('ar-EG')} ج.م
                </span>
              </div>

              <button
                onClick={handleSaveAndSubmit}
                className="py-3 px-6 rounded-2xl bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-black text-xs flex items-center gap-2 shadow-lg shadow-amber-500/25 transition cursor-pointer"
              >
                <Send className="w-4 h-4" />
                <span>حفظ وتأكيد الطلبية ونقلها للمشرف</span>
              </button>
            </div>

          </div>
        </div>
      )}

    </div>
  );
};
