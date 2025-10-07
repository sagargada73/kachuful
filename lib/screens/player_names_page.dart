import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_score_page.dart';

class PlayerNamesPage extends StatefulWidget {
  final int numberOfPlayers;
  final int startingCards;
  final int scoreMode;
  final bool showDefaultTrumpSuit;

  const PlayerNamesPage({
    super.key,
    required this.numberOfPlayers,
    required this.startingCards,
    required this.scoreMode,
    required this.showDefaultTrumpSuit,
  });

  @override
  State<PlayerNamesPage> createState() => _PlayerNamesPageState();
}

class _PlayerNamesPageState extends State<PlayerNamesPage> {
  List<TextEditingController> nameControllers = [];
  List<String> playerNames = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with default names
    for (int i = 0; i < widget.numberOfPlayers; i++) {
      nameControllers.add(TextEditingController(text: 'Player ${i + 1}'));
      playerNames.add('Player ${i + 1}');
    }
  }

  @override
  void dispose() {
    for (var controller in nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    // Collect all names
    List<String> finalNames = [];
    for (int i = 0; i < widget.numberOfPlayers; i++) {
      String name = nameControllers[i].text.trim();
      finalNames.add(name.isEmpty ? 'Player ${i + 1}' : name);
    }

    // Navigate to game score page with player names
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScorePage(
          numberOfPlayers: widget.numberOfPlayers,
          startingCards: widget.startingCards,
          scoreMode: widget.scoreMode,
          showDefaultTrumpSuit: widget.showDefaultTrumpSuit,
          playerNames: finalNames,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD81B60),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enter Player Names',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFD81B60).withValues(alpha: 0.1),
                    Colors.orange.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.people,
                    size: 48,
                    color: const Color(0xFFD81B60),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Who\'s Playing?',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD81B60),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter names for all ${widget.numberOfPlayers} players',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Player name inputs
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: widget.numberOfPlayers,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: nameControllers[index],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Player ${index + 1}',
                          labelStyle: GoogleFonts.inter(
                            color: const Color(0xFFD81B60),
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: Icon(
                            Icons.person,
                            color:
                                const Color(0xFFD81B60).withValues(alpha: 0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD81B60),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) {
                          playerNames[index] = value;
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Game Info Summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    icon: Icons.style,
                    label: '${widget.startingCards} Cards',
                  ),
                  _buildInfoChip(
                    icon: Icons.calculate,
                    label: widget.scoreMode == 0 ? 'Prepend 0' : 'Append 1',
                  ),
                  _buildInfoChip(
                    icon: Icons.star,
                    label: 'Trump: ♠',
                  ),
                ],
              ),
            ),

            // Start Game Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Game',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.play_arrow, size: 28),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFFD81B60),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
