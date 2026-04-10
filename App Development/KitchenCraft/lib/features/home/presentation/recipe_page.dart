// lib/recipe_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:KitchenCraft/main.dart' as globals;
import 'package:KitchenCraft/widgets/custom_scaffold.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _ingredientsCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  // Use Hive directly; Hive is initialized in main.dart
  final Box _localBox = Hive.box('kitchenCraftBox');
  List<Map<String, dynamic>> _localRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadLocalRecipes();
    globals.socket.on('recipeUpdate', (data) {
      setState(() {
        _localRecipes = List<Map<String, dynamic>>.from(data);
        _localBox.put('recipes', _localRecipes);
      });
    });
  }

  void _loadLocalRecipes() {
    final cached = _localBox.get('recipes', defaultValue: []);
    final List<Map<String, dynamic>> normalized = [];
    try {
      for (final entry in List.from(cached)) {
        if (entry is Map) {
          final Map<String, dynamic> map = {};
          entry.forEach((k, v) => map[k?.toString() ?? ''] = v);
          map.putIfAbsent('name', () => '');
          map.putIfAbsent('ingredients', () => '');
          map.putIfAbsent('category', () => '');
          normalized.add(map);
        }
      }
    } catch (_) {}
    setState(() => _localRecipes = normalized);
  }

  Future<void> _addRecipe() async {
    if (_nameCtrl.text.isNotEmpty && _ingredientsCtrl.text.isNotEmpty) {
      final newRecipe = {
        'userId': user?.uid,
        'name': _nameCtrl.text.trim(),
        'ingredients': _ingredientsCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _localRecipes.insert(0, newRecipe);
      _localBox.put('recipes', _localRecipes);
      setState(() {});
      _nameCtrl.clear();
      _ingredientsCtrl.clear();
      _categoryCtrl.clear();

      try {
        await FirebaseFirestore.instance.collection('recipes').add(newRecipe);
        globals.socket.emit('recipeUpdate', _localRecipes);
      } catch (e) {
  debugPrint('Offline recipe save: $e');
      }
    }
  }

  void _addToGrocery(String ingredients) {
    // Parse ingredients and add to grocery (integrate with GroceryPage logic)
    final ingredientList = ingredients.split(',').map((i) => i.trim()).where((i) => i.isNotEmpty).toList();
    for (final ingredient in ingredientList) {
      // Emit to WebSocket for grocery sync (or call GroceryPage method)
      globals.socket.emit('addToGrocery', ingredient);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ingredients to grocery list!')));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ingredientsCtrl.dispose();
    _categoryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Add Recipe Card Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                color: Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: Colors.orange[700], size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Add New Recipe',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Recipe Name',
                          hintText: 'e.g., Spaghetti Carbonara',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.food_bank, color: Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ingredientsCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Ingredients',
                          hintText: 'e.g., pasta, eggs, bacon, parmesan',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.list_alt, color: Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _categoryCtrl,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          hintText: 'e.g., Breakfast, Lunch, Dinner',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.category, color: Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _addRecipe,
                              icon: const Icon(Icons.add_circle),
                              label: const Text('Add Recipe'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _addToGrocery(_ingredientsCtrl.text),
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('To Grocery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Search Card Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 6,
                color: Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Search Recipes',
                      hintText: 'Search by name or category...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, color: Colors.orange, size: 28),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ),
            ),
            
            // Recipe List Section
            Builder(builder: (context) {
              final userId = user?.uid;
              if (userId == null) {
                return const Center(child: Text('Please log in to see your recipes.'));
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .where('userId', isEqualTo: userId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                      //search recipies
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return const Center(child: Text('No recipes found. Start adding some!'));

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final recipeData = docs[index].data() as Map<String, dynamic>;
                      final name = recipeData['name'] ?? 'Untitled Recipe';
                      final category = recipeData['category'] ?? '';
                      final ingredients = recipeData['ingredients'] ?? '';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('Category: $category\nIngredients: $ingredients'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.shopping_cart),
                                onPressed: () => _addToGrocery(ingredients.toString()),
                                tooltip: 'Add to Grocery',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance.collection('recipes').doc(docs[index].id).delete();
                                  } catch (e) {
                                    debugPrint('Failed to delete recipe: $e');
                                  }
                                },
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}