// lib/features/home/presentation/grocery_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:KitchenCraft/src/hive_utils.dart';
import 'package:KitchenCraft/main.dart' as globals;
import 'package:KitchenCraft/widgets/custom_scaffold.dart'; // Keep this import for socket usage
class GroceryPage extends StatefulWidget {
  const GroceryPage({super.key});
  @override
  State<GroceryPage> createState() => _GroceryPageState();
}
class _GroceryPageState extends State<GroceryPage> {
  final TextEditingController _itemCtrl = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  late Box _localBox;
  List<Map<String, dynamic>> _localItems = [];
  
  String get _userGroceryKey => 'groceryItems_${user?.uid ?? "guest"}';

  @override
  void initState() {
    super.initState();
    _initBoxAndListeners();
  }

  Future<void> _initBoxAndListeners() async {
    try {
      _localBox = await openBoxSafe('kitchenCraftBox');
    } catch (e) {
      debugPrint('Failed to open kitchenCraftBox: $e');
      // Fallback to direct Hive.box (may throw if not opened) - safer than referencing via globals
      _localBox = Hive.box('kitchenCraftBox');
    }

    _loadLocalItems();
    _syncFromFirestore(); // Load items from Firestore on startup
    _listenToFirestore(); // Set up real-time listener

    globals.socket.on('groceryUpdate', (data) {
      if (!mounted) return;
      try {
        final incoming = _normalizeList(data);
        setState(() {
          _localItems = incoming;
        });
        _localBox.put(_userGroceryKey, incoming);
      } catch (e) {
        debugPrint('groceryUpdate handler error: $e');
      }
    });
  }
  void _loadLocalItems() {
    try {
      final cached = _localBox.get(_userGroceryKey, defaultValue: []);
      final casted = _normalizeList(cached);
      if (mounted) setState(() => _localItems = casted);
    } catch (e) {
      debugPrint('Grocery load error: $e');
      if (mounted) setState(() => _localItems = []);
    }
  }

