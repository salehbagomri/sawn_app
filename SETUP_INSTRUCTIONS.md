# 🔧 تعليمات التهيئة - للعمل مع Claude في Cursor

## معلومات المشروع
- **الاسم:** صَوْن (Sawn)
- **المطور:** صالح
- **اللغة المفضلة:** العربية للتواصل، الإنجليزية للكود

---

## الملفات المرجعية (اقرأها أولاً)
1. `CLAUDE_CONTEXT_COMPLETE.md` - السياق الكامل للمشروع
2. `DESIGN_GUIDE.md` - دليل التصميم النظيف
3. `.cursorrules` - قواعد سريعة

---

## المتطلبات الجاهزة من المستخدم

### 1. Google Cloud Console
- [ ] مشروع جديد تم إنشاؤه
- [ ] Google Drive API مفعّل
- [ ] OAuth Consent Screen مُعد
- [ ] OAuth Client ID لـ Android (يحتاج SHA-1)
- [ ] OAuth Client ID لـ iOS (اختياري الآن)

### 2. Supabase
- [ ] مشروع جديد تم إنشاؤه
- [ ] Project URL جاهز
- [ ] Anon Key جاهز

### 3. GitHub
- [ ] Repository خاص تم إنشاؤه

---

## خطوات التهيئة المطلوبة (بالترتيب)

### الخطوة 1: التحقق من البيئة
```bash
flutter doctor
flutter --version
```
تأكد أن Flutter يعمل بدون مشاكل.

### الخطوة 2: الحصول على SHA-1
```bash
cd android
./gradlew signingReport
```
ابحث عن SHA1 تحت Variant: debug
المستخدم يحتاج ينسخه ويضعه في Google Cloud Console.

### الخطوة 3: إنشاء ملف .gitignore
تأكد من وجوده ويحتوي:
```
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
.idea/
.vscode/
*.iml
.env
**/google-services.json
**/GoogleService-Info.plist
lib/core/constants/secrets.dart
```

### الخطوة 4: إنشاء ملف secrets.dart
المسار: `lib/core/constants/secrets.dart`
```dart
/// ⚠️ هذا الملف لا يُرفع لـ GitHub
class Secrets {
  Secrets._();
  
  // Supabase
  static const String supabaseUrl = 'URL_HERE';
  static const String supabaseAnonKey = 'KEY_HERE';
  
  // Google OAuth (Android)
  static const String googleClientIdAndroid = 'CLIENT_ID_HERE';
  
  // Google OAuth (iOS) - اختياري
  static const String googleClientIdIos = '';
}
```

### الخطوة 5: تحديث pubspec.yaml
تأكد من وجود الحزم المطلوبة:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Google Sign-In
  google_sign_in: ^6.2.1
  
  # Google APIs (Drive)
  googleapis: ^12.0.0
  googleapis_auth: ^1.6.0
  extension_google_sign_in_as_googleapis_auth: ^2.0.12
  
  # Supabase
  supabase_flutter: ^2.3.0
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # Navigation
  go_router: ^13.0.0
  
  # Security
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.1.8
  
  # OCR
  google_mlkit_text_recognition: ^0.11.0
  
  # Image
  image_picker: ^1.0.7
  
  # Local Storage
  hive_flutter: ^1.1.0
  
  # UI
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_svg: ^2.0.9
```

### الخطوة 6: إعداد Android
ملف `android/app/build.gradle`:
- minSdkVersion: 21
- compileSdkVersion: 34
- تفعيل multidex إذا لزم

### الخطوة 7: إنشاء جداول Supabase
اذهب لـ Supabase → SQL Editor وشغّل:
```sql
-- جدول المستخدمين
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  google_id TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  name TEXT,
  avatar_url TEXT,
  drive_folder_id TEXT,
  pin_enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول التصنيفات
CREATE TABLE categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  icon TEXT,
  drive_folder_id TEXT,
  is_default BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول المستندات
CREATE TABLE documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  document_type TEXT,
  document_number TEXT,
  issue_date DATE,
  expiry_date DATE,
  notes TEXT,
  is_favorite BOOLEAN DEFAULT false,
  is_offline BOOLEAN DEFAULT false,
  drive_file_id TEXT,
  drive_file_url TEXT,
  thumbnail_url TEXT,
  extracted_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول التذكيرات
CREATE TABLE reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  remind_date DATE NOT NULL,
  days_before INTEGER NOT NULL,
  is_sent BOOLEAN DEFAULT false,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول أسباب الحذف
CREATE TABLE deletion_reasons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reason TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- تفعيل RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- سياسات RLS (بسيطة للبداية - ستُحدث لاحقاً)
CREATE POLICY "Enable all for authenticated users" ON users FOR ALL USING (true);
CREATE POLICY "Enable all for authenticated users" ON categories FOR ALL USING (true);
CREATE POLICY "Enable all for authenticated users" ON documents FOR ALL USING (true);
CREATE POLICY "Enable all for authenticated users" ON reminders FOR ALL USING (true);
```

### الخطوة 8: التحقق النهائي
```bash
flutter pub get
flutter run
```

---

## بعد التهيئة - خطة العمل

### الأولوية 1: المصادقة
1. تحديث شاشة تسجيل الدخول (Google Sign-In)
2. إنشاء AuthService
3. إنشاء GoogleDriveService
4. إنشاء مجلد صَوْن في Drive

### الأولوية 2: الشاشات الأساسية
1. تحديث الشاشة الرئيسية (التصميم النظيف)
2. شاشة إضافة مستند
3. شاشة تفاصيل المستند
4. شاشة قائمة المستندات

### الأولوية 3: المميزات
1. OCR
2. التذكيرات
3. البحث والفلترة
4. المفضلة
5. Offline mode

---

## ملاحظات مهمة

- **اللغة:** العربية للتواصل، الإنجليزية للكود والتعليقات
- **التصميم:** Clean Design (راجع DESIGN_GUIDE.md)
- **PIN:** اختياري
- **التخزين:** غير محدود (Drive + Local)
- **الإصدار الأول:** مجاني بالكامل
