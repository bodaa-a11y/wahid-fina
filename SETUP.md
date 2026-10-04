# 🫂 واحد فينا — دليل الإعداد والتشغيل

## خطوات إعداد Firebase (مطلوبة قبل التشغيل)

### 1. إنشاء مشروع Firebase
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اضغط "Add project" → اسم المشروع: `wahid-fina`
3. أوقف Google Analytics (اختياري)

### 2. تفعيل الخدمات المطلوبة
في Firebase Console:
- **Authentication** → Sign-in method → Anonymous → Enable
- **Firestore Database** → Create database → Start in test mode
- انسخ قواعد `firestore.rules` إلى Firestore Rules

### 3. إضافة تطبيق Android
1. في Firebase Console → Project Settings → Add app → Android
2. Package name: `com.wahidfina.wahid_fina`
3. حمّل `google-services.json`
4. ضعه في: `android/app/google-services.json`

### 4. إعداد FlutterFire CLI (الأسهل)
```bash
# تثبيت FlutterFire CLI
dart pub global activate flutterfire_cli

# إعداد Firebase تلقائياً (يُنشئ firebase_options.dart)
flutterfire configure --project=wahid-fina
```

### 5. مفتاح Claude API
في ملف `lib/core/services/claude_service.dart`:
```dart
static const String _apiKey = 'YOUR_CLAUDE_API_KEY_HERE';
// استبدل بمفتاحك من: https://console.anthropic.com/
```

---

## تشغيل التطبيق

```bash
cd wahid_fina
flutter pub get
flutter run
```

---

## هيكل المشروع

```
wahid_fina/
├── lib/
│   ├── core/
│   │   ├── theme/           # الألوان والثيم
│   │   ├── models/          # نماذج البيانات
│   │   ├── services/        # Firebase + Claude API
│   │   ├── providers/       # Riverpod State Management
│   │   ├── constants/       # الأسئلة
│   │   └── widgets/         # مكونات مشتركة
│   └── features/
│       ├── auth/            # شاشة التسجيل
│       ├── home/            # الشاشة الرئيسية
│       ├── matchmaking/     # البحث عن غرفة
│       ├── room_intro/      # مقدمة الغرفة
│       ├── game/            # اللعبة الرئيسية
│       └── results/         # النتائج
├── firestore.rules
└── pubspec.yaml
```

---

## منطق اللعبة

1. **التسجيل** → اسم + اختيار دور (عادي / بيمر بوقت صعب)
2. **Matchmaking** → البحث عن غرفة (5-6 أشخاص)، 1 struggling + الباقي عاديون
3. **مقدمة الغرفة** → عرض اللاعبين + تحذير "في الغرفة دي واحد فينا"
4. **10 أسئلة** → كل شخص يجيب، بعد كل سؤال تظهر إجابات الكل + تعليق AI
5. **النتائج** → كشف من هو "واحد فينا" + رسالة AI دافئة + "كسبت X أصدقاء جدد"

---

## Claude API Prompts المستخدمة

### تعليق بعد كل سؤال
- Model: `claude-sonnet-4-5`
- Max Tokens: 200
- Context: السؤال + إجابات الكل

### الرسالة النهائية
- Model: `claude-sonnet-4-5`
- Max Tokens: 800
- Context: ملخص اللعبة كاملاً + اسم "واحد فينا"

### Offline Fallback
- 10 تعليقات جاهزة لو مفيش إنترنت أو API
