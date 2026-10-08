import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_music/locked_player.dart';
import 'package:little_music/locked_handler.dart';

class FakeTransport implements MusicTransport {
  final events = StreamController<bool>.broadcast(sync: true);
  final loads = <String>[];
  bool playing = false;
  double rate = 1;
  @override
  Stream<bool> get completions => events.stream;
  @override
  Future<void> load(String asset, Duration position) async {
    loads.add(asset);
  }

  @override
  Future<void> play() async {
    playing = true;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  Future<void> normalSpeed() async {
    rate = 1;
  }
}

class FailingTransport extends FakeTransport {
  @override
  Future<void> load(String asset, Duration position) async {
    if (asset == 'b') throw StateError('missing asset');
    await super.load(asset, position);
  }
}

void main() {
  test('play loads only first allowlisted asset at normal speed', () async {
    final t = FakeTransport()..rate = 2;
    final p = LockedPlayer(const [Song('a', 'A', '', 'assets/music/a.mp3')], t);
    await p.initialize();
    await p.play();
    expect(t.loads, ['assets/music/a.mp3']);
    expect(t.rate, 1);
    expect(p.playing, isTrue);
  });
  test('pause and non-completion events never advance; natural completion advances once', () async {
    final t = FakeTransport();
    final p = LockedPlayer(const [
      Song('a', 'A', '', 'a'),
      Song('b', 'B', '', 'b'),
    ], t);
    await p.initialize();
    await p.play();
    await p.pause();
    t.events.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(t.loads, ['a']);
    expect(p.playing, isFalse);
    await p.play();
    t.events.add(true);
    t.events.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(t.loads, ['a', 'b']);
    expect(p.index, 1);
    expect(p.playing, isTrue);
    t.events.add(false);
    t.events.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(p.finished, isTrue);
    expect(p.playing, isFalse);
    await p.play();
    expect(t.loads, ['a', 'b']);
  });
  test('saved progress restores without selecting another track', () async {
    final t = FakeTransport();
    final p = LockedPlayer(
      const [Song('a', 'A', '', 'a'), Song('b', 'B', '', 'b')],
      t,
      initialIndex: 1,
    );
    await p.initialize();
    expect(t.loads, ['b']);
    expect(p.playing, isFalse);
  });
  test(
    'headset and remote commands cannot skip seek speed or import',
    () async {
      final t = FakeTransport();
      final p = LockedPlayer(const [Song('a', 'A', '', 'a')], t);
      await p.initialize();
      final h = LockedHandler(p);
      await h.skipToNext();
      await h.skipToPrevious();
      await h.skipToQueueItem(10);
      await h.seek(const Duration(hours: 1));
      await h.setSpeed(2);
      await h.fastForward();
      await h.rewind();
      await h.playFromUri(Uri.parse('https://example.com/song.mp3'));
      expect(t.loads, ['a']);
      expect(t.rate, 1);
      expect(p.playing, isFalse);
      await h.play();
      expect(p.playing, isTrue);
      await h.pause();
      expect(p.playing, isFalse);
    },
  );
  test('load failure is surfaced instead of advancing silently', () async {
    final t = FailingTransport();
    final p = LockedPlayer(const [
      Song('a', 'A', '', 'a'),
      Song('b', 'B', '', 'b'),
    ], t);
    await p.initialize();
    await p.play();
    t.events.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(p.error, isNotNull);
    expect(p.playing, isFalse);
  });
  test('completion while paused is ignored', () async {
    final t = FakeTransport();
    final p = LockedPlayer(const [
      Song('a', 'A', '', 'a'),
      Song('b', 'B', '', 'b'),
    ], t);
    await p.initialize();
    await p.play();
    await p.pause();
    t.events.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(p.index, 0);
    expect(t.loads, ['a']);
  });
  test('completed state survives reopen without replay', () async {
    final t = FakeTransport();
    final p = LockedPlayer(
      const [Song('a', 'A', '', 'a')],
      t,
      wasFinished: true,
    );
    await p.initialize();
    await p.play();
    expect(p.finished, isTrue);
    expect(p.playing, isFalse);
  });
  test('play before initialization cannot start unloaded audio', () async {
    final t = FakeTransport();
    final p = LockedPlayer(const [Song('a', 'A', '', 'a')], t);
    await p.play();
    expect(t.playing, isFalse);
    expect(p.playing, isFalse);
  });
  test('empty library cannot play or load arbitrary media', () async {
    final t = FakeTransport();
    final p = LockedPlayer([], t);
    await p.initialize();
    await p.play();
    expect(t.loads, isEmpty);
    expect(p.playing, isFalse);
  });
}
