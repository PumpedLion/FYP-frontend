import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yourtales/CreateManuscript.dart';
import 'package:yourtales/SettingsPage.dart';

// --- IMPORTS ---
import 'Navigation.dart';   // Your shared navigation file
import 'Manuscript.dart';   // Your manuscripts screen file
import 'Store.dart';        // Your store screen file
import 'Notifications.dart'; // Your notifications screen file
import 'EditManuscript.dart';
import 'services/manuscript_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'SignUp.dart';

void main() {
  runApp(const YourTalesDashboard());
}

class YourTalesDashboard extends StatelessWidget {
  const YourTalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 0 = Dashboard, 1 = Manuscripts, etc.
  int _currentIndex = 0;
  List<dynamic> _recentManuscripts = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  
  // Dashboard Stats
  int _totalManuscripts = 0;
  int _publishedBooks = 0;
  int _totalReads = 0;
  double _totalEarnings = 0.0;
  bool _isLoadingStats = false;

  // New state for Notifications/Activity
  List<dynamic> _notifications = [];
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchDashboardStats();
    _fetchRecentManuscripts();
    _fetchNotifications();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    setState(() => _currentUser = user);
    
    // Refresh in background to get latest data (like avatarUrl)
    final profileResponse = await AuthService.refreshUserProfile();
    if (profileResponse['user'] != null) {
      if (mounted) {
        setState(() => _currentUser = profileResponse['user']);
      }
    }
  }

  Future<void> _fetchRecentManuscripts() async {
    setState(() => _isLoading = true);
    final response = await ManuscriptService.getMyManuscripts();
    setState(() {
      _recentManuscripts = (response['manuscripts'] as List?)?.take(4).toList() ?? [];
      _isLoading = false;
    });
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoadingNotifications = true);
    final response = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = response['notifications'] ?? [];
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _fetchDashboardStats() async {
    setState(() => _isLoadingStats = true);
    final response = await ManuscriptService.getDashboardStats();
    if (mounted) {
      setState(() {
        if (response['stats'] != null) {
          final stats = response['stats'];
          _totalManuscripts = stats['totalManuscripts'] ?? 0;
          _publishedBooks = stats['publishedBooks'] ?? 0;
          _totalReads = stats['totalReads'] ?? 0;
          _totalEarnings = (stats['totalEarnings'] as num?)?.toDouble() ?? 0.0;
        }
        _isLoadingStats = false;
      });
    }
  }

  void _onPageChanged(int index) {
    if (index == 5) {
      _handleLogout();
      return;
    }
    
    if (index == 2) {
      // --- IF STORE CLICKED, GO FULL PAGE ---
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StorePage()),
      );
    } else if (index == 3) {
      // --- IF SETTINGS CLICKED ---
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    } else {
      // --- OTHER PAGES (Dashboard, Manuscripts) STAY IN THE SIDEBAR ---
      setState(() {
        _currentIndex = index;
      });
      if (index == 0) _fetchRecentManuscripts();
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8B7D),
              foregroundColor: Colors.white,
            ),
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

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      
      // --- MOBILE DRAWER ---
      drawer: isDesktop ? null : Drawer(
        child: YourTalesSidebar(
          selectedIndex: _currentIndex,
          userRole: _currentUser?['role'],
          onItemSelected: (index) {
            _onPageChanged(index);
            Navigator.pop(context); // Close drawer on mobile after selection
          },
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.auto_stories, color: Color(0xFF1D2939)),
            const SizedBox(width: 8),
            Text("YourTales", 
              style: GoogleFonts.dmSerifDisplay(
                color: const Color(0xFF1D2939), 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(), // Use NotificationsContent from Notifications.dart
                ),
              );
            },
            icon: const Badge(child: Icon(Icons.notifications_none_outlined)),
          ),
          const SizedBox(width: 10),
          _userProfile(
            
          ),
          const SizedBox(width: 20),
        ],
      ),

      body: Row(
        children: [
          // --- DESKTOP SIDEBAR ---
          if (isDesktop) 
            YourTalesSidebar(
              selectedIndex: _currentIndex,
              userRole: _currentUser?['role'],
              onItemSelected: _onPageChanged,
            ),
          
          // --- DYNAMIC CONTENT AREA ---
          Expanded(
            child: _buildBody(isDesktop),
          ),
        ],
      ),
    );
  }

