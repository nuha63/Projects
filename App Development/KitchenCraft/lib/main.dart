// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/signup_page.dart';
import 'features/home/presentation/home_page.dart';
import 'features/home/presentation/family_page.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
// (firebase_auth import removed - not needed in main.dart)

late io.Socket socket;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  debugPrint('Gemini Key: ${dotenv.env['GEMINI_API_KEY']}');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  } catch (e) {
    debugPrint('Firebase App Check activation skipped or failed in dev: $e');
  }
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  await Hive.initFlutter();
  await Hive.openBox('chatHistoryBox');
  await Hive.openBox('kitchenCraftBox');
  final backendUrl = dotenv.env['BACKEND_URL'] ?? '';
  if (backendUrl.isEmpty) {
    debugPrint('Warning: BACKEND_URL not set in .env; socket connection will be skipped.');
  } else {
    socket = io.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
    });
    socket.onConnect((_) => debugPrint('WebSocket connected'));
    socket.onDisconnect((_) => debugPrint('WebSocket disconnected'));
  }

  // (seed helper removed from main - seeding depends on authenticated user and should be invoked elsewhere)

  runApp(const MyApp());
}

// Developer helper: seed sample recipes & groceries for a specific authenticated user.
// This helper requires an explicit authenticated `userId` to avoid calling
// FirebaseAuth at app bootstrap. Call it from a developer-only UI or a script.
//
// Developer seeding helper (public so dev UI/pages can call it)
Future<void> seedSampleData({required String userId, bool forceRun = false}) async {
  if (userId.isEmpty) {
    debugPrint('Error: Cannot seed data, no authenticated user ID provided.');
    return;
  }

  final timestamp = Timestamp.now();
  debugPrint('Starting seeding for userId: $userId');

  // Recipes
  final recipeSnapshot = await FirebaseFirestore.instance.collection('recipes').where('userId', isEqualTo: userId).get();
  debugPrint('Current recipes count for $userId: ${recipeSnapshot.docs.length}');
  if (forceRun || recipeSnapshot.docs.isEmpty) {
    debugPrint('Seeding recipes for $userId...');
    final recipes = [
      {
        'userId': userId,
        'name': 'Lemon Garlic Chicken',
        'ingredients': ['4 chicken breasts', '2 lemons (juiced)', '4 garlic cloves (minced)'],
        'instructions': 'Marinate chicken in lemon-garlic mix for 30 min. Bake at 375°F for 25 min.',
        'category': 'Dinner',
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'name': 'Creamy Shrimp Alfredo',
        'ingredients': ['1 lb shrimp', '8 oz fettuccine pasta', '1 cup heavy cream', '1/2 cup Parmesan cheese', '2 garlic cloves'],
        'instructions': 'Cook pasta. Sauté shrimp and garlic. Add cream and cheese; toss with pasta.',
        'category': 'Dinner',
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'name': 'Baked Parmesan Pasta',
        'ingredients': ['8 oz pasta', '1 cup marinara sauce', '1/2 cup Parmesan cheese', '1 cup mozzarella'],
        'instructions': 'Cook pasta. Mix with sauce and cheeses. Bake at 350°F for 20 min.',
        'category': 'Lunch',
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'name': 'Tuna Melt',
        'ingredients': ['1 can tuna (drained)', '4 slices bread', '4 slices cheese'],
        'instructions': 'Mix tuna with mayo. Top bread with tuna and cheese; broil 2-3 min.',
        'category': 'Lunch',
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'name': 'Simple Stir-Fry Veggies',
        'ingredients': ['2 cups mixed veggies (broccoli, carrots)', '1 tbsp soy sauce', '1 garlic clove', '1 tbsp oil', 'cooked rice'],
        'instructions': 'Sauté garlic and veggies in oil. Add soy sauce; serve over rice.',
        'category': 'Dinner',
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'name': 'Easy Pasta Primavera',
        'ingredients': ['8 oz pasta', '1 cup cherry tomatoes', '1 zucchini', '1 garlic clove', '2 tbsp olive oil', 'Parmesan (optional)'],
        'instructions': 'Cook pasta. Sauté veggies and garlic in oil; toss with pasta and tomatoes.',
        'category': 'Dinner',
        'timestamp': timestamp,
      },
    ];

    for (final recipe in recipes) {
      await FirebaseFirestore.instance.collection('recipes').add(recipe);
    }
    debugPrint('Seeded ${recipes.length} recipes for user $userId');
  }

  // Groceries
  final grocerySnapshot = await FirebaseFirestore.instance.collection('grocery').where('userId', isEqualTo: userId).get();
  debugPrint('Current groceries count for $userId: ${grocerySnapshot.docs.length}');
  if (forceRun || grocerySnapshot.docs.isEmpty) {
    debugPrint('Seeding groceries for $userId...');
    final groceries = [
      {
        'userId': userId,
        'item': 'Chicken Breasts',
        'isPurchased': false,
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'item': 'Rice',
        'isPurchased': true,
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'item': 'Tomatoes',
        'isPurchased': false,
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'item': 'Garlic Cloves',
        'isPurchased': false,
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'item': 'Pasta',
        'isPurchased': true,
        'timestamp': timestamp,
      },
      {
        'userId': userId,
        'item': 'Olive Oil',
        'isPurchased': false,
        'timestamp': timestamp,
      },
    ];

    for (final grocery in groceries) {
      await FirebaseFirestore.instance.collection('grocery').add(grocery);
    }
    debugPrint('Seeded ${groceries.length} groceries for user $userId');
  }

  debugPrint('Sample data seeding completed for $userId!');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KitchenCraft',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/family': (context) => const FamilyPage(),
      },
    );
  }
}