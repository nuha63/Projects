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
        throw UnsupportedError(
          'No iOS configuration provided. Add an iOS app to your Firebase project',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDSsfnwXJhS5_qaosJuEbtwvB02_KcJbgY', // Using the Android API key as a placeholder
    appId: '1:99196641606:web:8f3e950dd7b9c3172d0547', // Using a placeholder app ID
    authDomain: 'kitchenkraft-963bd.firebaseapp.com',
    messagingSenderId: '99196641606',
    projectId: 'kitchenkraft-963bd',
    storageBucket: 'kitchenkraft-963bd.firebasestorage.app'
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSsfnwXJhS5_qaosJuEbtwvB02_KcJbgY',
    appId: '1:99196641606:android:9d639ca99df599942d0547',
    messagingSenderId: '99196641606',
    projectId: 'kitchenkraft-963bd',
    storageBucket: 'kitchenkraft-963bd.firebasestorage.app'
  );
}