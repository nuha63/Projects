// lib/meal_plan_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
// socket import not required here; using globals.socket from main.dart
import 'package:table_calendar/table_calendar.dart';
import 'package:KitchenCraft/main.dart' as globals; // Keep this import for socket usage
import 'package:KitchenCraft/widgets/custom_scaffold.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}
class _MealPlanPageState extends State<MealPlanPage> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _recipeCtrl = TextEditingController();
  // Use Hive directly; initialized in main.dart
  final Box _localBox = Hive.box('kitchenCraftBox');
  List<Map<String, dynamic>> _localPlans = [];

  @override
  void initState() {
    super.initState();
    _loadLocalPlans();
    globals.socket.on('mealPlanUpdate', (data) { // Keep this line as is
      setState(() {
        _localPlans = List<Map<String, dynamic>>.from(data);
        _localBox.put('mealPlans', _localPlans);
      });
    });
  }

  void _loadLocalPlans() {
    final cached = _localBox.get('mealPlans', defaultValue: []);
    final List<Map<String, dynamic>> normalized = [];
    try {
      for (final entry in List.from(cached)) {
        if (entry is Map) {
          final Map<String, dynamic> map = {};
          entry.forEach((k, v) => map[k?.toString() ?? ''] = v);
          map.putIfAbsent('date', () => DateTime.now().millisecondsSinceEpoch);
          map.putIfAbsent('recipe', () => '');
          normalized.add(map);
        }
      }
    } catch (_) {}
    setState(() => _localPlans = normalized);
  }

  Future<void> _addMealPlan() async {
    if (_selectedDay != null && _recipeCtrl.text.isNotEmpty) {
      final newPlan = {
        'userId': user?.uid,
        'date': _selectedDay!.millisecondsSinceEpoch,
        'recipe': _recipeCtrl.text.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _localPlans.insert(0, newPlan);
      _localBox.put('mealPlans', _localPlans);
      setState(() {});
      _recipeCtrl.clear();

      try {
        await FirebaseFirestore.instance.collection('meal_plans').add(newPlan);
        globals.socket.emit('mealPlanUpdate', _localPlans);
      } catch (e) {
  debugPrint('Offline plan save: $e');
      }
    }
  }

  @override
  void dispose() {
    _recipeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: SingleChildScrollView(
        child: Column(
        children: [
          // Calendar Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              color: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.orange[700], size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Meal Planner',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
              }
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Colors.orange[700],
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.orange[300],
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.green[600],
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonDecoration: BoxDecoration(
                          color: Colors.orange[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        formatButtonTextStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Add Meal Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        Icon(Icons.restaurant, color: Colors.green[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Add Meal for ${DateFormat('MMM dd, yyyy').format(_selectedDay ?? DateTime.now())}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _recipeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Recipe or Meal Name',
                        hintText: 'Enter meal details...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.food_bank, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addMealPlan,
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Add to Meal Plan', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
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
          
          // Meals for Selected Day
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.event_note, color: Colors.orange[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Meals for ${DateFormat('MMM dd').format(_selectedDay ?? DateTime.now())}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
          
          ValueListenableBuilder<Box>(
            valueListenable: Hive.box('kitchenCraftBox').listenable(),
            builder: (context, box, _) {
              final raw = box.get('mealPlans', defaultValue: []);
              final List<Map<String, dynamic>> normalized = [];
              try {
                for (final entry in List.from(raw)) {
                  if (entry is Map) {
                    final Map<String, dynamic> map = {};
                    entry.forEach((k, v) => map[k?.toString() ?? ''] = v);
                    map.putIfAbsent('date', () => DateTime.now().millisecondsSinceEpoch);
                    map.putIfAbsent('recipe', () => '');
                    normalized.add(map);
                  }
                }
              } catch (_) {}
              _localPlans = normalized;
              final filtered = _localPlans.where((plan) {
                final date = DateTime.fromMillisecondsSinceEpoch(plan['date']);
                return isSameDay(_selectedDay, date);
              }).toList();
              
              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.no_meals, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No meals planned for this day', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final plan = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Card(
                      elevation: 4,
                      color: Colors.white.withOpacity(0.92),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[700],
                          child: const Icon(Icons.restaurant_menu, color: Colors.white),
                        ),
                        title: Text(
                          plan['recipe'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          DateFormat('EEEE, MMM dd, yyyy - hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(plan['date'])),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _localPlans.remove(plan));
                            _localBox.put('mealPlans', _localPlans);
                            globals.socket.emit('mealPlanUpdate', _localPlans);
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }
}