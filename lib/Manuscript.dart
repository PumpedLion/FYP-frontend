import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- IMPORTS ---
import 'CreateManuscript.dart';
import 'EditManuscript.dart'; // <--- ADD THIS IMPORT

import 'services/manuscript_service.dart';

class ManuscriptsContent extends StatefulWidget {
  const ManuscriptsContent({super.key});

  @override
  State<ManuscriptsContent> createState() => _ManuscriptsContentState();
}

class _ManuscriptsContentState extends State<ManuscriptsContent> {
  List<dynamic> _manuscripts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchManuscripts();
  }

  Future<void> _fetchManuscripts() async {
    setState(() => _isLoading = true);
    final response = await ManuscriptService.getMyManuscripts();
    setState(() {
      _manuscripts = response['manuscripts'] ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 30),
          _buildFilterBar(),
          const SizedBox(height: 30),
          _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _buildManuscriptGrid(context),
        ],
      ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("My Manuscripts",
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 32, fontWeight: FontWeight.bold)),
            Text("Manage and organize your writing projects",
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // --- FILTER & VIEW TOGGLE BAR ---
  Widget _buildFilterBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 12,
          children: const [
            FilterTab(label: "All", isActive: true),
            FilterTab(label: "Draft"),
            FilterTab(label: "In Progress"),
            FilterTab(label: "Published"),
          ],
        ),
        Row(
          children: [
            _viewIcon(Icons.grid_view_rounded, true),
            const SizedBox(width: 8),
            _viewIcon(Icons.format_list_bulleted_rounded, false),
          ],
        )
      ],
    );
  }

  Widget _viewIcon(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFFF8B7D).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isActive ? const Color(0xFFFF8B7D) : Colors.grey.shade300),
      ),
      child: Icon(icon,
          color: isActive ? const Color(0xFFFF8B7D) : Colors.grey, size: 20),
    );
  }

  // --- GRID OF CARDS ---
  Widget _buildManuscriptGrid(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 1400 ? 3 : (width > 850 ? 2 : 1);

    if (_manuscripts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text("No manuscripts found. Start by creating a new one!"),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 25,
        mainAxisSpacing: 25,
        childAspectRatio: 0.82,
      ),
      itemCount: _manuscripts.length,
      itemBuilder: (context, index) {
        final item = _manuscripts[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditManuscriptPage(
                  title: item['title'] ?? 'Untitled',
                  manuscriptId: item['id'],
                ),
              ),
            );
          },
          child: ManuscriptCard(
            title: item['title'] ?? 'Untitled',
            authorName: item['author']?['fullName'] ?? 'Unknown',
            authorAvatarUrl: item['author']?['avatarUrl'],
            tags: List<String>.from(item['tags'] ?? []),
            status: "In Progress",
            statusColor: Colors.blue,
            words: "Unknown", // Word count needs backend tracking
            chapters: (item['chapters'] as List?)?.length ?? 0,
          ),
        );
      },
    );
  }
}

// ==========================================
// REMAINDER OF COMPONENTS (ManuscriptCard, FilterTab, etc.)
// ==========================================

class ManuscriptCard extends StatelessWidget {
  final String title, status, words, authorName;
  final String? authorAvatarUrl;
  final List<String> tags;
  final Color statusColor;
  final int chapters;

  const ManuscriptCard({
    super.key,
    required this.title,
    required this.tags,
    required this.status,
    required this.statusColor,
    required this.words,
    required this.chapters,
    required this.authorName,
    this.authorAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion( // Added MouseRegion to show a pointer on PC
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      image: DecorationImage(
                        image: NetworkImage(
                            "https://picsum.photos/seed/${title.hashCode}/600/400"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(status,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
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
                  Text(title,
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF8B7D))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: tags.map((tag) => _tagWidget(tag)).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statItem(Icons.description_outlined, "$chapters chapters"),
                      _statItem(Icons.text_fields_rounded, "$words words"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundImage: authorAvatarUrl != null ? NetworkImage(authorAvatarUrl!) : null,
                            backgroundColor: const Color(0xFFFF8B7D).withOpacity(0.2),
                            child: authorAvatarUrl == null ? Text(authorName[0].toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)) : null,
                          ),
                          const SizedBox(width: 6),
                          Text(authorName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                      _statItem(Icons.access_time, "2 hours ago"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagWidget(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }
}

class FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  const FilterTab({super.key, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFF8B7D) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (!isActive)
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)
        ],
      ),
      child: Text(label,
          style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14)),
    );
  }
}