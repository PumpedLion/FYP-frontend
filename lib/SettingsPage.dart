import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'SignUp.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 0: Profile, 1: Security, 2: Notifications, 3: Billing
  int _activeTabIndex = 0;

  // Profile Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();

  // Security Controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUpdatingPassword = false;

  // Notification Preferences
  bool _emailNotifs = true;
  bool _collabNotifs = true;
  bool _commentNotifs = true;
  bool _salesNotifs = true;
  bool _marketingNotifs = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationPrefs();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _avatarController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _emailNotifs = prefs.getBool('emailNotifs') ?? true;
        _collabNotifs = prefs.getBool('collabNotifs') ?? true;
        _commentNotifs = prefs.getBool('commentNotifs') ?? true;
        _salesNotifs = prefs.getBool('salesNotifs') ?? true;
        _marketingNotifs = prefs.getBool('marketingNotifs') ?? false;
      });
    }
  }

  Future<void> _saveNotificationPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'emailNotifs') _emailNotifs = value;
      if (key == 'collabNotifs') _collabNotifs = value;
      if (key == 'commentNotifs') _commentNotifs = value;
      if (key == 'salesNotifs') _salesNotifs = value;
      if (key == 'marketingNotifs') _marketingNotifs = value;
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    // Try to get stored user first
    final user = await AuthService.getUser();
    if (user != null) {
      _updateControllers(user);
    }

    // Always fetch fresh data from server
    final response = await AuthService.refreshUserProfile();
    if (response['user'] != null && mounted) {
      setState(() {
        _currentUser = response['user'];
        _updateControllers(_currentUser!);
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _updateControllers(Map<String, dynamic> user) {
    _nameController.text = user['fullName'] ?? '';
    _emailController.text = user['email'] ?? '';
    _bioController.text = user['bio'] ?? '';
    _avatarController.text = user['avatarUrl'] ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final response = await AuthService.updateProfile({
      'fullName': _nameController.text,
      'bio': _bioController.text,
      'avatarUrl': _avatarController.text,
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (response['user'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to update profile"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);
    final response = await AuthService.updatePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    if (mounted) {
      setState(() => _isUpdatingPassword = false);
      if (response['message'] == 'Password updated successfully') {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to update password"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final bool isMobile = !isDesktop;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isMobile ? null : IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D2939)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: isMobile,
        title: Text(
          "Settings",
          style: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF1D2939),
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 20 : 24,
          ),
        ),
        actions: isMobile ? [
          IconButton(
            onPressed: () => _handleLogout(),
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 8),
        ] : null,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SIDEBAR (Desktop) ---
          if (isDesktop)
            Container(
              width: 260,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sidebarItem(0, Icons.person_outline, "Profile"),
                  _sidebarItem(1, Icons.shield_outlined, "Security"),
                  _sidebarItem(2, Icons.notifications_none, "Notifications"),
                  _sidebarItem(3, Icons.credit_card, "Billing"),
                  const Spacer(),
                  _sidebarItem(4, Icons.logout, "Logout", isLogout: true),
                ],
              ),
            ),

          // --- MAIN CONTENT ---
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 16 : 24,
              ),
              child: Column(
                children: [
                  // Mobile Tabs
                  if (isMobile) _buildMobileTabs(),
                  
                  // Content Area
                  _buildActiveContent(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? BottomNavigationBar(
        currentIndex: 2, // Hardcoded to Settings tab
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
        selectedItemColor: const Color(0xFFFF8B7D),
        unselectedItemColor: Colors.blueGrey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined), label: "Store"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_stories_outlined), label: "Library"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
        ],
      ) : null,
    );
  }

  Widget _buildActiveContent(bool isMobile) {
    switch (_activeTabIndex) {
      case 0: return _buildProfileSection(isMobile);
      case 1: return _buildSecuritySection(isMobile);
      case 2: return _buildNotificationsSection(isMobile);
      case 3: return _buildBillingSection(isMobile);
      default: return _buildProfileSection(isMobile);
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8B7D), foregroundColor: Colors.white),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignUpPage(initialIsSignIn: true)),
          (route) => false,
        );
      }
    }
  }

  Widget _sidebarItem(int index, IconData icon, String label, {bool isLogout = false}) {
    bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        if (isLogout) {
          _handleLogout();
        } else {
          setState(() => _activeTabIndex = index);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF2F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFFFF8B7D)
                  : (isLogout ? Colors.redAccent.shade100 : Colors.blueGrey),
            ),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFFF8B7D)
                    : (isLogout ? Colors.redAccent.shade100 : Colors.blueGrey.shade700),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabs() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _mobileTab(0, "Profile"),
          _mobileTab(1, "Security"),
          _mobileTab(2, "Notifications"),
          _mobileTab(3, "Billing"),
        ],
      ),
    );
  }

  Widget _mobileTab(int index, String label) {
    bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF8B7D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black)),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 1: PROFILE
  // ==========================================
  Widget _buildProfileSection(bool isMobile) {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(50.0),
        child: CircularProgressIndicator(),
      ));
    }

    return _sectionWrapper(
      isMobile: isMobile,
      title: "Profile Information",
      child: Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isMobile ? 50 : 45,
                backgroundColor: const Color(0xFFFF8B7D).withOpacity(0.1),
                backgroundImage: _avatarController.text.isNotEmpty 
                    ? NetworkImage(_avatarController.text) 
                    : null,
                child: _avatarController.text.isEmpty 
                    ? Icon(Icons.person, size: isMobile ? 60 : 50, color: const Color(0xFFFF8B7D))
                    : null,
              ),
              const SizedBox(width: 25, height: 20),
              Column(
                crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showAvatarUrlDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8B7D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Change Photo", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  const Text("Enter a valid Image URL", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 35),
          _inputLabel("Full Name"),
          _textField(_nameController, "Your Full Name"),
          const SizedBox(height: 20),
          _inputLabel("Email Address (Read-only)"),
          _textField(_emailController, "Your Email", readOnly: true),
          const SizedBox(height: 20),
          _inputLabel("Bio"),
          _textField(_bioController, "Tell us about yourself", maxLines: 3),
          const SizedBox(height: 20),
          _inputLabel("Avatar URL"),
          _textField(_avatarController, "https://example.com/image.jpg"),
          const SizedBox(height: 35),
          SizedBox(
            width: isMobile ? double.infinity : null,
            child: Align(
              alignment: isMobile ? Alignment.center : Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8B7D),
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showAvatarUrlDialog() {
    final TextEditingController tempController = TextEditingController(text: _avatarController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Avatar URL"),
        content: TextField(
          controller: tempController,
          decoration: const InputDecoration(hintText: "Enter Image URL"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() => _avatarController.text = tempController.text);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 2: SECURITY
  // ==========================================
  Widget _buildSecuritySection(bool isMobile) {
    return Column(
      children: [
        _sectionWrapper(
          isMobile: isMobile,
          title: "Password",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputLabel("Current Password"), _textField(_currentPasswordController, "••••••••", isPass: true),
              const SizedBox(height: 15),
              _inputLabel("New Password"), _textField(_newPasswordController, "••••••••", isPass: true),
              const SizedBox(height: 15),
              _inputLabel("Confirm New Password"), _textField(_confirmPasswordController, "••••••••", isPass: true),
              const SizedBox(height: 25),
              SizedBox(
                width: isMobile ? double.infinity : null,
                child: ElevatedButton(
                  onPressed: _isUpdatingPassword ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8B7D),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  child: _isUpdatingPassword 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Update Password", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionWrapper(
          isMobile: isMobile,
          title: "Two-Factor Authentication",
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Enable 2FA", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Add an extra layer of security to your account"),
            value: false,
            activeColor: const Color(0xFFFF8B7D),
            onChanged: (v) {},
          ),
        ),
        const SizedBox(height: 24),
        _sectionWrapper(
          isMobile: isMobile,
          title: "Active Sessions",
          child: Column(
            children: [
              _sessionItem(Icons.laptop, "MacBook Pro", "Current session", "Active", Colors.green),
              const Divider(height: 30),
              _sessionItem(Icons.phone_iphone, "iPhone 14", "2 hours ago", "Revoke", const Color(0xFFFF8B7D)),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 3: NOTIFICATIONS
  // ==========================================
  Widget _buildNotificationsSection(bool isMobile) {
    return _sectionWrapper(
      isMobile: isMobile,
      title: "Notification Preferences",
      child: Column(
        children: [
          _notifRow("Email Notifications", "Receive updates about your activity", _emailNotifs, (v) => _saveNotificationPref('emailNotifs', v)),
          _notifRow("Collaboration Updates", "Get notified when collaborators make changes", _collabNotifs, (v) => _saveNotificationPref('collabNotifs', v)),
          _notifRow("New Comments", "Receive notifications for new comments", _commentNotifs, (v) => _saveNotificationPref('commentNotifs', v)),
          _notifRow("Sales Notifications", "Get notified when someone buys your book", _salesNotifs, (v) => _saveNotificationPref('salesNotifs', v)),
          _notifRow("Marketing Emails", "Receive promotional newsletters", _marketingNotifs, (v) => _saveNotificationPref('marketingNotifs', v)),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 4: BILLING
  // ==========================================
  Widget _buildBillingSection(bool isMobile) {
    return Column(
      children: [
        _sectionWrapper(
          isMobile: isMobile,
          title: "Payment Methods",
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF8B7D), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card, color: Color(0xFFFF8B7D)),
                    const SizedBox(width: 15),
                    const Expanded(child: Text("•••• •••• •••• 4242\nExpires 12/25", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    if (!isMobile) const Text("Default", style: TextStyle(color: Color(0xFFFF8B7D), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text("+ Add Payment Method", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionWrapper(
          isMobile: isMobile,
          title: "Transaction History",
          child: Column(
            children: [
              _billingTile("Book Sale - \"The Midnight Garden\"", "Dec 15, 2024", "+\$12.99", Colors.green),
              _billingTile("Book Sale - \"Summer Dreams\"", "Dec 10, 2024", "+\$9.99", Colors.green),
              _billingTile("Platform Fee", "Dec 5, 2024", "-\$2.50", const Color(0xFFFF8B7D)),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPER UI WIDGETS ---

  Widget _sectionWrapper({required String title, required Widget child, bool isMobile = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.dmSerifDisplay(fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.bold)),
          SizedBox(height: isMobile ? 20 : 25),
          child,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1, bool isPass = false, bool readOnly = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: isPass,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFF8B7D))),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)));
  }

  Widget _sessionItem(IconData i, String d, String s, String a, Color c) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(i, color: Colors.blueGrey),
      title: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(s),
      trailing: Text(a, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
    );
  }

  Widget _notifRow(String t, String s, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(s, style: const TextStyle(fontSize: 13)),
      value: value,
      activeColor: const Color(0xFFFF8B7D),
      onChanged: onChanged,
    );
  }

  Widget _billingTile(String t, String d, String a, Color c) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(d, style: const TextStyle(fontSize: 12)),
      trailing: Text(a, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}