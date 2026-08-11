import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:untitled3/app/theme/app_colors.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const List<Map<String, String>> faqs = [
    {
      'q': 'How do I track my order?',
      'a': 'Go to Profile > My Orders to see the live status and timeline of your order.',
    },
    {
      'q': 'What payment methods are supported?',
      'a': 'We support Khalti, eSewa, and Cash on Delivery.',
    },
    {
      'q': 'Can I return a product?',
      'a': 'Yes, most items can be returned within 3 days of delivery if unused and in original packaging.',
    },
    {
      'q': 'How do I become a seller?',
      'a': 'Log out and choose "Seller" on the login screen, then create a seller account.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Frequently Asked Questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...faqs.map((faq) => Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ExpansionTile(
                    title: Text(faq['q']!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faq['a']!, style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
          const Text('Contact Us',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: AppColors.accent),
                  title: const Text('Call us'),
                  subtitle: const Text('+977 98XXXXXXXX'),
                  onTap: () => Fluttertoast.showToast(msg: 'Opening dialer...'),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppColors.accent),
                  title: const Text('Email us'),
                  subtitle: const Text('support@poojapasal.com'),
                  onTap: () => Fluttertoast.showToast(msg: 'Opening email app...'),
                ),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.chat_outlined, color: AppColors.accent),
                  title: const Text('Live chat'),
                  subtitle: const Text('Chat with our support team'),
                  onTap: () => Fluttertoast.showToast(msg: 'Live chat coming soon.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
