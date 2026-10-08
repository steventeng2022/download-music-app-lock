import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locked_player.dart';
import 'locked_handler.dart';

class AssetTransport implements MusicTransport {
  final AudioPlayer _audio = AudioPlayer();
  @override
  Stream<bool> get completions =>
      _audio.processingStateStream.map((s) => s == ProcessingState.completed);
  @override
  Future<void> load(String asset, Duration position) async {
    await _audio.setAsset(asset, initialPosition: position, preload: !kIsWeb);
  }

  @override
  Future<void> normalSpeed() => _audio.setSpeed(1);
  @override
  Future<void> play() async {
    unawaited(_audio.play());
  }

  @override
  Future<void> pause() => _audio.pause();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final songs = (jsonDecode(
      await rootBundle.loadString('assets/library.json'),
    ) as List).map((j) => Song.fromJson(j as Map<String, dynamic>)).toList();
    final prefs = await SharedPreferences.getInstance();
    final transport = AssetTransport();
    final player = LockedPlayer(
      songs,
      transport,
      initialIndex: prefs.getInt('index') ?? 0,
      initialPosition: Duration(milliseconds: prefs.getInt('position') ?? 0),
      wasFinished: prefs.getBool('finished') ?? false,
      save: (i, done) async {
        await prefs.setInt('index', i);
        await prefs.setInt('position', 0);
        await prefs.setBool('finished', done);
      },
    );
    await player.initialize();
    if (!kIsWeb) {
      final handler = await AudioService.init<LockedHandler>(
        builder: () => LockedHandler(player),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'app.littlemusic.playback',
          androidNotificationChannelName: '小小音樂屋',
        ),
      );
      void publish() {
        handler.mediaItem.add(
          songs.isEmpty
              ? null
              : MediaItem(
                  id: songs[player.index].id,
                  title: songs[player.index].title,
                ),
        );
        handler.playbackState.add(
          PlaybackState(
            controls: [player.playing ? MediaControl.pause : MediaControl.play],
            systemActions: const {},
            androidCompactActionIndices: const [0],
            processingState: player.finished
                ? AudioProcessingState.completed
                : AudioProcessingState.ready,
            playing: player.playing,
            speed: 1,
          ),
        );
      }

      player.addListener(publish);
      publish();
    }
    int lastSecond = -1;
    transport._audio.positionStream.listen((pos) {
      if (pos.inSeconds != lastSecond && !player.finished) {
        lastSecond = pos.inSeconds;
        unawaited(prefs.setInt('position', pos.inMilliseconds));
      }
    });
    runApp(MusicApp(player: player));
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                '音樂屋暫時無法開啟。\n請大人協助重新開啟。',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key, required this.player});
  final LockedPlayer player;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '小小音樂屋',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff316b62)),
      scaffoldBackgroundColor: const Color(0xfffff8eb),
    ),
    home: MusicHome(player: player),
  );
}

class MusicHome extends StatelessWidget {
  const MusicHome({super.key, required this.player});
  final LockedPlayer player;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: player,
        builder: (context, _) {
          final empty = player.songs.isEmpty;
          final song = empty ? null : player.songs[player.index];
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cottage_rounded, color: Color(0xff316b62)),
                        SizedBox(width: 10),
                        Text(
                          '小小音樂屋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '安心聽，慢慢長大',
                      style: TextStyle(color: Color(0xff526761)),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xffe2eedf),
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.forest_rounded,
                            size: 88,
                            color: Color(0xff316b62),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            empty
                                ? '還沒有音樂'
                                : player.finished
                                ? '今天的音樂聽完了'
                                : song!.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff214c44),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            empty
                                ? '請大人加入已授權的音樂，再更新音樂屋。'
                                : player.finished
                                ? '謝謝你一起聽音樂。休息一下吧！'
                                : song!.subtitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 72),
                                textStyle: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: empty || player.finished
                                  ? null
                                  : () async {
                                      if (player.playing) {
                                        await player.pause();
                                      } else {
                                        await player.play();
                                      }
                                    },
                              icon: Icon(
                                player.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 34,
                              ),
                              label: Text(player.playing ? '暫停一下' : '播放音樂'),
                            ),
                          ),
                          if (player.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(player.error!),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: Color(0xff526761),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '只有播放與暫停 · 固定正常速度',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '每段音樂聽完，才會接著播放下一段。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xff526761)),
                    ),
                    const SizedBox(height: 24),
                    if (!empty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '音樂小書架',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            for (var i = 0; i < player.songs.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      i < player.index || player.finished
                                          ? Icons.check_circle_outline
                                          : Icons.music_note,
                                      size: 20,
                                      color: const Color(0xff316b62),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(player.songs[i].title),
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
        },
      ),
    ),
  );
}
