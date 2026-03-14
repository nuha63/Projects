// This file provides mock implementations of Firebase Core for web environment
// It allows the app to compile and run on web without requiring Firebase JS SDK

class FirebaseOptions {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? storageBucket;
  
  const FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.storageBucket,
  });
}

class FirebaseApp {
  final String name;
  final FirebaseOptions options;
  
  FirebaseApp({required this.name, required this.options});
}

class Firebase {
  static FirebaseApp? _app;
  
  static FirebaseApp? get app => _app;
  
  static Future<FirebaseApp> initializeApp({
    String name = '[DEFAULT]',
    required FirebaseOptions options,
  }) async {
    // Simulate initialization delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    _app = FirebaseApp(name: name, options: options);
    return _app!;
  }
}