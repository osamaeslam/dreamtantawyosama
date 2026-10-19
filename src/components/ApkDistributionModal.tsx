import React, { useState } from 'react';
import { 
  X, 
  Smartphone, 
  Download, 
  Share2, 
  Check, 
  Copy, 
  CheckCircle2, 
  ShieldCheck, 
  ArrowRight, 
  HelpCircle,
  ExternalLink,
  Laptop
} from 'lucide-react';
import { PWAInstallButton } from './PWAInstallButton';

interface Props {
  onClose: () => void;
}

export const ApkDistributionModal: React.FC<Props> = ({ onClose }) => {
  const [copied, setCopied] = useState(false);
  const [activeTab, setActiveTab] = useState<'apk' | 'pwa' | 'ios'>('apk');

  const apkDownloadUrl = `${window.location.origin}/downloads/tantawy-sales-v1.0.apk`;
  const shareMessage = `تطبيق مبيعات مجموعة الطنطاوي للأندرويد والموبايل: حمل وثبت التطبيق مباشرة للمناديب من الرابط: ${window.location.href}`;

  const handleCopyLink = () => {
    navigator.clipboard.writeText(shareMessage);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleShareWhatsApp = () => {
    const url = `https://api.whatsapp.com/send?text=${encodeURIComponent(shareMessage)}`;
    window.open(url, '_blank');
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
      <div 
        className="relative w-full max-w-2xl bg-slate-900 border border-slate-700 rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[92vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-slate-800 bg-slate-950/60">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-blue-600/20 text-blue-400 flex items-center justify-center border border-blue-500/30">
              <Smartphone className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-white">تثبيت التطبيق على هواتف المناديب</h2>
              <p className="text-xs text-slate-400">دليل تشغيل APK وتثبيت أيقونة التطبيق بدون متصفح</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b border-slate-800 bg-slate-950/40 p-2 gap-2 text-xs font-semibold">
          <button
            onClick={() => setActiveTab('apk')}
            className={`flex-1 py-2.5 px-3 rounded-xl transition flex items-center justify-center gap-2 ${
              activeTab === 'apk'
                ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/20'
                : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
            }`}
          >
            <Smartphone className="w-4 h-4" />
            ملف Android APK
          </button>
          <button
            onClick={() => setActiveTab('pwa')}
            className={`flex-1 py-2.5 px-3 rounded-xl transition flex items-center justify-center gap-2 ${
              activeTab === 'pwa'
                ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/20'
                : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
            }`}
          >
            <Download className="w-4 h-4" />
            تثبيت فوري (PWA أيقونة)
          </button>
          <button
            onClick={() => setActiveTab('ios')}
            className={`flex-1 py-2.5 px-3 rounded-xl transition flex items-center justify-center gap-2 ${
              activeTab === 'ios'
                ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/20'
                : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
            }`}
          >
            <Laptop className="w-4 h-4" />
            أجهزة آبل (iOS iPhone)
          </button>
        </div>

        {/* Tab Contents */}
        <div className="p-6 overflow-y-auto space-y-6 text-sm">
          {activeTab === 'apk' && (
            <div className="space-y-4">
              <div className="bg-gradient-to-br from-blue-950/40 to-slate-900 border border-blue-900/40 p-4 rounded-2xl">
                <span className="text-xs font-bold text-blue-400 block mb-1">كيف يشغل المندوب ملف الـ APK على هاتفه؟</span>
                <p className="text-xs text-slate-300 leading-relaxed">
                  يتم إرسال رابط التحميل للمندوب عبر الواتساب أو تيليجرام. عند الضغط والتحميل، يفتح الهاتف شاشة التثبيت فوراً.
                </p>
              </div>

              {/* 3 Steps */}
              <div className="space-y-3">
                <div className="flex items-start gap-3 bg-slate-800/40 border border-slate-700/60 p-3.5 rounded-2xl">
                  <div className="w-7 h-7 rounded-xl bg-blue-600 text-white font-bold flex items-center justify-center text-xs shrink-0">
                    1
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-white mb-0.5">تحميل ملف APK</h4>
                    <p className="text-[11px] text-slate-300">
                      يضغط المندوب على رابط التنزيل. سيظهر إشعار «قد يكون هذا الملف ضاراً»، يضغط «تنزيل على أي حال» (لأنه تطبيق خاص بالمؤسسة).
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3 bg-slate-800/40 border border-slate-700/60 p-3.5 rounded-2xl">
                  <div className="w-7 h-7 rounded-xl bg-blue-600 text-white font-bold flex items-center justify-center text-xs shrink-0">
                    2
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-white mb-0.5">السماح بتثبيت التطبيقات غير المعروفة</h4>
                    <p className="text-[11px] text-slate-300">
                      إذا طلب الهاتف إذناً، يضغط «الإعدادات» ثم يفعل خيار «السماح بتثبيت التطبيقات من هذا المصدر».
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-3 bg-slate-800/40 border border-slate-700/60 p-3.5 rounded-2xl">
                  <div className="w-7 h-7 rounded-xl bg-blue-600 text-white font-bold flex items-center justify-center text-xs shrink-0">
                    3
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-white mb-0.5">الفتح وبدء تسجيل المبيعات</h4>
                    <p className="text-[11px] text-slate-300">
                      تظهر أيقونة «مجموعة الطنطاوي» على شاشة هاتفه، يفتح التطبيق مباشرة ويدخل باسم مستخدم المندوب لإنشاء الفواتير ومراجعة العملاء.
                    </p>
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="pt-2 flex flex-col sm:flex-row gap-3">
                <button
                  onClick={handleShareWhatsApp}
                  className="flex-1 py-3 px-4 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs flex items-center justify-center gap-2 shadow-lg shadow-emerald-600/20 transition"
                >
                  <Share2 className="w-4 h-4" />
                  إرسال الرابط لمناديب المبيعات (WhatsApp)
                </button>
                <button
                  onClick={handleCopyLink}
                  className="py-3 px-4 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-xs flex items-center justify-center gap-2 border border-slate-700 transition"
                >
                  {copied ? <Check className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
                  {copied ? 'تم نسخ الرابط!' : 'نسخ رابط التنزيل'}
                </button>
              </div>
            </div>
          )}

          {activeTab === 'pwa' && (
            <div className="space-y-4">
              <div className="bg-gradient-to-br from-indigo-950/40 to-slate-900 border border-indigo-900/40 p-4 rounded-2xl">
                <span className="text-xs font-bold text-indigo-400 block mb-1">
                  تثبيت أيقونة التطبيق المستقلة (بدون شريط المتصفح)
                </span>
                <p className="text-xs text-slate-300 leading-relaxed">
                  ميزة PWA الرائعة تسمح بتحويل التطبيق إلى برنامج موبايل كامل يفتح بملء الشاشة وبدون شريط عنوان المتصفح على أي موبايل أو كمبيوتر!
                </p>
              </div>

              <div className="p-4 bg-slate-800/50 border border-slate-700 rounded-2xl space-y-3 text-xs text-slate-300">
                <div className="flex items-center gap-2 text-white font-bold">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                  طريقة التثبيت التلقائي بنقرة واحدة:
                </div>
                <p>
                  من متصفح Chrome على هاتف المندوب، اضغط على القائمة (الثلاث نقاط في الأعلى) ثم اختر:
                </p>
                <div className="bg-slate-900 p-2.5 rounded-xl border border-slate-700 font-bold text-blue-400 text-center">
                  «تثبيت التطبيق» أو «الإضافة إلى الشاشة الرئيسية»
                </div>
                <p className="text-[11px] text-slate-400">
                  سيتم إنشاء أيقونة التطبيق فوراً. عندما يضغط المندوب عليها ستفتح نافذة التطبيق المستقلة تماماً مثل تطبيقات Play Store.
                </p>
              </div>

              {/* Instant Install Button */}
              <div className="pt-2">
                <PWAInstallButton className="w-full py-3 px-4 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs flex items-center justify-center gap-2 shadow-lg shadow-blue-600/30 transition cursor-pointer" />
              </div>
            </div>
          )}

          {activeTab === 'ios' && (
            <div className="space-y-4 text-xs text-slate-300">
              <div className="bg-gradient-to-br from-slate-900 to-slate-850 border border-slate-700 p-4 rounded-2xl">
                <span className="text-xs font-bold text-white block mb-1">تثبيت التطبيق على هواتف iPhone / iPad:</span>
                <p className="text-[11px] text-slate-300 leading-relaxed">
                  أجهزة آبل تدعم تثبيت تطبيقات الويب المتقدمة بدون الحاجة إلى متجر App Store.
                </p>
              </div>

              <div className="space-y-2.5">
                <div className="p-3 bg-slate-800/40 rounded-xl border border-slate-700 flex items-start gap-2.5">
                  <span className="font-bold text-blue-400">1.</span>
                  <span>افتح الرابط في متصفح <strong>Safari</strong> على الآيفون.</span>
                </div>
                <div className="p-3 bg-slate-800/40 rounded-xl border border-slate-700 flex items-start gap-2.5">
                  <span className="font-bold text-blue-400">2.</span>
                  <span>اضغط على زر المشاركة <strong>(Share / السهم لأعلى)</strong> في أسفل شاشة سفاري.</span>
                </div>
                <div className="p-3 bg-slate-800/40 rounded-xl border border-slate-700 flex items-start gap-2.5">
                  <span className="font-bold text-blue-400">3.</span>
                  <span>انزل لأسفل واختر <strong>«إضافة إلى الصفحة الرئيسية» (Add to Home Screen)</strong>.</span>
                </div>
                <div className="p-3 bg-slate-800/40 rounded-xl border border-slate-700 flex items-start gap-2.5">
                  <span className="font-bold text-blue-400">4.</span>
                  <span>اضغط «إضافة» (Add). ستجد أيقونة التطبيق على شاشة التطبيقات جاهزة للعمل.</span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-slate-800 bg-slate-950/80 flex items-center justify-between text-xs text-slate-400">
          <div className="flex items-center gap-1.5">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>نظام مشفر ومربوط بقاعدة بيانات Supabase الآمنة</span>
          </div>
          <button
            onClick={onClose}
            className="px-5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold transition"
          >
            إغلاق
          </button>
        </div>
      </div>
    </div>
  );
};
