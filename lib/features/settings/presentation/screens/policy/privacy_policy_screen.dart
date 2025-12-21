import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFF0F0F13),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            centerTitle: true,
            title: Text(
              'Privacy Policy',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildLastUpdated(),
            const SizedBox(height: 24),
            _buildSection(
              number: '01',
              title: 'Information Collection',
              content: 'We collect information you provide directly to us when you create an account, update your profile, submit quotes, or communicate with us. This may include your name, email address, password, and any other information you choose to provide.',
            ),
            _buildSection(
              number: '02',
              title: 'Usage of Data',
              content: 'We use the information we collect to provide, maintain, and improve our services. This includes personalizing your experience, sending technical notices, updates, and support messages, and detecting/preventing fraud.',
            ),
            _buildSection(
              number: '03',
              title: 'Data Storage',
              content: 'Your data is securely stored on cloud servers. We implement appropriate technical and organizational measures to protect the security of your personal information.',
            ),
            _buildSection(
              number: '04',
              title: 'Third-Party Services',
              content: 'We may use third-party services that collect, monitor and analyze data. These third-party service providers have their own privacy policies addressing how they use such information.',
            ),
            _buildSection(
              number: '05',
              title: 'Your Rights',
              content: 'You have the right to access, correct, or delete your personal information. You can manage your account settings within the app or contact us for assistance.',
            ),
            _buildSection(
              number: '06',
              title: 'Updates to Policy',
              content: 'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'If you have any questions about this Privacy Policy,\nplease contact us.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated',
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'December 21, 2025',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8B5CF6),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 0), // Aligned with start
            child: Text(
              content,
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
        ],
      ),
    );
  }
}
