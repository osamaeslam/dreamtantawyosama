# تطبيق مجموعة الطنطاوي للتجارة والتوزيع (Flutter & Dart Multiplatform)

تطبيق متعدد المنصات مبني بتقنيات **Flutter & Dart** يعمل بكود برمجي واحد على:
1. **الويب (Web)**
2. **أندرويد (Android)**
3. **آيفون (iOS)**

مرتبط مباشرة وبنفس الجداول مع قاعدة بيانات **Supabase** وبنفس صلاحيات وسجلات المنظومة السابقة بدون أي تغيير في البيانات.

---

## المكونات الأساسية المتوفرة بالكود:
- `lib/main.dart`: نقطة الانطلاق مع دعم اتجاه اليمين لليسار (RTL) وخطوط القاهرة (Cairo Font).
- `lib/theme/app_theme.dart`: ألوان وهوية مجموعة الطنطاوي الذهبية والداكنة (`#F59E0B` و `#0F172A`).
- `lib/models/models.dart`: نماذج المنتجات، العملاء، السلة، الفواتير الإلكترونية، والزيارات الميدانية.
- `lib/services/supabase_service.dart`: دوال القراءة والكتابة اللحظية (Realtime Streams) مع Supabase.
- `lib/services/cart_service.dart`: إدارة سلة المندوب ومنع الحجز المزدوج وحساب الخصومات.
- `lib/services/pdf_invoice_service.dart`: توليد وطباعة فواتير حرارية عبر طابعات البلوتوث وتصدير PDF A4.
- `lib/screens/login_screen.dart`: شاشة الدخول الموحدة بحسب الصلاحيات.
- `lib/screens/catalog_screen.dart`: كتالوج المنتجات مع فلاتر الأقسام والبحث ورصيد الفرع ورصيد أكتوبر.
- `lib/screens/order_builder_screen.dart`: حجز الطلبيات وفحص الحد الائتماني للعميل واختيار طريقة الدفع.
- `lib/screens/rep_dashboard_screen.dart`: لوحة المندوب الميدانية اليومية.
- `lib/screens/invoices_screen.dart`: إدارة الفواتير والطباعة الفورية.
- `lib/screens/visits_screen.dart`: خط السير وتسجيل التحصيلات مع إحداثيات GPS.

---

## أوامر التشغيل والبناء:

### 1. تثبيت الحزم:
```bash
flutter pub get
```

### 2. التشغيل على الويب (Web):
```bash
flutter run -d chrome
```

### 3. التشغيل على هاتف أندرويد (Android):
```bash
flutter run -d android
```

### 4. بناء ملف التثبيت النهائي للأندرويد (Release APK):
```bash
flutter build apk --release
```
الملف الناتج ستجده في المسار:
`build/app/outputs/flutter-apk/app-release.apk`

### 5. بناء نسخة الويب للنشر السحابي (Web Production):
```bash
flutter build web --release
```
الملفات الناتجة في مجلد `build/web/` يمكنك رفعها لأي استضافة سحابية.