// --- UPDATED _buildBody ---
  Widget _buildBody(bool isDesktop) {
    switch (_currentIndex) {
      case 0:
        return _dashboardHomeContent(isDesktop); // The main dashboard view
      case 1:
        // CHANGE THIS LINE:
        return const ManuscriptsContent(); 
  
      default:
        return Center(
          child: Text("Page $_currentIndex Coming Soon", 
          style: GoogleFonts.dmSerifDisplay(fontSize: 24)),
        );
    }
  }
  // --- CONTENT: DASHBOARD HOME ---
  Widget _dashboardHomeContent(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerSection(),
          const SizedBox(height: 30),
          _statsGrid(isDesktop),
          const SizedBox(height: 30),
          _mainContentArea(isDesktop),
          const SizedBox(height: 30),
          _bottomCTASection(isDesktop),
        ],
      ),
    );
  }

  // --- REUSABLE UI COMPONENTS (Kept from your original code) ---

  Widget _headerSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back, ${_currentUser?['fullName']?.split(' ')[0] ?? 'Author'}", 
              style: GoogleFonts.dmSerifDisplay(fontSize: 32, fontWeight: FontWeight.bold)),
            Text("Here's what's happening with your stories today", 
              style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateManuscriptPage(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text("New Manuscript"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8B7D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _statsGrid(bool isDesktop) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        StatCard(
          title: "Total Manuscripts", 
          value: _totalManuscripts.toString(), 
          icon: Icons.description_outlined, 
          color: const Color(0xFFFFE8E5),
          isLoading: _isLoadingStats,
        ),
        StatCard(
          title: "Published Books", 
          value: _publishedBooks.toString(), 
          icon: Icons.book_outlined, 
          color: const Color(0xFFE8F5E9),
          isLoading: _isLoadingStats,
        ),
        StatCard(
          title: "Total Reads", 
          value: _formatLargeNumber(_totalReads), 
          icon: Icons.remove_red_eye_outlined, 
          color: const Color(0xFFEDE7F6),
          isLoading: _isLoadingStats,
        ),
        StatCard(
          title: "Earnings", 
          value: "\$${_totalEarnings.toStringAsFixed(2)}", 
          icon: Icons.monetization_on_outlined, 
          color: const Color(0xFFE3F2FD),
          isLoading: _isLoadingStats,
        ),
      ],
    );
  }

  String _formatLargeNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _mainContentArea(bool isDesktop) {
    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: isDesktop ? 2 : 0,
          child: _recentManuscriptsList(),
        ),
        if (isDesktop) const SizedBox(width: 30),
        Expanded(
          flex: isDesktop ? 1 : 0,
          child: Container(
            margin: EdgeInsets.only(top: isDesktop ? 0 : 30),
            child: _recentActivityFeed(),
          ),
        ),
      ],
    );
  }

  Widget _recentManuscriptsList() {
    return _sectionCard(
      title: "Recent Manuscripts",
      action: TextButton(
          onPressed: () => _onPageChanged(1),
          child: const Text("View all", style: TextStyle(color: Color(0xFFFF8B7D)))),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recentManuscripts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("No manuscripts found. Create your first one!")),
                )
              : Column(
                  children: _recentManuscripts.map((m) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditManuscriptPage(
                              title: m['title'] ?? 'Untitled',
                              manuscriptId: m['id'],
                            ),
                          ),
                        );
                      },
                      child: ManuscriptTile(
                        title: m['title'] ?? 'Untitled',
                        authorName: m['author']?['fullName'] ?? 'Unknown',
                        authorAvatarUrl: m['author']?['avatarUrl'],
                        chapters: (m['chapters'] as List?)?.length ?? 0,
                        collaborators: (m['collaborations'] as List?)?.length ?? 0,
                        time: "Updated ${_formatDate(m['updatedAt'])}",
                        status: "In Progress",
                        statusColor: Colors.blue,
                      ),
                    );
                  }).toList().cast<Widget>(),
                ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Unknown";
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  Widget _recentActivityFeed() {
    return _sectionCard(
      title: "Recent Activity",
      child: _isLoadingNotifications
          ? const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ))
          : _notifications.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text("No recent activity.", style: TextStyle(color: Colors.grey))),
                )
              : Column(
                  children: _notifications.take(5).map((n) {
                    final mapping = _getActivityMapping(n['type'] ?? 'SYSTEM');
                    return ActivityItem(
                      name: mapping['name'] ?? "User",
                      action: n['message'] ?? "",
                      story: n['title'] ?? "",
                      time: _formatDate(n['createdAt']),
                      color: mapping['color'] ?? Colors.blue,
                    );
                  }).toList(),
                ),
    );
  }

  Map<String, dynamic> _getActivityMapping(String type) {
    switch (type) {
      case 'COMMENT':
        return {'color': Colors.orange, 'name': 'Comment'};
      case 'COLLABORATION':
        return {'color': Colors.green, 'name': 'Collaborator'};
      case 'SALE':
        return {'color': Colors.blue, 'name': 'Sale'};
      case 'MENTION':
        return {'color': Colors.purple, 'name': 'Mention'};
      case 'SYSTEM':
        return {'color': const Color(0xFFFF8B7D), 'name': 'Me'};
      default:
        return {'color': Colors.grey, 'name': 'Update'};
    }
  }

  Widget _bottomCTASection(bool isDesktop) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _ctaCard("Start Writing", "Create a new manuscript and begin your story", const Color(0xFFFFE8E5), Icons.edit_note),
        _ctaCard("Browse Store", "Discover new books and bestsellers", const Color(0xFFE8F5E9), Icons.store_outlined),
        _ctaCard("View Analytics", "Track your performance and earnings", const Color(0xFFF3E5F5), Icons.bar_chart),
      ],
    );
  }

  Widget _userProfile() {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsPage(),
        ),
      );
    },
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFFF8B7D).withOpacity(0.8),
          backgroundImage: _currentUser?['avatarUrl'] != null 
              ? NetworkImage(_currentUser!['avatarUrl']) 
              : null,
          child: _currentUser?['avatarUrl'] == null 
              ? Text(_getInitials(_currentUser?['fullName']), 
                  style: const TextStyle(color: Colors.white, fontSize: 12))
              : null,
        ),
        const SizedBox(width: 8),
        Text(_currentUser?['fullName'] ?? "Author User", 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    ),
  );
}

