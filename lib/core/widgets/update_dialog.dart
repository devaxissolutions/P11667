import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateDialog extends StatelessWidget {
  final String version;
  final String releaseNotes;
  final VoidCallback onUpdate;
  final VoidCallback onCancel;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.releaseNotes,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16161D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Color(0xFF34C759),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Available',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'v$version',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF34C759),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (releaseNotes.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s New',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          releaseNotes,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Not Now',
                      style: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Update Now',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
