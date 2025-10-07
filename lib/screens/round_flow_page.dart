import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import '../models/game_history_model.dart';
import '../services/cloud_game_history_service.dart';

class RoundFlowPage extends StatefulWidget {
  final List<String> playerNames;
  final int startingCards;
  final int scoreMode; // 0 prepend-0, 1 append-1

  const RoundFlowPage({
    super.key,
    required this.playerNames,
    required this.startingCards,
    required this.scoreMode,
  });

  @override
  State<RoundFlowPage> createState() => _RoundFlowPageState();
}

class _RoundFlowPageState extends State<RoundFlowPage> {
  int currentRound = 1;
  int currentHandSize = 0;
  bool isDescending = true;
  int trumpIndex = 0;

  int phase = 0; // 0 = bids, 1 = won
  int idx = 0; // current player index for this phase

  late List<String> names;
  late List<int?> bids;
  late List<int> won;
  late List<int> totals;
  final List<List<int>> roundScores = [];

  final suits = const ['♠', '♦', '♣', '♥'];
  String get trump => suits[trumpIndex % 4];

  @override
  void initState() {
    super.initState();
    names = List.of(widget.playerNames);
    bids = List<int?>.filled(names.length, null);
    won = List<int>.filled(names.length, 0);
    totals = List<int>.filled(names.length, 0);
    currentHandSize = widget.startingCards;
  }

  void _changeValue(int delta) {
    setState(() {
      if (phase == 0) {
        final v = (bids[idx] ?? 0) + delta;
        bids[idx] = v.clamp(0, currentHandSize);
      } else {
        final v = won[idx] + delta;
        won[idx] = v.clamp(0, currentHandSize);
      }
    });
  }

  void _next() {
    setState(() {
      if (phase == 0) {
        // bids phase - require non-null
        bids[idx] ??= 0;
      }
      if (idx < names.length - 1) {
        idx++;
      } else {
        if (phase == 0) {
          // move to won phase
          phase = 1;
          idx = 0;
        } else {
          _completeRound();
        }
      }
    });
  }

  void _prev() {
    setState(() {
      if (idx > 0) idx--;
    });
  }

  void _completeRound() {
    // validate won sum
    final sumWon = won.fold<int>(0, (a, b) => a + b);
    if (sumWon != currentHandSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sum of won ($sumWon) must equal $currentHandSize',
              style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // score this round
    final thisRound = List<int>.filled(names.length, 0);
    for (var i = 0; i < names.length; i++) {
      final bid = bids[i] ?? 0;
      final w = won[i];
      if (bid == w) {
        int score;
        if (widget.scoreMode == 0) {
          score = bid == 0 ? 10 : bid * 10;
        } else {
          score = bid == 0 ? 10 : 10 + bid;
        }
        totals[i] += score;
        thisRound[i] = score;
      }
    }
    roundScores.add(thisRound);

    // show round summary
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Round $currentRound Summary',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...List.generate(names.length, (i) {
                final bid = bids[i] ?? 0;
                final w = won[i];
                final s = thisRound[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(names[i],
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600))),
                      Text('Bid $bid • Won $w',
                          style: GoogleFonts.inter(color: Colors.black54)),
                      const SizedBox(width: 12),
                      Text(s > 0 ? '+$s' : '0',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color:
                                  s > 0 ? Colors.green[700] : Colors.red[700])),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                      child: Text('Totals',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w700))),
                  ...totals.map((t) => Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text('$t',
                            style: GoogleFonts.inter(
                                color: const Color(0xFFD81B60),
                                fontWeight: FontWeight.bold)),
                      )),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _advanceToNextRound();
                  },
                  child: const Text('Next Round'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _advanceToNextRound() {
    // advance trump and hand size
    trumpIndex++;
    if (isDescending) {
      currentHandSize--;
      if (currentHandSize < 1) {
        currentHandSize = 2;
        isDescending = false;
      }
    } else {
      currentHandSize++;
      if (currentHandSize > widget.startingCards) {
        _gameOver();
        return;
      }
    }
    setState(() {
      currentRound++;
      phase = 0;
      idx = 0;
      bids = List<int?>.filled(names.length, null);
      won = List<int>.filled(names.length, 0);
    });
  }

  void _gameOver() {
    final max = totals.reduce((a, b) => a > b ? a : b);
    final winnerIndexes = <int>[];
    for (var i = 0; i < names.length; i++) {
      if (totals[i] == max) winnerIndexes.add(i);
    }

    // Persist game to history (non-blocking; handles offline and auth gating)
    final game = GameHistory(
      timestamp: DateTime.now(),
      numberOfPlayers: names.length,
      startingCards: widget.startingCards,
      scoreMode: widget.scoreMode,
      playerScores: List.generate(
        names.length,
        (i) => PlayerScore(
          id: 'player_$i',
          name: names[i],
          totalScore: totals[i],
          isWinner: winnerIndexes.contains(i),
        ),
      )..sort((a, b) => b.totalScore.compareTo(a.totalScore)),
      winnerId: 'player_${winnerIndexes.first}',
    );
    _saveGameInBackground(game);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Game Over',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          winnerIndexes.length == 1
              ? '${names[winnerIndexes.first]} wins with $max!'
              : 'Winners: ${winnerIndexes.map((i) => names[i]).join(', ')} (score $max)',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGameInBackground(GameHistory game) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Not signed in — game won’t be saved to history',
                  style: GoogleFonts.inter()),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      if (AppConfig.requireEmailVerifiedToSave && user.emailVerified != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verify your email to save game history',
                  style: GoogleFonts.inter()),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      await CloudGameHistoryService().saveGame(game);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game saved. Offline? It will sync automatically',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFFD81B60),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save game failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Round $currentRound • ${currentHandSize} Cards';
    final who = names[idx];
    final value = phase == 0 ? (bids[idx] ?? 0) : won[idx];
    final max = currentHandSize;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD81B60),
        title:
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text('Trump: $trump',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: phase == 0 ? Colors.orange[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        (phase == 0 ? Colors.orange[300] : Colors.green[300])!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(phase == 0 ? Icons.edit : Icons.check_circle,
                      color: (phase == 0
                          ? Colors.orange[700]
                          : Colors.green[700])),
                  const SizedBox(width: 8),
                  Text(
                      phase == 0
                          ? 'Phase 1: Enter bid for each player'
                          : 'Phase 2: Enter won for each player',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(who,
                        style: GoogleFonts.inter(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(phase == 0 ? 'Bid (0..$max)' : 'Won (0..$max)',
                        style: GoogleFonts.inter(color: Colors.black54)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _changeValue(-1),
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 36,
                        ),
                        const SizedBox(width: 16),
                        Text('$value',
                            style: GoogleFonts.inter(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD81B60))),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => _changeValue(1),
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 36,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: value.toDouble(),
                      min: 0,
                      max: max.toDouble(),
                      divisions: max,
                      label: '$value',
                      onChanged: (d) {
                        setState(() {
                          if (phase == 0) {
                            bids[idx] = d.toInt();
                          } else {
                            won[idx] = d.toInt();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                            onPressed: _prev,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Prev')),
                        ElevatedButton.icon(
                            onPressed: _next,
                            icon: Icon(phase == 0 ? Icons.lock : Icons.check),
                            label: Text(phase == 0
                                ? 'Next'
                                : (idx == names.length - 1
                                    ? 'Complete Round'
                                    : 'Next'))),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // quick glance totals
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(names.length,
                  (i) => Chip(label: Text('${names[i]}: ${totals[i]}'))),
            ),
          ],
        ),
      ),
    );
  }
}
