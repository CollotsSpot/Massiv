import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_assistant_provider.dart';
import '../screens/now_playing_screen.dart';
import '../screens/queue_screen.dart';
import 'volume_control.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final maProvider = context.watch<MusicAssistantProvider>();
    final selectedPlayer = maProvider.selectedPlayer;
    final currentTrack = maProvider.currentTrack;

    // Don't show mini player if no track is playing or no player selected
    if (currentTrack == null || selectedPlayer == null) {
      return const SizedBox.shrink();
    }

    final imageUrl = maProvider.getImageUrl(currentTrack, size: 96);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NowPlayingScreen(),
          ),
        );
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status indicator bar
            Container(
              height: 2,
              color: selectedPlayer.isPlaying
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
            ),
            // Player content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.white12,
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white54,
                                    size: 24,
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              color: Colors.white12,
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: Colors.white54,
                                size: 24,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Track info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTrack.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentTrack.artistsString,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Queue button
                    IconButton(
                      icon: const Icon(Icons.queue_music),
                      color: Colors.white70,
                      iconSize: 22,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QueueScreen(),
                          ),
                        );
                      },
                    ),
                    // Volume control (compact mute button)
                    const VolumeControl(compact: true),
                    // Playback controls for selected player
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: Colors.white,
                      iconSize: 26,
                      onPressed: maProvider.previousTrackSelectedPlayer,
                    ),
                    IconButton(
                      icon: Icon(
                        selectedPlayer.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: maProvider.playPauseSelectedPlayer,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      color: Colors.white,
                      iconSize: 28,
                      onPressed: maProvider.nextTrackSelectedPlayer,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
