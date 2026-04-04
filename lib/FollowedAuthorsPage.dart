import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/user_service.dart';
import 'services/auth_service.dart';

class FollowedAuthorsPage extends StatefulWidget {
  const FollowedAuthorsPage({super.key});

  @override
  State<FollowedAuthorsPage> createState() => _FollowedAuthorsPageState();
}

class _FollowedAuthorsPageState extends State<FollowedAuthorsPage> {
  List<dynamic> _authors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowedAuthors();
  }

  Future<void> _fetchFollowedAuthors() async {
    final user = await AuthService.getUser();
    if (user != null) {
      final response = await UserService.getFollowing(user['id']);
      if (mounted) {
        setState(() {
          _authors = response['following'] ?? [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unfollowAuthor(int authorId) async {
    await UserService.unfollowUser(authorId);
    _fetchFollowedAuthors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: Text(
          "Followed Authors",
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
          : _authors.isEmpty
              ? _buildEmptyState()
              : _buildAuthorsList(),
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
            "You aren't following any authors yet",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _authors.length,
      itemBuilder: (context, index) {
        final author = _authors[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFFF8B7D).withOpacity(0.1),
              backgroundImage: author['avatarUrl'] != null
                  ? NetworkImage(author['avatarUrl'].toString().startsWith('/uploads/') ? 'http://localhost:8000${author['avatarUrl']}' : author['avatarUrl'])
                  : null,
              child: author['avatarUrl'] == null
                  ? Text(
                      author['fullName'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFF8B7D),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            title: Text(
              author['fullName'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              author['role'] ?? 'Author',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: OutlinedButton(
              onPressed: () => _unfollowAuthor(author['id']),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Unfollow", style: TextStyle(color: Colors.blueGrey)),
            ),
          ),
        );
      },
    );
  }
}
