import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  // Form controllers
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  
  String _gender = 'Male';
  String _activityLevel = 'Sedentary';
  String _goal = 'Lose Weight';
  
  // Results
  double? _bmi;
  String? _bmiCategory;
  int? _dailyCalories;
  Map<String, int>? _macros;
  bool _hasCalculated = false;

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // Load saved profile from Firestore
  Future<void> _loadSavedProfile() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('nutrition_profile')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _ageCtrl.text = data['age']?.toString() ?? '';
          _heightCtrl.text = data['height']?.toString() ?? '';
          _weightCtrl.text = data['weight']?.toString() ?? '';
          _gender = data['gender'] ?? 'Male';
          _activityLevel = data['activityLevel'] ?? 'Sedentary';
          _goal = data['goal'] ?? 'Lose Weight';
        });
        _calculateNutrition(); // Auto-calculate if profile exists
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

  // Save profile to Firestore
  Future<void> _saveProfile() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('nutrition_profile')
          .doc('current')
          .set({
        'age': int.tryParse(_ageCtrl.text) ?? 0,
        'height': double.tryParse(_heightCtrl.text) ?? 0,
        'weight': double.tryParse(_weightCtrl.text) ?? 0,
        'gender': _gender,
        'activityLevel': _activityLevel,
        'goal': _goal,
        'bmi': _bmi,
        'bmiCategory': _bmiCategory,
        'dailyCalories': _dailyCalories,
        'macros': _macros,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving profile: $e");
    }
  }

  void _calculateNutrition() {
    // Get inputs
    int age = int.tryParse(_ageCtrl.text) ?? 0;
    double height = double.tryParse(_heightCtrl.text) ?? 0;
    double weight = double.tryParse(_weightCtrl.text) ?? 0;

    if (age == 0 || height == 0 || weight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    // Calculate BMI
    double heightM = height / 100;
    _bmi = weight / (heightM * heightM);

    // Determine BMI category
    if (_bmi! < 18.5) {
      _bmiCategory = 'Underweight';
    } else if (_bmi! < 25) {
      _bmiCategory = 'Normal Weight';
    } else if (_bmi! < 30) {
      _bmiCategory = 'Overweight';
    } else if (_bmi! < 35) {
      _bmiCategory = 'Obese Class I';
    } else if (_bmi! < 40) {
      _bmiCategory = 'Obese Class II';
    } else {
      _bmiCategory = 'Obese Class III';
    }

    // Calculate BMR (Mifflin-St Jeor)
    double bmr;
    if (_gender == 'Male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Apply activity multiplier
    Map<String, double> activityMultipliers = {
      'Sedentary': 1.2,
      'Lightly Active': 1.375,
      'Moderately Active': 1.55,
      'Very Active': 1.725,
    };
    double tdee = bmr * activityMultipliers[_activityLevel]!;

    // Adjust for goal
    if (_goal == 'Lose Weight') {
      _dailyCalories = (tdee - 500).round();
      _macros = {
        'protein': ((_dailyCalories! * 0.30) / 4).round(),
        'carbs': ((_dailyCalories! * 0.40) / 4).round(),
        'fats': ((_dailyCalories! * 0.30) / 9).round(),
      };
    } else if (_goal == 'Gain Weight') {
      _dailyCalories = (tdee + 300).round();
      _macros = {
        'protein': ((_dailyCalories! * 0.25) / 4).round(),
        'carbs': ((_dailyCalories! * 0.50) / 4).round(),
        'fats': ((_dailyCalories! * 0.25) / 9).round(),
      };
    } else if (_goal == 'Build Muscle') {
      _dailyCalories = (tdee + 200).round();
      _macros = {
        'protein': ((_dailyCalories! * 0.35) / 4).round(),
        'carbs': ((_dailyCalories! * 0.40) / 4).round(),
        'fats': ((_dailyCalories! * 0.25) / 9).round(),
      };
    } else {
      // Maintain Weight
      _dailyCalories = tdee.round();
      _macros = {
        'protein': ((_dailyCalories! * 0.25) / 4).round(),
        'carbs': ((_dailyCalories! * 0.45) / 4).round(),
        'fats': ((_dailyCalories! * 0.30) / 9).round(),
      };
    }

    setState(() {
      _hasCalculated = true;
    });

    _saveProfile(); // Save to Firestore

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nutrition plan calculated!')),
    );
  }

  Color _getBmiColor() {
    if (_bmi == null) return Colors.white;
    if (_bmi! < 18.5) return Colors.blue.shade100;
    if (_bmi! < 25) return Colors.green.shade100;
    if (_bmi! < 30) return Colors.orange.shade100;
    return Colors.red.shade100;
  }

  IconData _getBmiIcon() {
    if (_bmi == null) return Icons.fitness_center;
    if (_bmi! < 18.5) return Icons.trending_down;
    if (_bmi! < 25) return Icons.check_circle;
    if (_bmi! < 30) return Icons.warning;
    return Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Calculator'),
        backgroundColor: Colors.orange[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileForm(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculateNutrition,
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate My Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_hasCalculated) ...[
              const SizedBox(height: 30),
              _buildResults(),
              const SizedBox(height: 20),
              _buildMealPlanButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Age
            TextField(
              controller: _ageCtrl,
              decoration: const InputDecoration(
                labelText: 'Age',
                suffixText: 'years',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Gender
            const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Male'),
                    value: 'Male',
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Female'),
                    value: 'Female',
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Height & Weight
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      suffixText: 'cm',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      suffixText: 'kg',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Activity Level
            DropdownButtonFormField<String>(
              initialValue: _activityLevel,
              decoration: const InputDecoration(
                labelText: 'Activity Level',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_run),
              ),
              items: [
                'Sedentary',
                'Lightly Active',
                'Moderately Active',
                'Very Active'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _activityLevel = val!),
            ),
            const SizedBox(height: 16),
            
            // Goal
            DropdownButtonFormField<String>(
              initialValue: _goal,
              decoration: const InputDecoration(
                labelText: 'Health Goal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items: [
                'Lose Weight',
                'Gain Weight',
                'Maintain Weight',
                'Build Muscle'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _goal = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        // BMI Card
        Card(
          elevation: 4,
          color: _getBmiColor(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Body Mass Index',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _bmi!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _bmiCategory!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Icon(_getBmiIcon(), size: 64, color: Colors.black54),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Daily Calories Card
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Daily Nutrition Plan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Target Calories: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '$_dailyCalories cal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Macros
                _buildMacroRow('Protein', _macros!['protein']!, Colors.blue),
                const SizedBox(height: 12),
                _buildMacroRow('Carbs', _macros!['carbs']!, Colors.green),
                const SizedBox(height: 12),
                _buildMacroRow('Fats', _macros!['fats']!, Colors.orange),
                
                const SizedBox(height: 20),
                _buildRecommendations(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRow(String name, int grams, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '${grams}g',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    String recommendation = '';
    List<String> tips = [];

    if (_bmiCategory == 'Underweight') {
      recommendation = 'Focus on gaining healthy weight';
      tips = [
        '🥜 Eat calorie-dense foods (nuts, avocados)',
        '🍽️ Eat 5-6 small meals per day',
        '💪 Strength training to build muscle',
        '🥛 Protein-rich foods and smoothies',
      ];
    } else if (_bmiCategory == 'Overweight' || _bmiCategory!.contains('Obese')) {
      recommendation = 'Focus on healthy weight loss';
      tips = [
        '🥗 High protein, moderate carbs',
        '🚶 Regular cardio and strength training',
        '💧 Drink 2-3 liters of water daily',
        '🚫 Avoid sugary drinks and processed foods',
      ];
    } else {
      recommendation = 'Maintain your healthy weight';
      tips = [
        '⚖️ Balanced diet with variety',
        '🏃 Regular exercise (150min/week)',
        '😴 Get 7-9 hours of sleep',
        '💧 Stay hydrated',
      ];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(tip, style: const TextStyle(fontSize: 14)),
              )),
        ],
      ),
    );
  }

  Widget _buildMealPlanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MealPlanSuggestionsPage(
                bmiCategory: _bmiCategory!,
                dailyCalories: _dailyCalories!,
                goal: _goal,
              ),
            ),
          );
        },
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('View Meal Plan Suggestions'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ------------------ Meal Plan Suggestions Page ----------------------

class MealPlanSuggestionsPage extends StatelessWidget {
  final String bmiCategory;
  final int dailyCalories;
  final String goal;

  const MealPlanSuggestionsPage({
    super.key,
    required this.bmiCategory,
    required this.dailyCalories,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final mealPlan = _getMealPlan();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan Suggestions'),
        backgroundColor: Colors.orange[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal: $goal',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Daily Target: $dailyCalories calories'),
                  Text('Status: $bmiCategory'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          _buildMealCard('🌅 Breakfast', mealPlan['breakfast']!, Colors.orange),
          _buildMealCard('🌞 Lunch', mealPlan['lunch']!, Colors.green),
          _buildMealCard('🌙 Dinner', mealPlan['dinner']!, Colors.blue),
          _buildMealCard('🍎 Snacks', mealPlan['snacks']!, Colors.purple),
          
          const SizedBox(height: 20),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Tips for Success',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._getTips().map((tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String title, Map<String, dynamic> meal, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Text(
              '$title (${meal['calories']} cal)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (meal['items'] as List<String>)
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✓ ', style: TextStyle(color: Colors.green)),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, dynamic>> _getMealPlan() {
    if (goal == 'Lose Weight' || bmiCategory.contains('Obese') || bmiCategory == 'Overweight') {
      return {
        'breakfast': {
          'calories': (dailyCalories * 0.25).round(),
          'items': [
            'Oatmeal with berries and almonds',
            '2 boiled eggs',
            'Green tea or black coffee',
            'Small apple',
          ],
        },
        'lunch': {
          'calories': (dailyCalories * 0.35).round(),
          'items': [
            'Grilled chicken breast (150g)',
            'Brown rice (1 cup)',
            'Steamed vegetables (broccoli, carrots)',
            'Mixed green salad with olive oil',
          ],
        },
        'dinner': {
          'calories': (dailyCalories * 0.30).round(),
          'items': [
            'Baked salmon (120g)',
            'Quinoa (1/2 cup)',
            'Roasted vegetables',
            'Greek yogurt (unsweetened)',
          ],
        },
        'snacks': {
          'calories': (dailyCalories * 0.10).round(),
          'items': [
            'Handful of almonds (20-25)',
            'Carrot sticks with hummus',
            'Protein shake (optional)',
          ],
        },
      };
    } else if (goal == 'Gain Weight' || bmiCategory == 'Underweight') {
      return {
        'breakfast': {
          'calories': (dailyCalories * 0.25).round(),
          'items': [
            'Whole grain toast with peanut butter',
            'Banana smoothie with protein powder',
            '3 scrambled eggs',
            'Glass of whole milk',
          ],
        },
        'lunch': {
          'calories': (dailyCalories * 0.30).round(),
          'items': [
            'Grilled chicken or beef (200g)',
            'White rice or pasta (1.5 cups)',
            'Avocado salad',
            'Sweet potato',
          ],
        },
        'dinner': {
          'calories': (dailyCalories * 0.30).round(),
          'items': [
            'Salmon or tuna (150g)',
            'Brown rice (1 cup)',
            'Cheese and vegetables',
            'Fruit smoothie',
          ],
        },
        'snacks': {
          'calories': (dailyCalories * 0.15).round(),
          'items': [
            'Trail mix (nuts, dried fruits)',
            'Protein bar',
            'Greek yogurt with granola',
            'Whole milk or protein shake',
          ],
        },
      };
    } else {
      // Maintain Weight / Build Muscle
      return {
        'breakfast': {
          'calories': (dailyCalories * 0.25).round(),
          'items': [
            'Whole grain cereal with milk',
            'Banana and berries',
            '2 eggs (any style)',
            'Orange juice',
          ],
        },
        'lunch': {
          'calories': (dailyCalories * 0.35).round(),
          'items': [
            'Grilled chicken or fish (150g)',
            'Mixed rice (brown and white)',
            'Vegetable stir-fry',
            'Side salad',
          ],
        },
        'dinner': {
          'calories': (dailyCalories * 0.30).round(),
          'items': [
            'Lean protein (chicken, fish, tofu)',
            'Quinoa or whole wheat pasta',
            'Roasted vegetables',
            'Small dessert (dark chocolate)',
          ],
        },
        'snacks': {
          'calories': (dailyCalories * 0.10).round(),
          'items': [
            'Apple with almond butter',
            'Greek yogurt',
            'Mixed nuts',
          ],
        },
      };
    }
  }

  List<String> _getTips() {
    if (goal == 'Lose Weight') {
      return [
        'Drink water before meals',
        'Avoid sugary drinks and sodas',
        'Eat slowly and mindfully',
        'Get 7-9 hours of sleep',
        'Exercise 30-45 min daily',
      ];
    } else if (goal == 'Gain Weight') {
      return [
        'Eat every 2-3 hours',
        'Add healthy fats to meals',
        'Do strength training 3-4x/week',
        'Drink calorie-rich smoothies',
        'Track your progress weekly',
      ];
    } else {
      return [
        'Balance your macronutrients',
        'Stay consistent with meals',
        'Mix cardio and strength training',
        'Listen to your body',
        'Stay hydrated throughout the day',
      ];
    }
  }
}