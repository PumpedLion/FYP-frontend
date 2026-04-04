import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/user_service.dart';
import 'services/auth_service.dart';

class FollowersPage extends StatefulWidget {
  const FollowersPage({super.key});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  List<dynamic> _followers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    final user = await AuthService.getUser();
    if (user != null) {
      final response = await UserService.getFollowers(user['id']);
      if (mounted) {
        setState(() {
          _followers = response['followers'] ?? [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: Text(
          "Followers",
          style: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF1D2939),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D2939)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followers.isEmpty
              ? _buildEmptyState()
              : _buildFollowersList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "You don't have any followers yet",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final follower = _followers[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFFF8B7D).withOpacity(0.1),
              backgroundImage: follower['avatarUrl'] != null
                  ? NetworkImage(follower['avatarUrl'].toString().startsWith('/uploads/') ? 'http://localhost:8000${follower['avatarUrl']}' : follower['avatarUrl'])
                  : null,
              child: follower['avatarUrl'] == null
                  ? Text(
                      follower['fullName'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFF8B7D),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            title: Text(
              follower['fullName'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              follower['role'] ?? 'User',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        );
      },
    );
  }
}
