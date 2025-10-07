import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'how_to_play_page.dart';
import 'player_names_page.dart';
import 'score_history_page.dart';
import '../services/auth_service.dart';

class GameSetupPage extends StatefulWidget {
  const GameSetupPage({super.key});

  @override
  State<GameSetupPage> createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _numberOfPlayersController = TextEditingController();
  final _startingCardsController = TextEditingController(text: '8');

  int _scoreMode = 0; // 0 = Prepend 0, 1 = Append 1
  // Always show default trump suit; toggle removed
  final bool _showDefaultTrumpSuit = true;

  @override
  void dispose() {
    _numberOfPlayersController.dispose();
    _startingCardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD81B60),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Game Options',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // User info header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFD81B60),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFFD81B60),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? 'Guest',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kachu Ful Player',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFFD81B60)),
              title: Text(
                'Help',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HowToPlayPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFFD81B60)),
              title: Text(
                'Score History',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScoreHistoryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFFD81B60)),
              title: Text(
                'Home',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            const Spacer(),
            const Divider(),
            // Logout Button
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              onTap: () async {
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Logout',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Are you sure you want to logout?',
                      style: GoogleFonts.inter(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && mounted) {
                  await AuthService().signOut();
                  // AuthWrapper will automatically redirect to login
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number of Players
                  Text(
                    'No of Players:',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _numberOfPlayersController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter number (3-7)',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black26,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black26,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD81B60),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of players';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number < 3 || number > 7) {
                        return 'Please enter a number between 3 and 7';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // Score Mode Selection
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD81B60),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prepend 0 Option
                        InkWell(
                          onTap: () {
                            setState(() {
                              _scoreMode = 0;
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Prepend 0',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Radio<int>(
                                value: 0,
                                groupValue: _scoreMode,
                                onChanged: (value) {
                                  setState(() {
                                    _scoreMode = value!;
                                  });
                                },
                                fillColor:
                                    WidgetStateProperty.all(Colors.white),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Append 1 Option
                        InkWell(
                          onTap: () {
                            setState(() {
                              _scoreMode = 1;
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Append 1',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Radio<int>(
                                value: 1,
                                groupValue: _scoreMode,
                                onChanged: (value) {
                                  setState(() {
                                    _scoreMode = value!;
                                  });
                                },
                                fillColor:
                                    WidgetStateProperty.all(Colors.white),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Explanation Text (dynamic)
                        Builder(
                          builder: (_) {
                            final isPrepend = _scoreMode == 0;
                            final title = isPrepend
                                ? 'Scoring: Prepend 0 (bid × 10, with 0 → 10)'
                                : 'Scoring: Append 1 (10 + bid, with 0 → 10)';
                            final line1 = '0 → 10';
                            final line2 = isPrepend ? '1 → 10' : '1 → 11';
                            final line3 = isPrepend ? '2 → 20' : '2 → 12';
                            final line4 = isPrepend ? '3 → 30' : '3 → 13';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(line1,
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(line2,
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(line3,
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(line4,
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: Colors.white)),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Default trump suit is always shown now; toggle removed

                  // Starting Cards
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD81B60),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting Cards',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Number of Starting cards (min cards)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _startingCardsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Default: 8',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.black38,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter starting cards';
                            }
                            final number = int.tryParse(value);
                            if (number == null || number < 1) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Start Game Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final numberOfPlayers =
                              int.parse(_numberOfPlayersController.text);
                          final startingCards =
                              int.parse(_startingCardsController.text);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerNamesPage(
                                numberOfPlayers: numberOfPlayers,
                                startingCards: startingCards,
                                scoreMode: _scoreMode,
                                showDefaultTrumpSuit: _showDefaultTrumpSuit,
                              ),
                            ),
                          );
                        }
                      },
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
                          const Icon(Icons.arrow_forward, size: 24),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // How To Play Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HowToPlayPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD81B60),
                        side: const BorderSide(
                          color: Color(0xFFD81B60),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'How To Play',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
