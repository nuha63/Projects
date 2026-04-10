import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Opens a Hive box and recovers from corruption by deleting and recreating the box.
/// Use this for boxes that may have been corrupted or contain invalid data.
Future<Box> openBoxSafe(String name) async {
  try {
    return await Hive.openBox(name);
  } catch (e, st) {
    debugPrint('Failed to open Hive box "$name": $e\n$st');
    try {
      debugPrint('Deleting corrupted box "$name" from disk and recreating...');
      await Hive.deleteBoxFromDisk(name);
    } catch (delErr, delSt) {
      debugPrint('Failed to delete Hive box "$name": $delErr\n$delSt');
    }
    // Try to reopen (this will create a fresh box)
    return await Hive.openBox(name);
  }
}
