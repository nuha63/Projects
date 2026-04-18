// lib/expense_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
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
    if (_amountCtrl.text.isNotEmpty) {
      final amount = double.parse(_amountCtrl.text);
      final messenger = ScaffoldMessenger.of(context);
      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': user?.uid,
        'amount': amount,
        'category': _category,
        'description': _descriptionCtrl.text.trim(),
        'timestamp': Timestamp.now(),
      });
      if (!mounted) return;
      _amountCtrl.clear();
      _descriptionCtrl.clear();
      messenger.showSnackBar(const SnackBar(content: Text('Expense added!')));
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
    // Show professional guest prompt if user is not logged in
    if (user == null) {
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
                      'Sign up or login to start tracking your food expenses and stay within budget.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
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
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[700],
                            side: BorderSide(color: Colors.orange[700]!),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return CustomScaffold(
      body: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
      .collection('expenses')
      .where('userId', isEqualTo: user?.uid)
      .orderBy('timestamp', descending: true)
      .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final err = snapshot.error.toString();
            if (err.contains('requires an index')) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Index needed for this query.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final url = Uri.parse('https://console.firebase.google.com/v1/r/project/kitchenkraft-963bd/firestore/indexes?create_composite=ClNwcm9qZWN0cy9raXRjaGVua3JhZnQtOTYzYmQvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2V4cGVuc2VzL2luZGV4ZXMvXxABGgoKBnVzZXJJZBABGg0KCXRpbWVzdGFtcBACGgwKCF9fbmFtZV9fEAI');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          messenger.showSnackBar(const SnackBar(content: Text('Could not open link')));
                        }
                      },
                      child: const Text('Create Index'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Error loading expenses'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Sort documents client-side by timestamp descending to avoid requiring
          // a composite index on the server for the where()+orderBy() combination.
          final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = _readDate(aData['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = _readDate(bData['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          final monthlyTotal = _getMonthlyTotal(docs);
          final categoryTotals = _getCategoryTotals(docs);

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
                
                // Pie Chart Card
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
                
                // Add Expense Card
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
                  Text(
                    'Expense History',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                    ],
                  ),
                ),
                
                // Expense List
                if (docs.isEmpty)
                  EmptyStateWidget(
                    icon: Icons.receipt_long,
                    title: 'No Expenses Yet',
                    description: 'Start tracking your food expenses using the form above to see insights and charts.',
                    actionButtonText: 'Add First Expense',
                    onActionPressed: null,
                    color: Colors.orange[700],
                  ),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Fix layout error
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>; // Explicit cast
                    final date = (data['timestamp'] as Timestamp).toDate();
                    final amount = (data['amount'] as num).toDouble();
                    final category = data['category'] as String;
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
                          '$category\n${data['description'] ?? 'No description'}\n${DateFormat('MMM dd, yyyy - hh:mm a').format(date)}',
                            style: const TextStyle(fontSize: 12),
                        ),
                          isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('expenses').doc(docs[index].id).delete();
                          },
                        ),
                      ),
                    ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
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