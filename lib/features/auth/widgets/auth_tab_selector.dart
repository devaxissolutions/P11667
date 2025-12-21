import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthTabSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const AuthTabSelector({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Animated Background Pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            alignment: selectedIndex == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tab Buttons
          Row(
            children: [
              _TabItem(
                label: 'Log In',
                isSelected: selectedIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _TabItem(
                label: 'Sign Up',
                isSelected: selectedIndex == 1,
                onTap: () => onTabSelected(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : Colors.grey[500],
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
