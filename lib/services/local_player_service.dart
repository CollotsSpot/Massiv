import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'debug_logger.dart';
import 'auth/auth_manager.dart';

/// Metadata for the currently playing track
class TrackMetadata {
  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  final Duration? duration;

  TrackMetadata({
    required this.title,
    required this.artist,
    this.album,
    this.artworkUrl,
    this.duration,
  });
}

class LocalPlayerService {
  final AuthManager authManager;
  final _logger = DebugLogger();
  bool _isInitialized = false;

  // Audio player with background support via just_audio_background
  AudioPlayer? _player;

  // Current track metadata for notifications
  TrackMetadata? _currentMetadata;

  LocalPlayerService(this.authManager);

  // Expose player state streams
  Stream<PlayerState> get playerStateStream {
    return _player?.playerStateStream ?? const Stream.empty();
  }

  Stream<Duration> get positionStream {
    return _player?.positionStream ?? const Stream.empty();
  }

  Stream<Duration?> get durationStream {
    return _player?.durationStream ?? const Stream.empty();
  }

  // Current state getters
  bool get isPlaying {
    return _player?.playing ?? false;
  }

  double get volume {
    return _player?.volume ?? 1.0;
  }

  PlayerState get playerState {
    return _player?.playerState ?? PlayerState(false, ProcessingState.idle);
  }

  Duration get position {
    return _player?.position ?? Duration.zero;
  }

  Duration get duration {
    return _player?.duration ?? Duration.zero;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.log('LocalPlayerService: Initializing with just_audio_background...');

      // Create audio player with background support
      _player = AudioPlayer();
      await _player!.setVolume(1.0);
      _logger.log('LocalPlayerService: Audio player created');

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Handle audio interruptions
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player?.setVolume(0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _player?.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player?.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              _player?.play();
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });

      // Handle becoming noisy (headphones unplugged)
      session.becomingNoisyEventStream.listen((_) {
        _player?.pause();
      });

      _logger.log('LocalPlayerService initialized with just_audio_background (background playback enabled)');

      _isInitialized = true;
    } catch (e) {
      _logger.log('Error initializing LocalPlayerService: $e');
    }
  }

  /// Set metadata for the current track (for notification display)
  void setCurrentTrackMetadata(TrackMetadata metadata) {
    _currentMetadata = metadata;
  }

  /// Play a stream URL with authentication headers
  Future<void> playUrl(String url) async {
    // Ensure player is initialized before playing
    if (!_isInitialized) {
      _logger.log('LocalPlayerService: Not initialized, initializing now...');
      await initialize();
    }

    try {
      _logger.log('LocalPlayerService: Loading URL: $url');

      // Get auth headers from AuthManager
      final headers = authManager.getStreamingHeaders();

      if (headers.isNotEmpty) {
        _logger.log('LocalPlayerService: Added auth headers to request: ${headers.keys.join(', ')}');
      } else {
        _logger.log('LocalPlayerService: No authentication needed for streaming');
      }

      if (_player != null) {
        _logger.log('LocalPlayerService: Playing with just_audio_background');

        // Create audio source with MediaItem tag for notification
        final source = AudioSource.uri(
          Uri.parse(url),
          headers: headers.isNotEmpty ? headers : null,
          tag: MediaItem(
            id: url,
            title: _currentMetadata?.title ?? 'Unknown Track',
            artist: _currentMetadata?.artist ?? 'Unknown Artist',
            album: _currentMetadata?.album ?? '',
            duration: _currentMetadata?.duration,
            artUri: _currentMetadata?.artworkUrl != null
                ? Uri.parse(_currentMetadata!.artworkUrl!)
                : null,
          ),
        );

        await _player!.setAudioSource(source);
        await _player!.play();
        _logger.log('LocalPlayerService: Playback started with notification');
      } else {
        _logger.log('LocalPlayerService: ERROR - No player available!');
      }
    } catch (e, stackTrace) {
      _logger.log('LocalPlayerService: Error playing URL: $e');
      _logger.log('LocalPlayerService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update the notification with new track info (without reloading audio)
  void updateNotification({
    required String id,
    required String title,
    String? artist,
    String? album,
    String? artworkUrl,
    Duration? duration,
  }) {
    // Update metadata for next playUrl call
    _currentMetadata = TrackMetadata(
      title: title,
      artist: artist ?? 'Unknown Artist',
      album: album,
      artworkUrl: artworkUrl,
      duration: duration,
    );

    // Note: With just_audio_background, notification updates happen automatically
    // when setting a new AudioSource with a MediaItem tag
    _logger.log('LocalPlayerService: Metadata updated for notification');
  }

  /// Update the notification while audio is already playing
  /// This re-sets the audio source with new metadata at the current position
  Future<void> updateNotificationWhilePlaying(TrackMetadata metadata) async {
    if (_player == null) return;

    final currentSource = _player!.audioSource;
    if (currentSource == null) return;

    // Get current playback state to restore after update
    final wasPlaying = _player!.playing;
    final currentPosition = _player!.position;

    _logger.log('LocalPlayerService: Updating notification mid-playback: ${metadata.title} by ${metadata.artist}');

    try {
      // Get the current URL from the audio source
      String? currentUrl;
      if (currentSource is UriAudioSource) {
        currentUrl = currentSource.uri.toString();
      } else if (currentSource is ProgressiveAudioSource) {
        currentUrl = currentSource.uri.toString();
      }

      if (currentUrl == null) {
        _logger.log('LocalPlayerService: Cannot get current URL for notification update');
        return;
      }

      // Get auth headers
      final headers = authManager.getStreamingHeaders();

      // Create new audio source with updated metadata
      final newSource = AudioSource.uri(
        Uri.parse(currentUrl),
        headers: headers.isNotEmpty ? headers : null,
        tag: MediaItem(
          id: currentUrl,
          title: metadata.title,
          artist: metadata.artist,
          album: metadata.album ?? '',
          duration: metadata.duration,
          artUri: metadata.artworkUrl != null
              ? Uri.parse(metadata.artworkUrl!)
              : null,
        ),
      );

      // Set new source and seek to current position
      await _player!.setAudioSource(newSource, initialPosition: currentPosition);

      // Resume playback if was playing
      if (wasPlaying) {
        await _player!.play();
      }

      _currentMetadata = metadata;
      _logger.log('LocalPlayerService: Notification updated successfully');
    } catch (e) {
      _logger.log('LocalPlayerService: Error updating notification: $e');
    }
  }

  Future<void> play() async {
    await _player?.play();
  }

  Future<void> pause() async {
    await _player?.pause();
  }

  Future<void> stop() async {
    await _player?.stop();
  }

  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player?.setVolume(volume.clamp(0.0, 1.0));
  }

  void dispose() {
    _player?.dispose();
  }
}
