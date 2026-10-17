import React, { useState } from 'react';
import {
  X,
  ZoomIn,
  ZoomOut,
  Maximize2,
  Package,
  Plus,
  Minus,
  CheckCircle2,
  Tag,
  ShieldCheck,
  Boxes,
  Truck,
  RotateCcw,
  Sparkles,
  Barcode,
  Layers,
  ShoppingBag
} from 'lucide-react';
import { formatCurrency } from '../services/invoiceService';
import { ProductImage } from './ProductImage';

interface ProductLightboxModalProps {
  product: any | null;
  isOpen: boolean;
  onClose: () => void;
  onAddToCart?: (product: any, quantity: number) => void;
  currentCartQty?: number;
}

export const ProductLightboxModal: React.FC<ProductLightboxModalProps> = ({
  product,
  isOpen,
  onClose,
  onAddToCart,
  currentCartQty = 0,
}) => {
  const [zoomLevel, setZoomLevel] = useState<number>(1);
  const [orderQty, setOrderQty] = useState<number>(1);
  const [addedNotice, setAddedNotice] = useState(false);

  if (!isOpen || !product) return null;

  const cartonPrice = product.promoPrice || product.cartonPrice || 1200;
  const factor = product.cartonQuantity || product.factor || 12;
  const piecePrice = Math.round(cartonPrice / factor);
  const originalPrice = product.cartonPrice && product.promoPrice && product.promoPrice < product.cartonPrice 
    ? product.cartonPrice 
    : cartonPrice * 1.15;
  const savings = originalPrice - cartonPrice;

  const handleZoomIn = () => {
    setZoomLevel((prev) => Math.min(prev + 0.4, 2.5));
  };

  const handleZoomOut = () => {
    setZoomLevel((prev) => Math.max(prev - 0.4, 1));
  };

  const handleResetZoom = () => {
    setZoomLevel(1);
  };

  const handleAdd = () => {
    if (onAddToCart) {
      onAddToCart(product, orderQty);
      setAddedNotice(true);
      setTimeout(() => setAddedNotice(false), 2000);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
      <div 
        className="bg-white rounded-3xl max-w-4xl w-full max-h-[92vh] overflow-hidden flex flex-col shadow-2xl border border-slate-700/30"
        onClick={(e) => e.stopPropagation()}
      >
        {/* هيدر نافذة التكبير */}
        <div className="bg-slate-900 text-white px-5 py-3.5 flex items-center justify-between border-b border-slate-800">
          <div className="flex items-center gap-2.5 min-w-0">
            <span className="font-mono text-xs font-black bg-amber-400 text-slate-950 px-2.5 py-0.5 rounded-lg shadow-sm">
              {product.code}
            </span>
            <div className="min-w-0">
              <h3 className="font-black text-sm sm:text-base text-white truncate">
                {product.name}
              </h3>
              <p className="text-[11px] text-slate-400 truncate">
                {product.department || 'أدوات منزلية'} • {product.category || 'عام'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            {/* أدوات التحكم في الزووم */}
            <div className="hidden sm:flex items-center gap-1 bg-slate-800 p-1 rounded-xl border border-slate-700">
              <button
                onClick={handleZoomIn}
                className="p-1.5 text-slate-300 hover:text-white hover:bg-slate-700 rounded-lg transition"
                title="تكبير الصورة (+)"
              >
                <ZoomIn className="w-4 h-4" />
              </button>
              <button
                onClick={handleZoomOut}
                className="p-1.5 text-slate-300 hover:text-white hover:bg-slate-700 rounded-lg transition"
                title="تصغير الصورة (-)"
              >
                <ZoomOut className="w-4 h-4" />
              </button>
              {zoomLevel > 1 && (
                <button
                  onClick={handleResetZoom}
                  className="p-1.5 text-amber-300 hover:bg-slate-700 rounded-lg transition"
                  title="إعادة الحجم الطبيعي"
                >
                  <RotateCcw className="w-4 h-4" />
                </button>
              )}
            </div>

            <button
              onClick={onClose}
              className="w-8 h-8 rounded-xl bg-slate-800 hover:bg-rose-600 text-slate-300 hover:text-white flex items-center justify-center transition cursor-pointer"
              title="إغلاق"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* جسم المعاينة والتكبير */}
        <div className="flex-1 overflow-y-auto grid grid-cols-1 md:grid-cols-2 divide-y md:divide-y-0 md:divide-x md:divide-x-reverse divide-slate-200">
          {/* قسم الصورة المكبرة عالي الدقة */}
          <div className="bg-gradient-to-br from-slate-50 via-slate-100 to-amber-50/20 p-6 flex flex-col items-center justify-center relative min-h-[340px] overflow-hidden select-none">
            {/* مؤشر مستوى الزووم */}
            <div className="absolute top-3 right-3 bg-slate-900/80 backdrop-blur-sm text-white px-2.5 py-1 rounded-lg text-[10px] font-mono font-bold flex items-center gap-1 z-10">
              <span>{Math.round(zoomLevel * 100)}%</span>
              <span className="text-slate-400">زووم</span>
            </div>

            {/* الصورة بحجم كبير مع إمكانية التكبير */}
            <div 
              className="relative w-full h-72 sm:h-80 flex items-center justify-center transition-transform duration-200 cursor-zoom-in"
              style={{ transform: `scale(${zoomLevel})` }}
              onClick={() => {
                if (zoomLevel === 1) handleZoomIn();
                else handleResetZoom();
              }}
              title="انقر للتكبير أو التصغير"
            >
              {product.imageUrl ? (
                <img
                  src={product.imageUrl}
                  alt={product.name}
                  className="max-w-full max-h-full object-contain filter drop-shadow-lg"
                  loading="eager"
                />
              ) : (
                <div className="w-44 h-44 rounded-3xl bg-amber-100/60 border-2 border-amber-300/60 flex flex-col items-center justify-center text-amber-700 p-4 text-center">
                  <Boxes className="w-16 h-16 mb-2 text-amber-600" />
                  <span className="font-black text-xs">صورة الصنف التجاري</span>
                  <span className="text-[10px] text-amber-600/80 mt-1">{product.code}</span>
                </div>
              )}
            </div>

            <div className="text-[11px] text-slate-500 font-bold mt-3 text-center">
              💡 نصيحة: انقر على الصورة مباشرة لتكبير التفاصيل ومواصفات المنتج
            </div>
          </div>

          {/* قسم البيانات المالية ومواصفات الكرتونة والطلب السريع */}
          <div className="p-5 sm:p-6 space-y-4 flex flex-col justify-between bg-white">
            <div className="space-y-4">
              {/* الأسعار وتفاصيل الوفر */}
              <div className="bg-amber-50/60 border border-amber-200/80 p-4 rounded-2xl space-y-2">
                <div className="flex items-baseline justify-between">
                  <span className="text-xs text-slate-600 font-bold">سعر الجملة للكرتونة:</span>
                  <div className="text-left">
                    <span className="text-xl sm:text-2xl font-black text-slate-950">
                      {formatCurrency(cartonPrice)}
                    </span>
                    {savings > 0 && (
                      <span className="text-xs text-slate-400 line-through mr-2 font-bold">
                        {formatCurrency(originalPrice)}
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex items-center justify-between text-xs pt-2 border-t border-amber-200/50">
                  <span className="text-slate-600">سعر القطعة المفردة المحسوب:</span>
                  <span className="font-black text-amber-900">
                    {formatCurrency(piecePrice)} / قطعة
                  </span>
                </div>

                {savings > 0 && (
                  <div className="text-[11px] font-black text-emerald-700 bg-emerald-100/80 px-2.5 py-1 rounded-xl flex items-center gap-1.5">
                    <Tag className="w-3.5 h-3.5" />
                    <span>وفرت لعميلك {formatCurrency(savings)} في كل كرتونة!</span>
                  </div>
                )}
              </div>

              {/* بطاقة مواصفات الشدة والباركود */}
              <div className="grid grid-cols-2 gap-2.5 text-xs">
                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-slate-500 text-[11px] block">شدة الكرتونة (Factor):</span>
                  <span className="font-black text-sm text-slate-900">{factor} قطعة</span>
                </div>
                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-slate-500 text-[11px] block">رصيد المخزن المركزي:</span>
                  <span className="font-black text-sm text-emerald-700">
                    {product.branchStockActual || product.mainWarehouseActual || 180} كرتونة متاحة
                  </span>
                </div>
                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-slate-500 text-[11px] block">الكود الموحد (#):</span>
                  <span className="font-mono font-bold text-xs text-slate-900">
                    {product.unifiedCode || `#${product.code}`}
                  </span>
                </div>
                <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-slate-500 text-[11px] block">الباركود الدولي:</span>
                  <span className="font-mono font-bold text-[11px] text-slate-900 truncate block">
                    {product.barcode || '6221000998812'}
                  </span>
                </div>
              </div>

              {/* إشعار النجاح */}
              {addedNotice && (
                <div className="bg-emerald-600 text-white p-3 rounded-xl text-xs font-bold flex items-center gap-2 animate-in fade-in">
                  <CheckCircle2 className="w-4 h-4 shrink-0" />
                  <span>تم إضافة {orderQty} كرتونة إلى طلبية العميل بنجاح!</span>
                </div>
              )}
            </div>

            {/* أدوات الإضافة السريعة للطلبية */}
            <div className="pt-3 border-t border-slate-200 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-slate-700">تحديد عدد الكراتين المطلوبة:</span>
                <div className="flex items-center gap-2 bg-slate-100 p-1 rounded-xl border border-slate-300">
                  <button
                    onClick={() => setOrderQty((q) => Math.max(1, q - 1))}
                    className="w-7 h-7 rounded-lg bg-white text-slate-800 hover:bg-slate-200 flex items-center justify-center font-black cursor-pointer shadow-xs"
                  >
                    -
                  </button>
                  <span className="font-black text-xs px-2 text-slate-900">{orderQty} كرتونة</span>
                  <button
                    onClick={() => setOrderQty((q) => q + 1)}
                    className="w-7 h-7 rounded-lg bg-amber-400 hover:bg-amber-300 text-slate-950 flex items-center justify-center font-black cursor-pointer shadow-xs"
                  >
                    +
                  </button>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={handleAdd}
                  className="flex-1 bg-amber-400 hover:bg-amber-300 active:bg-amber-500 text-slate-950 font-black py-3 rounded-xl text-xs sm:text-sm flex items-center justify-center gap-2 shadow-md transition cursor-pointer border border-amber-500/40"
                >
                  <ShoppingBag className="w-4 h-4 text-slate-950" />
                  <span>أضف للطلبية ({formatCurrency(cartonPrice * orderQty)}) 🛒</span>
                </button>

                <button
                  onClick={onClose}
                  className="px-4 py-3 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs cursor-pointer"
                >
                  إغلاق
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
