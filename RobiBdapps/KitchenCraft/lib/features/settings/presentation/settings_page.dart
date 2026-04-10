import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:KitchenCraft/widgets/custom_scaffold.dart';
import 'package:KitchenCraft/services/theme_provider.dart';
import 'dart:convert';
import 'dart:async';
import 'edit_profile_page.dart';
import 'privacy_policy_page.dart';
import 'about_app_page.dart';

class SettingsPage extends StatefulWidget {
  final ThemeProvider? themeProvider;

  const SettingsPage({
    super.key,
    this.themeProvider,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeProvider _themeProvider;
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _themeProvider = widget.themeProvider ?? ThemeProvider();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from KitchenCraft?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // Clear BDApps session if logged in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userPhone');

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // Navigate to login page
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUnsubscribe() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('userPhone') ?? '';

    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not found'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsubscribe from Service'),
        content: const Text(
          'Are you sure you want to unsubscribe? The service will be discontinued.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      const baseUrl = 'https://www.flicksize.com/kitchencraft';
      
      final res = await http
          .post(
            Uri.parse('$baseUrl/unsubscribe.php'),
            body: {'user_mobile': phone},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      Navigator.of(context).pop();

      final data = jsonDecode(res.body);
      final statusCode = data['statusCode']?.toString() ?? '';
      final statusDetail = data['statusDetail']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';
      final error = data['error']?.toString() ?? '';
      final successFlag = data['success'] == true;
      final subscriptionStatus =
          data['subscriptionStatus']?.toString().toUpperCase() ?? '';
      final success =
          successFlag ||
          statusCode == 'S1000' ||
          subscriptionStatus == 'UNREGISTERED';

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Unsubscribe successful'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear BDApps session and sign out
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('userPhone');
        await FirebaseAuth.instance.signOut();
        
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      } else {
        String errorMsg = 'Unsubscribe failed. Please try again.';
        if (error.isNotEmpty) {
          errorMsg = error;
        } else if (statusDetail.isNotEmpty) {
          errorMsg = statusDetail;
        } else if (message.isNotEmpty) {
          errorMsg = message;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request timeout. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // APPEARANCE SECTION
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'APPEARANCE',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildThemeOption(
                            context: context,
                            title: 'Light Mode',
                            icon: Icons.light_mode,
                            isSelected: _themeProvider.isLightMode,
                            onTap: () async {
                              await _themeProvider.setLightMode();
                              setState(() {});
                            },
                          ),
                          Divider(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          _buildThemeOption(
                            context: context,
                            title: 'Dark Mode',
                            icon: Icons.dark_mode,
                            isSelected: _themeProvider.isDarkMode,
                            onTap: () async {
                              await _themeProvider.setDarkMode();
                              setState(() {});
                            },
                          ),
                          Divider(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          _buildThemeOption(
                            context: context,
                            title: 'System Default',
                            icon: Icons.brightness_auto,
                            isSelected: _themeProvider.isSystemMode,
                            onTap: () async {
                              await _themeProvider.setSystemMode();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ACCOUNT SECTION
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'ACCOUNT',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile Information',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  context: context,
                                  label: 'Name',
                                  value: _currentUser?.displayName ?? 'Not set',
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  context: context,
                                  label: 'Email',
                                  value: _currentUser?.email ?? 'Not set',
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.edit,
                              color: Colors.orange[700],
                            ),
                            title: const Text('Edit Profile'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECURITY & ACCESS SECTION
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'SECURITY & ACCESS',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.logout,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Sign Out',
                              style: TextStyle(color: Colors.red),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.red,
                            ),
                            onTap: _isLoading ? null : _handleSignOut,
                          ),
                          Divider(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.cancel_schedule_send,
                              color: Colors.orange[700],
                            ),
                            title: const Text(
                              'Unsubscribe from Service',
                              style: TextStyle(color: Colors.orange),
                            ),
                            subtitle: const Text(
                              'Discontinue the BDApps subscription',
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.orange,
                            ),
                            onTap: _isLoading ? null : _handleUnsubscribe,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // APP INFORMATION SECTION
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'APP INFORMATION',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.privacy_tip,
                              color: Colors.blue[700],
                            ),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacyPolicyPage(),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.info,
                              color: Colors.teal[700],
                            ),
                            title: const Text('About App'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AboutAppPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Version info at bottom
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'KitchenCraft v1.0.0\n© 2024 All rights reserved',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.orange[700] : Colors.grey[600],
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Colors.orange[700],
            )
          : const SizedBox.shrink(),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: Colors.orange.withOpacity(0.1),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