  Future<void> _syncFromFirestore() async {
    if (user == null) {
      debugPrint('No user logged in, skipping Firestore sync');
      return;
    }
    try {
      debugPrint('Syncing grocery items for user: ${user!.uid}');
      final snapshot = await FirebaseFirestore.instance
          .collection('grocery')
          .where('userId', isEqualTo: user!.uid)
          .get();

      debugPrint('Found ${snapshot.docs.length} grocery items in Firestore');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('No grocery items found in Firestore');
        return;
      }

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'];
        int timestampMillis;
        
        if (timestamp is Timestamp) {
          timestampMillis = timestamp.millisecondsSinceEpoch;
        } else if (timestamp is int) {
          timestampMillis = timestamp;
        } else if (timestamp is String) {
          timestampMillis = int.tryParse(timestamp) ?? DateTime.now().millisecondsSinceEpoch;
        } else {
          timestampMillis = DateTime.now().millisecondsSinceEpoch;
        }
        
        return {
          'id': doc.id,
          'userId': data['userId'] ?? user!.uid,
          'item': data['item'] ?? '',
          'isPurchased': data['isPurchased'] ?? false,
          'timestamp': timestampMillis,
        };
      }).toList();

      _localItems = items;
      _localBox.put(_userGroceryKey, items);
      if (mounted) setState(() {});
      
      debugPrint('Synced ${items.length} grocery items from Firestore');
    } catch (e) {
      debugPrint('Error syncing from Firestore: $e');
    }
  }

  void _listenToFirestore() {
    if (user == null) return;
    
    FirebaseFirestore.instance
        .collection('grocery')
        .where('userId', isEqualTo: user!.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      debugPrint('Firestore snapshot received: ${snapshot.docs.length} items');
      
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'];
        int timestampMillis;
        
        if (timestamp is Timestamp) {
          timestampMillis = timestamp.millisecondsSinceEpoch;
        } else if (timestamp is int) {
          timestampMillis = timestamp;
        } else if (timestamp is String) {
          timestampMillis = int.tryParse(timestamp) ?? DateTime.now().millisecondsSinceEpoch;
        } else {
          timestampMillis = DateTime.now().millisecondsSinceEpoch;
        }
        
        return {
          'id': doc.id,
          'userId': data['userId'] ?? user!.uid,
          'item': data['item'] ?? '',
          'isPurchased': data['isPurchased'] ?? false,
          'timestamp': timestampMillis,
        };
      }).toList();

      setState(() => _localItems = items);
      _localBox.put(_userGroceryKey, items);
    }, onError: (error) {
      debugPrint('Firestore listener error: $error');
    });
  }

  List<Map<String, dynamic>> _normalizeList(dynamic raw) {
    try {
      final list = List.from(raw ?? []);
      return list.map<Map<String, dynamic>>((item) {
        if (item is Map) {
          // Convert dynamic keys to strings and normalize timestamp
          final Map<String, dynamic> m = {};
          item.forEach((k, v) {
            final key = k?.toString() ?? '';
            dynamic val = v;
            if (key == 'timestamp' && v is int) {
              // keep as epoch millis
              val = v;
            } else if (key == 'timestamp' && v is String) {
              // try parse
              val = int.tryParse(v) ?? DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
            }
            m[key] = val;
          });
          return m;
        }
        return {'item': item?.toString() ?? '', 'isPurchased': false, 'timestamp': DateTime.now().millisecondsSinceEpoch};
      }).toList();
    } catch (e) {
      debugPrint('normalizeList error: $e');
      return [];
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null || timestamp == 0) return 'Just now';
      final int millis = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? 0;
      if (millis == 0) return 'Just now';
      final dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      debugPrint('Error formatting timestamp: $e');
      return 'Unknown time';
    }
  }

  Future<void> _addItem(String item) async {
    final trimmedItem = item.trim();
    if (trimmedItem.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill the box before pressing Add')),
        );
      }
      return;
    }

    // Check for duplicates (case-insensitive)
    final itemLower = trimmedItem.toLowerCase();
    final isDuplicate = _localItems.any((existingItem) {
      final existing = (existingItem['item'] as String).toLowerCase();
      return existing == itemLower;
    });

    if (isDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$trimmedItem" is already in your list'),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final newItem = {
      'userId': user?.uid,
      'item': trimmedItem,
      'isPurchased': false,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _localItems.insert(0, newItem);
    _itemCtrl.clear();
    try {
      _localBox.put(_userGroceryKey, _localItems);
    } catch (e) {
      debugPrint('Failed to write groceryItems to box: $e');
    }
    if (mounted) setState(() {});
    try {
      final docRef = await FirebaseFirestore.instance.collection('grocery').add(newItem);
      // Update local item with Firestore ID
      newItem['id'] = docRef.id;
      _localBox.put(_userGroceryKey, _localItems);
      globals.socket.emit('groceryUpdate', _localItems);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$trimmedItem"'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Offline add: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added offline - will sync when online'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    final item = _localItems[index];
    final itemName = item['item'] as String;
    final itemId = item['id'] as String?;
    // Remove from local list
    setState(() => _localItems.removeAt(index));
    
    try {
      _localBox.put(_userGroceryKey, _localItems);
    } catch (e) {
      debugPrint('Failed to persist after remove: $e');
    }

    // Delete from Firestore
    if (itemId != null) {
      try {
        await FirebaseFirestore.instance.collection('grocery').doc(itemId).delete();
        globals.socket.emit('groceryUpdate', _localItems);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "$itemName"'),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to delete from Firestore: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deleted locally - will sync when online'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      globals.socket.emit('groceryUpdate', _localItems);
    }
  }

  Future<void> _togglePurchased(int index, bool? value) async {
    final item = _localItems[index];
    final itemId = item['id'] as String?;

    // Update locally
    setState(() => item['isPurchased'] = value ?? false);
    
    try {
      _localBox.put(_userGroceryKey, _localItems);
    } catch (e) {
      debugPrint('Failed to persist after toggle: $e');
    }

    // Update Firestore
    if (itemId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('grocery')
            .doc(itemId)
            .update({'isPurchased': value ?? false});
        globals.socket.emit('groceryUpdate', _localItems);
        debugPrint('Updated isPurchased in Firestore for item: ${item['item']}');
      } catch (e) {
        debugPrint('Failed to update Firestore: $e');
      }
    } else {
      globals.socket.emit('groceryUpdate', _localItems);
    }
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              color: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemCtrl,
                        decoration: InputDecoration(
                          labelText: 'Add Grocery Item',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.shopping_basket, color: Colors.orange),
                        ),
                        onSubmitted: (value) => _addItem(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _addItem(_itemCtrl.text),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Hive.isBoxOpen('kitchenCraftBox')
                ? ValueListenableBuilder<Box>(
                    valueListenable: Hive.box('kitchenCraftBox').listenable(),
                    builder: (context, box, _) {
                      try {
                        final cached = box.get(_userGroceryKey, defaultValue: []);
                        _localItems = _normalizeList(cached);
                        // Sort alphabetically (A-Z)
                        _localItems.sort((a, b) {
                          final aItem = (a['item'] as String).toLowerCase();
                          final bItem = (b['item'] as String).toLowerCase();
                          return aItem.compareTo(bItem);
                        });
                      } catch (e) {
                        debugPrint('Grocery builder error: $e');
                        _localItems = [];
                      }  
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _localItems.length,
                        itemBuilder: (context, index) {
                          final item = _localItems[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            color: Colors.white.withOpacity(0.92),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(
                                Icons.shopping_cart,
                                color: (item['isPurchased'] as bool) ? Colors.green : Colors.orange[700],
                              ),
                              title: Text(
                                item['item'] as String,
                                style: TextStyle(
                                  decoration: (item['isPurchased'] as bool) ? TextDecoration.lineThrough : null,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                _formatTimestamp(item['timestamp']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: item['isPurchased'] as bool,
                                    activeColor: Colors.green,
                                    onChanged: (value) => _togglePurchased(index, value),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteItem(index),
                                    tooltip: 'Delete item',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}