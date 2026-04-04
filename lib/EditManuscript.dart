import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'services/chapter_service.dart';
import 'services/manuscript_service.dart';
import 'services/comment_service.dart';
import 'services/suggested_edit_service.dart';
import 'package:intl/intl.dart';
import 'services/auth_service.dart';
import 'services/socket_service.dart';

class EditManuscriptPage extends StatefulWidget {
  final String title;
  final int manuscriptId;
  const EditManuscriptPage({super.key, this.title = "Untitled", required this.manuscriptId});

  @override
  State<EditManuscriptPage> createState() => _EditManuscriptPageState();
}

class _EditManuscriptPageState extends State<EditManuscriptPage> {
  final Color salmonColor = const Color(0xFFFF8B7D);
  final Color bgColor = const Color(0xFFF9FBFB);

  late QuillController _controller;
  final ValueNotifier<int> _wordCountNotifier = ValueNotifier<int>(0);

  List<dynamic> _chapters = [];
  dynamic _currentChapter;
  dynamic _manuscriptDetails;
  List<dynamic> _acceptedCollaborators = [];
  List<dynamic> _comments = [];
  List<dynamic> _suggestedEdits = [];
  bool _isLoadingChapters = false;
  bool _isLoadingComments = false;
  bool _isLoadingSuggestions = false;
  bool _isSaving = false;
  bool _isPublishing = false;
  int? _currentUserId;
  bool _isAuthor = false;
  bool _isEditor = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _controller.document.changes.listen((event) {
      _calculateWordCount();
    });
    _startTimer();
    _listenToComments();
    _listenToSuggestions();
    // IMPORTANT: fetch user first, THEN manuscript details so that
    // _currentUserId is set before _isAuthor / _isEditor are evaluated.
    _initData();
  }

  Future<void> _initData() async {
    await _getCurrentUser();     // Must complete first
    await _fetchManuscriptDetails(); // Now _currentUserId is guaranteed set
    _fetchChapters();
  }

  void _listenToComments() {
    SocketService.comments.listen((comment) {
      if (mounted && _currentChapter != null && comment['chapterId'] == _currentChapter['id']) {
        setState(() {
          _comments.add(comment);
        });
      }
    });
  }

  void _listenToSuggestions() {
    // Author receives new suggestion in real-time
    SocketService.suggestionNew.listen((data) {
      if (mounted && _currentChapter != null &&
          data['chapterId'] == _currentChapter['id']) {
        _fetchSuggestedEdits(_currentChapter['id']);
      }
    });

    // Editor receives resolution (accepted/declined) in real-time
    SocketService.suggestionResolved.listen((data) {
      if (mounted && _currentChapter != null &&
          data['chapterId'] == _currentChapter['id']) {
        final status = data['status']?.toString() ?? '';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Your suggested edit was ${status.toLowerCase()}.'),
          backgroundColor: status == 'ACCEPTED' ? Colors.green : Colors.redAccent,
        ));
        _fetchSuggestedEdits(_currentChapter['id']);
      }
    });

    // Chapter content updated after accept — reload editor for author
    SocketService.chapterContentUpdated.listen((data) {
      if (mounted && _currentChapter != null &&
          data['chapterId'] == _currentChapter['id']) {
        final newContent = data['content']?.toString() ?? '';
        setState(() {
          _currentChapter = {..._currentChapter, 'content': newContent};
          final displayContent = newContent.endsWith('\n') && newContent.length > 1
              ? newContent.substring(0, newContent.length - 1)
              : newContent;
          _controller = QuillController(
            document: displayContent.isEmpty
                ? Document()
                : (Document()..insert(0, displayContent)),
            selection: const TextSelection.collapsed(offset: 0),
          );
          _controller.document.changes.listen((_) => _calculateWordCount());
          _calculateWordCount();
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _getCurrentUser() async {
    final user = await AuthService.getUser();
    if (user != null) {
      setState(() {
        _currentUserId = user['id'];
      });
    }
  }

  Future<void> _fetchManuscriptDetails() async {
    final response = await ManuscriptService.getManuscriptById(widget.manuscriptId);
    if (response['manuscript'] != null) {
      setState(() {
        _manuscriptDetails = response['manuscript'];
        _isAuthor = _manuscriptDetails['authorId'] == _currentUserId;
        
        final allCollabs = _manuscriptDetails['collaborations'] as List<dynamic>? ?? [];
        _acceptedCollaborators = allCollabs.where((c) => c['status'] == 'ACCEPTED').toList();
        
        _isEditor = _acceptedCollaborators.any((c) => c['userId'] == _currentUserId && c['role'] == 'EDITOR');
      });
    }
  }

  Future<void> _fetchComments(int chapterId) async {
    setState(() => _isLoadingComments = true);
    final response = await CommentService.getCommentsByChapter(chapterId, type: 'EDITORIAL');
    setState(() {
      _comments = response['comments'] ?? [];
      _isLoadingComments = false;
    });
  }

  Future<void> _fetchSuggestedEdits(int chapterId) async {
    setState(() => _isLoadingSuggestions = true);
    final response = await SuggestedEditService.getSuggestedEdits(chapterId);
    setState(() {
      _suggestedEdits = response['suggestedEdits'] ?? [];
      _isLoadingSuggestions = false;
    });
  }

  Future<void> _fetchChapters() async {
    setState(() => _isLoadingChapters = true);
    final response = await ChapterService.getChaptersByManuscript(widget.manuscriptId);
    setState(() {
      _chapters = response['chapters'] ?? [];
      _isLoadingChapters = false;
      if (_chapters.isNotEmpty) {
        _selectChapter(_chapters.first);
      }
    });
  }

  void _selectChapter(dynamic chapter) {
    setState(() {
      _currentChapter = chapter;
      // Load content into editor cleanly.
      // We build a fresh Document from the raw text to avoid the
      // double-newline issue that occurs with `Document()..insert(0,text)`
      // (Quill's empty Document already contains a terminal \n at pos 0).
      final rawContent = (chapter['content'] ?? '').toString();
      // Strip a single trailing newline that Quill always appends on save
      // so it doesn't grow on every save-reload cycle.
      final displayContent = rawContent.endsWith('\n') && rawContent.length > 1
          ? rawContent.substring(0, rawContent.length - 1)
          : rawContent;
      _controller = QuillController(
        document: displayContent.isEmpty
            ? Document()
            : (Document()..insert(0, displayContent)),
        selection: const TextSelection.collapsed(offset: 0),
      );
      // Re-attach word count listener after replacing the controller
      _controller.document.changes.listen((_) => _calculateWordCount());
      _calculateWordCount();
    });
    _fetchComments(chapter['id']);
    _fetchSuggestedEdits(chapter['id']);

    // Join socket room for this chapter
    SocketService.joinChapter(chapter['id']);
  }

  Future<void> _saveCurrentChapter() async {
    if (_currentChapter == null) return;

    final content = _controller.document.toPlainText();

    // ── EDITOR: submit a suggested edit instead of saving directly ──
    if (_isEditor && !_isAuthor) {
      setState(() => _isSaving = true);
      final currentSaved = (_currentChapter['content'] ?? '').toString();
      if (content.trim() == currentSaved.trim()) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to suggest.'), backgroundColor: Colors.grey),
        );
        return;
      }
      final result = await SuggestedEditService.createSuggestedEdit(
        _currentChapter['id'],
        content,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        final bool success = result['suggestedEdit'] != null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Edit submitted for author review ✓'
              : (result['message'] ?? 'Failed to submit suggestion')),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ));
        if (success) _fetchSuggestedEdits(_currentChapter['id']);
      }
      return;
    }

    // ── AUTHOR: save directly ──
    setState(() => _isSaving = true);

    debugPrint('💾 Saving chapter ${_currentChapter['id']} | content length: ${content.length} | isAuthor: $_isAuthor | isEditor: $_isEditor | userId: $_currentUserId');

    final result = await ChapterService.updateChapter(_currentChapter['id'], {
      'content': content,
    });

    debugPrint('💾 Save result: $result');

    if (mounted) {
      final bool success = result['chapter'] != null;
      setState(() {
        _isSaving = false;
        if (success) {
          // Update the in-memory chapter list so re-selecting this chapter
          // loads the freshly saved content instead of the stale original.
          final savedContent = result['chapter']['content'] ?? content;
          _currentChapter = {..._currentChapter, 'content': savedContent};
          final idx = _chapters.indexWhere((c) => c['id'] == _currentChapter['id']);
          if (idx != -1) {
            _chapters[idx] = _currentChapter;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (success ? 'Saved successfully' : 'Failed to save')),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showPublishDialog() async {
    // Guard: Prevent publish if there are unsaved changes
    if (_currentChapter != null) {
      final currentText = _controller.document.toPlainText();
      final savedText = (_currentChapter['content'] ?? '').toString();
      final expectedText = savedText.endsWith('\n') ? savedText : '$savedText\n';
      
      debugPrint('📖 Publish guard | currentText: "${currentText.substring(0, currentText.length.clamp(0, 50))}" | savedText: "${savedText.substring(0, savedText.length.clamp(0, 50))}"');
      
      if (currentText.trim().isNotEmpty && currentText.trim() != savedText.trim()) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Unsaved Changes'),
                ],
              ),
              content: const Text('You have unsaved changes in the current chapter. Please click "Save Now" before publishing/updating the manuscript.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return; // Halt the publish flow
      }
    }

    // Guard: at least one chapter must have content
    final liveEditorText = _controller.document.toPlainText().trim();
    final hasContent = _chapters.any((c) {
      final content = c['content'];
      return content != null && content.toString().trim().isNotEmpty;
    }) || liveEditorText.isNotEmpty;

    debugPrint('📖 hasContent check: $hasContent | chapters: ${_chapters.length} | liveText len: ${liveEditorText.length}');

    if (!hasContent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot publish: at least one chapter must have content.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // Determine initial values from existing manuscript data
    final currentPrice = (_manuscriptDetails?['price'] ?? 0).toDouble();
    bool isPaid = currentPrice > 0;
    final TextEditingController priceController = TextEditingController(
      text: isPaid ? currentPrice.toStringAsFixed(2) : '',
    );

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: salmonColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.rocket_launch_rounded, color: salmonColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _manuscriptDetails?['status'] == 'PUBLISHED'
                                ? 'Update Publication'
                                : 'Publish Manuscript',
                            style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: const Color(0xFF1D2939)),
                          ),
                          Text(
                            'Choose how readers access your work',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Free / Paid Toggle Cards ───────────────────────────
                  Text('Access Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // FREE card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() {
                            isPaid = false;
                            priceController.clear();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                            decoration: BoxDecoration(
                              color: !isPaid ? const Color(0xFFF0FDF4) : Colors.white,
                              border: Border.all(
                                color: !isPaid ? Colors.green.shade400 : Colors.grey.shade200,
                                width: !isPaid ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.lock_open_rounded,
                                    color: !isPaid ? Colors.green.shade600 : Colors.grey, size: 28),
                                const SizedBox(height: 8),
                                Text('Free',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !isPaid ? Colors.green.shade700 : Colors.grey,
                                    )),
                                const SizedBox(height: 4),
                                Text('Anyone can read',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // PAID card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => isPaid = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                            decoration: BoxDecoration(
                              color: isPaid ? const Color(0xFFFFF7ED) : Colors.white,
                              border: Border.all(
                                color: isPaid ? salmonColor : Colors.grey.shade200,
                                width: isPaid ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.monetization_on_rounded,
                                    color: isPaid ? salmonColor : Colors.grey, size: 28),
                                const SizedBox(height: 8),
                                Text('Paid',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPaid ? salmonColor : Colors.grey,
                                    )),
                                const SizedBox(height: 4),
                                Text('Set a price to earn',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Price Input (animated) ────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: isPaid
                        ? Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Price (USD)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700, fontSize: 13)),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 4.99',
                                    prefixText: '\$ ',
                                    prefixStyle: TextStyle(color: salmonColor, fontWeight: FontWeight.bold),
                                    filled: true,
                                    fillColor: const Color(0xFFFFF7ED),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: salmonColor.withOpacity(0.4)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: salmonColor, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Readers pay once to access all chapters.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 28),

                  // ── Action Buttons ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Validate price if paid
                          if (isPaid) {
                            final priceVal = double.tryParse(priceController.text.trim());
                            if (priceVal == null || priceVal <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid price greater than 0.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx, priceVal);
                          } else {
                            Navigator.pop(ctx, 0.0);
                          }
                        },
                        icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                        label: Text(
                          _manuscriptDetails?['status'] == 'PUBLISHED' ? 'Update' : 'Publish',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: salmonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((price) async {
      priceController.dispose();
      // price == null means dialog was dismissed (Cancel)
      if (price == null) return;
      await _doPublish((price as num).toDouble());
    });
  }

  Future<void> _doPublish(double price) async {
    setState(() => _isPublishing = true);
    debugPrint('🚀 _doPublish called with price: $price');
    final result = await ManuscriptService.updateManuscript(widget.manuscriptId, {
      'status': 'PUBLISHED',
      'price': price,
    });
    debugPrint('🚀 publish result: $result');

    if (!mounted) return;

    if (result['manuscript'] != null || (result['message']?.toString().contains('successfully') == true)) {
      // Re-fetch the full manuscript so we get nested author/collaborations
      await _fetchManuscriptDetails();
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Published successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to publish. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _calculateWordCount() {
    final text = _controller.document.toPlainText();
    // 2. Update the notifier value instead of calling setState
    _wordCountNotifier.value = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _wordCountNotifier.dispose(); // Dispose the notifier
    super.dispose();
  }

  Future<void> _showAddChapterDialog() async {
    final TextEditingController titleController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Chapter'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: "Enter chapter title"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () async {
                final String title = titleController.text.trim();
                if (title.isNotEmpty) {
                  Navigator.pop(context);
                  final result = await ChapterService.createChapter(
                    widget.manuscriptId,
                    title,
                    order: _chapters.length + 1,
                  );
                  if (result['id'] != null) {
                    _fetchChapters();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? 'Failed to create chapter')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8B7D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameChapterDialog(dynamic chapter) async {
    final TextEditingController titleController = TextEditingController(text: chapter['title']);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Chapter'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: "Enter new chapter title"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () async {
                final String newTitle = titleController.text.trim();
                if (newTitle.isNotEmpty && newTitle != chapter['title']) {
                  Navigator.pop(context);
                  final result = await ChapterService.updateChapter(chapter['id'], {
                    'title': newTitle,
                  });
                  if (result['id'] != null) {
                    _fetchChapters();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? 'Failed to rename chapter')),
                      );
                    }
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: salmonColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteChapter(dynamic chapter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chapter?'),
        content: Text('Are you sure you want to delete "${chapter['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      final result = await ChapterService.deleteChapter(chapter['id']);
      if (result['message']?.toString().toLowerCase().contains('successfully') == true) {
        if (_currentChapter?['id'] == chapter['id']) {
          setState(() {
            _currentChapter = null;
            _controller.document = Document()..insert(0, '\n');
            _wordCountNotifier.value = 0;
            _comments.clear();
          });
        }
        await _fetchChapters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chapter deleted successfully'), backgroundColor: Colors.green));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to delete chapter'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _showInviteCollaboratorDialog() async {
    final TextEditingController emailController = TextEditingController();
    String selectedRole = 'EDITOR'; // Default role

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Invite Collaborator'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: "Enter email address",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    onChanged: (value) {
                      setDialogState(() => selectedRole = value!);
                    },
                    items: const [
                      DropdownMenuItem(value: 'EDITOR', child: Text('Editor (Can edit chapters)')),
                      DropdownMenuItem(value: 'VIEWER', child: Text('Viewer (Read only)')),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String email = emailController.text.trim();
                    if (email.isNotEmpty) {
                      Navigator.pop(context);
                      final result = await ManuscriptService.inviteCollaborator(
                        widget.manuscriptId,
                        email,
                        selectedRole,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Invitation sent')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: salmonColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Note: We are NOT calling setState in the listener anymore, 
    // so this build method only runs ONCE when the page loads.
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: ChapterSidebar(
              chapters: _chapters,
              currentChapterId: _currentChapter?['id'],
              isAuthor: _isAuthor,
              onChapterSelected: _selectChapter,
              onAddChapter: () => _showAddChapterDialog(),
              onRenameChapter: (chapter) => _showRenameChapterDialog(chapter),
              onDeleteChapter: (chapter) => _deleteChapter(chapter),
              isLoading: _isLoadingChapters,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildQuillToolbar(),
                Expanded(child: _buildQuillEditor()),
              ],
            ),
          ),
          SizedBox(
            width: 340,
            child: _buildRightPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    final pendingCount = _suggestedEdits.where((e) => e['status'] == 'PENDING').length;
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Column(
          children: [
            TabBar(
              labelColor: salmonColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: salmonColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                const Tab(text: 'Comments'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Suggestions'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: salmonColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  CommentsSidebar(
                    comments: _comments,
                    isLoading: _isLoadingComments,
                    onAddComment: (content) async {
                      if (_currentChapter == null) return;
                      final result = await CommentService.addComment(
                        _currentChapter['id'],
                        content,
                        type: 'EDITORIAL',
                      );
                      if (result['comment'] != null) {
                        _fetchComments(_currentChapter['id']);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Failed to add comment')),
                        );
                      }
                    },
                  ),
                  SuggestedEditsSidebar(
                    suggestedEdits: _suggestedEdits,
                    isLoading: _isLoadingSuggestions,
                    isAuthor: _isAuthor,
                    onAccept: (id) async {
                      final result = await SuggestedEditService.acceptSuggestedEdit(id);
                      if (result['suggestedEdit'] != null) {
                        if (_currentChapter != null) {
                          final newContent = result['chapter']?['content'] ?? '';
                          setState(() {
                            _currentChapter = {..._currentChapter, 'content': newContent};
                            final displayContent = newContent.endsWith('\n') && newContent.length > 1
                                ? newContent.substring(0, newContent.length - 1)
                                : newContent;
                            _controller = QuillController(
                              document: displayContent.isEmpty
                                  ? Document()
                                  : (Document()..insert(0, displayContent)),
                              selection: const TextSelection.collapsed(offset: 0),
                            );
                            _controller.document.changes.listen((_) => _calculateWordCount());
                            _calculateWordCount();
                          });
                          _fetchSuggestedEdits(_currentChapter['id']);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Suggestion accepted ✓'), backgroundColor: Colors.green),
                          );
                        }
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Failed to accept')),
                        );
                      }
                    },
                    onDecline: (id) async {
                      final result = await SuggestedEditService.declineSuggestedEdit(id);
                      if (result['suggestedEdit'] != null) {
                        if (_currentChapter != null) _fetchSuggestedEdits(_currentChapter['id']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Suggestion declined.'), backgroundColor: Colors.grey),
                          );
                        }
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Failed to decline')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuillToolbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(30, 30, 30, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: QuillSimpleToolbar(
              controller: _controller,
              config: QuillSimpleToolbarConfig(
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    iconTheme: QuillIconTheme(
                      iconButtonSelectedData: IconButtonData(style: IconButton.styleFrom(foregroundColor: salmonColor)),
                      iconButtonUnselectedData: IconButtonData(style: IconButton.styleFrom(foregroundColor: Colors.blueGrey)),
                    ),
                  ),
                ),
                showFontFamily: false,
                showFontSize: false,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: false,
                showColorButton: true,
                showBackgroundColorButton: false,
                showClearFormat: true,
                showAlignmentButtons: true,
                showHeaderStyle: true,
                showListNumbers: true,
                showListBullets: true,
                showQuote: true,
                showLink: true,
                showUndo: true,
                showRedo: true,
                showSearchButton: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Row(
              children: [
                // 3. Use ValueListenableBuilder to only rebuild this small text widget
                ValueListenableBuilder<int>(
                  valueListenable: _wordCountNotifier,
                  builder: (context, value, child) {
                    return Text("$value words", style: const TextStyle(color: Colors.grey, fontSize: 13));
                  },
                ),
                const SizedBox(width: 15),
                if (_isSaving)
                  const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                else ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 5),
                  const Text("Saved", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
                const SizedBox(width: 15),
                TextButton(
                  onPressed: _isSaving ? null : _saveCurrentChapter,
                  child: const Text("Save Now"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuillEditor() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
        ),
        child: QuillEditor.basic(
          controller: _controller,
          config: const QuillEditorConfig( // Added const for performance
            placeholder: 'Start writing your story...',
            autoFocus: true,
            expands: true,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1D2939)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF1D2939), fontSize: 20)),
          Text(
            _currentChapter != null 
                ? "Editing: ${_currentChapter['title']}" 
                : "Select or add a chapter", 
            style: const TextStyle(fontSize: 12, color: Colors.grey)
          ),
        ],
      ),
      actions: [
        if (_manuscriptDetails != null && _manuscriptDetails['author'] != null)
           _collaboratorAvatar(
            _getInitials(_manuscriptDetails['author']['fullName'] ?? "Author"),
            Colors.blue.shade300,
            _manuscriptDetails['author']['fullName'] ?? "Author",
            avatarUrl: _manuscriptDetails['author']['avatarUrl'],
          ),
        ..._acceptedCollaborators.map((collab) {
           final user = collab['user'] ?? {};
           final displayName = user['fullName'] ?? collab['email'] ?? "Collaborator";
           return _collaboratorAvatar(
             _getInitials(displayName),
             Colors.orange.shade300,
             displayName,
             avatarUrl: user['avatarUrl'],
           );
        }).toList(),
        _addCollaboratorButton(),
        const VerticalDivider(width: 40, indent: 15, endIndent: 15),
        _iconLabelButton(Icons.history, "Revisions"),
        _iconLabelButton(Icons.file_download_outlined, "Export"),
        if (_isAuthor) ...[
          const SizedBox(width: 15),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _showPublishDialog,
              icon: _isPublishing
                  ? const SizedBox(
                      height: 14, width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.rocket_launch_rounded, size: 16),
              label: Text(
                _manuscriptDetails?['status'] == 'PUBLISHED'
                    ? 'Update Status/Price'
                    : 'Publish',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _manuscriptDetails?['status'] == 'PUBLISHED'
                    ? const Color(0xFF2E90FA)
                    : salmonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
        const SizedBox(width: 20),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "?";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final cleanName = name.trim();
    return cleanName.substring(0, cleanName.length >= 2 ? 2 : cleanName.length).toUpperCase();
  }

  Widget _collaboratorAvatar(String initials, Color color, String name, {String? avatarUrl}) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Tooltip(
      message: name,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: color,
        backgroundImage: avatarUrl != null 
            ? NetworkImage(avatarUrl.startsWith('/uploads/') ? 'http://localhost:8000$avatarUrl' : avatarUrl) 
            : null,
        child: avatarUrl == null 
            ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
            : null,
      ),
    ),
  );

  Widget _addCollaboratorButton() => GestureDetector(
    onTap: _showInviteCollaboratorDialog,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.5)),
          child: const Icon(Icons.add, size: 16, color: Colors.grey),
        ),
      ),
    ),
  );

  Widget _iconLabelButton(IconData icon, String label) => TextButton.icon(
    onPressed: () {},
    icon: Icon(icon, size: 20, color: Colors.blueGrey),
    label: Text(label, style: const TextStyle(color: Colors.blueGrey)),
  );
}

// ... Rest of your ChapterSidebar and CommentsSidebar code (unchanged)
class ChapterSidebar extends StatelessWidget {
  final List<dynamic> chapters;
  final int? currentChapterId;
  final bool isAuthor;
  final Function(dynamic) onChapterSelected;
  final Function(dynamic) onRenameChapter;
  final Function(dynamic) onDeleteChapter;
  final VoidCallback onAddChapter;
  final bool isLoading;

  const ChapterSidebar({
    super.key,
    required this.chapters,
    this.currentChapterId,
    required this.isAuthor,
    required this.onChapterSelected,
    required this.onRenameChapter,
    required this.onDeleteChapter,
    required this.onAddChapter,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Colors.grey.shade100))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Chapters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  onPressed: onAddChapter,
                  icon: Icon(Icons.add, color: Colors.red.shade300, size: 20),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (chapters.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No chapters yet."),
            )
          else
            Expanded(
              child: ListView(
                children: chapters.map((chapter) {
                  final isActive = chapter['id'] == currentChapterId;
                  return _chapterTile(
                    chapter: chapter,
                    isActive: isActive,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chapterTile({required dynamic chapter, required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFF8B7D).withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? Border.all(color: const Color(0xFFFF8B7D).withOpacity(0.2)) : null,
      ),
      child: ListTile(
        onTap: () => onChapterSelected(chapter),
        dense: true,
        title: Text(
          chapter['title'] ?? 'Untitled Chapter',
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFFFF8B7D) : Colors.black87,
          ),
        ),
        subtitle: const Text("Click to edit", style: TextStyle(fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive && isAuthor) ...[
              IconButton(
                icon: const Icon(Icons.edit_note, size: 18, color: Colors.grey),
                onPressed: () => onRenameChapter(chapter),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                onPressed: () => onDeleteChapter(chapter),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              const SizedBox(width: 4),
            ],
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.blue : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsSidebar extends StatelessWidget {
  final List<dynamic> comments;
  final bool isLoading;
  final Function(String) onAddComment;

  const CommentsSidebar({
    super.key,
    required this.comments,
    required this.isLoading,
    required this.onAddComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Colors.grey.shade100))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Icon(Icons.close, color: Colors.grey, size: 18),
              ],
            ),
          ),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (comments.isEmpty)
            const Expanded(child: Center(child: Text("No comments yet", style: TextStyle(color: Colors.grey))))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  final author = comment['author'] ?? {};
                  final createdAt = DateTime.parse(comment['createdAt']);
                  final timeAgo = _getTimeAgo(createdAt);

                  return _commentCard(
                    author['fullName'] ?? "Unknown",
                    timeAgo,
                    comment['content'] ?? "",
                    Colors.orange.shade300,
                    avatarUrl: author['avatarUrl'],
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GestureDetector(
              onTap: () => _showAddCommentDialog(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text("+ Add Comment", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return "${difference.inMinutes} min ago";
    if (difference.inHours < 24) return "${difference.inHours} hours ago";
    return DateFormat('MMM d, y').format(dateTime);
  }

  Future<void> _showAddCommentDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Comment"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your comment"),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final content = controller.text.trim();
              if (content.isNotEmpty) {
                onAddComment(content);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8B7D), foregroundColor: Colors.white),
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  Widget _commentCard(String name, String time, String text, Color avatarColor, {String? avatarUrl}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14, 
                backgroundColor: avatarColor, 
                backgroundImage: avatarUrl != null 
                    ? NetworkImage(avatarUrl.startsWith('/uploads/') ? 'http://localhost:8000$avatarUrl' : avatarUrl) 
                    : null,
                child: avatarUrl == null 
                    ? Text(name.isNotEmpty ? name[0] : "?", style: const TextStyle(color: Colors.white, fontSize: 10))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 5),
              Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
          const SizedBox(height: 10),
          Row(children: const [Text("Reply", style: TextStyle(fontSize: 12, color: Colors.grey)), SizedBox(width: 15), Text("Resolve", style: TextStyle(fontSize: 12, color: Colors.grey))])
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SuggestedEditsSidebar Widget
// ─────────────────────────────────────────────────────────────────────────────
class SuggestedEditsSidebar extends StatelessWidget {
  final List<dynamic> suggestedEdits;
  final bool isLoading;
  final bool isAuthor;
  final Future<void> Function(int id) onAccept;
  final Future<void> Function(int id) onDecline;

  const SuggestedEditsSidebar({
    super.key,
    required this.suggestedEdits,
    required this.isLoading,
    required this.isAuthor,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (suggestedEdits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFFCFD8DC)),
              SizedBox(height: 12),
              Text('No suggested edits yet',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 6),
              Text('Editors can submit edits which\nyou can accept or decline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suggestedEdits.length,
      itemBuilder: (context, index) {
        final edit = suggestedEdits[index];
        return _SuggestionCard(
          edit: edit,
          isAuthor: isAuthor,
          onAccept: () => onAccept(edit['id']),
          onDecline: () => onDecline(edit['id']),
        );
      },
    );
  }
}

class _SuggestionCard extends StatefulWidget {
  final dynamic edit;
  final bool isAuthor;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  const _SuggestionCard({
    required this.edit,
    required this.isAuthor,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _isExpanded = false;
  bool _isWorking = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'ACCEPTED': return Colors.green;
      case 'DECLINED': return Colors.redAccent;
      default: return const Color(0xFFFF8B7D);
    }
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.edit['status']?.toString() ?? 'PENDING';
    final editor = widget.edit['editor'] ?? {};
    final editorName = editor['fullName']?.toString() ?? 'Editor';
    final createdAt = widget.edit['createdAt']?.toString() ?? '';
    final original = widget.edit['originalContent']?.toString() ?? '';
    final suggested = widget.edit['suggestedContent']?.toString() ?? '';
    final isPending = status == 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? const Color(0xFFFF8B7D).withOpacity(0.4) : Colors.grey.shade200,
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.orange.shade200,
                  backgroundImage: editor['avatarUrl'] != null 
                      ? NetworkImage(editor['avatarUrl'].toString().startsWith('/uploads/') ? 'http://localhost:8000${editor['avatarUrl']}' : editor['avatarUrl'])
                      : null,
                  child: editor['avatarUrl'] == null 
                      ? Text(
                          editorName.isNotEmpty ? editorName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(editorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                      Text(_timeAgo(createdAt),
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(status).withOpacity(0.4)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor(status)),
                  ),
                ),
              ],
            ),
          ),

          // ── Diff View ─────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _isExpanded ? 'Hide diff' : 'Show diff',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 10),
            // Original (removed lines)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.remove_circle_outline, size: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('Original', style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    original.length > 300 ? '${original.substring(0, 300)}...' : original,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5C2626),
                      height: 1.5,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Suggested (added lines)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.add_circle_outline, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('Suggested', style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    suggested.length > 300 ? '${suggested.substring(0, 300)}...' : suggested,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF145A2C),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          const SizedBox(height: 12),

          // ── Accept / Decline (Author only, PENDING only) ───────────
          if (widget.isAuthor && isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isWorking ? null : () async {
                        setState(() => _isWorking = true);
                        await widget.onDecline();
                        if (mounted) setState(() => _isWorking = false);
                      },
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Decline', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isWorking ? null : () async {
                        setState(() => _isWorking = true);
                        await widget.onAccept();
                        if (mounted) setState(() => _isWorking = false);
                      },
                      icon: _isWorking
                          ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 14),
                      label: const Text('Accept', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                status == 'ACCEPTED' ? '✓ Accepted — content was updated.' : '✗ Declined — content unchanged.',
                style: TextStyle(
                  fontSize: 11,
                  color: status == 'ACCEPTED' ? Colors.green.shade700 : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
