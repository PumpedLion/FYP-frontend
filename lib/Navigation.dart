import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class YourTalesSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String? userRole;

  const YourTalesSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's being used as a drawer (on mobile)
    bool isDrawer = Scaffold.of(context).hasDrawer;
    final bool isReader = userRole == 'READER';

    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 1. Sidebar Header (Logo) - Only show if not in mobile appBar
          if (isDrawer) _buildSidebarLogo(),
          
          const SizedBox(height: 20),

          // 2. Navigation Items
          if (!isReader) _navItem(0, Icons.grid_view_rounded, "Dashboard"),
          if (!isReader) _navItem(1, Icons.description_outlined, "Manuscripts"),
          _navItem(2, Icons.store_outlined, "Store"),
          _navItem(3, Icons.settings_outlined, "Settings"),
          if (!isReader) _navItem(4, Icons.admin_panel_settings_outlined, "Admin"),

          const Spacer(),

          // 3. Footer (Optional - Logout button)
          _navItem(5, Icons.logout_rounded, "Logout", isLogout: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarLogo() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, color: Color(0xFF1D2939), size: 28),
          const SizedBox(width: 10),
          Text(
            "YourTales",
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D2939),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String title, {bool isLogout = false}) {
    bool isActive = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => onItemSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFF8B7D) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive 
              ? [BoxShadow(color: const Color(0xFFFF8B7D).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : [],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive ? Colors.white : (isLogout ? Colors.red.shade400 : Colors.blueGrey.shade400),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? Colors.white : (isLogout ? Colors.red.shade400 : Colors.blueGrey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}