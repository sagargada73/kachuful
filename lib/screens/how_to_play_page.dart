import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HowToPlayPage extends StatelessWidget {
  const HowToPlayPage({super.key});

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
          'How To Play',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFF6B6B),
                    Color(0xFFFF8E53),
                    Color(0xFFFFA500),
                    Color(0xFFFFD700),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  'Kachu Ful',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Also known as: Oh Hell!, Judgement, Contract Whist, Blackout, Blob',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 30),

              _buildSection(
                title: 'Overview',
                content:
                    'Kachu Ful is a trick-taking card game where players must bid the exact number of tricks they think they can win. The key challenge: you score points ONLY if you win exactly what you bid - no more, no less!',
              ),

              _buildSection(
                title: 'Players & Cards',
                content:
                    '• 3-7 players (best with 4-6)\n• Standard 52-card deck\n• Cards rank: A (high), K, Q, J, 10, 9, 8, 7, 6, 5, 4, 3, 2 (low)',
              ),

              _buildSection(
                title: 'Game Structure',
                content:
                    'The game consists of multiple hands. Each hand, the number of cards dealt changes:\n• First hand: 7-10 cards (depending on player count)\n• Each hand decreases by 1 card until reaching 1 card\n• Then increases back up to the starting number',
              ),

              _buildSection(
                title: 'Trump Suits (Kachuful Rotation)',
                content:
                    'The name "Kachu Ful" is a mnemonic for trump suit rotation:\n• Ka = Kari = ♠ Spades\n• Chu = Chukat = ♦ Diamonds\n• Fu = Falli = ♣ Clubs\n• L = Lal = ♥ Hearts',
              ),

              _buildSection(
                title: 'How To Play',
                content:
                    '1. DEAL: Cards are dealt, and one card is turned face-up to determine the trump suit.\n\n2. BIDDING: Starting left of dealer, each player bids how many tricks they think they\'ll win. You can bid zero!\n\n3. THE HOOK: The dealer cannot bid a number that would make the total bids equal the number of tricks available. This ensures at least one player will fail.\n\n4. PLAY: Player left of dealer leads first. Players must follow suit if possible. If you can\'t follow suit, you can play any card (including trump).\n\n5. WINNING TRICKS: Highest trump wins, or if no trump played, highest card of the led suit wins.',
              ),

              _buildSection(
                title: 'Scoring',
                content:
                    '• If you win EXACTLY your bid: 10 points + your bid\n  Example: Bid 2, win 2 = 12 points\n• If you bid zero and win zero: 10 points\n• If you fail your bid: 0 points\n\nWith "Prepend 0" mode:\n• Bid 1, win 1 = 01 → 10 points\n• Bid 2, win 2 = 02 → 20 points\n\nWith "Append 1" mode:\n• Bid 1, win 1 = 11 points\n• Bid 2, win 2 = 21 points',
              ),

              _buildSection(
                title: 'Strategy Tips',
                content:
                    '• Pay attention to bidding! If too many tricks are bid, someone must fail.\n• Trump cards are powerful - use them wisely.\n• Sometimes bidding zero is safer than bidding high.\n• Remember: taking MORE tricks than you bid gives you 0 points!',
              ),

              _buildSection(
                title: 'Winning',
                content:
                    'The player with the highest total score after all hands are played wins the game!',
              ),

              const SizedBox(height: 40),

              // Back Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Got It!',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD81B60),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
