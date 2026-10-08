import 'dart:async';

import 'package:flutter/foundation.dart';

class Song {
  const Song(this.id, this.title, this.subtitle, this.asset);
  final String id, title, subtitle, asset;
  factory Song.fromJson(Map<String, dynamic> j) => Song(
    j['id'] as String,
    j['title'] as String,
    j['subtitle'] as String,
    j['asset'] as String,
  );
}

abstract interface class MusicTransport {
  Stream<bool> get completions;
  Future<void> load(String asset, Duration position);
  Future<void> play();
  Future<void> pause();
  Future<void> normalSpeed();
}

class LockedPlayer extends ChangeNotifier {
  LockedPlayer(
    List<Song> songs,
    this.transport, {
    int initialIndex = 0,
    this.initialPosition = Duration.zero,
    bool wasFinished = false,
    this.save,
  }) : songs = List.unmodifiable(songs),
       _index = songs.isEmpty ? 0 : initialIndex.clamp(0, songs.length - 1),
       finished = wasFinished;
  final List<Song> songs;
  final MusicTransport transport;
  final Duration initialPosition;
  final Future<void> Function(int index, bool finished)? save;
  int _index;
  int get index => _index;
  bool playing = false, finished, _transition = false, _completed = false;
  String? error;
  StreamSubscription<bool>? _subscription;
  Future<void> initialize() async {
    _subscription = transport.completions.listen((done) {
      if (!done) {
        _completed = false;
        return;
      }
      if (_completed || _transition || finished || !playing) return;
      _completed = true;
      unawaited(_advance());
    });
    if (songs.isNotEmpty) {
      await transport.load(songs[_index].asset, initialPosition);
    }
  }

  Future<void> _advance() async {
    _transition = true;
    try {
      if (_index + 1 >= songs.length) {
        finished = true;
        await pause();
      } else {
        _index++;
        await save?.call(_index, false);
        await transport.load(songs[_index].asset, Duration.zero);
        await transport.normalSpeed();
        await transport.play();
      }
      await save?.call(_index, finished);
    } catch (_) {
      error = '音樂暫時無法播放，請大人協助。';
      await pause();
    }
    _transition = false;
    notifyListeners();
  }

  Future<void> play() async {
    if (songs.isEmpty || finished || _transition) return;
    try {
      await transport.normalSpeed();
      await transport.play();
      playing = true;
      error = null;
    } catch (_) {
      playing = false;
      error = '音樂暫時無法播放，請大人協助。';
    }
    notifyListeners();
  }

  Future<void> pause() async {
    await transport.pause();
    playing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
