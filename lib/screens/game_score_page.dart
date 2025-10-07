import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_history_model.dart';
import '../config/app_config.dart';
import '../services/cloud_game_history_service.dart';
import '../services/auth_service.dart';
import 'score_history_page.dart';
import 'how_to_play_page.dart';

class GameScorePage extends StatefulWidget {
  final int numberOfPlayers;
  final int startingCards;
  final int scoreMode; // 0 = Prepend 0, 1 = Append 1
  final bool showDefaultTrumpSuit;
  final List<String> playerNames;

  const GameScorePage({
    super.key,
    required this.numberOfPlayers,
    required this.startingCards,
    required this.scoreMode,
    required this.showDefaultTrumpSuit,
    required this.playerNames,
  });

  @override
  State<GameScorePage> createState() => _GameScorePageState();
}

class _GameScorePageState extends State<GameScorePage> {
  int currentRound = 1;
  int currentHandSize = 0;
  bool isDescending = true;

  // Player names - will be initialized from widget.playerNames
  List<String> playerNames = [];

  // Player bids for current round
  List<int?> playerBids = [];

  // Player tricks won for current round
  List<int> playerTricksWon = [];

  // Player total scores
  List<int> playerScores = [];

  // Round-by-round score history: List of rounds, each containing player scores for that round
  List<List<int>> roundScores = [];

  // Trump suits rotation
  // Use proper suit symbols; avoid mojibake/encoding issues
  final List<String> trumpSuits = ['♠', '♦', '♣', '♥'];
  int trumpSuitIndex = 0;

  // Two-phase system: false = entering bids, true = bids locked, entering won
  bool bidsLocked = false;
  bool _gameOverShown = false;

  // Text controllers for clearing fields
  List<TextEditingController> bidControllers = [];
  List<TextEditingController> wonControllers = [];
  // Scroll controllers for better UX and visible indicators
  final ScrollController _vScrollController = ScrollController();
  final ScrollController _scoreTableHController = ScrollController();
  final ScrollController _historyHController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentHandSize = widget.startingCards;

