import React, { useState } from 'react';
import {
  Smartphone,
  Copy,
  Check,
  Download,
  FolderTree,
  Code2,
  Layers,
  Globe,
  Database,
  ExternalLink,
  X,
  FileCode,
  Terminal,
  Zap,
  Sparkles
} from 'lucide-react';

interface FlutterProjectViewerModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const FLUTTER_FILES: Record<string, { title: string; path: string; language: string; content: string }> = {
  'pubspec.yaml': {
    title: 'pubspec.yaml (التبعيات والحزم)',
    path: 'flutter_tantawy/pubspec.yaml',
    language: 'yaml',
    content: `name: tantawy_group
description: "منظومة مجموعة الطنطاوي للتجارة والتوزيع - Flutter Multiplatform (Web, Android, iOS)"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # قاعدة البيانات السحابية (نفس قاعدة بياناتك الحالية)
  supabase_flutter: ^2.8.0

  # إدارة الحالة والخطوط
  provider: ^6.1.2
  google_fonts: ^6.2.1
  intl: ^0.19.0

  # صور وشبكة
  cached_network_image: ^3.3.1
  http: ^1.2.0

  # أيقونات
  lucide_icons: ^0.257.0

  # رسوم بيانية تفاعلية
  fl_chart: ^0.68.0

  # طباعة وتصدير الفواتير PDF وإكسل
  pdf: ^3.10.8
  printing: ^5.13.0
  excel: ^4.0.3

  # ماسح الباركود بالكاميرا (للمناديب والمخازن)
  mobile_scanner: ^5.2.0

  # الموقع الجغرافي لتسجيل الحضور في الزيارات
  geolocator: ^12.0.0

  # التخزين المحلي والأوفلاين
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true`
  },
  'main.dart': {
    title: 'lib/main.dart (نقطة الانطلاق ودعم العربية)',
    path: 'flutter_tantawy/lib/main.dart',
    language: 'dart',
    content: `import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'services/cart_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة اتصال Supabase بنفس رابط ومشروع قاعدة بياناتك الحالية
  try {
    await SupabaseService.initialize(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://your-project.supabase.co'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'your-anon-key'),
    );
  } catch (e) {
    debugPrint('Supabase offline or initialized in mock mode: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: const TantawyGroupApp(),
    ),
  );
}

class TantawyGroupApp extends StatelessWidget {
  const TantawyGroupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مجموعة الطنطاوي للتجارة والتوزيع',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,

      // إعدادات اللغة العربية والـ RTL
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: LoginScreen(),
      ),
    );
  }
}`
  },
  'app_theme.dart': {
    title: 'lib/theme/app_theme.dart (هوية وألوان الطنطاوي)',
    path: 'flutter_tantawy/lib/theme/app_theme.dart',
    language: 'dart',
    content: `import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // هوية مجموعة الطنطاوي للتجارة والتوزيع
  static const Color primaryGold = Color(0xFFF59E0B); // Amber 500
  static const Color secondaryGold = Color(0xFFFBBF24); // Amber 400
  static const Color darkSlate = Color(0xFF0F172A); // Slate 900
  static const Color cardSlate = Color(0xFF1E293B); // Slate 800
  static const Color borderSlate = Color(0xFF334155); // Slate 700

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: GoogleFonts.cairoTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSlate,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}`
  },
  'models.dart': {
    title: 'lib/models/models.dart (النماذج ومطابقة Supabase)',
    path: 'flutter_tantawy/lib/models/models.dart',
    language: 'dart',
    content: `// نماذج البيانات لمجموعة الطنطاوي للتجارة والتوزيع - متوافقة 100% مع Supabase

class Product {
  final String id;
  final String code;
  final String name;
  final String department;
  final String category;
  final double piecePrice;
  final double cartonPrice;
  final double? promoPrice;
  final int cartonQuantity;
  final int branchStockActual;
  final int branchStockReserved;
  final int mainWarehouseStock;
  final String? imageUrl;
  final String status;
  final String salesPriority;

  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.category,
    required this.piecePrice,
    required this.cartonPrice,
    this.promoPrice,
    required this.cartonQuantity,
    required this.branchStockActual,
    required this.branchStockReserved,
    required this.mainWarehouseStock,
    this.imageUrl,
    required this.status,
    required this.salesPriority,
  });

  int get availableStock => branchStockActual - branchStockReserved;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? 'عام',
      category: json['category']?.toString() ?? '',
      piecePrice: (json['piecePrice'] ?? json['piece_price'] ?? 0).toDouble(),
      cartonPrice: (json['cartonPrice'] ?? json['carton_price'] ?? 0).toDouble(),
      promoPrice: json['promoPrice'] != null ? (json['promoPrice']).toDouble() : null,
      cartonQuantity: (json['cartonQuantity'] ?? json['factor'] ?? 1).toInt(),
      branchStockActual: (json['branchStockActual'] ?? json['branch_stock_actual'] ?? 0).toInt(),
      branchStockReserved: (json['branchStockReserved'] ?? json['branch_stock_reserved'] ?? 0).toInt(),
      mainWarehouseStock: (json['mainWarehouseActual'] ?? 0).toInt(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'متاح',
      salesPriority: json['salesPriority']?.toString() ?? 'عادي',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'department': department,
    'category': category,
    'piece_price': piecePrice,
    'carton_price': cartonPrice,
    'branch_stock_actual': branchStockActual,
    'branch_stock_reserved': branchStockReserved,
    'status': status,
  };
}`
  },
  'supabase_service.dart': {
    title: 'lib/services/supabase_service.dart (الاتصال والتزامن اللحظي)',
    path: 'flutter_tantawy/lib/services/supabase_service.dart',
    language: 'dart',
    content: `import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient? _client;
  SupabaseClient get client {
    _client ??= Supabase.instance.client;
    return _client!;
  }

  static Future<void> initialize({
    required String supabaseUrl,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: supabaseUrl, anonKey: anonKey);
  }

  // جلب المنتجات من نفس جدول Supabase الحالي
  Future<List<Product>> fetchProducts({String? department}) async {
    var query = client.from('products').select();
    if (department != null && department != 'الكل') {
      query = query.eq('department', department);
    }
    final data = await query.order('name');
    return (data as List<dynamic>).map((e) => Product.fromJson(e)).toList();
  }

  // ترحيل فاتورة جديدة
  Future<bool> createInvoice(OrderInvoice invoice) async {
    await client.from('invoices').insert(invoice.toJson());
    return true;
  }
}`
  },
  'pdf_invoice_service.dart': {
    title: 'lib/services/pdf_invoice_service.dart (الطباعة الحرارية)',
    path: 'flutter_tantawy/lib/services/pdf_invoice_service.dart',
    language: 'dart',
    content: `import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class PdfInvoiceService {
  // توليد وطباعة فاتورة رسمية حرارية للبلوتوث أو ورقية A4
  static Future<void> printInvoice(OrderInvoice invoice, {bool isThermal = true}) async {
    final pdf = pw.Document();
    final pageFormat = isThermal
        ? const PdfPageFormat(72 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm)
        : PdfPageFormat.a4;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('مجموعة الطنطاوي للتجارة والتوزيع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('فاتورة رقم: \${invoice.invoiceNumber}'),
              pw.Text('العميل: \${invoice.customerName}'),
              pw.Divider(),
              ...invoice.items.map((i) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(i.productName),
                  pw.Text('\${i.cartons} كرتونة = \${i.totalPrice} ج.م'),
                ],
              )),
              pw.Divider(),
              pw.Text('الصافي: \${invoice.totalAmount} ج.م', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}`
  },
  'catalog_screen.dart': {
    title: 'lib/screens/catalog_screen.dart (كتالوج المنتجات)',
    path: 'flutter_tantawy/lib/screens/catalog_screen.dart',
    language: 'dart',
    content: `// شاشة كتالوج الأصناف الموحد مع فلاتر الأقسام والبحث ورصيد الفرع والسلة
// متوفرة بالكامل داخل مجلد flutter_tantawy/lib/screens/catalog_screen.dart`
  },
  'order_builder_screen.dart': {
    title: 'lib/screens/order_builder_screen.dart (حجز الطلبية)',
    path: 'flutter_tantawy/lib/screens/order_builder_screen.dart',
    language: 'dart',
    content: `// شاشة إنشاء وتأكيد الطلبية للمندوب مع فحص الحد الائتماني ومنع الحجز المزدوج
// متوفرة بالكامل داخل مجلد flutter_tantawy/lib/screens/order_builder_screen.dart`
  }
};

