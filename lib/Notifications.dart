import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/notification_service.dart';
import 'services/manuscript_service.dart';
import 'services/auth_service.dart';
import 'AdminDashBoard.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _activeFilter = "All";
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final response = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = response['notifications'] ?? [];
        _unreadCount = response['unreadCount'] ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    _fetchNotifications();
  }

  Future<void> _markAsRead(int id) async {
    await NotificationService.markAsRead(id);
    _fetchNotifications();
  }

  Future<void> _deleteNotification(int id) async {
    await NotificationService.deleteNotification(id);
    _fetchNotifications();
  }

  String _formatTime(String createdAt) {
    try {
      final DateTime dt = DateTime.parse(createdAt);
      final Duration diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return "${diff.inMinutes} minutes ago";
      if (diff.inHours < 24) return "${diff.inHours} hours ago";
      return DateFormat('MMM d, y').format(dt);
    } catch (e) {
      return "Just now";
    }
  }

  Map<String, dynamic> _getTheme(String type) {
    switch (type) {
      case 'COMMENT':
        return {'category': 'Comments', 'icon': Icons.chat_bubble_outline, 'color': Colors.orange.shade300, 'iconColor': Colors.white};
      case 'COLLABORATION':
        return {'category': 'Collaborations', 'icon': Icons.people_outline, 'color': Colors.blue.shade300, 'iconColor': Colors.white};
      case 'SALE':
        return {'category': 'Sales', 'icon': Icons.shopping_bag_outlined, 'color': Colors.green.shade300, 'iconColor': Colors.white};
      case 'MENTION':
        return {'category': 'Comments', 'icon': Icons.alternate_email, 'color': Colors.pink.shade300, 'iconColor': Colors.white};
      case 'SYSTEM':
      default:
        return {'category': 'System', 'icon': Icons.settings_outlined, 'color': Colors.grey.shade400, 'iconColor': Colors.white};
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _activeFilter == "All"
        ? _notifications
        : _notifications.where((n) {
            final theme = _getTheme(n['type']);
            return theme['category'] == _activeFilter;
          }).toList();

    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D2939)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: isMobile,
        title: Text(
          "Notifications",
          style: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF1D2939),
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 20 : 22,
          ),
        ),
        actions: [
          if (!isMobile)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18, color: Color(0xFFFF8B7D)),
              label: const Text("Mark all as read",
                  style: TextStyle(color: Color(0xFFFF8B7D), fontWeight: FontWeight.bold)),
            )
          else
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Color(0xFFFF8B7D)),
              tooltip: "Mark all as read",
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20, 
              vertical: isMobile ? 24 : 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You have $_unreadCount unread notifications",
                  style: TextStyle(color: Colors.grey, fontSize: isMobile ? 14 : 16),
                ),
                SizedBox(height: isMobile ? 20 : 30),

                // --- CATEGORY FILTERS ---
                isMobile ? _buildMobileFilters() : _buildFilterChips(),
                SizedBox(height: isMobile ? 20 : 30),

                // --- DYNAMIC LIST ---
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (filteredNotifications.isEmpty)
                  _buildEmptyState()
                else
                  _buildNotificationsList(filteredNotifications, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _categoryChip("All", icon: Icons.notifications_none),
        _categoryChip("Comments", icon: Icons.chat_bubble_outline),
        _categoryChip("Collaborations", icon: Icons.people_outline),
        _categoryChip("Sales", icon: Icons.shopping_bag_outlined),
        _categoryChip("System", icon: Icons.settings_outlined),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return SizedBox(
      height: 45,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryChip("All", icon: Icons.notifications_none, isMobile: true),
          _categoryChip("Comments", icon: Icons.chat_bubble_outline, isMobile: true),
          _categoryChip("Collaborations", icon: Icons.people_outline, isMobile: true),
          _categoryChip("Sales", icon: Icons.shopping_bag_outlined, isMobile: true),
          _categoryChip("System", icon: Icons.settings_outlined, isMobile: true),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, {required IconData icon, bool isMobile = false}) {
    bool isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label), // Change filter on tap
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: isMobile ? 10 : 0),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 15 : 20, 
          vertical: isMobile ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF8B7D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade200),
          boxShadow: [
            if (isActive) 
              BoxShadow(color: const Color(0xFFFF8B7D).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isMobile ? 16 : 18, color: isActive ? Colors.white : Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.blueGrey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List filteredList, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: filteredList.map((item) {
          final theme = _getTheme(item['type']);
          return _notificationTile(
            id: item['id'],
            title: item['title'],
            subtitle: item['message'], // Backend uses 'message'
            time: _formatTime(item['createdAt']),
            icon: theme['icon'],
            avatarColor: theme['color'],
            iconColor: theme['iconColor'],
            isUnread: !item['isRead'],
            type: item['type'],
            data: item['data'], // Pass the data payload
            isMobile: isMobile,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No notifications in $_activeFilter", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToInvitation(int notificationId, int collaborationId, String status) async {
    final response = await ManuscriptService.respondToInvitation(collaborationId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Response sent')),
      );

      if (status == 'ACCEPTED') {
        // Refresh profile to get the new role
        final profileResponse = await AuthService.refreshUserProfile();
        if (profileResponse['user'] != null) {
          final String role = profileResponse['user']['role'];
          if (role != 'READER' && mounted) {
            // Redirect to Dashboard if they are now an Author/Editor
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
            return;
          }
        }
      }

      // Mark notification as read after responding
      await _markAsRead(notificationId);
    }
  }

  Widget _notificationTile({
    required int id,
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color avatarColor,
    required Color iconColor,
    required bool isUnread,
    required String type,
    dynamic data,
    bool isMobile = false,
  }) {
    bool hasCollaborationActions = type == "COLLABORATION" && isUnread && data != null && data['collaborationId'] != null;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isMobile ? 20 : 24,
            backgroundColor: avatarColor,
            child: Icon(icon, color: iconColor, size: isMobile ? 18 : 20),
          ),
          SizedBox(width: isMobile ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: isMobile ? 14 : 16
                        )
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: 8),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF8B7D), shape: BoxShape.circle)),
                    ]
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle, 
                  style: TextStyle(
                    color: Colors.blueGrey.shade600, 
                    height: 1.4,
                    fontSize: isMobile ? 13 : 14,
                  )
                ),
                const SizedBox(height: 8),
                Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                
                // Collaboration Actions (Mobile)
                if (isMobile && hasCollaborationActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _respondToInvitation(id, data['collaborationId'], 'ACCEPTED'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8B7D), 
                            foregroundColor: Colors.white, 
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Accept"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _respondToInvitation(id, data['collaborationId'], 'DECLINED'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Decline"),
                        ),
                      ),
                    ],
                  ),
                ] else if (isMobile && isUnread) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _markAsRead(id),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey.shade50, 
                        side: BorderSide(color: Colors.grey.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text("Mark as Read", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Actions (Desktop)
          if (!isMobile) ...[
            if (hasCollaborationActions)
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _respondToInvitation(id, data['collaborationId'], 'ACCEPTED'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8B7D), foregroundColor: Colors.white, elevation: 0),
                    child: const Text("Accept"),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _respondToInvitation(id, data['collaborationId'], 'DECLINED'),
                    child: const Text("Decline"),
                  ),
                ],
              )
            else if (isUnread)
              OutlinedButton(
                onPressed: () => _markAsRead(id),
                style: OutlinedButton.styleFrom(backgroundColor: Colors.grey.shade50, side: BorderSide(color: Colors.grey.shade200)),
                child: const Text("Read", style: TextStyle(color: Colors.blueGrey)),
              ),
            const SizedBox(width: 10),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text("Delete"),
                  onTap: () => _deleteNotification(id),
                ),
              ],
            ),
          ] else
            // Popup menu for mobile always at end
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text("Delete"),
                  onTap: () => _deleteNotification(id),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
