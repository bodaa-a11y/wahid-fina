// ⚠️ هذا ملف Placeholder — ستحتاج لاستبداله بالملف الحقيقي من Firebase Console
// 
// خطوات إعداد Firebase:
// 1. اذهب إلى https://console.firebase.google.com/
// 2. أنشئ مشروع جديد باسم "wahid-fina"
// 3. أضف تطبيق Android (com.wahidfina.wahid_fina)
// 4. حمّل google-services.json وضعه في android/app/
// 5. شغّل: dart pub global activate flutterfire_cli
// 6. شغّل: flutterfire configure
// 7. سيتم إنشاء هذا الملف تلقائياً بإعداداتك الحقيقية
//
// أو استبدل القيم التالية بقيمك الحقيقية من Firebase Console:

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions is not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2gHK-kawLdRw3ZCuZXpcmRDy3Pzxkgzc',
    appId: '1:288117831489:android:8352fc202ea2c3ee6393c0',
    messagingSenderId: '288117831489',
    projectId: 'supporter-app-894fd',
    storageBucket: 'supporter-app-894fd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY_IOS', defaultValue: 'YOUR_IOS_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_IOS', defaultValue: '1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: 'YOUR_PROJECT_NUMBER'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'YOUR_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET_IOS', defaultValue: 'YOUR_PROJECT_ID.appspot.com'),
    iosBundleId: 'com.wahidfina.wahidFina',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY_WEB', defaultValue: 'YOUR_WEB_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_WEB', defaultValue: '1:YOUR_PROJECT_NUMBER:web:YOUR_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: 'YOUR_PROJECT_NUMBER'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'YOUR_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET_WEB', defaultValue: 'YOUR_PROJECT_ID.appspot.com'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN_WEB', defaultValue: 'YOUR_PROJECT_ID.firebaseapp.com'),
  );
}