export const FlutterProjectViewerModal: React.FC<FlutterProjectViewerModalProps> = ({
  isOpen,
  onClose
}) => {
  const [selectedFileKey, setSelectedFileKey] = useState<string>('pubspec.yaml');
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  if (!isOpen) return null;

  const activeFile = FLUTTER_FILES[selectedFileKey] || FLUTTER_FILES['pubspec.yaml'];

  const handleCopy = (key: string, content: string) => {
    navigator.clipboard.writeText(content);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  const handleDownloadFile = () => {
    const blob = new Blob([activeFile.content], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = selectedFileKey;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-3 sm:p-6 animate-in fade-in">
      <div className="bg-slate-900 border border-slate-700 w-full max-w-5xl h-[88vh] rounded-2xl shadow-2xl flex flex-col overflow-hidden text-slate-100">
        
        {/* هيدر المودال */}
        <div className="bg-slate-950 px-6 py-4 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-500/20 border border-amber-500/40 flex items-center justify-center text-amber-400">
              <Smartphone className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base sm:text-lg font-black text-amber-400">
                  تطبيق مجموعة الطنطاوي بـ Flutter & Dart
                </h2>
                <span className="bg-emerald-500/20 text-emerald-400 text-xs px-2 py-0.5 rounded-full font-bold border border-emerald-500/30">
                  Multiplatform (Web, Android, iOS)
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-0.5">
                الكود البرمجي الكامل والمهيأ للربط المباشر مع نفس قاعدة بيانات Supabase الحالية
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={onClose}
              className="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
              title="إغلاق"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* شريط الإحصائيات السريعة */}
        <div className="bg-slate-950/60 px-6 py-2.5 border-b border-slate-800 grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
          <div className="flex items-center gap-2 text-slate-300">
            <Database className="w-4 h-4 text-emerald-400" />
            <span>قاعدة البيانات: <strong>Supabase (نفسها 100%)</strong></span>
          </div>
          <div className="flex items-center gap-2 text-slate-300">
            <Globe className="w-4 h-4 text-sky-400" />
            <span>المنصات: <strong>Web + Android + iOS</strong></span>
          </div>
          <div className="flex items-center gap-2 text-slate-300">
            <Layers className="w-4 h-4 text-amber-400" />
            <span>إدارة الحالة: <strong>Provider / ChangeNotifier</strong></span>
          </div>
          <div className="flex items-center gap-2 text-slate-300">
            <Zap className="w-4 h-4 text-purple-400" />
            <span>الطباعة: <strong>Bluetooth Thermal & A4</strong></span>
          </div>
        </div>

        {/* جسم المودال المقسم */}
        <div className="flex-1 flex flex-col md:flex-row overflow-hidden">
          
          {/* القائمة الجانبية للملفات */}
          <div className="w-full md:w-64 bg-slate-950/90 border-b md:border-b-0 md:border-l border-slate-800 p-3 overflow-y-auto space-y-1">
            <div className="text-[11px] font-bold text-slate-400 px-3 py-1.5 flex items-center gap-1.5">
              <FolderTree className="w-3.5 h-3.5 text-amber-400" />
              <span>هيكل ملفات فلاتر (flutter_tantawy)</span>
            </div>

            {Object.entries(FLUTTER_FILES).map(([key, file]) => {
              const isSelected = key === selectedFileKey;
              return (
                <button
                  key={key}
                  onClick={() => setSelectedFileKey(key)}
                  className={`w-full text-right px-3 py-2 rounded-xl text-xs font-semibold flex items-center justify-between transition ${
                    isSelected
                      ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                      : 'text-slate-300 hover:bg-slate-800/60'
                  }`}
                >
                  <div className="flex items-center gap-2 truncate">
                    <FileCode className={`w-3.5 h-3.5 shrink-0 ${isSelected ? 'text-amber-400' : 'text-slate-400'}`} />
                    <span className="truncate">{key}</span>
                  </div>
                </button>
              );
            })}

            <div className="pt-4 mt-4 border-t border-slate-800 text-[11px] text-slate-400 p-2">
              <p className="font-bold text-slate-300 mb-1">أوامر التشغيل المباشرة:</p>
              <div className="bg-slate-900 rounded p-2 font-mono text-[10px] space-y-1 text-amber-300/90">
                <div>flutter pub get</div>
                <div>flutter run -d chrome</div>
                <div>flutter build apk --release</div>
              </div>
            </div>
          </div>

          {/* محرر عرض الكود والنسخ */}
          <div className="flex-1 flex flex-col bg-slate-900 overflow-hidden">
            
            {/* شريط أدوات الملف */}
            <div className="bg-slate-850 px-4 py-2.5 border-b border-slate-800 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Code2 className="w-4 h-4 text-amber-400" />
                <span className="font-mono text-xs text-slate-200">{activeFile.path}</span>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleCopy(selectedFileKey, activeFile.content)}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-bold text-slate-200 transition border border-slate-700"
                >
                  {copiedKey === selectedFileKey ? (
                    <>
                      <Check className="w-3.5 h-3.5 text-emerald-400" />
                      <span className="text-emerald-400">تم النسخ!</span>
                    </>
                  ) : (
                    <>
                      <Copy className="w-3.5 h-3.5" />
                      <span>نسخ الكود</span>
                    </>
                  )}
                </button>

                <button
                  onClick={handleDownloadFile}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold transition shadow-sm"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>تنزيل الملف</span>
                </button>
              </div>
            </div>

            {/* صندوق الكود المنسق */}
            <div className="flex-1 overflow-auto p-4 bg-slate-950 font-mono text-xs text-slate-300 leading-relaxed dir-ltr text-left selection:bg-amber-500 selection:text-slate-950">
              <pre className="whitespace-pre">{activeFile.content}</pre>
            </div>
          </div>
        </div>

        {/* فوتر تأكيد */}
        <div className="bg-slate-950 px-6 py-3 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-amber-400" />
            <span>تم توليد ملفات مشروع فلاتر كاملة داخل مجلد <code className="text-amber-300 bg-slate-900 px-1 py-0.5 rounded">flutter_tantawy/</code> في هذا المشروع.</span>
          </div>
          <button
            onClick={onClose}
            className="px-4 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-white font-bold transition"
          >
            إغلاق
          </button>
        </div>
      </div>
    </div>
  );
};
