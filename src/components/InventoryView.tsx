import React, { useState, useMemo } from 'react';
import { Boxes, Search, Building2, Package, Tag, AlertTriangle, ShieldCheck } from 'lucide-react';
import { useApp } from '../context/AppContext';

export const InventoryView: React.FC = () => {
  const { products, setSelectedLightboxProduct } = useApp();
  const [searchQuery, setSearchQuery] = useState('');
  const [deptFilter, setDeptFilter] = useState('الكل');

  const departments = ['الكل', 'أطقم سفرة', 'زجاج وكريستال', 'أدوات مائدة', 'أواني طهي'];

  const filtered = useMemo(() => {
    return products.filter((p) => {
      const matchDept = deptFilter === 'الكل' || p.department === deptFilter;
      const q = searchQuery.toLowerCase().trim();
      const matchQuery =
        !q ||
        p.name.toLowerCase().includes(q) ||
        p.code.toLowerCase().includes(q) ||
        p.category.toLowerCase().includes(q);
      return matchDept && matchQuery;
    });
  }, [products, deptFilter, searchQuery]);

  return (
    <div className="w-full max-w-6xl mx-auto p-3 sm:p-6 space-y-6">
      {/* Header */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 shadow-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-xs font-bold text-emerald-400 mb-1">
            <Boxes className="w-4 h-4" />
            أرصدة المخازن والتشغيل
          </div>
          <h2 className="text-xl font-bold text-white">إدارة المخزون الفعلي والمحجوز</h2>
          <p className="text-xs text-slate-400 mt-1">
            متابعة أرصدة المخزن الرئيسي (مدينة 6 أكتوبر) وأرصدة الفروع المتاحة للصرف الفوري
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="bg-slate-950 px-4 py-2 rounded-2xl border border-slate-800 text-xs">
            <span className="text-slate-400 block text-[10px]">إجمالي الأصناف:</span>
            <span className="text-base font-bold text-white">{products.length} صنف</span>
          </div>
        </div>
      </div>

      {/* Search & Filter */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-slate-900 p-3 rounded-2xl border border-slate-800">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute right-3.5 top-3" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="ابحث بكود الصنف أو الاسم..."
            className="w-full pr-10 pl-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
          />
        </div>

        <div className="flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0">
          {departments.map((d) => (
            <button
              key={d}
              onClick={() => setDeptFilter(d)}
              className={`px-3 py-1 rounded-xl text-xs font-bold whitespace-nowrap transition ${
                deptFilter === d ? 'bg-emerald-600 text-white' : 'bg-slate-950 text-slate-400 hover:text-white border border-slate-800'
              }`}
            >
              {d}
            </button>
          ))}
        </div>
      </div>

      {/* Stock Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-xl">
        <table className="w-full text-right text-xs">
          <thead>
            <tr className="bg-slate-950/80 text-slate-400 border-b border-slate-800">
              <th className="p-4">الصنف والكود</th>
              <th className="p-4">القسم</th>
              <th className="p-4 text-center">الكرتونة (قطعة)</th>
              <th className="p-4 text-center">رصيد الفرع الفعلي</th>
              <th className="p-4 text-center">المحجوز للطلبيات</th>
              <th className="p-4 text-center">الرصيد المتاح للبيع</th>
              <th className="p-4 text-center">المخزن الرئيسي (أكتوبر)</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {filtered.map((prod) => {
              const available = prod.branchStockActual - prod.branchStockReserved;
              return (
                <tr key={prod.id} className="hover:bg-slate-850/40 transition">
                  <td className="p-4">
                    <div className="flex items-center gap-3">
                      <img
                        src={prod.imageUrl}
                        alt={prod.name}
                        onClick={() => setSelectedLightboxProduct(prod)}
                        className="w-10 h-10 object-contain rounded-xl bg-slate-950 p-1 cursor-pointer hover:scale-105 transition"
                      />
                      <div>
                        <span 
                          onClick={() => setSelectedLightboxProduct(prod)}
                          className="font-bold text-white hover:text-emerald-400 cursor-pointer block"
                        >
                          {prod.name}
                        </span>
                        <span className="text-[10px] text-slate-500 font-mono">{prod.code}</span>
                      </div>
                    </div>
                  </td>
                  <td className="p-4 text-slate-400">{prod.department}</td>
                  <td className="p-4 text-center font-bold text-slate-300">{prod.cartonQuantity}</td>
                  <td className="p-4 text-center font-bold text-white">{prod.branchStockActual} ك</td>
                  <td className="p-4 text-center text-amber-400 font-bold">{prod.branchStockReserved} ك</td>
                  <td className="p-4 text-center">
                    <span className="px-2.5 py-1 rounded-full bg-emerald-950 text-emerald-400 border border-emerald-800/60 font-black">
                      {available} كرتونة
                    </span>
                  </td>
                  <td className="p-4 text-center font-bold text-slate-300">{prod.mainWarehouseStock} ك</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};
