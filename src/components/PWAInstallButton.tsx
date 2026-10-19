import React, { useState } from 'react';
import { Download, Smartphone, Share2, PlusSquare, X, Check } from 'lucide-react';
import { usePWAInstall } from '../hooks/usePWAInstall';

interface Props {
  className?: string;
  variant?: 'button' | 'badge';
}

export const PWAInstallButton: React.FC<Props> = ({ className, variant = 'button' }) => {
  const { isInstallable, isInstalled, isIOS, install } = usePWAInstall();
  const [showIOSGuide, setShowIOSGuide] = useState(false);

  // If already installed and running standalone, hide the button
  if (isInstalled) {
    return (
      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl bg-emerald-950/40 border border-emerald-500/30 text-emerald-400 text-xs font-bold">
        <Check className="w-3.5 h-3.5" />
        <span>تطبيق مثبت (PWA)</span>
      </span>
    );
  }

  // Chromium / Android / Desktop flow
  if (isInstallable) {
    return (
      <button
        onClick={install}
        className={className || "bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-lg shadow-blue-600/30 transition"}
        title="تثبيت التطبيق على الشاشة الرئيسية للموبايل"
      >
        <Download className="w-3.5 h-3.5" />
        <span>تثبيت التطبيق 📲</span>
      </button>
    );
  }

  // iOS Safari flow (beforeinstallprompt is not fired on WebKit)
  if (isIOS) {
    return (
      <>
        <button
          onClick={() => setShowIOSGuide(true)}
          className={className || "bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition"}
          title="تثبيت التطبيق على الآيفون والآيباد"
        >
          <Smartphone className="w-3.5 h-3.5 text-blue-400" />
          <span>تثبيت على iPhone</span>
        </button>

        {showIOSGuide && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4 font-['Cairo',sans-serif]">
            <div className="w-full max-w-sm rounded-3xl bg-slate-900 border border-slate-800 p-6 shadow-2xl text-right">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-4">
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Smartphone className="w-5 h-5 text-blue-400" />
                  <span>تثبيت التطبيق على iPhone / iPad</span>
                </h3>
                <button
                  onClick={() => setShowIOSGuide(false)}
                  className="text-slate-400 hover:text-white"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="space-y-3 text-xs text-slate-300">
                <div className="flex items-start gap-3 bg-slate-950 p-3 rounded-2xl border border-slate-800">
                  <div className="w-7 h-7 rounded-xl bg-blue-600/20 text-blue-400 flex items-center justify-center shrink-0 font-bold">
                    1
                  </div>
                  <div>
                    <span>اضغط على زر المشاركة </span>
                    <strong className="text-white">Share <Share2 className="w-3.5 h-3.5 inline mx-1 text-blue-400" /></strong>
                    <span>في أسفل متصفح Safari.</span>
                  </div>
                </div>

                <div className="flex items-start gap-3 bg-slate-950 p-3 rounded-2xl border border-slate-800">
                  <div className="w-7 h-7 rounded-xl bg-blue-600/20 text-blue-400 flex items-center justify-center shrink-0 font-bold">
                    2
                  </div>
                  <div>
                    <span>مرر لأسفل واختر </span>
                    <strong className="text-white">إضافة إلى الشاشة الرئيسية (Add to Home Screen) <PlusSquare className="w-3.5 h-3.5 inline mx-1 text-emerald-400" /></strong>
                  </div>
                </div>

                <div className="flex items-start gap-3 bg-slate-950 p-3 rounded-2xl border border-slate-800">
                  <div className="w-7 h-7 rounded-xl bg-blue-600/20 text-blue-400 flex items-center justify-center shrink-0 font-bold">
                    3
                  </div>
                  <span>اضغط على <strong>إضافة (Add)</strong> في أعلى الزاوية، وسيعمل التطبيق كبرنامج كامل بدون شريط المتصفح!</span>
                </div>
              </div>

              <button
                onClick={() => setShowIOSGuide(false)}
                className="mt-5 w-full rounded-2xl bg-blue-600 hover:bg-blue-500 py-2.5 text-xs font-bold text-white transition shadow-lg shadow-blue-600/30"
              >
                فهمت ذلك
              </button>
            </div>
          </div>
        )}
      </>
    );
  }

  // Fallback button for browsers where prompt isn't ready yet or desktop
  return (
    <button
      onClick={() => {
        alert('لتثبيت التطبيق على هاتفك:\n1. من قائمة متصفح Chrome اضغط على الثلاث نقاط (⋮)\n2. اختر "تثبيت التطبيق" أو "إضافة إلى الشاشة الرئيسية (Install App)"');
      }}
      className={className || "bg-slate-800/80 hover:bg-slate-700 text-slate-300 border border-slate-700 px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition"}
      title="تثبيت التطبيق على الموبايل"
    >
      <Download className="w-3.5 h-3.5 text-blue-400" />
      <span>تثبيت PWA 📲</span>
    </button>
  );
};
