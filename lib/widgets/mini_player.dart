import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_assistant_provider.dart';
import '../screens/now_playing_screen.dart';
import '../screens/queue_screen.dart';
import 'volume_control.dart';
import '../constants/hero_tags.dart';
import 'animated_icon_button.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicAssistantProvider>(
      builder: (context, maProvider, child) {
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
          child: Hero(
            tag: HeroTags.nowPlayingBackground,
            child: Material(
              color: const Color(0xFF2a2a2a),
              elevation: 8,
              shadowColor: Colors.black,
              child: Container(
                height: 64,
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
                            // Album art with Hero animation
                            Hero(
                              tag: HeroTags.nowPlayingArt,
                              child: Container(
                                width: 48,
                                height: 48,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl != null
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          cacheWidth: 96,
                                          cacheHeight: 96,
                                          filterQuality: FilterQuality.medium,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
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
                                          color: Colors.white12,
                                          child: const Icon(
                                            Icons.music_note_rounded,
                                            color: Colors.white54,
                                            size: 24,
                                          ),
                                        ),
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
                            Hero(
                              tag: HeroTags.nowPlayingPreviousButton,
                              child: Material(
                                color: Colors.transparent,
                                child: AnimatedIconButton(
                                  icon: Icons.skip_previous_rounded,
                                  color: Colors.white,
                                  iconSize: 26,
                                  onPressed: () async {
                                    try {
                                      await maProvider.previousTrackSelectedPlayer();
                                    } catch (e) {
                                      print('❌ Error in previous track: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                            Hero(
                              tag: HeroTags.nowPlayingPlayButton,
                              child: Material(
                                color: Colors.transparent,
                                child: AnimatedIconButton(
                                  icon: selectedPlayer.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  iconSize: 32,
                                  onPressed: () async {
                                    try {
                                      await maProvider.playPauseSelectedPlayer();
                                    } catch (e) {
                                      print('❌ Error in play/pause: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                            Hero(
                              tag: HeroTags.nowPlayingNextButton,
                              child: Material(
                                color: Colors.transparent,
                                child: AnimatedIconButton(
                                  icon: Icons.skip_next_rounded,
                                  color: Colors.white,
                                  iconSize: 28,
                                  onPressed: () async {
                                    try {
                                      await maProvider.nextTrackSelectedPlayer();
                                    } catch (e) {
                                      print('❌ Error in next track: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
