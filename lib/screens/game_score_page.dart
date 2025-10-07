import 'package:flutter/material.dart';
import 'round_flow_page.dart';

// Temporary wrapper to keep builds green while migrating to the new per-round flow.
// The original GameScorePage was corrupted in a previous edit. This wrapper
// immediately redirects to the new RoundFlowPage using the provided settings.
class GameScorePage extends StatefulWidget {
  final int numberOfPlayers;
  final int startingCards;
  final int scoreMode; // 0 = prepend 0, 1 = append 1
  final bool showDefaultTrumpSuit; // kept for API compatibility
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
  @override
  void initState() {
    super.initState();
    // Defer navigation until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoundFlowPage(
            playerNames: widget.playerNames,
            startingCards: widget.startingCards,
            scoreMode: widget.scoreMode,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Minimal shell shown briefly during redirect
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
