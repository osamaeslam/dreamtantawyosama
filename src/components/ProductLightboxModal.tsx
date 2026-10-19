import React, { useState } from 'react';
import { 
  X, 
  ZoomIn, 
  ZoomOut, 
  RotateCcw, 
  ShoppingBag, 
  Plus, 
  Minus, 
  CheckCircle2, 
  Tag, 
  Layers, 
  Boxes, 
  ShieldCheck, 
  Barcode 
} from 'lucide-react';
import { Product } from '../types';
import { useApp } from '../context/AppContext';

interface Props {
  product: Product;
  onClose: () => void;
}

export const ProductLightboxModal: React.FC<Props> = ({ product, onClose }) => {
  const { addToCart } = useApp();
  const [zoomLevel, setZoomLevel] = useState(1);
  const [cartonQty, setCartonQty] = useState(1);
  const [pieceQty, setPieceQty] = useState(0);
  const [addedSuccess, setAddedSuccess] = useState(false);

  const effectiveCartonPrice = product.promoPrice || product.cartonPrice;
  const totalPrice = cartonQty * effectiveCartonPrice + pieceQty * product.piecePrice;

  const handleAdd = () => {
    addToCart(product, cartonQty, pieceQty);
    setAddedSuccess(true);
    setTimeout(() => {
      setAddedSuccess(false);
      onClose();
    }, 900);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
      <div 
        className="relative w-full max-w-4xl bg-slate-900 border border-slate-700 rounded-3xl shadow-2xl overflow-hidden flex flex-col md:flex-row max-h-[92vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 left-4 z-20 p-2.5 rounded-full bg-slate-800/80 hover:bg-slate-700 text-slate-300 hover:text-white transition shadow"
          title="إغلاق"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Left/Top: Image and Zoom Controls */}
        <div className="relative md:w-1/2 bg-slate-950/70 p-6 flex flex-col items-center justify-center min-h-[300px] md:min-h-[460px] overflow-hidden border-b md:border-b-0 md:border-l border-slate-800">
          <div className="relative w-full h-full flex items-center justify-center overflow-hidden rounded-2xl">
            <img
              src={product.imageUrl}
              alt={product.name}
              style={{ transform: `scale(${zoomLevel})`, transition: 'transform 0.25s ease-out' }}
              className="max-h-[340px] max-w-full object-contain cursor-zoom-in select-none drop-shadow-2xl"
              onClick={() => setZoomLevel((z) => (z < 2 ? z + 0.35 : 1))}
            />
          </div>

          {/* Zoom floating toolbar */}
          <div className="absolute bottom-4 right-4 flex items-center gap-1.5 bg-slate-900/90 border border-slate-700/80 px-3 py-1.5 rounded-full shadow-lg backdrop-blur text-xs">
            <button
              onClick={() => setZoomLevel((z) => Math.min(2.5, z + 0.25))}
              className="p-1 text-slate-300 hover:text-white"
              title="تكبير"
            >
              <ZoomIn className="w-4 h-4" />
            </button>
            <span className="text-slate-400 font-mono px-1">{Math.round(zoomLevel * 100)}%</span>
            <button
              onClick={() => setZoomLevel((z) => Math.max(0.8, z - 0.25))}
              className="p-1 text-slate-300 hover:text-white"
              title="تصغير"
            >
              <ZoomOut className="w-4 h-4" />
            </button>
            <button
              onClick={() => setZoomLevel(1)}
              className="p-1 text-slate-400 hover:text-blue-400 mr-1"
              title="إعادة ضبط"
            >
              <RotateCcw className="w-3.5 h-3.5" />
            </button>
          </div>

          {product.salesPriority === 'عرض خاص' && (
            <div className="absolute top-4 right-4 bg-gradient-to-r from-amber-500 to-rose-600 text-white text-xs font-bold px-3 py-1 rounded-full shadow-lg flex items-center gap-1">
              <Tag className="w-3 h-3" />
              عرض خاص وحصري
            </div>
          )}
        </div>

        {/* Right/Bottom: Product specs & Order controls */}
        <div className="md:w-1/2 p-6 flex flex-col justify-between overflow-y-auto max-h-[500px] md:max-h-[600px]">
          <div>
            <div className="flex items-center gap-2 text-xs font-medium text-blue-400 mb-1.5">
              <span>{product.department}</span>
              <span>•</span>
              <span className="text-slate-400">{product.category}</span>
              <span>•</span>
              <span className="bg-slate-800 text-slate-300 px-2 py-0.5 rounded font-mono text-[11px]">{product.code}</span>
            </div>

            <h2 className="text-xl sm:text-2xl font-bold text-white mb-2 leading-snug">
              {product.name}
            </h2>

            {product.notes && (
              <p className="text-xs text-slate-300 bg-slate-800/60 p-3 rounded-xl border border-slate-700/60 mb-4 leading-relaxed">
                {product.notes}
              </p>
            )}

            {/* Price Grid */}
            <div className="grid grid-cols-2 gap-3 mb-4">
              <div className="bg-slate-800/80 border border-slate-700 p-3 rounded-2xl">
                <span className="text-[11px] text-slate-400 block mb-0.5">سعر الكرتونة</span>
                <div className="flex items-baseline gap-2">
                  <span className="text-xl font-black text-emerald-400">
                    {effectiveCartonPrice.toLocaleString('ar-EG')} ج.م
                  </span>
                  {product.promoPrice && (
                    <span className="text-xs line-through text-slate-500">
                      {product.cartonPrice.toLocaleString('ar-EG')}
                    </span>
                  )}
                </div>
                <span className="text-[10px] text-slate-400 block mt-0.5">تحتوي {product.cartonQuantity} قطعة</span>
              </div>

              <div className="bg-slate-800/80 border border-slate-700 p-3 rounded-2xl">
                <span className="text-[11px] text-slate-400 block mb-0.5">سعر القطعة المفردة</span>
                <span className="text-xl font-bold text-slate-200">
                  {product.piecePrice.toLocaleString('ar-EG')} ج.م
                </span>
                <span className="text-[10px] text-slate-400 block mt-0.5">للطلب الفردي أو الكسر</span>
              </div>
            </div>

            {/* Specs badges */}
            <div className="space-y-2 mb-5 text-xs text-slate-300">
              {product.size && (
                <div className="flex items-center gap-2">
                  <span className="text-slate-400 min-w-16">المواصفات:</span>
                  <span className="font-semibold text-white">{product.size}</span>
                </div>
              )}
              {product.color && (
                <div className="flex items-center gap-2">
                  <span className="text-slate-400 min-w-16">اللون / الطراز:</span>
                  <span className="font-semibold text-white">{product.color}</span>
                </div>
              )}
              <div className="flex items-center gap-2">
                <Boxes className="w-3.5 h-3.5 text-blue-400" />
                <span className="text-slate-400">الرصيد المتاح بالمخزن:</span>
                <span className="font-bold text-emerald-400">{product.branchStockActual - product.branchStockReserved} كرتونة</span>
              </div>
              {product.barcode && (
                <div className="flex items-center gap-2 font-mono text-[11px] text-slate-400">
                  <Barcode className="w-3.5 h-3.5 text-slate-500" />
                  <span>{product.barcode}</span>
                </div>
              )}
            </div>
          </div>

          {/* Quantity Controls & Add to Cart */}
          <div className="pt-4 border-t border-slate-800">
            <div className="flex items-center justify-between mb-4">
              <div>
                <span className="text-xs font-semibold text-slate-300 block">كمية الكراتين:</span>
                <div className="flex items-center gap-3 mt-1.5 bg-slate-950 border border-slate-700 rounded-xl p-1">
                  <button
                    onClick={() => setCartonQty((q) => Math.max(1, q - 1))}
                    className="w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 flex items-center justify-center text-slate-200"
                  >
                    <Minus className="w-4 h-4" />
                  </button>
                  <span className="text-base font-bold text-white px-2 min-w-6 text-center">{cartonQty}</span>
                  <button
                    onClick={() => setCartonQty((q) => q + 1)}
                    className="w-8 h-8 rounded-lg bg-slate-800 hover:bg-slate-700 flex items-center justify-center text-slate-200"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <div className="text-left">
                <span className="text-xs text-slate-400 block">الإجمالي التقريبي:</span>
                <span className="text-xl font-black text-emerald-400">
                  {totalPrice.toLocaleString('ar-EG')} ج.م
                </span>
                <span className="text-[10px] text-slate-400 block">({cartonQty * product.cartonQuantity} قطعة)</span>
              </div>
            </div>

            <button
              onClick={handleAdd}
              disabled={addedSuccess}
              className={`w-full py-3.5 rounded-2xl font-bold flex items-center justify-center gap-2 shadow-lg transition-all text-sm ${
                addedSuccess
                  ? 'bg-emerald-600 text-white'
                  : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white shadow-blue-500/20 hover:shadow-blue-500/40'
              }`}
            >
              {addedSuccess ? (
                <>
                  <CheckCircle2 className="w-5 h-5 animate-bounce" />
                  تمت الإضافة للطلبية بنجاح!
                </>
              ) : (
                <>
                  <ShoppingBag className="w-5 h-5" />
                  إضافة إلى طلبية المندوب
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
