import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ReadingPage.dart';
import 'SettingsPage.dart';
// AdminDashBoard import removed
import 'package:yourtales/Notifications.dart';
import 'services/auth_service.dart';
import 'services/manuscript_service.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  Map<String, dynamic>? _currentUser;
  List<dynamic> _manuscripts = [];
  bool _isLoadingUser = false;
  bool _isLoadingBooks = false;
  int _currentIndex = 0; // 0: Store, 1: Library, 2: Settings

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() => _isLoadingBooks = true);
    final response = await ManuscriptService.getAllManuscripts();
    if (mounted) {
      setState(() {
        _manuscripts = response['manuscripts'] ?? [];
        _isLoadingBooks = false;
      });
    }
  }

  Future<void> _loadUser() async {
    setState(() => _isLoadingUser = true);
    final user = await AuthService.getUser();
    setState(() {
      _currentUser = user;
      _isLoadingUser = false;
    });

    // Refresh in background
    final profileResponse = await AuthService.refreshUserProfile();
    if (profileResponse['user'] != null) {
      if (mounted) {
        setState(() => _currentUser = profileResponse['user']);
      }
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;
    
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      ).then((_) => setState(() => _currentIndex = 0)); // Reset when coming back
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: !isDesktop,
        title: _buildAppBarContent(context, isDesktop),
        actions: isDesktop ? const [SizedBox(width: 20)] : [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
            icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF1D2939)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            if (!isDesktop) _buildMobileCategories(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 60 : 16,
                vertical: isDesktop ? 40 : 24,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop)
                    const SizedBox(width: 260, child: CategorySidebar()),
                  if (isDesktop) const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGridHeader(isDesktop),
                        const SizedBox(height: 24),
                        _buildBookGrid(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop ? null : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: const Color(0xFFFF8B7D),
        unselectedItemColor: Colors.blueGrey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined), label: "Store"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_stories_outlined), label: "Library"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
        ],
      ),
    );
  }

  Widget _buildAppBarContent(BuildContext context, bool isDesktop) {
    if (!isDesktop) {
      return Row(
        children: [
          const Icon(Icons.auto_stories, color: Color(0xFF1D2939), size: 24),
          const SizedBox(width: 8),
          Text(
            "YourTales",
            style: GoogleFonts.dmSerifDisplay(
              color: const Color(0xFF1D2939),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Logo
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              const Icon(
                Icons.auto_stories,
                color: Color(0xFF1D2939),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                "YourTales",
                style: GoogleFonts.dmSerifDisplay(
                  color: const Color(0xFF1D2939),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Search Bar
        if (isDesktop)
          Container(
            width: 400, // Reduced slightly to accommodate more buttons
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Search books, authors...",
                prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        const Spacer(),
        // Links
        TextButton(
          onPressed: () {},
          child: const Text(
            "Library",
            style: TextStyle(color: Colors.blueGrey),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8B7D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Get Premium",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),

        // --- NOTIFICATIONS ---
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
          icon: const Icon(Icons.notifications_none_outlined, color: Colors.blueGrey),
        ),

        // --- PROFILE BUTTON ---
        const SizedBox(width: 15),
        GestureDetector(
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
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF8B7D).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFF8B7D),
                  backgroundImage: _currentUser?['avatarUrl'] != null 
                      ? NetworkImage(_currentUser!['avatarUrl']) 
                      : null,
                  child: _currentUser?['avatarUrl'] == null 
                      ? Text(_getInitials(_currentUser?['fullName']), 
                          style: const TextStyle(color: Colors.white, fontSize: 10))
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              if (isDesktop)
                Text(
                  _currentUser?['fullName'] ?? "Reader",
                  style: const TextStyle(
                    color: Color(0xFF1D2939),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCategories() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _mobileCategoryChip("All Books", Icons.dashboard_outlined, isActive: true),
          _mobileCategoryChip("Free", Icons.card_giftcard_outlined),
          _mobileCategoryChip("Fiction", Icons.auto_awesome_outlined),
          _mobileCategoryChip("Fantasy", Icons.auto_fix_high_outlined),
          _mobileCategoryChip("Sci-Fi", Icons.rocket_launch_outlined),
        ],
      ),
    );
  }

  Widget _mobileCategoryChip(String label, IconData icon, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(label),
        avatar: Icon(icon, size: 16, color: isActive ? Colors.white : Colors.blueGrey),
        selected: isActive,
        onSelected: (bool selected) {},
        selectedColor: const Color(0xFFFF8B7D),
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.blueGrey,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isActive ? Colors.transparent : Colors.grey.shade200),
        ),
      ),
    );
  }


  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "RE";
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
  }

  // --- REST OF THE UI (Hero, Grid, etc.) ---

  Widget _buildHeroSection(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      width: double.infinity,
      height: isMobile ? 320 : 450,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage(
            "https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&q=80&w=2000",
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.55),
            BlendMode.darken,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.dmSerifDisplay(
                fontSize: isMobile ? 36 : 64,
                color: Colors.white,
                height: 1.1,
              ),
              children: const [
                TextSpan(text: "Discover Your Next\n"),
                TextSpan(
                  text: "Great Read",
                  style: TextStyle(color: Color(0xFFFF8B7D)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Explore thousands of e-books from talented authors worldwide",
            style: TextStyle(color: Colors.white70, fontSize: isMobile ? 16 : 20),
          ),
          SizedBox(height: isMobile ? 25 : 40),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8B7D),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 30,
                    vertical: isMobile ? 16 : 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isMobile ? "Bestsellers" : "Browse Bestsellers",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 15),
              if (!isMobile)
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white60, width: 1.5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.black26,
                  ),
                  child: const Text("Free Books"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridHeader(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "All Books",
          style: GoogleFonts.dmSerifDisplay(
            fontSize: isDesktop ? 32 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isDesktop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Text("Sort by: Featured", style: TextStyle(fontSize: 14)),
                SizedBox(width: 10),
                Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBookGrid(BuildContext context) {
    if (_isLoadingBooks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_manuscripts.isEmpty) {
      return const Center(child: Text("No books available yet."));
    }

    double width = MediaQuery.of(context).size.width;
    int crossAxisCount =
        width > 1600 ? 5 : (width > 1200 ? 4 : (width > 700 ? 2 : 1));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 30,
        mainAxisSpacing: 40,
        childAspectRatio: 0.65,
      ),
      itemCount: _manuscripts.length,
      itemBuilder: (context, index) {
        final item = _manuscripts[index];
        return BookCard(manuscript: item);
      },
    );
  }
}

// --- SIDEBAR & CARD COMPONENTS ---

class CategorySidebar extends StatelessWidget {
  const CategorySidebar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Categories",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 25),
          _catItem("All Books", Icons.dashboard_outlined, isActive: true),
          _catItem("Free Books", Icons.card_giftcard_outlined),
          _catItem("Fiction", Icons.auto_awesome_outlined),
          _catItem("Fantasy", Icons.auto_fix_high_outlined),
          _catItem("Sci-Fi", Icons.rocket_launch_outlined),
          _catItem("Romance", Icons.favorite_border),
          _catItem("Mystery", Icons.search),
        ],
      ),
    );
  }

  Widget _catItem(String label, IconData icon, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFF8B7D) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isActive ? Colors.white : Colors.blueGrey.shade400,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.blueGrey.shade700,
            fontSize: 15,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final dynamic manuscript;
  const BookCard({super.key, required this.manuscript});

  @override
  Widget build(BuildContext context) {
    final title = manuscript['title'] ?? 'Untitled';
    final author = manuscript['author']?['fullName'] ?? 'Unknown Author';
    final coverUrl = manuscript['coverUrl'] ?? "https://picsum.photos/seed/${title.hashCode}/500/800";
    const String price = "Free"; // Backend logic for price needed later
    bool isFree = true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(coverUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade400,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "New",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundImage: manuscript['author']?['avatarUrl'] != null 
                          ? NetworkImage(manuscript['author']['avatarUrl']) 
                          : null,
                      backgroundColor: const Color(0xFFFF8B7D).withOpacity(0.2),
                      child: manuscript['author']?['avatarUrl'] == null 
                          ? Text(author[0].toUpperCase(), 
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)) 
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "by $author",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 5),
                    const Text(
                      "4.5", // Static for now
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      " (12 reviews)", // Static for now
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReaderPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade100.withOpacity(0.5),
                        foregroundColor: Colors.teal.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Read Now",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- PLACEHOLDER SETTINGS PAGE ---

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Settings")),
      body: const Center(child: Text("Settings Content Here")),
    );
  }
}
