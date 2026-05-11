import 'package:flutter/foundation.dart';

class AudioProvider extends ChangeNotifier {
  String? _currentUrl;
  String? _surahName;
  int? _playingVerseId;

  String? get currentUrl => _currentUrl;
  String? get surahName => _surahName;
  int? get playingVerseId => _playingVerseId;
  bool get isPlaying => _currentUrl != null;

  void playAudio({
    required String url,
    required String surahName,
    required int playingVerseId,
  }) {
    _currentUrl = url;
    _surahName = surahName;
    _playingVerseId = playingVerseId;
    notifyListeners();
  }

  void stop() {
    _currentUrl = null;
    _surahName = null;
    _playingVerseId = null;
    notifyListeners();
  }
}