    // Initialize player data with provided names
    for (int i = 0; i < widget.numberOfPlayers; i++) {
      playerNames.add(widget.playerNames[i]);
      playerBids.add(null);
      playerTricksWon.add(0);
      playerScores.add(0);
      bidControllers.add(TextEditingController());
      wonControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _vScrollController.dispose();
    _scoreTableHController.dispose();
    _historyHController.dispose();
    // Dispose controllers
    for (var controller in bidControllers) {
      controller.dispose();
    }
    for (var controller in wonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String get currentTrumpSuit {
    return trumpSuits[trumpSuitIndex % 4];
  }

  void _lockBids() {
    // Validate that all bids are entered
    bool allBidsEntered = true;
    for (int i = 0; i < widget.numberOfPlayers; i++) {
      final bid = playerBids[i];
      if (bid == null || bid < 0 || bid > currentHandSize) {
        allBidsEntered = false;
        break;
      }
    }

    if (!allBidsEntered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter valid bids (0..$currentHandSize) for all players first!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      bidsLocked = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bids locked! Now enter tricks won.',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _nextRound() {
    // Validate that bids are locked first
    if (!bidsLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please lock bids first before proceeding!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate that all "Won" fields are filled
    bool allWonEntered = true;
    for (int i = 0; i < widget.numberOfPlayers; i++) {
      if (wonControllers[i].text.isEmpty) {
        allWonEntered = false;
        break;
      }
    }

    if (!allWonEntered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter tricks won for all players!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Additional validation: ensure all "won" values are valid and sum to current hand size
    int totalWon = 0;
    for (int i = 0; i < widget.numberOfPlayers; i++) {
      final won = int.tryParse(wonControllers[i].text) ?? 0;
      if (won < 0 || won > currentHandSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid input: Won must be between 0 and $currentHandSize for all players.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      totalWon += won;
      playerTricksWon[i] = won;
    }

    if (totalWon != currentHandSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sum of tricks won ($totalWon) must equal $currentHandSize.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Calculate scores for current round
    List<int> thisRoundScores = List.filled(widget.numberOfPlayers, 0);

    for (int i = 0; i < widget.numberOfPlayers; i++) {
      if (playerBids[i] != null) {
        if (playerBids[i] == playerTricksWon[i]) {
          // Successful bid
          int score = 0;
          if (widget.scoreMode == 0) {
            // Prepend 0: 0->10, 1->10, 2->20, 3->30
            score = playerBids[i]! * 10;
            if (score == 0) score = 10;
          } else {
            // Append 1: 0->10, 1->11, 2->12, 3->13
            if (playerBids[i] == 0) {
              score = 10;
            } else {
              score = 10 + playerBids[i]!;
            }
          }
          playerScores[i] += score;
          thisRoundScores[i] = score;
        }
        // Failed bid = 0 points added
      }
    }

    // Add this round's scores to history
    roundScores.add(thisRoundScores);

    // Compute next round state first
    final int nextRound = currentRound + 1;
    final int nextTrumpIndex = trumpSuitIndex + 1;
    int nextHand = currentHandSize;
    bool nextDescending = isDescending;
    bool isGameOver = false;

    if (isDescending) {
      nextHand--;
      if (nextHand < 1) {
        nextHand = 2;
        nextDescending = false;
      }
    } else {
      nextHand++;
      if (nextHand > widget.startingCards) {
        isGameOver = true;
      }
    }

    if (isGameOver) {
      _showGameOverDialog();
      return;
    }

    // Apply state for next round
    setState(() {
      currentRound = nextRound;
      trumpSuitIndex = nextTrumpIndex;
      currentHandSize = nextHand;
      isDescending = nextDescending;

      // Reset for next round
      for (int i = 0; i < widget.numberOfPlayers; i++) {
        playerBids[i] = null;
        playerTricksWon[i] = 0;
        bidControllers[i].clear();
        wonControllers[i].clear();
      }
      bidsLocked = false; // Reset lock for next round
    });
  }

  void _showGameOverDialog() async {
    if (_gameOverShown) return;
    _gameOverShown = true;
    // Find winner
    int maxScore = playerScores.reduce((a, b) => a > b ? a : b);
    final winnerIndexes = <int>[];
    for (int i = 0; i < playerScores.length; i++) {
      if (playerScores[i] == maxScore) winnerIndexes.add(i);
    }

    // Save game to history
    final gameHistory = GameHistory(
      timestamp: DateTime.now(),
      numberOfPlayers: widget.numberOfPlayers,
      startingCards: widget.startingCards,
      scoreMode: widget.scoreMode,
      playerScores: List.generate(
        widget.numberOfPlayers,
        (index) => PlayerScore(
          id: 'player_$index',
          name: playerNames[index],
          totalScore: playerScores[index],
          isWinner: winnerIndexes.contains(index),
        ),
      )..sort((a, b) =>
          b.totalScore.compareTo(a.totalScore)), // Sort by score descending
      // Keep schema stable: store first winner's id (used only as a hint)
      winnerId: 'player_${winnerIndexes.first}',
    );

    // Save in background; optionally require verified email
    final isVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (AppConfig.requireEmailVerifiedToSave && !isVerified) {
      debugPrint(
          'Skipping save: email not verified and saving requires verification');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verify your email to save game history.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      CloudGameHistoryService()
          .saveGame(gameHistory)
          .catchError((e) => debugPrint('Save game error (ignored): $e'));
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Game Over!',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (winnerIndexes.length == 1)
              Text(
                '${playerNames[winnerIndexes.first]} Wins!',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD81B60),
                ),
              )
            else
              Text(
                'Winners: ${winnerIndexes.map((i) => playerNames[i]).join(', ')}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD81B60),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Final Score: $maxScore',
              style: GoogleFonts.inter(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'New Game',
              style: GoogleFonts.inter(
                color: const Color(0xFFD81B60),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Round $currentRound - $currentHandSize Cards',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: Text(
                'Trump: $currentTrumpSuit',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
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
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: Color(0xFFD81B60),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FirebaseAuth.instance.currentUser?.email ??
                                    'Guest',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Round $currentRound',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                Navigator.pop(context); // Go back to setup
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
                      'Are you sure you want to logout?\n\nYour current game will be lost.',
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
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: Scrollbar(
        controller: _vScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _vScrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              // Phase Indicator
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: bidsLocked ? Colors.green[50] : Colors.orange[50],
                  border: Border(
                    bottom: BorderSide(
                      color:
                          bidsLocked ? Colors.green[300]! : Colors.orange[300]!,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      bidsLocked ? Icons.check_circle : Icons.edit,
                      color:
                          bidsLocked ? Colors.green[700] : Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bidsLocked
                          ? 'Phase 2: Enter tricks won for each player'
                          : 'Phase 1: Enter bids for each player',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            bidsLocked ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ), // Phase Indicator

              // Score Table
              Scrollbar(
                controller: _scoreTableHController,
                thumbVisibility: true,
                notificationPredicate: (notif) =>
                    notif.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _scoreTableHController,
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFD81B60).withValues(alpha: 0.1),
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Player',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Total',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Bid',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Won',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: List.generate(
                      widget.numberOfPlayers,
                      (index) => DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Text(
                                playerNames[index],
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${playerScores[index]}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD81B60),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: bidControllers[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(),
                                enabled: !bidsLocked,
                                decoration: InputDecoration(
                                  hintText: '?',
                                  hintStyle: GoogleFonts.inter(
                                    color: Colors.black26,
                                  ),
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  filled: bidsLocked,
                                  fillColor:
                                      bidsLocked ? Colors.grey[200] : null,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    playerBids[index] = int.tryParse(value);
                                  });
                                },
                              ),
                            ),
                          ),
                          DataCell(
                            Builder(builder: (cellCtx) {
                              return SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: wonControllers[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(),
                                  enabled: bidsLocked,
                                  scrollPadding: EdgeInsets.only(
                                    bottom: MediaQuery.of(cellCtx)
                                            .viewInsets
                                            .bottom +
                                        80,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: GoogleFonts.inter(
                                      color: Colors.black26,
                                    ),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    filled: !bidsLocked,
                                    fillColor:
                                        !bidsLocked ? Colors.grey[200] : null,
                                  ),
                                  onTap: () {
                                    // Bring field into view when focused
                                    Scrollable.ensureVisible(
                                      cellCtx,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      alignment: 0.2,
                                    );
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      playerTricksWon[index] =
                                          int.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ), // Score Table

              if (roundScores.isNotEmpty)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Round History',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD81B60),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Scrollbar(
                        controller: _historyHController,
                        thumbVisibility: true,
                        notificationPredicate: (notif) =>
                            notif.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _historyHController,
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 35,
                            dataRowMinHeight: 30,
                            dataRowMaxHeight: 35,
                            columnSpacing: 20,
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFD81B60).withValues(alpha: 0.1),
                            ),
                            columns: [
                              DataColumn(
                                label: Text(
                                  'Round',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              ...List.generate(
                                widget.numberOfPlayers,
                                (index) => DataColumn(
                                  label: SizedBox(
                                    width: 60,
                                    child: Text(
                                      playerNames[index].length > 8
                                          ? '${playerNames[index].substring(0, 8)}...'
                                          : playerNames[index],
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            rows: List.generate(
                              roundScores.length,
                              (roundIndex) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '${roundIndex + 1}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ...List.generate(
                                    widget.numberOfPlayers,
                                    (playerIndex) => DataCell(
                                      Text(
                                        roundScores[roundIndex][playerIndex] > 0
                                            ? '+${roundScores[roundIndex][playerIndex]}'
                                            : '0',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: roundScores[roundIndex]
                                                      [playerIndex] >
                                                  0
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                'Total:',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            ...List.generate(
                              widget.numberOfPlayers,
                              (index) => SizedBox(
                                width: 80,
                                child: Center(
                                  child: Text(
                                    '${playerScores[index]}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD81B60),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Lock Bids / Next Round Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: bidsLocked ? _nextRound : _lockBids,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          bidsLocked ? const Color(0xFFD81B60) : Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          bidsLocked ? Icons.arrow_forward : Icons.lock,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          bidsLocked ? 'Next Round' : 'Lock Bids',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
