// lib/shared_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SharedPage extends StatefulWidget {
  const SharedPage({super.key});

  @override
  State<SharedPage> createState() => _SharedPageState();
}

class _SharedPageState extends State<SharedPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? _familyId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserFamily();
  }

  Future<void> _loadUserFamily() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      setState(() {
        _familyId = userDoc.data()?['familyId'];
      });
    } catch (e) {
      print("Error loading family: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Shared"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.shopping_cart), text: "Groceries"),
              Tab(icon: Icon(Icons.restaurant_menu), text: "Recipes"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _familyId == null
                ? const Center(
                    child: Text(
                      "Join a family group first",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildGroceryList(),
                      _buildRecipesList(),
                    ],
                  ),
      ),
    );
  }

  // ------------------ Grocery List Tab ----------------------

  Widget _buildGroceryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shared_grocery')
          .where('familyId', isEqualTo: _familyId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data?.docs ?? [];

        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No grocery items yet",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index].data() as Map<String, dynamic>;
            final itemName = item['item'] ?? 'Unknown';
            final assignedTo = item['assignedTo'] ?? 'Unassigned';
            final isPurchased = item['isPurchased'] ?? false;
            final addedBy = item['addedByName'] ?? 'Unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Checkbox(
                  value: isPurchased,
                  onChanged: (val) {
                    FirebaseFirestore.instance
                        .collection('shared_grocery')
                        .doc(items[index].id)
                        .update({'isPurchased': val});
                  },
                ),
                title: Text(
                  itemName,
                  style: TextStyle(
                    decoration: isPurchased
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Added by $addedBy • Assigned to $assignedTo',
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('shared_grocery')
                        .doc(items[index].id)
                        .delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ------------------ Recipes List Tab ----------------------

  Widget _buildRecipesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shared_recipes')
          .where('familyId', isEqualTo: _familyId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final recipes = snapshot.data?.docs ?? [];

        if (recipes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No recipes shared yet",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  "Go to Family tab to share recipes",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index].data() as Map<String, dynamic>;
            final recipeName = recipe['recipeName'] ?? 'Untitled Recipe';
            final sharedBy = recipe['sharedByName'] ?? 'Unknown';
            final timestamp = recipe['timestamp'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.restaurant),
                ),
                title: Text(
                  recipeName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Shared by $sharedBy${timestamp != null ? ' • ${_formatDate(timestamp)}' : ''}",
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailPage(
                        recipe: recipe,
                        recipeId: recipes[index].id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ------------------ Recipe Detail Page ----------------------

class RecipeDetailPage extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final String recipeId;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context) {
    final recipeName = recipe['recipeName'] ?? 'Untitled Recipe';
    final procedure = recipe['procedure'] ?? 'No procedure provided';
    final sharedBy = recipe['sharedByName'] ?? 'Unknown';
    final timestamp = recipe['timestamp'] as Timestamp?;
    final sharedById = recipe['sharedBy'];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipeName),
        actions: [
          // Only show delete if user is the owner
          if (sharedById == currentUserId)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Delete Recipe"),
                    content: const Text(
                        "Are you sure you want to delete this recipe?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseFirestore.instance
                      .collection('shared_recipes')
                      .doc(recipeId)
                      .delete();

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Recipe deleted")),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: Text(sharedBy[0].toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sharedBy,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (timestamp != null)
                            Text(
                              _formatDate(timestamp),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recipe Name
            Text(
              recipeName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Procedure
            const Text(
              "Procedure",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  procedure,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}