import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('Firebase is not configured for iOS yet.');
      default:
        throw UnsupportedError(
            'Unsupported platform: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcETjuHcvmy7TKL7vHW6sYlUk9sxa-6CA',
    appId: '1:783428944628:android:937db7f519026f9a5bd4a1',
    messagingSenderId: '783428944628',
    projectId: 'shipeast-1a1f6',
    storageBucket: 'shipeast-1a1f6.firebasestorage.app',
  );
}
