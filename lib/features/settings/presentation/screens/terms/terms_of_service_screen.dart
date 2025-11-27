import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Terms of Service',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing or using DevQuote, you agree to be bound by these Terms of Service and all applicable laws and regulations.',
            ),
            _buildSection(
              '2. User Conduct',
              'You agree not to use the service for any unlawful purpose or in any way that interrupts, damages, impairs, or renders the service less efficient.',
            ),
            _buildSection(
              '3. Content',
              'You retain ownership of any quotes you submit, but you grant DevQuote a worldwide, royalty-free license to use, reproduce, and display such content.',
            ),
            _buildSection(
              '4. Termination',
              'We reserve the right to terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}
