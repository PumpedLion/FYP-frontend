import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'services/chapter_service.dart';
import 'services/manuscript_service.dart';
import 'services/comment_service.dart';
import 'package:intl/intl.dart';
import 'services/auth_service.dart';

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
  bool _isLoadingChapters = false;
  bool _isLoadingComments = false;
  bool _isSaving = false;
  bool _isPublishing = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _getCurrentUser();
    _fetchManuscriptDetails();
    _fetchChapters();

    _controller.document.changes.listen((event) {
      _calculateWordCount();
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
        final allCollabs = _manuscriptDetails['collaborations'] as List<dynamic>? ?? [];
        _acceptedCollaborators = allCollabs.where((c) => c['status'] == 'ACCEPTED').toList();
      });
    }
  }

  Future<void> _fetchComments(int chapterId) async {
    setState(() => _isLoadingComments = true);
    final response = await CommentService.getCommentsByChapter(chapterId);
    setState(() {
      _comments = response['comments'] ?? [];
      _isLoadingComments = false;
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
      // Load content into editor
      final content = chapter['content'] ?? '';
      // Simple text to Delta conversion (assuming backend sends plain text for now)
      // If backend sends Json Delta, use Document.fromJson
      _controller.document = Document()..insert(0, content);
      _calculateWordCount();
    });
    _fetchComments(chapter['id']);
  }

  Future<void> _saveCurrentChapter() async {
    if (_currentChapter == null) return;
    setState(() => _isSaving = true);
    
    final content = _controller.document.toPlainText();
    final result = await ChapterService.updateChapter(_currentChapter['id'], {
      'content': content,
    });

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Saved successfully')),
      );
    }
  }

  Future<void> _publishManuscript() async {
    setState(() => _isPublishing = true);
    final result = await ManuscriptService.updateManuscript(widget.manuscriptId, {
      'status': 'PUBLISHED',
    });

    if (mounted) {
      setState(() {
        _isPublishing = false;
        if (result['manuscript'] != null) {
          _manuscriptDetails = result['manuscript'];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Published successfully!'),
          backgroundColor: Colors.green,
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
              onChapterSelected: _selectChapter,
              onAddChapter: () => _showAddChapterDialog(),
              onRenameChapter: (chapter) => _showRenameChapterDialog(chapter),
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
            width: 320, 
            child: CommentsSidebar(
              comments: _comments,
              isLoading: _isLoadingComments,
              onAddComment: (content) async {
                if (_currentChapter == null) return;
                final result = await CommentService.addComment(_currentChapter['id'], content);
                if (result['comment'] != null) {
                  _fetchComments(_currentChapter['id']);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Failed to add comment')),
                  );
                }
              },
            )
          ),
        ],
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
          ),
        ..._acceptedCollaborators.map((collab) {
           final user = collab['user'] ?? {};
           final displayName = user['fullName'] ?? collab['email'] ?? "Collaborator";
           return _collaboratorAvatar(
             _getInitials(displayName),
             Colors.orange.shade300,
             displayName,
           );
        }).toList(),
        _addCollaboratorButton(),
        const VerticalDivider(width: 40, indent: 15, endIndent: 15),
        _iconLabelButton(Icons.history, "Revisions"),
        _iconLabelButton(Icons.file_download_outlined, "Export"),
        const SizedBox(width: 15),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton(
            onPressed: (_isPublishing || (_manuscriptDetails != null && _manuscriptDetails['status'] == 'PUBLISHED')) 
                ? null 
                : _publishManuscript,
            style: ElevatedButton.styleFrom(
              backgroundColor: salmonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isPublishing 
                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_manuscriptDetails?['status'] == 'PUBLISHED' ? "Published" : "Publish"),
          ),
        ),
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

  Widget _collaboratorAvatar(String initials, Color color, String name) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Tooltip(
      message: name,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: color,
        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
  final Function(dynamic) onChapterSelected;
  final Function(dynamic) onRenameChapter;
  final VoidCallback onAddChapter;
  final bool isLoading;

  const ChapterSidebar({
    super.key,
    required this.chapters,
    this.currentChapterId,
    required this.onChapterSelected,
    required this.onRenameChapter,
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
            if (isActive)
              IconButton(
                icon: const Icon(Icons.edit_note, size: 18, color: Colors.grey),
                onPressed: () => onRenameChapter(chapter),
              ),
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

  Widget _commentCard(String name, String time, String text, Color avatarColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFB), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: avatarColor, child: Text(name.isNotEmpty ? name[0] : "?", style: const TextStyle(color: Colors.white, fontSize: 10))),
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
