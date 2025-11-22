import 'package:just_audio/just_audio.dart';
import '../models/audio_track.dart';
import 'debug_logger.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final _logger = DebugLogger();

  AudioPlayer get audioPlayer => _audioPlayer;

  List<AudioTrack> _playlist = [];
  int _currentIndex = 0;

  List<AudioTrack> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  AudioTrack? get currentTrack =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<double> get volumeStream => _audioPlayer.volumeStream;

  bool get isPlaying => _audioPlayer.playing;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;

  Future<void> setPlaylist(List<AudioTrack> tracks, {int initialIndex = 0}) async {
    _playlist = tracks;
    _currentIndex = initialIndex;

    if (_playlist.isNotEmpty) {
      await loadTrack(_currentIndex);
    }
  }

  Future<void> loadTrack(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      final track = _playlist[index];

      try {
        _logger.log('Loading track: ${track.title} from ${track.filePath}');
        // Use setUrl for HTTP streams, setFilePath for local files
        if (track.filePath.startsWith('http://') ||
            track.filePath.startsWith('https://')) {
          await _audioPlayer.setUrl(track.filePath);
          _logger.log('Track loaded from URL successfully');
        } else {
          await _audioPlayer.setFilePath(track.filePath);
          _logger.log('Track loaded from file path successfully');
        }
      } catch (e) {
        _logger.log('Error loading track: $e');
        rethrow;
      }
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    if (_currentIndex < _playlist.length - 1) {
      await loadTrack(_currentIndex + 1);
      await play();
    }
  }

  Future<void> previous() async {
    if (position.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      await loadTrack(_currentIndex - 1);
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> addToPlaylist(AudioTrack track) async {
    _playlist.add(track);
  }

  Future<void> removeFromPlaylist(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);

      if (index == _currentIndex && _playlist.isNotEmpty) {
        await loadTrack(_currentIndex.clamp(0, _playlist.length - 1));
      } else if (index < _currentIndex) {
        _currentIndex--;
      }
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
