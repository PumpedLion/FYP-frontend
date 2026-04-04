import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'services/auth_service.dart';
import 'services/payment_service.dart';
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
  String _avatarUrl = '';
  bool _isUploadingAvatar = false;

  // Security Controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUpdatingPassword = false;

  // Billing / Purchase history
  List<dynamic> _purchases = [];
  bool _isLoadingPurchases = false;

  // Active Sessions
  bool _isSigningOutAll = false;

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

  Future<void> _loadPurchaseHistory() async {
    setState(() => _isLoadingPurchases = true);
    final purchases = await PaymentService.getPurchaseHistory();
    if (mounted) {
      setState(() {
        _purchases = purchases;
        _isLoadingPurchases = false;
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
    _avatarUrl = user['avatarUrl'] ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final response = await AuthService.updateProfile({
      'fullName': _nameController.text,
      'bio': _bioController.text,
      'avatarUrl': _avatarUrl,
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (response['user'] != null) {
        setState(() => _avatarUrl = response['user']['avatarUrl'] ?? _avatarUrl);
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

  Future<void> _pickAndUploadAvatar() async {
    // Show bottom sheet: Gallery or Camera
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Profile Photo',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF2F0),
                  child: Icon(Icons.photo_library_outlined, color: Color(0xFFFF8B7D)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF2F0),
                  child: Icon(Icons.camera_alt_outlined, color: Color(0xFFFF8B7D)),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 600,
    );

    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    final bytes = await picked.readAsBytes();
    final response = await AuthService.uploadAvatar(bytes, picked.name);
    if (mounted) {
      setState(() => _isUploadingAvatar = false);
      if (response['user'] != null) {
        setState(() => _avatarUrl = response['user']['avatarUrl'] ?? _avatarUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Upload failed'), backgroundColor: Colors.red),
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
          if (index == 3 && _purchases.isEmpty && !_isLoadingPurchases) {
            _loadPurchaseHistory();
          }
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
      onTap: () {
        if (index == 3 && _purchases.isEmpty && !_isLoadingPurchases) {
          _loadPurchaseHistory();
        }
        setState(() => _activeTabIndex = index);
      },
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
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: isMobile ? 50 : 45,
                    backgroundColor: const Color(0xFFFF8B7D).withOpacity(0.1),
                    backgroundImage: _avatarUrl.isNotEmpty
                        ? (_avatarUrl.startsWith('/uploads/')
                            ? NetworkImage('http://localhost:8000$_avatarUrl')
                            : NetworkImage(_avatarUrl)) as ImageProvider
                        : null,
                    child: _isUploadingAvatar
                        ? const CircularProgressIndicator(color: Color(0xFFFF8B7D), strokeWidth: 2)
                        : (_avatarUrl.isEmpty
                            ? Icon(Icons.person, size: isMobile ? 60 : 50, color: const Color(0xFFFF8B7D))
                            : null),
                  ),
                  GestureDetector(
                    onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8B7D),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 25, height: 20),
              Column(
                crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8B7D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isUploadingAvatar
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.upload_rounded, color: Colors.white, size: 18),
                    label: Text(
                      _isUploadingAvatar ? 'Uploading...' : 'Change Photo',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('JPG, PNG or WebP · Max 5 MB', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  // _showAvatarUrlDialog removed — replaced by _pickAndUploadAvatar()


  // ==========================================
  // SECTION 2: SECURITY
  // ==========================================
  Widget _buildSecuritySection(bool isMobile) {
    String _currentDevice = 'This Device';
    String _currentPlatform = 'Unknown';
    if (!kIsWeb) {
      if (Platform.isWindows) _currentPlatform = 'Windows PC';
      else if (Platform.isMacOS) _currentPlatform = 'Mac';
      else if (Platform.isAndroid) _currentPlatform = 'Android';
      else if (Platform.isIOS) _currentPlatform = 'iPhone/iPad';
      else if (Platform.isLinux) _currentPlatform = 'Linux';
    } else {
      _currentPlatform = 'Web Browser';
    }

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
          title: "Active Sessions",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current session
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      kIsWeb ? Icons.web : (Platform.isAndroid || Platform.isIOS ? Icons.phone_android : Icons.laptop),
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_currentPlatform,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Logged in now · Current session',
                              style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Active',
                          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'YourTales uses JWT tokens that expire in 7 days. '
                'Logging out will immediately invalidate your current session.',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSigningOutAll ? null : () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Sign Out Everywhere'),
                        content: const Text('This will log you out of this device. You will need to sign in again.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      setState(() => _isSigningOutAll = true);
                      await AuthService.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage(initialIsSignIn: true)),
                          (route) => false,
                        );
                      }
                    }
                  },
                  icon: _isSigningOutAll
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  label: const Text('Sign Out & Invalidate Session', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose what you want to be notified about. Changes are saved immediately.',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          _notifRow("Email Notifications", "Receive activity updates to your email inbox", _emailNotifs, (v) => _saveNotificationPref('emailNotifs', v)),
          const Divider(height: 1),
          _notifRow("Collaboration Updates", "Get notified when collaborators make changes", _collabNotifs, (v) => _saveNotificationPref('collabNotifs', v)),
          const Divider(height: 1),
          _notifRow("New Comments", "Receive notifications for new comments on your work", _commentNotifs, (v) => _saveNotificationPref('commentNotifs', v)),
          const Divider(height: 1),
          _notifRow("Sales Notifications", "Get notified when someone purchases your book", _salesNotifs, (v) => _saveNotificationPref('salesNotifs', v)),
          const Divider(height: 1),
          _notifRow("Marketing Emails", "Receive newsletters and promotional content", _marketingNotifs, (v) => _saveNotificationPref('marketingNotifs', v)),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 4: BILLING
  // ==========================================
  Widget _buildBillingSection(bool isMobile) {
    if (_isLoadingPurchases) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(50),
        child: CircularProgressIndicator(),
      ));
    }

    return Column(
      children: [
        // Summary Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8B7D), Color(0xFFFF6B5B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _billingStatItem(Icons.shopping_bag_outlined, '${_purchases.length}', 'Purchases'),
              Container(height: 50, width: 1, color: Colors.white30),
              _billingStatItem(
                Icons.payments_outlined,
                'NPR ${_purchases.fold(0.0, (sum, p) => sum + (p['amount'] ?? 0)).toStringAsFixed(0)}',
                'Total Spent',
              ),
              Container(height: 50, width: 1, color: Colors.white30),
              _billingStatItem(Icons.receipt_long_outlined, _purchases.isNotEmpty ? '✓' : '—', 'Has Receipts'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Purchase History
        _sectionWrapper(
          isMobile: isMobile,
          title: "Purchase History",
          child: _purchases.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No purchases yet',
                            style: TextStyle(color: Colors.grey, fontSize: 15)),
                        const SizedBox(height: 6),
                        const Text('Purchased manuscripts will appear here.',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: _purchases.map((p) {
                    final title = p['manuscript']?['title'] ?? 'Untitled';
                    final amount = (p['amount'] ?? 0).toDouble();
                    final gateway = (p['gateway'] ?? '').toString();
                    final date = _formatBillingDate(p['createdAt']);
                    final manuscriptId = p['manuscriptId'];
                    final gatewayColor = gateway == 'KHALTI' ? const Color(0xFF5C2D91) : Colors.green.shade600;

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: gatewayColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.menu_book_rounded, color: gatewayColor, size: 20),
                          ),
                          title: Text(title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('$date · $gateway',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('NPR ${amount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.download_rounded, size: 20, color: Color(0xFFFF8B7D)),
                                tooltip: 'Download Invoice',
                                onPressed: () => PaymentService.downloadInvoice(manuscriptId),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: Colors.grey.shade100),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _billingStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  String _formatBillingDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    final date = DateTime.parse(dateStr).toLocal();
    return '${date.day}/${date.month}/${date.year}';
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

  Widget _notifRow(String t, String s, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(s, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      value: value,
      activeColor: const Color(0xFFFF8B7D),
      onChanged: onChanged,
    );
  }
}