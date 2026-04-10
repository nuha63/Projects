// lib/features/home/presentation/family_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'dart:math';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final TextEditingController _groupCodeCtrl = TextEditingController();
  final TextEditingController _groupNameCtrl = TextEditingController();
  final TextEditingController _itemCtrl = TextEditingController();
  final TextEditingController _recipeNameCtrl = TextEditingController();
  final TextEditingController _recipeProcedureCtrl = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;

  String? _familyId;
  String? _groupCode;
  String? _groupName;
  Map<String, String> _members = {}; // uid -> displayName
  String _currentUserName = "Unknown";

  bool _isLoading = false;
  final String _assignedMember = "Unassigned";

  @override
  void initState() {
    super.initState();
    _loadUserFamily();
    _loadCurrentUserName();
  }

  @override
  void dispose() {
    _groupCodeCtrl.dispose();
    _groupNameCtrl.dispose();
    _itemCtrl.dispose();
    _recipeNameCtrl.dispose();
    _recipeProcedureCtrl.dispose();
    super.dispose();
  }

  // ------------------ Load User Info ----------------------

  Future<void> _loadCurrentUserName() async {
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      setState(() {
        _currentUserName = userDoc.data()?['displayName'] ?? user!.email ?? "Unknown";
      });
    } catch (e) {
      print("Error loading user name: $e");
    }
  }

  // ------------------ Load User -> Family ----------------------

  Future<void> _loadUserFamily() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      _familyId = userDoc.data()?['familyId'];

      if (_familyId != null) {
        await _loadFamilyData();
      }
    } catch (e) {
      _showMessage("Error fetching family: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadFamilyData() async {
    if (_familyId == null) return;

    try {
      final familyDoc = await FirebaseFirestore.instance
          .collection('families')
          .doc(_familyId)
          .get();

      final data = familyDoc.data();
      if (data == null) return;

      setState(() {
        _groupCode = data['groupCode'];
        _groupName = data['groupName'] ?? 'Unnamed Group';
      });

      // Load member names
      List<String> memberIds = List<String>.from(data['members'] ?? []);
      await _loadMemberNames(memberIds);
    } catch (e) {
      _showMessage("Error loading family: $e");
    }
  }

  Future<void> _loadMemberNames(List<String> memberIds) async {
    Map<String, String> memberMap = {};

    for (String uid in memberIds) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        final name = userDoc.data()?['displayName'] ?? 
                     userDoc.data()?['email'] ?? 
                     'Member ${uid.substring(0, 6)}';
        
        memberMap[uid] = name;
      } catch (e) {
        memberMap[uid] = 'Member ${uid.substring(0, 6)}';
      }
    }

    setState(() {
      _members = memberMap;
    });
  }

  // ------------------ Group Actions ----------------------

  String _generateCode() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random r = Random();
    return String.fromCharCodes(
      List.generate(6, (_) => chars.codeUnitAt(r.nextInt(chars.length))),
    );
  }

  Future<void> _createGroup() async {
    if (user == null) return;

    final groupName = _groupNameCtrl.text.trim();
    if (groupName.isEmpty) {
      _showMessage("Enter a group name");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String code = _generateCode();

      final ref = await FirebaseFirestore.instance
          .collection('families')
          .add({
        "groupCode": code,
        "groupName": groupName,
        "members": [user!.uid],
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": user!.uid,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({}, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({"familyId": ref.id});

      setState(() {
        _familyId = ref.id;
        _groupCode = code;
        _groupName = groupName;
        _members = {user!.uid: _currentUserName};
      });

      _groupNameCtrl.clear();
      _showMessage("Group '$groupName' created successfully!");
    } catch (e) {
      _showMessage("Error creating group: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _joinGroup() async {
    if (user == null) return;

    final code = _groupCodeCtrl.text.trim();
    if (code.isEmpty) {
      _showMessage("Enter a group code");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('families')
          .where('groupCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showMessage("Group not found");
        setState(() => _isLoading = false);
        return;
      }

      final familyDoc = query.docs.first;

      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyDoc.id)
          .update({
        "members": FieldValue.arrayUnion([user!.uid])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({}, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({"familyId": familyDoc.id});

      setState(() => _familyId = familyDoc.id);

      await _loadFamilyData();

      _groupCodeCtrl.clear();
      _showMessage("Joined group!");
    } catch (e) {
      _showMessage("Error joining group: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _leaveGroup() async {
    if (_familyId == null || user == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Leave Group"),
        content: const Text("Are you sure you want to leave this group?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Leave")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(_familyId)
          .update({
        "members": FieldValue.arrayRemove([user!.uid])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({}, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({"familyId": FieldValue.delete()});

      setState(() {
        _familyId = null;
        _groupCode = null;
        _groupName = null;
        _members = {};
      });

      _showMessage("Left group");
    } catch (e) {
      _showMessage("Error leaving group: $e");
    }

    setState(() => _isLoading = false);
  }

  // ------------------ Add Grocery Item ----------------------

  Future<void> _addItem() async {
    if (_familyId == null || user == null) {
      _showMessage("Join a family first.");
      return;
    }

    final itemName = _itemCtrl.text.trim();
    if (itemName.isEmpty) {
      _showMessage("Item cannot be empty.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection("shared_grocery")
          .add({
        "item": itemName,
        "assignedTo": _assignedMember,
        "familyId": _familyId,
        "isPurchased": false,
        "addedBy": user!.uid,
        "addedByName": _currentUserName,
        "timestamp": FieldValue.serverTimestamp(),
      });

      _itemCtrl.clear();
      _showMessage("Item added!");
    } catch (e) {
      _showMessage("Error adding item: $e");
    }

    setState(() => _isLoading = false);
  }

  // ------------------ Share Recipe ----------------------

  Future<void> _shareRecipe() async {
    if (_familyId == null || user == null) {
      _showMessage("Join a family first.");
      return;
    }

    final recipeName = _recipeNameCtrl.text.trim();
    final procedure = _recipeProcedureCtrl.text.trim();

    if (recipeName.isEmpty || procedure.isEmpty) {
      _showMessage("Recipe name and procedure are required.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection("shared_recipes")
          .add({
        "recipeName": recipeName,
        "procedure": procedure,
        "familyId": _familyId,
        "sharedBy": user!.uid,
        "sharedByName": _currentUserName,
        "timestamp": FieldValue.serverTimestamp(),
      });

      _recipeNameCtrl.clear();
      _recipeProcedureCtrl.clear();
      
      Navigator.pop(context); // Close dialog
      _showMessage("Recipe shared successfully!");
    } catch (e) {
      _showMessage("Error sharing recipe: $e");
    }

    setState(() => _isLoading = false);
  }

  void _showShareRecipeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Share Recipe"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _recipeNameCtrl,
                decoration: const InputDecoration(
                  labelText: "Recipe Name",
                  hintText: "e.g., Chocolate Cake",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _recipeProcedureCtrl,
                decoration: const InputDecoration(
                  labelText: "Procedure",
                  hintText: "Step by step instructions...",
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                minLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _recipeNameCtrl.clear();
              _recipeProcedureCtrl.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _shareRecipe,
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }

  // ------------------ Helpers ----------------------

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _copyCode() async {
    if (_groupCode == null) return;
    await FlutterClipboard.copy(_groupCode!);
    _showMessage("Group code copied!");
  }

  // ------------------ UI ----------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_groupName ?? "Family"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _familyId == null
              ? _buildNoGroup()
              : _buildGroupUI(),
      floatingActionButton: _familyId != null
          ? FloatingActionButton.extended(
              onPressed: _showShareRecipeDialog,
              icon: const Icon(Icons.restaurant_menu),
              label: const Text("Share Recipe"),
            )
          : null,
    );
  }

  Widget _buildNoGroup() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Join or Create a Family Group",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _groupCodeCtrl,
            decoration: const InputDecoration(
              labelText: "Group Code",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _joinGroup,
            icon: const Icon(Icons.login),
            label: const Text("Join Group"),
          ),
          
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          
          TextField(
            controller: _groupNameCtrl,
            decoration: const InputDecoration(
              labelText: "Group Name",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.group),
              hintText: "e.g., Smith Family",
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _createGroup,
            icon: const Icon(Icons.add),
            label: const Text("Create Group"),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _groupName ?? "Group",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _leaveGroup,
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text("Leave"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        "Code: $_groupCode",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: _copyCode,
                        tooltip: "Copy code",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Members Section
          const Text(
            "Members",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: _members.entries
                  .map((entry) => ListTile(
                        leading: CircleAvatar(
                          child: Text(entry.value[0].toUpperCase()),
                        ),
                        title: Text(entry.value),
                        subtitle: entry.key == user!.uid 
                            ? const Text("You") 
                            : null,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Grocery Item Section
          const Text(
            "Add Grocery Item",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _itemCtrl,
            decoration: const InputDecoration(
              labelText: "Item name",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_cart),
            ),
          ),
          const SizedBox(height: 10),

          ElevatedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text("Add Item"),
          ),
        ],
      ),
    );
  }
}

// ------------------ Recipes List Page ----------------------

class RecipesListPage extends StatelessWidget {
  final String familyId;

  const RecipesListPage({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Family Recipes")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shared_recipes')
            .where('familyId', isEqualTo: familyId)
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
                          recipeId: recipes[index].id,  // ← ADD THIS LINE
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
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
    final sharedById = recipe['sharedBy'];  // ← ADD THIS
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;  // ← ADD THIS

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
                    content: const Text("Are you sure you want to delete this recipe?"),
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
