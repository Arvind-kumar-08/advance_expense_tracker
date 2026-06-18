import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // REPLACE THESE VALUES WITH YOUR OWN FROM google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCmopa3nYv2Gs9y15DJLfIEzGKcsxLR3VI',              // ← From google-services.json
    appId:  "1:225843432203:android:e220f12c42ff51161e700e",                // ← From google-services.json
    messagingSenderId: '225843432203', // ← From google-services.json
    projectId: 'expense-tracker-c2fdf',        // ← From google-services.json
    storageBucket: "expense-tracker-c2fdf.firebasestorage.app", // ← From google-services.json
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCmopa3nYv2Gs9y15DJLfIEzGKcsxLR3VI',              // ← From google-services.json
    appId:  "1:225843432203:android:e220f12c42ff51161e700e",                // ← From google-services.json
    messagingSenderId: '225843432203', // ← From google-services.json
    projectId: 'expense-tracker-c2fdf',        // ← From google-services.json
    storageBucket: "expense-tracker-c2fdf.firebasestorage.app",
    iosBundleId: 'com.example.advanceExpanseTrackerApp',
  );
}