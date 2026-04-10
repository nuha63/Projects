// This file provides mock implementations of Firebase Auth for web environment
// It allows the app to compile and run on web without requiring Firebase JS SDK

class User {
  final String uid;
  final String? email;
  final bool emailVerified;

  User({required this.uid, this.email, this.emailVerified = false});
}

class UserCredential {
  final User? user;
  
  UserCredential({this.user});
}

class FirebaseAuthException implements Exception {
  final String code;
  final String? message;
  
  FirebaseAuthException({required this.code, this.message});
}

class FirebaseAuth {
  static final FirebaseAuth _instance = FirebaseAuth._();
  
  // Singleton pattern
  static FirebaseAuth get instance => _instance;
  
  FirebaseAuth._();
  
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Perform basic validation
    if (!email.contains('@') || password.length < 6) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'The credential is invalid',
      );
    }
    
    // Create a mock user
    _currentUser = User(
      uid: 'web-mock-uid-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      emailVerified: true,
    );
    
    return UserCredential(user: _currentUser);
  }
  
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Perform basic validation
    if (!email.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'The email address is badly formatted.',
      );
    }
    
    if (password.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Password should be at least 6 characters',
      );
    }
    
    // Create a mock user
    _currentUser = User(
      uid: 'web-mock-uid-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      emailVerified: false,
    );
    
    return UserCredential(user: _currentUser);
  }
  
  Future<void> signOut() async {
    _currentUser = null;
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
  }
}