// lib/services/recipe_init_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RecipeInitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Popular recipes that will be added for all users
  static final List<Map<String, dynamic>> _popularRecipes = [
    {
      'name': 'Classic Spaghetti Carbonara',
      'ingredients': 'Spaghetti, Eggs, Bacon, Parmesan cheese, Black pepper, Salt',
      'instructions': '1. Cook spaghetti according to package directions\n2. Fry bacon until crispy\n3. Mix eggs and parmesan in a bowl\n4. Combine hot pasta with bacon\n5. Remove from heat and quickly mix in egg mixture\n6. Season with black pepper and serve',
      'category': 'Italian',
      'prepTime': 20,
      'servings': 4,
      'isPopular': true,
    },
    {
      'name': 'Chicken Tikka Masala',
      'ingredients': 'Chicken breast, Yogurt, Garam masala, Tomato sauce, Cream, Onion, Garlic, Ginger',
      'instructions': '1. Marinate chicken in yogurt and spices for 2 hours\n2. Grill or bake chicken pieces\n3. Sauté onions, garlic, and ginger\n4. Add tomato sauce and spices\n5. Add grilled chicken and cream\n6. Simmer for 15 minutes and serve with rice',
      'category': 'Indian',
      'prepTime': 45,
      'servings': 4,
      'isPopular': true,
    },
    {
      'name': 'Caesar Salad',
      'ingredients': 'Romaine lettuce, Caesar dressing, Croutons, Parmesan cheese, Chicken breast (optional)',
      'instructions': '1. Wash and chop romaine lettuce\n2. Toss with Caesar dressing\n3. Add croutons and shaved parmesan\n4. Top with grilled chicken if desired\n5. Serve immediately',
      'category': 'Salad',
      'prepTime': 15,
      'servings': 2,
      'isPopular': true,
    },
    {
      'name': 'Beef Tacos',
      'ingredients': 'Ground beef, Taco shells, Lettuce, Tomatoes, Cheese, Sour cream, Taco seasoning',
      'instructions': '1. Brown ground beef in a pan\n2. Add taco seasoning and water\n3. Simmer for 5 minutes\n4. Warm taco shells\n5. Fill shells with meat, lettuce, tomatoes, cheese\n6. Top with sour cream and enjoy',
      'category': 'Mexican',
      'prepTime': 25,
      'servings': 4,
      'isPopular': true,
    },
    {
      'name': 'Vegetable Stir Fry',
      'ingredients': 'Mixed vegetables (bell peppers, broccoli, carrots), Soy sauce, Garlic, Ginger, Sesame oil, Rice',
      'instructions': '1. Heat sesame oil in a wok\n2. Add garlic and ginger, stir-fry briefly\n3. Add harder vegetables first (carrots, broccoli)\n4. Add softer vegetables (peppers)\n5. Add soy sauce and stir\n6. Serve over steamed rice',
      'category': 'Asian',
      'prepTime': 20,
      'servings': 3,
      'isPopular': true,
    },
    {
      'name': 'Chocolate Chip Cookies',
      'ingredients': 'Butter, Sugar, Brown sugar, Eggs, Vanilla, Flour, Baking soda, Salt, Chocolate chips',
      'instructions': '1. Cream butter and sugars together\n2. Beat in eggs and vanilla\n3. Mix in flour, baking soda, and salt\n4. Fold in chocolate chips\n5. Drop spoonfuls onto baking sheet\n6. Bake at 375°F for 10-12 minutes',
      'category': 'Dessert',
      'prepTime': 30,
      'servings': 24,
      'isPopular': true,
    },
    {
      'name': 'Greek Salad',
      'ingredients': 'Cucumber, Tomatoes, Red onion, Feta cheese, Olives, Olive oil, Lemon juice, Oregano',
      'instructions': '1. Chop cucumber, tomatoes, and onion\n2. Add olives and crumbled feta\n3. Drizzle with olive oil and lemon juice\n4. Sprinkle with oregano\n5. Toss gently and serve',
      'category': 'Salad',
      'prepTime': 10,
      'servings': 4,
      'isPopular': true,
    },
    {
      'name': 'Pancakes',
      'ingredients': 'Flour, Milk, Eggs, Sugar, Baking powder, Salt, Butter, Maple syrup',
      'instructions': '1. Mix flour, sugar, baking powder, and salt\n2. Whisk in milk and eggs\n3. Heat buttered griddle\n4. Pour batter and cook until bubbles form\n5. Flip and cook other side\n6. Serve with butter and syrup',
      'category': 'Breakfast',
      'prepTime': 20,
      'servings': 4,
      'isPopular': true,
    },
  ];

  /// Initialize popular recipes for a new user
  static Future<void> initializePopularRecipes(String userId) async {
    try {
      debugPrint('Initializing popular recipes for user: $userId');

      final batch = _firestore.batch();
      
      for (final recipe in _popularRecipes) {
        final recipeData = {
          ...recipe,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'isFavorite': false,
        };

        final docRef = _firestore.collection('recipes').doc();
        batch.set(docRef, recipeData);
      }

      await batch.commit();
      debugPrint('Successfully added ${_popularRecipes.length} popular recipes for user $userId');
      
    } catch (e) {
      debugPrint('Error initializing popular recipes: $e');
      // Don't throw - we don't want signup to fail if recipes fail
    }
  }

  /// Check if user already has recipes
  static Future<bool> hasRecipes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('recipes')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user recipes: $e');
      return false;
    }
  }

  /// Initialize recipes if user doesn't have any
  static Future<void> ensureUserHasRecipes(String userId) async {
    final hasRecipes = await RecipeInitService.hasRecipes(userId);
    if (!hasRecipes) {
      await RecipeInitService.initializePopularRecipes(userId);
    }
  }
}
