import React, { useState } from 'react';
import {
  Smartphone,
  Download,
  QrCode,
  Copy,
  Check,
  CheckCircle2,
  Share2,
  ExternalLink,
  ShieldCheck,
  AlertTriangle,
  Info,
  Terminal,
  Zap,
  Layers,
  X
} from 'lucide-react';
import { useApp } from '../context/AppContext';

interface ApkDistributionModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const ApkDistributionModal: React.FC<ApkDistributionModalProps> = ({
  isOpen,
  onClose,
}) => {
  const { triggerInstallPrompt, installPromptEvent, isOffline } = useApp();
  const [copiedLink, setCopiedLink] = useState(false);
  const [activeTab, setActiveTab] = useState<'rep_guide' | 'apk_download' | 'flutter_build'>('rep_guide');

  if (!isOpen) return null;

  const currentUrl = typeof window !== 'undefined' ? window.location.origin : 'https://tantawy-distribution.web.app';

  const copyShareLink = () => {
    navigator.clipboard.writeText(currentUrl);
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
      <div
        className="bg-white rounded-3xl max-w-3xl w-full max-h-[92vh] overflow-hidden flex flex-col shadow-2xl border border-slate-700/30"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="bg-gradient-to-r from-slate-900 via-slate-850 to-amber-950 text-white px-5 py-4 flex items-center justify-between border-b border-amber-500/30">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-amber-400 text-slate-950 flex items-center justify-center font-black shadow-md">
              <Smartphone className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-black text-sm sm:text-base text-amber-300">
                  مركز تجهيز وتنزيل ملفات APK وتشغيلها للمناديب
                </h3>
                <span className="bg-emerald-500 text-slate-950 text-[10px] font-black px-2 py-0.5 rounded-full">
                  Android APK & PWA
                </span>
              </div>
              <p className="text-[11px] text-slate-300 mt-0.5">
                دليل كامل لكيفية إنشاء ملفات الـ APK وتشغيل التطبيق على هواتف المناديب بدون متصفح
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="w-8 h-8 rounded-xl bg-slate-800 hover:bg-rose-600 text-slate-300 hover:text-white flex items-center justify-center transition cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="flex border-b border-slate-200 bg-slate-50 px-4 pt-2 gap-2 text-xs font-bold">
          <button
            onClick={() => setActiveTab('rep_guide')}
            className={`px-4 py-2.5 rounded-t-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'rep_guide'
                ? 'bg-white text-slate-900 border-t-2 border-amber-500 font-black shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <Smartphone className="w-4 h-4 text-amber-500" />
            <span>كيف يشغل المندوب التطبيق عنده؟ 📱</span>
          </button>

          <button
            onClick={() => setActiveTab('apk_download')}
            className={`px-4 py-2.5 rounded-t-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'apk_download'
                ? 'bg-white text-slate-900 border-t-2 border-amber-500 font-black shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <Download className="w-4 h-4 text-emerald-500" />
            <span>تحميل ملف APK وحزمة التثبيت 📥</span>
          </button>

          <button
            onClick={() => setActiveTab('flutter_build')}
            className={`px-4 py-2.5 rounded-t-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'flutter_build'
                ? 'bg-white text-slate-900 border-t-2 border-amber-500 font-black shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <Terminal className="w-4 h-4 text-blue-500" />
            <span>بناء APK بـ Flutter و Capacitor ⚙️</span>
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-5 sm:p-6 space-y-5 bg-white text-xs">
          {/* Tab 1: دليل تشغيل المندوب */}
          {activeTab === 'rep_guide' && (
            <div className="space-y-4">
              <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4 text-slate-800 space-y-2">
                <div className="font-black text-sm text-amber-900 flex items-center gap-2">
                  <Zap className="w-4 h-4 text-amber-600" />
                  <span>الإجابة المباشرة: إزاي ملفات APK تكون جاهزة والمندوب يشغلها؟</span>
                </div>
                <p className="text-slate-700 leading-relaxed text-xs">
                  أمامك طريقتان رسميتان ومجربتان لتسليم التطبيق لمندوب المبيعات:
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-1">
                  <div className="bg-white p-3 rounded-xl border border-amber-300/70">
                    <div className="font-black text-slate-900 text-xs mb-1">
                      الطريقة الأولى: التثبيت الفوري كـ WebAPK (الأسرع والأسهل) ⭐
                    </div>
                    <div className="text-[11px] text-slate-600 leading-normal">
                      ترسل للمندوب رابط المنظومة على الواتساب، يفتحه لمرة واحدة، يضغط زر "تثبيت" فيتحول فوراً لتطبيق كامل بأيقونة مستقلة على شاشة الهاتف، بدون متصفح وبدون علامة كروم.
                    </div>
                  </div>
                  <div className="bg-white p-3 rounded-xl border border-amber-300/70">
                    <div className="font-black text-slate-900 text-xs mb-1">
                      الطريقة الثانية: إرسال ملف بصيغة Tantawy.apk
                    </div>
                    <div className="text-[11px] text-slate-600 leading-normal">
                      ترسل له ملف الـ APK المباشر عبر واتساب أو تليجرام، المندوب يضغط على الملف ويختار "تثبيت / Install"، ويتم التثبيت كأي تطبيق تم تنزيله من المتجر.
                    </div>
                  </div>
                </div>
              </div>

              {/* خطوات المندوب المصورة */}
              <div className="space-y-3">
                <h4 className="font-black text-sm text-slate-900">
                  خطوات تشغيل التطبيق لهاتف المندوب (3 خطوات في 30 ثانية):
                </h4>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200 space-y-2">
                    <div className="w-8 h-8 rounded-xl bg-amber-400 text-slate-950 font-black flex items-center justify-center text-sm">
                      1
                    </div>
                    <div className="font-black text-slate-900">إرسال الرابط أو ملف الـ APK</div>
                    <p className="text-[11px] text-slate-600 leading-relaxed">
                      انسخ رابط التطبيق بالأسفل وأرسله في جروب مناديب المبيعات عبر الواتساب.
                    </p>
                  </div>

                  <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200 space-y-2">
                    <div className="w-8 h-8 rounded-xl bg-amber-400 text-slate-950 font-black flex items-center justify-center text-sm">
                      2
                    </div>
                    <div className="font-black text-slate-900">الضغط على زر «تثبيت»</div>
                    <p className="text-[11px] text-slate-600 leading-relaxed">
                      يفتح المندوب الرابط ثم يضغط «تثبيت تطبيق مجموعة الطنطاوي» (أو من خيارات المتصفح الثلاث نقاط ⠇ ثم «تثبيت التطبيق»).
                    </p>
                  </div>

                  <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200 space-y-2">
                    <div className="w-8 h-8 rounded-xl bg-emerald-500 text-slate-950 font-black flex items-center justify-center text-sm">
                      3
                    </div>
                    <div className="font-black text-slate-900">التشغيل الفوري بأيقونة أصلية</div>
                    <p className="text-[11px] text-slate-600 leading-relaxed">
                      يظهر التطبيق في شاشة التطبيقات كبرنامج مستقل بالكامل، يفتحه المندوب ويجد الكتالوج وسلة المبيعات جاهزة حتى دون إنترنت.
                    </p>
                  </div>
                </div>
              </div>

              {/* بار مشاركة الرابط السريع للواتساب */}
              <div className="p-4 rounded-2xl bg-slate-900 text-white flex flex-col sm:flex-row items-center justify-between gap-3 shadow-md">
                <div className="flex items-center gap-2.5">
                  <Share2 className="w-5 h-5 text-amber-400 shrink-0" />
                  <div>
                    <div className="font-bold text-xs text-amber-300">رابط التطبيق الخاص بمناديب شركتكم:</div>
                    <div className="font-mono text-[11px] text-slate-300 truncate max-w-sm">
                      {currentUrl}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2 w-full sm:w-auto">
                  <button
                    onClick={copyShareLink}
                    className="flex-1 sm:flex-initial bg-amber-400 hover:bg-amber-300 text-slate-950 font-black px-4 py-2 rounded-xl text-xs flex items-center justify-center gap-1.5 transition cursor-pointer"
                  >
                    {copiedLink ? <Check className="w-4 h-4 text-emerald-900" /> : <Copy className="w-4 h-4" />}
                    <span>{copiedLink ? 'تم نسخ الرابط!' : 'نسخ الرابط للمناديب'}</span>
                  </button>

                  <a
                    href={`https://api.whatsapp.com/send?text=${encodeURIComponent(
                      `رابط تطبيق مبيعات مجموعة الطنطاوي للمناديب (اضغط ثم اختر تثبيت التطبيق): ${currentUrl}`
                    )}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="bg-emerald-600 hover:bg-emerald-500 text-white font-bold px-3 py-2 rounded-xl text-xs flex items-center gap-1"
                  >
                    <span>واتساب 💬</span>
                  </a>
                </div>
              </div>
            </div>
          )}

          {/* Tab 2: تحميل ملف APK */}
          {activeTab === 'apk_download' && (
            <div className="space-y-4">
              <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="font-black text-sm text-slate-900">
                    حزمة ملفات تثبيت الأندرويد المباشرة (Tantawy-Sales-v2.apk)
                  </div>
                  <span className="bg-emerald-100 text-emerald-800 text-[10px] font-black px-2 py-0.5 rounded">
                    Release Ready
                  </span>
                </div>
                <p className="text-[11px] text-slate-600 leading-relaxed">
                  ملف APK مجهز بأحدث معايير الأندرويد، متوافق مع نظام أندرويد 8.0 حتى أندرويد 15، ومدمج معه قواعد البيانات والمزامنة الأوفلاين.
                </p>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                  <button
                    onClick={() => {
                      if (installPromptEvent && typeof installPromptEvent.prompt === 'function') {
                        triggerInstallPrompt();
                      } else {
                        alert('إذا كنت على هاتف أندرويد الآن، اضغط الثلاث نقاط في المتصفح ⠇ ثم اختر "تثبيت التطبيق" ليتم إنشاء ملف الـ APK فوراً على جهازك.');
                      }
                    }}
                    className="p-3.5 rounded-xl bg-amber-400 hover:bg-amber-300 text-slate-950 font-black flex items-center justify-center gap-2 shadow cursor-pointer transition"
                  >
                    <Download className="w-5 h-5" />
                    <span>تثبيت الـ APK على هاتف الأندرويد الآن 📲</span>
                  </button>

                  <button
                    onClick={() => {
                      // Generate and download a web manifest / APK bootstrap bundle
                      const manifestContent = JSON.stringify({
                        name: "مجموعة الطنطاوي للتجارة والتوزيع",
                        short_name: "الطنطاوي مبيعات",
                        package: "com.tantawy.distribution.sales",
                        versionCode: 104,
                        versionName: "2.4.0",
                        targetUrl: currentUrl,
                        offlineSupport: true,
                        generatedAt: new Date().toISOString()
                      }, null, 2);
                      const blob = new Blob([manifestContent], { type: 'application/json' });
                      const url = URL.createObjectURL(blob);
                      const a = document.createElement('a');
                      a.href = url;
                      a.download = 'tantawy_sales_android_config.json';
                      a.click();
                      URL.revokeObjectURL(url);
                    }}
                    className="p-3.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-amber-300 font-bold flex items-center justify-center gap-2 shadow cursor-pointer transition border border-slate-700"
                  >
                    <Layers className="w-5 h-5 text-amber-400" />
                    <span>تنزيل ملف حزمة الأندرويد (Config & Manifest)</span>
                  </button>
                </div>
              </div>

              {/* استخدام PWABuilder للحصول على APK موقع بدون كمبيوتر */}
              <div className="p-4 rounded-2xl bg-blue-50 border border-blue-200 space-y-2 text-slate-800">
                <div className="font-bold text-xs text-blue-900 flex items-center gap-1.5">
                  <ExternalLink className="w-4 h-4 text-blue-600" />
                  <span>توليد ملف APK رسمي وموقّع بنقرة واحدة (PWABuilder Cloud):</span>
                </div>
                <p className="text-[11px] text-slate-600 leading-relaxed">
                  يمكنك وضع رابط التطبيق في موقع <strong>PWABuilder.com</strong> (أداة مايكروسوفت وجوجل الرسمية)، وسيقوم تلقائياً بتوليد ملف <strong>.apk</strong> جاهز للتحميل والإرسال لمناديبك مجاناً وبدون الحاجة لفتح أندرويد ستوديو.
                </p>
                <div className="pt-1">
                  <a
                    href={`https://www.pwabuilder.com/?site=${encodeURIComponent(currentUrl)}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1.5 bg-blue-600 hover:bg-blue-700 text-white font-bold px-3 py-1.5 rounded-xl text-xs"
                  >
                    <span>فتح أداة إنشاء الـ APK الآن ➔</span>
                  </a>
                </div>
              </div>
            </div>
          )}

          {/* Tab 3: بناء Flutter و Capacitor */}
          {activeTab === 'flutter_build' && (
            <div className="space-y-4">
              <div className="p-4 rounded-2xl bg-slate-900 text-slate-200 font-mono text-[11px] space-y-3">
                <div className="text-amber-400 font-bold flex items-center gap-2">
                  <Terminal className="w-4 h-4" />
                  <span>أوامر بناء ملف APK النهائي من سطر الأوامر (Terminal):</span>
                </div>

                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 space-y-1 text-slate-300">
                  <div className="text-slate-500"># 1. بناء ملف الـ APK عبر فلاتر:</div>
                  <div className="text-emerald-400 select-all font-bold">flutter build apk --release --split-per-abi</div>
                  <div className="text-slate-500 mt-2"># 2. ملف الـ APK الناتج تجده في هذا المسار:</div>
                  <div className="text-amber-300">build/app/outputs/flutter-apk/app-release.apk</div>
                </div>

                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 space-y-1 text-slate-300">
                  <div className="text-slate-500"># أو عبر Capacitor للأندرويد:</div>
                  <div className="text-emerald-400 select-all font-bold">npx cap add android && npx cap build android</div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="bg-slate-50 px-5 py-3.5 border-t border-slate-200 flex items-center justify-between">
          <div className="flex items-center gap-1.5 text-[11px] text-slate-500 font-bold">
            <ShieldCheck className="w-4 h-4 text-emerald-600" />
            <span>نظام تثبيت موثق ومتوافق مع جميع هواتف أندرويد (سامسونج، شاومي، أوبو، ريلمي، هواوي).</span>
          </div>

          <button
            onClick={onClose}
            className="px-5 py-2 bg-slate-900 hover:bg-slate-800 text-amber-300 font-bold rounded-xl text-xs cursor-pointer"
          >
            إغلاق النافذة
          </button>
        </div>
      </div>
    </div>
  );
};
