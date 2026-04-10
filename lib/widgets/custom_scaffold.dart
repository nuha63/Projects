import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  /// Accepts the specific content (page body) for the current screen
  final Widget body;
  
  /// Optionally accepts an AppBar
  final PreferredSizeWidget? appBar;
  
  /// Optionally accepts a FloatingActionButton
  final Widget? floatingActionButton;
  
  /// Optionally accepts a BottomNavigationBar
  final Widget? bottomNavigationBar;
  
  /// Optionally accepts a Drawer
  final Widget? drawer;

  const CustomScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    // We use the standard Flutter Scaffold as the base
    return Scaffold(
      appBar: appBar, // Use the optional AppBar passed in
      drawer: drawer, // Use the optional Drawer passed in
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      // Stack allows us to layer the background and the foreground content
      body: Stack(
        children: <Widget>[
          // --- Layer 1: The Background Image ---
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback gradient if image fails to load
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF005AA7),
                        Color(0xFFFFFDE4),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // --- Layer 2: Semi-transparent Overlay for Better Readability ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          
          // --- Layer 3: The Page Content (Foreground) ---
          // This displays the actual content (lists, buttons, text) of the page
          body,
        ],
      ),
    );
  }
}
