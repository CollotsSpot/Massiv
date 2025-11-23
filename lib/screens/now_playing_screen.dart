import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_assistant_provider.dart';
import '../models/player.dart';
import '../widgets/volume_control.dart';
import 'queue_screen.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maProvider = context.watch<MusicAssistantProvider>();
    final selectedPlayer = maProvider.selectedPlayer;
    final currentTrack = maProvider.currentTrack;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
        title: Column(
          children: [
            const Text(
              'Now Playing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
            if (selectedPlayer != null)
              Text(
                selectedPlayer.name,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QueueScreen(),
                ),
              );
            },
            color: Colors.white,
          ),
        ],
      ),
      body: currentTrack == null || selectedPlayer == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off_rounded,
                    size: 64,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nothing playing',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Album artwork
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width - 48,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.album_rounded,
                        size: 128,
                        color: Colors.white24,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Track info
                    Text(
                      currentTrack.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      currentTrack.artistsString,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (currentTrack.album != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        currentTrack.album!.name,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Volume control
                    const VolumeControl(compact: false),

                    const SizedBox(height: 32),

                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Shuffle
                        IconButton(
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: maProvider.isShuffleEnabled
                                ? Colors.white
                                : Colors.white38,
                          ),
                          iconSize: 28,
                          onPressed: selectedPlayer.playerId.isNotEmpty
                              ? () => maProvider.toggleShuffle(
                                    selectedPlayer.playerId,
                                  )
                              : null,
                        ),

                        // Previous
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          color: Colors.white,
                          iconSize: 48,
                          onPressed: maProvider.previousTrackSelectedPlayer,
                        ),

                        // Play/Pause
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              selectedPlayer.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            color: const Color(0xFF1a1a1a),
                            iconSize: 42,
                            onPressed: maProvider.playPauseSelectedPlayer,
                          ),
                        ),

                        // Next
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          color: Colors.white,
                          iconSize: 48,
                          onPressed: maProvider.nextTrackSelectedPlayer,
                        ),

                        // Repeat
                        IconButton(
                          icon: Icon(
                            maProvider.repeatMode == 'one'
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: maProvider.repeatMode != 'off'
                                ? Colors.white
                                : Colors.white38,
                          ),
                          iconSize: 28,
                          onPressed: selectedPlayer.playerId.isNotEmpty
                              ? () => maProvider.toggleRepeat(
                                    selectedPlayer.playerId,
                                  )
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Player status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedPlayer.isPlaying
                                ? Icons.play_circle_rounded
                                : Icons.pause_circle_rounded,
                            color: selectedPlayer.isPlaying
                                ? Colors.green
                                : Colors.white54,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedPlayer.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  selectedPlayer.isPlaying
                                      ? 'Playing'
                                      : 'Paused',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