String _getInitials(String? name) {
  if (name == null || name.isEmpty) return "AU";
  final parts = name.trim().split(' ');
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
}


  Widget _sectionCard({required String title, Widget? action, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.dmSerifDisplay(fontSize: 22, fontWeight: FontWeight.bold)),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _ctaCard(String title, String desc, Color color, IconData icon) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.dmSerifDisplay(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

// NOTE: Sidebar class has been removed from this file because 
// it is now provided by Navigation.dart

// --- REMAINING HELPER CLASSES (StatCard, ManuscriptTile, ActivityItem) ---
class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final bool isLoading;
  const StatCard({
    super.key, 
    required this.title, 
    required this.value, 
    required this.icon, 
    required this.color,
    this.isLoading = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20)),
        const SizedBox(height: 15),
        isLoading 
          ? const SizedBox(height: 33, width: 33, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ]),
    );
  }
}

class ManuscriptTile extends StatelessWidget {
  final String title, time, status, authorName;
  final String? authorAvatarUrl;
  final int chapters, collaborators;
  final Color statusColor;
  const ManuscriptTile({
    super.key, 
    required this.title, 
    required this.chapters, 
    required this.collaborators, 
    required this.time, 
    required this.status, 
    required this.statusColor,
    required this.authorName,
    this.authorAvatarUrl,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade100), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Row(children: [
            CircleAvatar(
              radius: 8,
              backgroundImage: authorAvatarUrl != null ? NetworkImage(authorAvatarUrl!) : null,
              backgroundColor: const Color(0xFFFF8B7D).withOpacity(0.2),
              child: authorAvatarUrl == null ? Text(authorName[0].toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)) : null,
            ),
            const SizedBox(width: 4),
            Text(authorName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(width: 15),
            Icon(Icons.description_outlined, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4), Text("$chapters chapters", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(width: 15), Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4), Text("$collaborators collaborators", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4), Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ]),
        ]),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}

class ActivityItem extends StatelessWidget {
  final String name, action, story, time;
  final Color color;
  const ActivityItem({super.key, required this.name, required this.action, required this.story, required this.time, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.2), child: Text(name[0], style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 13), children: [TextSpan(text: "$name ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: "$action ")])),
          Text(story, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ])),
      ]),
    );
  }
}