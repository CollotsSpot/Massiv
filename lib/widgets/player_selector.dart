import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_assistant_provider.dart';

class PlayerSelector extends StatelessWidget {
  const PlayerSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final maProvider = context.watch<MusicAssistantProvider>();
    final selectedPlayer = maProvider.selectedPlayer;
    final availablePlayers = maProvider.availablePlayers;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showPlayerSelector(context, maProvider, availablePlayers),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedPlayer != null) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        selectedPlayer.name,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.speaker_group_rounded, 
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPlayerSelector(
    BuildContext context,
    MusicAssistantProvider provider,
    List players,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true, // Allow tapping outside to close
      builder: (context) {
        // Use Consumer to listen for updates while sheet is open
        return Consumer<MusicAssistantProvider>(
          builder: (context, maProvider, child) {
            // Use the fresh list of players from the provider
            final currentPlayers = maProvider.availablePlayers;
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.speaker_group_rounded, color: colorScheme.onSurface),
                            const SizedBox(width: 12),
                            Text(
                              'Select Player',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurfaceVariant),
                              onPressed: () async {
                                await maProvider.refreshPlayers();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: currentPlayers.isEmpty
                            ? Center(
                                child: Text(
                                  'No players available',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                itemCount: currentPlayers.length,
                                itemBuilder: (context, index) {
                                  final player = currentPlayers[index];
                                  final isSelected =
                                      player.playerId == maProvider.selectedPlayer?.playerId;
                                  final isOn = player.available && player.powered;
                                  final isPlaying = player.state == 'playing';
                                  final isPaused = player.state == 'paused';

                                  final colorScheme = Theme.of(context).colorScheme;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () {
                                        maProvider.selectPlayer(player);
                                        Navigator.pop(context);
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colorScheme.primary.withOpacity(0.15)
                                              : colorScheme.surfaceVariant.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(16),
                                          border: isSelected
                                              ? Border.all(color: colorScheme.primary, width: 2)
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            // Player icon
                                            Padding(
                                              padding: const EdgeInsets.only(left: 16),
                                              child: Icon(
                                                _getPlayerIcon(player.name),
                                                color: player.available
                                                    ? (isSelected ? colorScheme.primary : colorScheme.onSurface)
                                                    : colorScheme.onSurface.withOpacity(0.38),
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Player info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    player.name,
                                                    style: TextStyle(
                                                      color: player.available
                                                          ? colorScheme.onSurface
                                                          : colorScheme.onSurface.withOpacity(0.38),
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                      fontSize: 16,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      // Status indicator dot
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: !player.available
                                                              ? colorScheme.onSurface.withOpacity(0.24)
                                                              : isPlaying
                                                                  ? Colors.green
                                                                  : isPaused
                                                                      ? Colors.orange
                                                                      : colorScheme.onSurfaceVariant.withOpacity(0.5),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        !player.available
                                                            ? 'Unavailable'
                                                            : isPlaying
                                                                ? 'Playing'
                                                                : isPaused
                                                                    ? 'Paused'
                                                                    : 'Idle',
                                                        style: TextStyle(
                                                          color: player.available
                                                              ? colorScheme.onSurfaceVariant
                                                              : colorScheme.onSurface.withOpacity(0.24),
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      if (isSelected) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: colorScheme.primary.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'Selected',
                                                            style: TextStyle(
                                                              color: colorScheme.primary,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Play/Pause button
                                            if (player.available && isOn)
                                              IconButton(
                                                icon: Icon(
                                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                  color: colorScheme.onSurface,
                                                  size: 28,
                                                ),
                                                onPressed: () {
                                                  if (isPlaying) {
                                                    maProvider.pausePlayer(player.playerId);
                                                  } else {
                                                    maProvider.resumePlayer(player.playerId);
                                                  }
                                                },
                                              ),
                                            // Power button
                                            IconButton(
                                              icon: Icon(
                                                Icons.power_settings_new_rounded,
                                                size: 24,
                                                color: player.available
                                                    ? (isOn ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.5))
                                                    : colorScheme.onSurface.withOpacity(0.2),
                                              ),
                                              onPressed: player.available
                                                  ? () => maProvider.togglePower(player.playerId)
                                                  : null,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _getPlayerIcon(String playerName) {
    final nameLower = playerName.toLowerCase();

    if (nameLower.contains('music assistant mobile') || nameLower.contains('builtin')) {
      return Icons.phone_android_rounded;
    } else if (nameLower.contains('group') || nameLower.contains('sync')) {
      return Icons.speaker_group_rounded;
    } else if (nameLower.contains('bedroom') || nameLower.contains('living') ||
        nameLower.contains('kitchen') || nameLower.contains('dining')) {
      return Icons.speaker_rounded;
    } else if (nameLower.contains('tv') || nameLower.contains('television')) {
      return Icons.tv_rounded;
    } else if (nameLower.contains('cast') || nameLower.contains('chromecast')) {
      return Icons.cast_rounded;
    } else {
      return Icons.speaker_rounded;
    }
  }
}
