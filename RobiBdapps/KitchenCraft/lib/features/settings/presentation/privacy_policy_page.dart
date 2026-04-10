import 'package:flutter/material.dart';
import 'package:KitchenCraft/widgets/custom_scaffold.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: March 2024',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content
            _buildSection(
              context: context,
              title: '1. Introduction',
              content:
                  'KitchenCraft ("we", "our", or "us") operates the KitchenCraft application. This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our Service and the choices you have associated with that data.',
            ),

            _buildSection(
              context: context,
              title: '2. Information Collection and Use',
              content:
                  'We collect several different types of information for various purposes to provide and improve our Service to you.\n\n'
                  '• Account Information: Name, email address, phone number\n'
                  '• Usage Data: Recipes, meal plans, grocery lists, expense tracking\n'
                  '• Device Information: Device type, operating system, IP address\n'
                  '• Cookies: We use cookies to enhance your experience',
            ),

            _buildSection(
              context: context,
              title: '3. Use of Data',
              content:
                  'KitchenCraft uses the collected data for various purposes:\n\n'
                  '• To provide and maintain the Service\n'
                  '• To notify you about changes to our Service\n'
                  '• To provide customer support\n'
                  '• To gather analysis or valuable information so that we can improve the Service\n'
                  '• To monitor the usage of the Service\n'
                  '• To detect, prevent and address technical issues',
            ),

            _buildSection(
              context: context,
              title: '4. Security of Data',
              content:
                  'The security of your data is important to us but remember that no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your Personal Data, we cannot guarantee its absolute security.',
            ),

            _buildSection(
              context: context,
              title: '5. Changes to This Privacy Policy',
              content:
                  'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date at the top of this Privacy Policy.',
            ),

            _buildSection(
              context: context,
              title: '6. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                  'Email: privacy@kitchencraft.app\n'
                  'Address: Your Company Address Here',
            ),

            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                '© 2024 KitchenCraft. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
