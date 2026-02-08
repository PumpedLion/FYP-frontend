import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReaderPage extends StatelessWidget {
  final String title;
  final String chapterTitle;

  const ReaderPage({
    super.key,
    this.title = "Whispers in the Dark",
    this.chapterTitle = "Chapter 1: The Abandoned House",
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Very light grey/white background for reading
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // The scrollable reading area
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  // Limit width on PC for better readability (optimal line length)
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chapter Title
                      Text(
                        chapterTitle,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: isDesktop ? 42 : 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1D2939),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Story Body Text
                      _buildStoryText(
                        "The old Victorian mansion stood at the end of Maple Street, its windows dark and empty like hollow eyes staring into the night. Sarah had always been curious about the place, despite the warnings from the townspeople."
                      ),
                      _buildStoryText(
                        "As she approached the rusted iron gate, a chill ran down her spine. The wind whispered through the overgrown garden, carrying with it the scent of decay and forgotten memories. She pushed the gate open, its hinges screaming in protest."
                      ),
                      _buildStoryText(
                        "The front door was ajar, as if inviting her in. Or warning her to stay away. Sarah took a deep breath and stepped inside, her flashlight cutting through the darkness. Dust motes danced in the beam of light, and somewhere in the distance, she heard what sounded like footsteps."
                      ),
                      _buildStoryText(
                        "But she was alone. Wasn't she?"
                      ),
                      const SizedBox(height: 100), // Extra space at the bottom
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  // --- HEADER ---
  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
            title,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Chapter 1: The Abandoned House",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chrome_reader_mode_outlined, color: Colors.black87),
          onPressed: () {}, // Open Table of Contents
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black87),
          onPressed: () {}, // Open Text Settings (Font size, Theme)
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // --- STORY TEXT HELPER ---
  Widget _buildStoryText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 18,
          height: 1.8, // Increased line height for better readability
          color: const Color(0xFF344054),
        ),
      ),
    );
  }

  // --- FOOTER NAVIGATION ---
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
            label: const Text("Prev", style: TextStyle(color: Colors.grey)),
          ),
          
          // Progress text
          const Text(
            "Chapter 1 of 10",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          
          // Next Button
          TextButton(
            onPressed: () {},
            child: Row(
              children: const [
                Text("Next", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right, color: Colors.black87),
              ],
            ),
          ),
        ],
      ),
    );
  }
}