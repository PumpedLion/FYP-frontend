import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/manuscript_service.dart';
import 'services/auth_service.dart';
import 'SettingsPage.dart';

class CreateManuscriptPage extends StatefulWidget {
  const CreateManuscriptPage({super.key});

  @override
  State<CreateManuscriptPage> createState() => _CreateManuscriptPageState();
}

class _CreateManuscriptPageState extends State<CreateManuscriptPage> {
  int currentStep = 1; // 1, 2, or 3

  // Form Data
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String selectedGenre = "Mystery";
  String visibility = "Private";
  String selectedStyle = "Minimal";
  List<String> tags = ["dds"];
  final TextEditingController _tagController = TextEditingController();
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  final Color salmonColor = const Color(0xFFFF8B7D);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    setState(() => _currentUser = user);
    
    // Refresh in background
    final profileResponse = await AuthService.refreshUserProfile();
    if (profileResponse['user'] != null) {
      if (mounted) {
        setState(() => _currentUser = profileResponse['user']);
      }
    }
  }

  void nextStep() {
    if (currentStep < 3) setState(() => currentStep++);
  }

  void prevStep() {
    if (currentStep > 1) setState(() => currentStep--);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final data = {
      'title': title,
      'subtitle': _subtitleController.text.trim(),
      'genre': selectedGenre,
      'description': _descriptionController.text.trim(),
      'tags': tags,
      'coverUrl': "https://picsum.photos/seed/${selectedStyle.hashCode}/400", // Using the selected template as a default coverUrl
    };

    final result = await ManuscriptService.createManuscript(data);
    
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['id'] != null || result['message']?.toString().contains('successfully') == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manuscript created successfully!')),
        );
        Navigator.pop(context); // Go back to dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create manuscript')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              // Main Form Container
              Container(
                width: 700,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
                ),
                child: _buildStepContent(),
              ),
              const SizedBox(height: 40),
              // Bottom Navigation
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // --- APP BAR & STEPPER ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1D2939)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("Create New Manuscript",
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF1D2939), fontSize: 24)),
      actions: [
        _userProfile(),
        const SizedBox(width: 20),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                _stepIndicator(1),
                _stepIndicator(2),
                _stepIndicator(3),
                const SizedBox(width: 15),
                Text("Step $currentStep of 3", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _stepIndicator(int step) {
    bool active = currentStep >= step;
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? salmonColor : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // --- STEP DISPATCHER ---
  Widget _buildStepContent() {
    switch (currentStep) {
      case 1: return _step1BasicInfo();
      case 2: return _step2AdditionalDetails();
      case 3: return _step3CoverStyle();
      default: return _step1BasicInfo();
    }
  }

  // ==========================================
  // STEP 1: BASIC INFO
  // ==========================================
  Widget _step1BasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Basic Information", style: GoogleFonts.dmSerifDisplay(fontSize: 28)),
        const Text("Let's start with the essentials of your manuscript", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        _inputLabel("Title", required: true),
        _textField("Enter title...", controller: _titleController),
        const SizedBox(height: 20),
        _inputLabel("Subtitle (Optional)"),
        _textField("Enter subtitle...", controller: _subtitleController),
        const SizedBox(height: 20),
        _inputLabel("Genre", required: true),
        const SizedBox(height: 10),
        _genreGrid(),
        const SizedBox(height: 20),
        _inputLabel("Target Word Count"),
        _dropdown(["50,000 words (Novel)", "20,000 words (Novella)", "5,000 words (Short Story)"]),
      ],
    );
  }

  Widget _genreGrid() {
    final genres = ["Fiction", "Non-Fiction", "Fantasy", "Science Fiction", "Mystery", "Thriller", "Romance", "Horror", "Historical", "Biography", "Poetry", "Drama", "Adventure", "Young Adult", "Children"];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: genres.map((g) {
        bool selected = selectedGenre == g;
        return GestureDetector(
          onTap: () => setState(() => selectedGenre = g),
          child: Container(
            width: 130,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? salmonColor : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(g, style: TextStyle(color: selected ? Colors.white : Colors.blueGrey, fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // STEP 2: ADDITIONAL DETAILS
  // ==========================================
  Widget _step2AdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Additional Details", style: GoogleFonts.dmSerifDisplay(fontSize: 28)),
        const Text("Help organize and describe your manuscript", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        _inputLabel("Description (Optional)"),
        _textField("Enter description...", maxLines: 5, controller: _descriptionController),
        const Text("0/500 characters", style: TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 25),
        _inputLabel("Tags (Up to 5)"),
        Row(
          children: [
            Expanded(child: _textField("Add a tag", controller: _tagController)),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                if (_tagController.text.isNotEmpty && tags.length < 5) {
                  setState(() => tags.add(_tagController.text));
                  _tagController.clear();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: salmonColor.withOpacity(0.3), foregroundColor: salmonColor, elevation: 0),
              child: const Text("Add Tag"),
            )
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: tags.map((t) => Chip(
            label: Text(t, style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () => setState(() => tags.remove(t)),
            backgroundColor: const Color(0xFFE8F5E9),
          )).toList(),
        ),
        const SizedBox(height: 25),
        _inputLabel("Visibility"),
        const SizedBox(height: 10),
        Row(
          children: [
            _visibilityCard("Private", Icons.lock_outline, "Only you can see this manuscript"),
            const SizedBox(width: 20),
            _visibilityCard("Collaborators", Icons.people_outline, "Share with invited collaborators"),
          ],
        ),
      ],
    );
  }

  Widget _visibilityCard(String title, IconData icon, String sub) {
    bool selected = visibility == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => visibility = title),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF2F0) : Colors.white,
            border: Border.all(color: selected ? salmonColor : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 3: COVER STYLE
  // ==========================================
  Widget _step3CoverStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Choose Cover Style", style: GoogleFonts.dmSerifDisplay(fontSize: 28)),
        const Text("Select a visual style for your manuscript cover", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        
        // CUSTOM UPLOAD BUTTON (NEW FEATURE)
        Center(
          child: OutlinedButton.icon(
            onPressed: () {
               // Logic to open file picker for PC
            },
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Custom Cover from PC"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              side: BorderSide(color: salmonColor),
              foregroundColor: salmonColor,
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Center(child: Text("— OR CHOOSE A TEMPLATE —", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2))),
        const SizedBox(height: 20),

        _coverGrid(),
        const SizedBox(height: 30),
        _infoBox("Cover Customization", "You can customize your cover design later in the manuscript settings. This is just a starting template."),
      ],
    );
  }

  Widget _coverGrid() {
    final styles = ["Minimal", "Artistic", "Modern", "Classic"];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 1),
      itemCount: 4,
      itemBuilder: (context, index) {
        String s = styles[index];
        bool selected = selectedStyle == s;
        return GestureDetector(
          onTap: () => setState(() => selectedStyle = s),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: selected ? salmonColor : Colors.grey.shade200, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Stack(
                      children: [
                        Image.network("https://picsum.photos/seed/${s.hashCode}/400", fit: BoxFit.cover, width: double.infinity),
                        if (selected) Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: salmonColor, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 16))),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- BOTTOM NAV ---
  Widget _buildBottomNav() {
    return SizedBox(
      width: 700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: currentStep > 1 ? prevStep : null,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text("Previous"),
            style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
          ),
          ElevatedButton(
            onPressed: _isLoading 
              ? null 
              : (currentStep == 3 ? _handleCreate : nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStep == 3 ? Colors.green.shade200 : salmonColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    children: [
                      Text(currentStep == 3 ? "Create Manuscript" : "Next", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      if (currentStep < 3) ...[const SizedBox(width: 8), const Icon(Icons.arrow_forward, color: Colors.white, size: 16)],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- INPUT HELPERS ---
  Widget _inputLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(text: TextSpan(text: text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13), children: [if (required) const TextSpan(text: " *", style: TextStyle(color: Colors.red))])),
    );
  }

  Widget _textField(String hint, {int maxLines = 1, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: salmonColor)),
      ),
    );
  }

  Widget _dropdown(List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.first,
          isExpanded: true,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) {},
        ),
      ),
    );
  }

  Widget _infoBox(String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.green.shade700, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13)), Text(sub, style: TextStyle(color: Colors.green.shade700, fontSize: 11))])),
        ],
      ),
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
            backgroundColor: salmonColor.withOpacity(0.8),
            backgroundImage: _currentUser?['avatarUrl'] != null 
                ? NetworkImage(_currentUser!['avatarUrl']) 
                : null,
            child: _currentUser?['avatarUrl'] == null 
                ? Text(_getInitials(_currentUser?['fullName']), 
                    style: const TextStyle(color: Colors.white, fontSize: 10))
                : null,
            radius: 16,
          ),
          const SizedBox(width: 8),
          Text(_currentUser?['fullName'] ?? "Author", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D2939))),
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
}
