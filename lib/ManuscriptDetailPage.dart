import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/chapter_service.dart';
import 'services/user_service.dart';
import 'services/auth_service.dart';
import 'services/payment_service.dart';
import 'PaymentPage.dart';
import 'ReadingPage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MANUSCRIPT DETAIL PAGE
// Shows cover, description, chapter list → tapping a chapter opens ReaderPage
// ─────────────────────────────────────────────────────────────────────────────

class ManuscriptDetailPage extends StatefulWidget {
  final dynamic manuscript; // full manuscript object from API

  const ManuscriptDetailPage({super.key, required this.manuscript});

  @override
  State<ManuscriptDetailPage> createState() => _ManuscriptDetailPageState();
}

class _ManuscriptDetailPageState extends State<ManuscriptDetailPage> {
  List<dynamic> _chapters = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isPurchased = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchChapters();
    _checkPurchaseStatus();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user['id'];
      });
      _checkFollowStatus();
    }
  }

  Future<void> _checkFollowStatus() async {
    final authorId = widget.manuscript['authorId'] ?? widget.manuscript['author']?['id'];
    if (authorId != null) {
      final following = await UserService.isFollowing(authorId);
      if (mounted) {
        setState(() => _isFollowing = following);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final authorId = widget.manuscript['authorId'] ?? widget.manuscript['author']?['id'];
    if (authorId == null) return;

    if (_isFollowing) {
      await UserService.unfollowUser(authorId);
    } else {
      await UserService.followUser(authorId);
    }
    _checkFollowStatus();
  }

  Future<void> _checkPurchaseStatus() async {
    final price = (widget.manuscript['price'] ?? 0).toDouble();
    if (price <= 0) {
      // Free — no need to check
      setState(() => _isPurchased = true);
      return;
    }
    final purchased = await PaymentService.checkPurchase(widget.manuscript['id']);
    if (mounted) setState(() => _isPurchased = purchased);
  }

  Future<void> _fetchChapters() async {
    final id = widget.manuscript['id'];
    final res = await ChapterService.getChaptersByManuscript(id);
    if (mounted) {
      setState(() {
        _chapters = res['chapters'] ?? [];
        _isLoading = false;
      });
    }
  }

  void _openChapter(int chapterId) {
    final price = (widget.manuscript['price'] ?? 0).toDouble();
    if (price > 0 && !_isPurchased) {
      _openPaymentPage();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          manuscriptId: widget.manuscript['id'],
          chapterId: chapterId,
          manuscriptTitle: widget.manuscript['title'] ?? 'Untitled',
          allChapters: _chapters,
        ),
      ),
    );
  }

  Future<void> _openPaymentPage() async {
    final purchased = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PaymentPage(manuscript: widget.manuscript)),
    );
    if (purchased == true && mounted) {
      setState(() => _isPurchased = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.manuscript['title'] ?? 'Untitled';
    final author =
        widget.manuscript['author']?['fullName'] ?? 'Unknown Author';
    final description =
        widget.manuscript['description'] ?? 'No description available.';
    final coverUrl = widget.manuscript['coverUrl'] ??
        'https://picsum.photos/seed/${title.hashCode}/500/800';
    final tags = List<String>.from(widget.manuscript['tags'] ?? []);
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: isDesktop ? 380 : 280,
            pinned: true,
            backgroundColor: const Color(0xFF1D2939),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(coverUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white,
                            fontSize: isDesktop ? 36 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'by $author',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 15),
                            ),
                            const SizedBox(width: 12),
                            if (_currentUserId != null && widget.manuscript['author']?['id'] != _currentUserId)
                              _buildFollowButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 20,
                vertical: 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8B7D)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFFF8B7D)
                                          .withOpacity(0.3)),
                                ),
                                child: Text(t,
                                    style: const TextStyle(
                                        color: Color(0xFFFF8B7D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 16),

                  // Price badge
                  Builder(builder: (_) {
                    final price = (widget.manuscript['price'] ?? 0).toDouble();
                    final isFree = price <= 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isFree
                            ? Colors.green.shade50
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isFree ? Colors.green.shade300 : const Color(0xFFFF8B7D).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFree ? Icons.lock_open_rounded : Icons.monetization_on_rounded,
                            size: 14,
                            color: isFree ? Colors.green.shade600 : const Color(0xFFFF8B7D),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFree ? 'Free' : '\$${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isFree ? Colors.green.shade700 : const Color(0xFFFF8B7D),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'About this book',
                    style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22, color: const Color(0xFF1D2939)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Color(0xFF4A5568)),
                  ),
                  const SizedBox(height: 36),

                  // Chapter list header
                  Row(
                    children: [
                      Text(
                        'Chapters',
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22, color: const Color(0xFF1D2939)),
                      ),
                      const SizedBox(width: 10),
                      if (!_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8B7D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_chapters.length}',
                            style: const TextStyle(
                                color: Color(0xFFFF8B7D),
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chapter list
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_chapters.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'No chapters published yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...List.generate(_chapters.length, (i) {
                      final ch = _chapters[i];
                      return _chapterTile(ch, i + 1);
                    }),

                  const SizedBox(height: 40),

                  // Read First Chapter CTA
                  if (_chapters.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: Builder(builder: (ctx) {
                        final price = (widget.manuscript['price'] ?? 0).toDouble();
                        final isPaidLocked = price > 0 && !_isPurchased;
                        return Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => isPaidLocked ? _openPaymentPage() : _openChapter(_chapters[0]['id']),
                              icon: Icon(isPaidLocked ? Icons.lock_open_rounded : Icons.menu_book_outlined),
                              label: Text(isPaidLocked ? 'Unlock Manuscript — NPR ${price.toStringAsFixed(0)}' : 'Start Reading'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPaidLocked ? const Color(0xFF5C2D91) : const Color(0xFFFF8B7D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (_isPurchased && price > 0) ...
                            [
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await PaymentService.downloadInvoice(widget.manuscript['id']);
                                },
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text('Download Invoice'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF8B7D),
                                  side: const BorderSide(color: Color(0xFFFF8B7D)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return InkWell(
      onTap: _toggleFollow,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _isFollowing ? Colors.white24 : const Color(0xFFFF8B7D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFollowing ? Icons.check : Icons.add,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chapterTile(dynamic ch, int num) {
    final price = (widget.manuscript['price'] ?? 0).toDouble();
    final isPaidLocked = price > 0 && !_isPurchased;
    return GestureDetector(
      onTap: () => _openChapter(ch['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isPaidLocked
                    ? Colors.grey.shade100
                    : const Color(0xFFFF8B7D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isPaidLocked
                    ? Icon(Icons.lock, size: 16, color: Colors.grey.shade400)
                    : Text('$num', style: const TextStyle(color: Color(0xFFFF8B7D), fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                ch['title'] ?? 'Chapter $num',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPaidLocked ? Colors.grey.shade400 : const Color(0xFF1D2939),
                ),
              ),
            ),
            Icon(
              isPaidLocked ? Icons.lock_outline : Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
