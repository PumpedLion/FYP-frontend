import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/chapter_service.dart';
import 'services/comment_service.dart';
import 'services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// READING PAGE  (fully live — real chapter content + comments + reviews)
// ─────────────────────────────────────────────────────────────────────────────

class ReaderPage extends StatefulWidget {
  final int manuscriptId;
  final int chapterId;
  final String manuscriptTitle;
  final List<dynamic> allChapters; // ordered list from ChapterService

  const ReaderPage({
    super.key,
    required this.manuscriptId,
    required this.chapterId,
    required this.manuscriptTitle,
    required this.allChapters,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  // ── state ──────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _chapter;
  bool _isLoadingChapter = true;
  late int _currentChapterId;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentChapterId = widget.chapterId;
    _loadUser();
    _fetchChapter(_currentChapterId);
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _fetchChapter(int id) async {
    setState(() => _isLoadingChapter = true);
    final res = await ChapterService.getChapterById(id);
    if (mounted) {
      setState(() {
        _chapter = res['chapter'] ?? res;
        _isLoadingChapter = false;
      });
    }
  }

  // ── chapter navigation ─────────────────────────────────────────────────────
  int get _currentIndex =>
      widget.allChapters.indexWhere((c) => c['id'] == _currentChapterId);

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex < widget.allChapters.length - 1;

  void _goToPrev() {
    if (_hasPrev) {
      final prev = widget.allChapters[_currentIndex - 1];
      setState(() => _currentChapterId = prev['id']);
      _fetchChapter(prev['id']);
    }
  }

  void _goToNext() {
    if (_hasNext) {
      final next = widget.allChapters[_currentIndex + 1];
      setState(() => _currentChapterId = next['id']);
      _fetchChapter(next['id']);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final chapterTitle = _chapter?['title'] ?? 'Loading…';
    final chapterContent = _chapter?['content'] ?? '';
    final totalChapters = widget.allChapters.length;
    final chapterNum = _currentIndex >= 0 ? _currentIndex + 1 : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(context, chapterTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEngagementSheet(context),
        backgroundColor: const Color(0xFFFF8B7D),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Comments & Reviews'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingChapter
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 40 : 20,
                          vertical: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapterTitle,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: isDesktop ? 42 : 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1D2939),
                              ),
                            ),
                            const SizedBox(height: 40),
                            if (chapterContent.isEmpty)
                              Text(
                                'This chapter has no content yet.',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  height: 1.8,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              ..._buildParagraphs(chapterContent),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          _buildFooter(context, chapterNum, totalChapters),
        ],
      ),
    );
  }

  List<Widget> _buildParagraphs(String content) {
    return content
        .split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 25.0),
              child: Text(
                p.trim(),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  height: 1.8,
                  color: const Color(0xFF344054),
                ),
              ),
            ))
        .toList();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String chapterTitle) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            widget.manuscriptTitle,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            chapterTitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, int chapterNum, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _hasPrev ? _goToPrev : null,
            icon: Icon(Icons.chevron_left,
                color: _hasPrev ? Colors.black87 : Colors.grey),
            label: Text('Prev',
                style: TextStyle(
                    color: _hasPrev ? Colors.black87 : Colors.grey)),
          ),
          Text(
            'Chapter $chapterNum of $total',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          TextButton.icon(
            onPressed: _hasNext ? _goToNext : null,
            icon: Icon(Icons.chevron_right,
                color: _hasNext ? Colors.black87 : Colors.grey),
            label: Text('Next',
                style: TextStyle(
                    color: _hasNext ? Colors.black87 : Colors.grey)),
          ),
        ],
      ),
    );
  }

  // ── Comments & Reviews Bottom Sheet ──────────────────────────────────────────
  void _openEngagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderEngagementSheet(
        chapterId: _currentChapterId,
        currentUser: _currentUser,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// READER ENGAGEMENT SHEET  (Comments tab + Reviews tab)
// ─────────────────────────────────────────────────────────────────────────────

class ReaderEngagementSheet extends StatefulWidget {
  final int chapterId;
  final Map<String, dynamic>? currentUser;

  const ReaderEngagementSheet({
    super.key,
    required this.chapterId,
    required this.currentUser,
  });

  @override
  State<ReaderEngagementSheet> createState() => _ReaderEngagementSheetState();
}

class _ReaderEngagementSheetState extends State<ReaderEngagementSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Comments state ─────────────────────────────────────────────────────────
  List<dynamic> _comments = [];
  bool _loadingComments = true;
  final _commentCtrl = TextEditingController();
  bool _submittingComment = false;

  // ── Reviews state ──────────────────────────────────────────────────────────
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;
  final _reviewCtrl = TextEditingController();
  double _selectedRating = 5;
  bool _submittingReview = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchComments();
    _fetchReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  // ── Data methods ───────────────────────────────────────────────────────────

  Future<void> _fetchComments() async {
    setState(() => _loadingComments = true);
    final res = await CommentService.getCommentsByChapter(widget.chapterId,
        type: 'READER');
    if (mounted) {
      setState(() {
        _comments = res['comments'] ?? [];
        _loadingComments = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submittingComment = true);
    final res =
        await CommentService.addComment(widget.chapterId, text, type: 'READER');
    if (mounted) {
      if (res['comment'] != null) {
        _commentCtrl.clear();
        await _fetchComments();
      } else {
        _showSnack(res['message'] ?? 'Failed to post comment');
      }
      setState(() => _submittingComment = false);
    }
  }

  Future<void> _deleteComment(int id) async {
    await CommentService.deleteComment(id);
    _fetchComments();
  }

  Future<void> _fetchReviews() async {
    setState(() => _loadingReviews = true);
    final res = await CommentService.getReviewsByChapter(widget.chapterId);
    if (mounted) {
      setState(() {
        _reviews = res['reviews'] ?? [];
        _loadingReviews = false;
      });
    }
  }

  Future<void> _submitReview() async {
    final text = _reviewCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submittingReview = true);
    final res =
        await CommentService.addReview(widget.chapterId, text, _selectedRating);
    if (mounted) {
      if (res['review'] != null) {
        _reviewCtrl.clear();
        setState(() => _selectedRating = 5);
        await _fetchReviews();
      } else {
        _showSnack(res['message'] ?? 'Failed to post review');
      }
      setState(() => _submittingReview = false);
    }
  }

  Future<void> _deleteReview(int id) async {
    await CommentService.deleteReview(id);
    _fetchReviews();
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  int? get _currentUserId => widget.currentUser?['id'];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF8B7D),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF8B7D),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 18),
                      const SizedBox(width: 6),
                      Text('Comments (${_comments.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_outline, size: 18),
                      const SizedBox(width: 6),
                      Text('Reviews (${_reviews.length})'),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCommentsTab(scrollController),
                  _buildReviewsTab(scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Comments Tab ───────────────────────────────────────────────────────────

  Widget _buildCommentsTab(ScrollController sc) {
    return Column(
      children: [
        Expanded(
          child: _loadingComments
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? _emptyState(
                      'No comments yet. Be the first!',
                      Icons.chat_bubble_outline,
                    )
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => _commentTile(_comments[i]),
                    ),
        ),
        if (widget.currentUser != null) _buildCommentInput(),
      ],
    );
  }

  Widget _commentTile(dynamic c) {
    final author = c['author'] ?? {};
    final name = author['fullName'] ?? 'Anonymous';
    final isOwn = _currentUserId != null &&
        (c['authorId'] == _currentUserId || author['id'] == _currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFF8B7D).withOpacity(0.2),
            backgroundImage: author['avatarUrl'] != null
                ? NetworkImage(author['avatarUrl'].toString().startsWith('/uploads/') ? 'http://localhost:8000${author['avatarUrl']}' : author['avatarUrl'])
                : null,
            child: author['avatarUrl'] == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8B7D)),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    if (isOwn)
                      GestureDetector(
                        onTap: () => _deleteComment(c['id']),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c['content'] ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF344054),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Write a comment…',
                filled: true,
                fillColor: const Color(0xFFF9FBFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _submittingComment
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send_rounded),
                  color: const Color(0xFFFF8B7D),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFFF8B7D).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Reviews Tab ────────────────────────────────────────────────────────────

  Widget _buildReviewsTab(ScrollController sc) {
    return Column(
      children: [
        Expanded(
          child: _loadingReviews
              ? const Center(child: CircularProgressIndicator())
              : _reviews.isEmpty
                  ? _emptyState(
                      'No reviews yet. Share your thoughts!',
                      Icons.star_outline,
                    )
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _reviews.length,
                      itemBuilder: (_, i) => _reviewTile(_reviews[i]),
                    ),
        ),
        if (widget.currentUser != null) _buildReviewInput(),
      ],
    );
  }

  Widget _reviewTile(dynamic r) {
    final author = r['author'] ?? {};
    final name = author['fullName'] ?? 'Anonymous';
    final rating = (r['rating'] as num?)?.toDouble() ?? 0;
    final isOwn = _currentUserId != null &&
        (r['authorId'] == _currentUserId || author['id'] == _currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.amber.shade100,
            backgroundImage: author['avatarUrl'] != null
                ? NetworkImage(author['avatarUrl'].toString().startsWith('/uploads/') ? 'http://localhost:8000${author['avatarUrl']}' : author['avatarUrl'])
                : null,
            child: author['avatarUrl'] == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    if (isOwn)
                      GestureDetector(
                        onTap: () => _deleteReview(r['id']),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _starRow(rating),
                const SizedBox(height: 6),
                Text(r['content'] ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF344054),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _starRow(double rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildReviewInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Your rating:',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 10),
              ...List.generate(5, (i) {
                final starVal = i + 1.0;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = starVal),
                  child: Icon(
                    starVal <= _selectedRating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 28,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _reviewCtrl,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Write your review…',
                    filled: true,
                    fillColor: const Color(0xFFFFFBF5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.amber.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.amber.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _submittingReview
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      onPressed: _submitReview,
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.amber.shade700,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.amber.shade100,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
