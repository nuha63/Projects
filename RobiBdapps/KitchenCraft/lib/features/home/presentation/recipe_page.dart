// lib/recipe_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:KitchenCraft/widgets/custom_scaffold.dart';
import 'package:KitchenCraft/widgets/empty_state_widget.dart';

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
  bool _isBdappsLoggedIn = false;
  String _bdappsPhone = '';

  @override
  void initState() {
    super.initState();
    _loadLocalRecipes();
    _loadBdappsSession();
  }

  Future<void> _loadBdappsSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isBdappsLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _bdappsPhone = prefs.getString('userPhone') ?? '';
    });
  }

  void _loadLocalRecipes() {
    // Clear old recipes and start fresh with defaults
    _localBox.clear();
    
    final List<Map<String, dynamic>> allRecipes = _getDefaultRecipes();
    
    _localBox.put('recipes', allRecipes);
    setState(() => _localRecipes = allRecipes);
  }

  List<Map<String, dynamic>> _getDefaultRecipes() {
    return [
      {
        'name': 'Rice Cooker',
        'ingredients': 'Rice, Water, Salt',
        'category': 'Main Course',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isDefault': true,
      },
      {
        'name': 'Chicken Biryani',
        'ingredients': 'Chicken, Rice, Onions, Ginger, Garlic, Yogurt, Spices',
        'category': 'Main Course',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 1000,
        'isDefault': true,
      },
      {
        'name': 'Dal Curry',
        'ingredients': 'Lentils, Onions, Tomatoes, Turmeric, Cumin, Salt',
        'category': 'Curry',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 2000,
        'isDefault': true,
      },
      {
        'name': 'Vegetable Stir Fry',
        'ingredients': 'Cabbage, Carrot, Bell Pepper, Onion, Soy Sauce, Garlic',
        'category': 'Vegetables',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 3000,
        'isDefault': true,
      },
      {
        'name': 'Bengali Fish Curry',
        'ingredients': 'Fish, Mustard Oil, Turmeric, Ginger, Garlic, Bay Leaf',
        'category': 'Seafood',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 4000,
        'isDefault': true,
      },
      {
        'name': 'Egg Fried Rice',
        'ingredients': 'Rice, Eggs, Peas, Carrots, Green Onions, Soy Sauce',
        'category': 'Rice',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 5000,
        'isDefault': true,
      },
      {
        'name': 'Lentil Soup',
        'ingredients': 'Red Lentils, Chicken Broth, Onion, Carrot, Celery, Salt',
        'category': 'Soup',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 6000,
        'isDefault': true,
      },
      {
        'name': 'Garlic Prawn Pasta',
        'ingredients': 'Pasta, Prawns, Garlic, Olive Oil, Red Chili, Salt',
        'category': 'Seafood',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 7000,
        'isDefault': true,
      },
      {
        'name': 'Mixed Vegetable Curry',
        'ingredients': 'Potato, Cauliflower, Spinach, Onion, Tomato, Spices',
        'category': 'Curry',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 8000,
        'isDefault': true,
      },
      {
        'name': 'Chicken Tandoori',
        'ingredients': 'Chicken, Yogurt, Ginger, Garlic, Lemon, Tandoori Spices',
        'category': 'Grill',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 9000,
        'isDefault': true,
      },
    ];
  }

  Future<void> _addRecipe() async {
    if (_nameCtrl.text.isNotEmpty && _ingredientsCtrl.text.isNotEmpty) {
      final userId = user?.uid ?? _bdappsPhone;
      final newRecipe = {
        'userId': userId,
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

      // Only sync to Firebase if Firebase authenticated
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('recipes').add(newRecipe);
        } catch (e) {
          debugPrint('Offline recipe save: $e');
        }
      }
    }
  }

  void _addToGrocery(String ingredients) async {
    // Parse ingredients and add to grocery collection
    final ingredientList = ingredients.split(',').map((i) => i.trim()).where((i) => i.isNotEmpty).toList();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      for (final ingredient in ingredientList) {
        await FirebaseFirestore.instance.collection('grocery').add({
          'userId': user.uid,
          'item': ingredient,
          'isPurchased': false,
          'timestamp': Timestamp.now(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added ingredients to grocery list!'))
        );
      }
    } catch (e) {
      debugPrint('Failed to add to grocery: $e');
    }
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
              // Check both Firebase and BDApps login status
              final isLoggedIn = (user != null && user!.uid.isNotEmpty) || 
                                 (_isBdappsLoggedIn && _bdappsPhone.isNotEmpty);
              
              if (!isLoggedIn) {
                return const Center(child: Text('Please log in to see your recipes.'));
              }

              // For Firebase users, use Firestore
              if (user != null && user!.uid.isNotEmpty) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('recipes')
                      .where('userId', isEqualTo: user?.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.book,
                        title: 'No Recipes Yet',
                        description: 'Start building your recipe collection!',
                        actionButtonText: 'Scroll Up to Add',
                        onActionPressed: null,
                        color: Colors.orange[700],
                      );
                    }
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
              }

              // For BDApps phone users (no Firebase), use local Hive data only
              if (_isBdappsLoggedIn && _bdappsPhone.isNotEmpty) {
                // Show local recipes from Hive
                final searchQuery = _searchCtrl.text.toLowerCase();
                final filtered = _localRecipes.where((r) {
                  final name = (r['name'] ?? '').toString().toLowerCase();
                  final category = (r['category'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery) || category.contains(searchQuery);
                }).toList();
                
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.book,
                    title: 'No Recipes Yet',
                    description: 'Start building your recipe collection!\nAdd your first recipe using the form above.',
                    actionButtonText: 'Scroll Up to Add',
                    onActionPressed: null,
                    color: Colors.orange[700],
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final recipe = filtered[index];
                    final name = recipe['name'] ?? 'Untitled';
                    final category = recipe['category'] ?? '';
                    final ingredients = recipe['ingredients'] ?? '';
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
                              onPressed: () {
                                _localRecipes.removeAt(_localRecipes.indexWhere((r) => r['name'] == name && r['timestamp'] == recipe['timestamp']));
                                _localBox.put('recipes', _localRecipes);
                                setState(() {});
                              },
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              
              // For Firebase authenticated users, use Firestore
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .where('userId', isEqualTo: user?.uid)
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
                  if (docs.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.book,
                      title: 'No Recipes Yet',
                      description: 'Start building your recipe collection!\nAdd your first recipe using the form above.',
                      actionButtonText: 'Scroll Up to Add',
                      onActionPressed: null, // Scroll handled by user
                      color: Colors.orange[700],
                    );
                  }

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