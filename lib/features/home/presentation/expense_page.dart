// lib/expense_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:KitchenCraft/widgets/custom_scaffold.dart';
import 'package:KitchenCraft/widgets/empty_state_widget.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  String _category = 'Groceries';
  final List<String> _categories = ['Groceries', 'Utensils', 'Dining', 'Other'];
  final User? user = FirebaseAuth.instance.currentUser;
  final Box _localBox = Hive.box('kitchenCraftBox');
  bool _isBdappsLoggedIn = false;
  String _bdappsPhone = '';
  List<Map<String, dynamic>> _localExpenses = [];

  String _getUserId() {
    // Use Firebase UID if available, otherwise use BDApps phone
    return user?.uid ?? _bdappsPhone;
  }

  @override
  void initState() {
    super.initState();
    _loadBdappsSession();
    _loadLocalExpenses();
  }

  Future<void> _loadBdappsSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final phone = prefs.getString('userPhone') ?? '';
    
    if (!mounted) return;
    setState(() {
      _isBdappsLoggedIn = isLoggedIn;
      _bdappsPhone = phone;
    });
  }

  void _loadLocalExpenses() {
    final cached = _localBox.get('expenses', defaultValue: []);
    final List<Map<String, dynamic>> normalized = [];
    try {
      for (final entry in List.from(cached)) {
        if (entry is Map) {
          final Map<String, dynamic> map = {};
          entry.forEach((k, v) => map[k?.toString() ?? ''] = v);
          map.putIfAbsent('amount', () => 0.0);
          map.putIfAbsent('category', () => 'Other');
          map.putIfAbsent('description', () => '');
          map.putIfAbsent('timestamp', () => DateTime.now().millisecondsSinceEpoch);
          normalized.add(map);
        }
      }
    } catch (_) {}
    setState(() => _localExpenses = normalized);
  }

  Map<String, double> _getCategoryTotals(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    return docs.fold<Map<String, double>>({}, (totals, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = _readDate(data['timestamp']);
      if (date != null && date.month == now.month && date.year == now.year) {
        final cat = (data['category'] is String) ? data['category'] as String : 'Other';
        final amt = _readAmount(data['amount']);
        totals[cat] = (totals[cat] ?? 0.0) + amt;
      }
      return totals;
    });
  }

  double _getMonthlyTotal(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    return docs.fold<double>(0.0, (acc, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = _readDate(data['timestamp']);
      if (date != null && date.month == now.month && date.year == now.year) {
        final amt = _readAmount(data['amount']);
        return acc + amt;
      }
      return acc;
    });
  }

  double _readAmount(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  DateTime? _readDate(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _addExpense() async {
    if (_amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }
    
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }

    try {
      final expense = {
        'amount': amount,
        'category': _category,
        'description': _descriptionCtrl.text.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Save locally FIRST (works for all users)
      _localExpenses.insert(0, expense);
      await _localBox.put('expenses', _localExpenses);
      
      _amountCtrl.clear();
      _descriptionCtrl.clear();
      if (!mounted) return;
      
      setState(() {});
      
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ Expense added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      debugPrint('Expense saved locally: $expense');

      // Then optionally sync to Firebase (only if Firebase authenticated)
      if (user != null && user!.uid.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('expenses').add({
            'userId': user!.uid,
            ...expense,
          });
          debugPrint('Expense synced to Firebase');
        } catch (e) {
          debugPrint('Firebase sync failed (local copy saved): $e');
        }
      }
    } catch (e) {
      debugPrint('Error adding expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFirebaseLoggedIn = user != null && user!.uid.isNotEmpty;
    final isBdappsLoggedIn = _isBdappsLoggedIn && _bdappsPhone.isNotEmpty;
    final isLoggedIn = isFirebaseLoggedIn || isBdappsLoggedIn;

    // Show login prompt if not logged in
    if (!isLoggedIn) {
      return CustomScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Track Your Expenses',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Login with your mobile number to start tracking your food expenses.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // For Firebase users - show Firestore expenses (with fallback to local if Firestore fails)
    if (isFirebaseLoggedIn) {
      return CustomScaffold(
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expenses')
              .where('userId', isEqualTo: user!.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // If Firestore error, show local expenses instead
            if (snapshot.hasError) {
              debugPrint('Firestore error: ${snapshot.error}');
              return _buildExpenseUI([]);
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildExpenseUI(snapshot.data?.docs ?? []);
          },
        ),
      );
    }

    // For BDApps phone users - show local expenses with full UI (no Firestore access)
    return CustomScaffold(
      body: _buildExpenseUI([]),
    );
  }

  Widget _buildExpenseUI(List<QueryDocumentSnapshot> firebaseExpenses) {
    // Get expenses to display (local for BDApps, Firebase for Firebase users)
    final isFirebaseUser = user != null && user!.uid.isNotEmpty;
    final expensesToShow = isFirebaseUser 
        ? firebaseExpenses.map((doc) => doc.data() as Map<String, dynamic>).toList()
        : _localExpenses;

    // Calculate monthly total
    final now = DateTime.now();
    final monthlyTotal = expensesToShow.fold<double>(0.0, (total, expense) {
      final timestamp = expense['timestamp'];
      DateTime expenseDate;
      if (timestamp is Timestamp) {
        expenseDate = timestamp.toDate();
      } else if (timestamp is int) {
        expenseDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return total;
      }

      if (expenseDate.month == now.month && expenseDate.year == now.year) {
        return total + ((expense['amount'] as num?)?.toDouble() ?? 0.0);
      }
      return total;
    });

    // Calculate category totals
    final categoryTotals = <String, double>{};
    for (final expense in expensesToShow) {
      final timestamp = expense['timestamp'];
      DateTime expenseDate;
      if (timestamp is Timestamp) {
        expenseDate = timestamp.toDate();
      } else if (timestamp is int) {
        expenseDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        continue;
      }

      if (expenseDate.month == now.month && expenseDate.year == now.year) {
        final category = (expense['category'] as String?) ?? 'Other';
        final amount = ((expense['amount'] as num?)?.toDouble() ?? 0.0);
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Total Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              color: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.green[700], size: 32),
                        const SizedBox(width: 12),
                        const Text(
                          'Monthly Expenses',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tk ${monthlyTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pie Chart
          if (categoryTotals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 6,
                color: Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pie_chart, color: Colors.orange[700], size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Category Breakdown',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: categoryTotals.entries.map((entry) {
                              return PieChartSectionData(
                                color: _getCategoryColor(entry.key),
                                value: entry.value,
                                title: '${entry.key}\nTk ${entry.value.toStringAsFixed(0)}',
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Add Expense Form Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 6,
              color: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Log New Expense',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountCtrl,
                      decoration: InputDecoration(
                        labelText: 'Amount (Tk)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.category, color: Colors.orange),
                      ),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (value) => setState(() => _category = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.notes, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addExpense,
                        icon: const Icon(Icons.save),
                        label: const Text('Log Expense', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expense History Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.orange[700], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Expense History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),

          // Expense List
          if (expensesToShow.isEmpty)
            EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'No Expenses Yet',
              description: 'Start tracking your food expenses using the form above to see insights and charts.',
              actionButtonText: 'Add First Expense',
              onActionPressed: null,
              color: Colors.orange[700],
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expensesToShow.length,
              itemBuilder: (context, index) {
                final expense = expensesToShow[index];
                final date = _parseDate(expense['timestamp']);
                final amount = ((expense['amount'] as num?)?.toDouble() ?? 0.0);
                final category = (expense['category'] as String?) ?? 'Other';
                final description = (expense['description'] as String?) ?? 'No description';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    elevation: 4,
                    color: Colors.white.withOpacity(0.92),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCategoryColor(category),
                        child: const Icon(Icons.shopping_bag, color: Colors.white),
                      ),
                      title: Text(
                        'Tk ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text(
                        '$category\n$description\n${DateFormat('MMM dd, yyyy - hh:mm a').format(date)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  DateTime _parseDate(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Groceries':
        return Colors.green;
      case 'Utensils':
        return Colors.blue;
      case 'Dining':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}