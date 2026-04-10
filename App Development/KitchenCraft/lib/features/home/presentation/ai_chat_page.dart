// lib/ai_chat_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Assuming these are paths to your local files
import '../../../src/config.dart' as config;
import 'package:KitchenCraft/widgets/custom_scaffold.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _queryCtrl = TextEditingController();
  // Store messages: {'role': 'user'/'assistant', 'content': '...', 'timestamp': DateTime}
  final List<Map<String, dynamic>> _messages = []; 
  bool _loading = false;
  
  // Hive box for local chat history
  Box? _chatBox;

  // Grocery list (used for context in the prompt). Loaded from Firestore for logged-in user.
  final List<String> _groceryList = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadGroceryList();
  }

  Future<void> _loadGroceryList() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load personal grocery items (collection: grocery) where userId == uid
      final qs = await FirebaseFirestore.instance
          .collection('grocery')
          .where('userId', isEqualTo: user.uid)
          .get();

      final items = <String>[];
      for (final doc in qs.docs) {
        final data = doc.data();
        final item = data['item'];
        if (item is String && item.trim().isNotEmpty) items.add(item.trim().toLowerCase());
      }

      setState(() {
        _groceryList.clear();
        _groceryList.addAll(items);
      });
    } catch (e) {
      debugPrint('Failed to load grocery list: $e');
    }
  }

  // Try to extract ingredients from a free-form user message.
  // Looks for phrases like "I have eggs, tomatoes and rice" or "Ingredients: eggs, milk"
  List<String> _extractIngredientsFromText(String text) {
    if (text.trim().isEmpty) return [];
    final lower = text.toLowerCase();

    // Primary pattern: 'i have' or 'ingredients' followed by a list
    final re = RegExp(r"(?:i have|i've got|ingredients?:)\s*([\s\S]+)", caseSensitive: false);
    final m = re.firstMatch(lower);
    String? listPart = m?.group(1);

    // Secondary pattern: 'with x, y and z' (common phrasing)
    if (listPart == null) {
      final re2 = RegExp(r'with\s+([\w\s, and-]+)', caseSensitive: false);
      final m2 = re2.firstMatch(lower);
      listPart = m2?.group(1);
    }

    if (listPart == null) return [];

    // Split by comma, ' and ', newline or semicolon
    final parts = listPart.split(RegExp(r',|;|\band\b|\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    // Clean punctuation and return unique items
    final cleaned = <String>{};
    for (final p in parts) {
      var item = p.replaceAll(RegExp(r"[^a-z0-9 ]"), '').trim();
      if (item.isNotEmpty) cleaned.add(item);
    }

    return cleaned.toList();
  }
  // --- GEMINI API INTEGRATION ---

  Future<String> _callGeminiAPI(String prompt, List<String> ingredients) async {
    try {
      final apiKey = config.groqApiKey;
      
      // Check if API key is available
      if (apiKey == null || apiKey.isEmpty) {
        return 'Error: Groq API key not found. Please check your .env file.';
      }
      
      // Construct a full prompt with context
      final fullPrompt = '''You are a helpful cooking assistant. The user has these ingredients: ${ingredients.join(', ')}.

User question: $prompt

Respond with a clear recipe or guidance. If the user asked for a recipe using the ingredients, provide:
- A short recipe title
- A concise list of ingredients required, marking which of the user's ingredients are used
- Step-by-step numbered instructions
- Approximate prep and cook time
- Substitutions for any likely missing ingredients

Return your answer as plain text but structure it clearly with headers and numbered steps.''';

      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      debugPrint('Calling Groq API...');
      debugPrint('API URL: $url');
      debugPrint('API Key present: ${apiKey.isNotEmpty}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'user',
              'content': fullPrompt
            }
          ]
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'];
        return text ?? 'No response from AI.';
      } else {
        final errorBody = response.body;
        debugPrint('API Error: ${response.statusCode} - $errorBody');
        
        if (response.statusCode == 400) {
          return 'Error: Invalid API key or request format. Please check your Groq API key.';
        } else if (response.statusCode == 429) {
          return 'Error: Too many requests. Please wait a moment and try again.';
        } else if (response.statusCode == 401) {
          return '''Error: API key is invalid or unauthorized.
Steps to fix:
1. Go to: https://console.groq.com/keys
2. Create a new API key
3. Update the GROQ_API_KEY in your .env file
4. Save and try again''';
        }
        
        return 'Error: Could not get response from AI (Status: ${response.statusCode}). Please try again.';
      }
      
    } on TimeoutException catch (_) {
      debugPrint('API Timeout');
      return 'Error: Request timed out. Please check your internet connection and try again.';
    } catch (e) {
      debugPrint('Error calling Groq API: $e');
      return '''Error: Failed to connect to AI service. Please check your internet connection.
Details: $e''';
    }
  }
  // --- HIVE HISTORY MANAGEMENT (Assuming _ensureBox and _loadHistory are correct) ---
  Future<Box> _ensureBox() async {
    if (!Hive.isBoxOpen('chatHistoryBox')) {
      // Assuming openBoxSafe is a utility function to safely open the box
      // Replace with: _chatBox = await Hive.openBox('chatHistoryBox'); if not using a safe wrapper
      // If you were using a backend, this would be a Firestore or database call
      // _chatBox = await openBoxSafe('chatHistoryBox'); 
      _chatBox = await Hive.openBox('chatHistoryBox');
    } else {
      _chatBox = Hive.box('chatHistoryBox');
    }
    return _chatBox!;
  }

  Future<void> _loadHistory() async {
    final box = await _ensureBox();
    final cachedHistory = box.get('chatHistory', defaultValue: []);
    final List<Map<String, dynamic>> normalized = [];

    // Simple normalization and deserialization of history from Hive
    try {
      for (final entry in List.from(cachedHistory)) {
        if (entry is Map) {
          final Map<String, dynamic> map = {};
          entry.forEach((k, v) => map[k?.toString() ?? ''] = v);
          
          final ts = map['timestamp'];
          // Convert stored timestamp (int) back to DateTime object
          if (ts is int) {
            map['timestamp'] = DateTime.fromMillisecondsSinceEpoch(ts);
          } else if (ts is String) {
            final parsed = int.tryParse(ts);
            map['timestamp'] = parsed != null ? DateTime.fromMillisecondsSinceEpoch(parsed) : DateTime.now();
          } else if (ts is! DateTime) {
            map['timestamp'] = DateTime.now();
          }
          
          normalized.add(map);
        }
      }
    } catch (_) {}

    setState(() => _messages.addAll(normalized));
  }

  Future<void> _saveHistory() async {
    final box = await _ensureBox();
    // Serialize DateTime to int before saving
    final serialized = _messages.map((m) {
      final copy = Map<String, dynamic>.from(m);
      final ts = copy['timestamp'];
      if (ts is DateTime) copy['timestamp'] = ts.millisecondsSinceEpoch;
      return copy;
    }).toList(growable: false);

    await box.put('chatHistory', serialized);
  }

  // --- SEND QUERY LOGIC ---

  Future<void> _sendQuery() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;

    final timestamp = DateTime.now();
    final userMsg = {'role': 'user', 'content': query, 'timestamp': timestamp};
    
    // Add user message to UI and set loading state
    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _queryCtrl.clear();
    await _saveHistory();

    Map<String, dynamic>? aiMsg;

    try {
      // 1. Create an empty message slot for the AI response
      aiMsg = {'role': 'assistant', 'content': '', 'timestamp': timestamp};
      setState(() => _messages.add(aiMsg!));

      // 2. Detect if the user provided ingredients in the message ("I have..." / "Ingredients:")
      final detected = _extractIngredientsFromText(query);
      final ingredientsForPrompt = detected.isNotEmpty ? detected : List<String>.from(_groceryList);

      // 3. Call the Gemini API with the selected ingredients
      final responseText = await _callGeminiAPI(query, ingredientsForPrompt);

      // 3. Update the content of the AI message slot
      setState(() => aiMsg!['content'] = responseText);
      await _saveHistory();

    } catch (e) {
      // Error handling logic
      String errorMessage = 'Error: Failed to get response.';
      
      if (aiMsg == null) {
        aiMsg = {'role': 'assistant', 'content': errorMessage, 'timestamp': timestamp};
        setState(() => _messages.add(aiMsg!));
      } else {
        setState(() => aiMsg!['content'] = errorMessage);
      }
      await _saveHistory();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // Use the CustomScaffold for the universal background
    return CustomScaffold(
      appBar: AppBar(
        title: const Text('AI Cooking Assistant'),
        backgroundColor: Colors.transparent, // Ensure AppBar is transparent to see background
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              setState(() => _messages.clear());
              final box = await _ensureBox();
              await box.put('chatHistory', []); // Clear local history
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                final isUser = msg['role'] == 'user';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isUser) // AI Avatar
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.smart_toy, color: Colors.white),
                        ),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // Adjust colors to contrast with your CustomScaffold background
                            color: isUser ? Colors.green[100] : Colors.grey[100], 
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(msg['content']),
                              const SizedBox(height: 4),
                              Text(
                                TimeOfDay.fromDateTime(msg['timestamp']).format(context),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isUser) // User Avatar
                        const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.smart_toy, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text('AI is typing...'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ask for recipe ideas, tips, or substitutes',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendQuery(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _sendQuery, // Disable button while loading
                  child: const Text('Send')
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}