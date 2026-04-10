// lib/offline_sync_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:KitchenCraft/main.dart' as globals; // use package import to access globals.socket

class OfflineSyncService {
  static Future<void> syncGrocery() async {
  // Ensure the box is open before accessing
  if (!Hive.isBoxOpen('kitchenCraftBox')) return;
  final box = Hive.box('kitchenCraftBox');
  final localItems = List<Map<String, dynamic>>.from(box.get('groceryItems', defaultValue: []));
    // Emit to WebSocket for sync
    globals.socket.emit('syncGrocery', localItems);
  debugPrint('Grocery synced from offline');
  }

  static Future<void> syncRecipes() async {
  if (!Hive.isBoxOpen('kitchenCraftBox')) return;
  final box = Hive.box('kitchenCraftBox');
  final localRecipes = List<Map<String, dynamic>>.from(box.get('recipes', defaultValue: []));
    globals.socket.emit('syncRecipes', localRecipes);
  debugPrint('Recipes synced from offline');
  }

  // Call this on app resume or reconnection
  static void performFullSync() {
    syncGrocery();
    syncRecipes();
    // Add more sync methods as needed
  }
}