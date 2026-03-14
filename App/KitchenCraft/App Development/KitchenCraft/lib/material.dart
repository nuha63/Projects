import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  // 1. Accepts the specific content (page body) for the current screen
  final Widget body; 
  // 2. Optionally accepts an AppBar
  final PreferredSizeWidget? appBar; 

  const CustomScaffold({
    super.key,
    required this.body,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    // We use the standard Flutter Scaffold as the base
    return Scaffold(
      appBar: appBar, // Use the optional AppBar passed in
      // 3. Stack allows us to layer the background and the foreground content
      body: Stack(
        children: <Widget>[
          // --- Layer 1: The Background ---
          Container(
            // Use a BoxDecoration to define the visual style
            decoration: const BoxDecoration(
              // Example: A blue-to-purple gradient background
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF005AA7), // Darker Blue
                  Color(0xFFFFFDE4), // Lighter Cream/Yellow
                ],
              ),
            ),
          ),
          
          // --- Layer 2: The Page Content (Foreground) ---
          // This displays the actual content (lists, buttons, text) of the page
          body,
        ],
      ),
    );
  }
}