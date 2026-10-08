import 'package:audio_service/audio_service.dart';

import 'locked_player.dart';

/// All platform commands cross the same restrictive boundary.
class LockedHandler extends BaseAudioHandler {
  LockedHandler(this.player);
  final LockedPlayer player;
  @override
  Future<void> play() => player.play();
  @override
  Future<void> pause() => player.pause();
  @override
  Future<void> stop() => player.pause();
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> skipToNext() async {}
  @override
  Future<void> skipToPrevious() async {}
  @override
  Future<void> skipToQueueItem(int index) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> fastForward() async {}
  @override
  Future<void> rewind() async {}
  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {}
  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {}
  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {}
  @override
  Future<void> prepareFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {}
  @override
  Future<void> prepareFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {}
  @override
  Future<void> prepareFromUri(Uri uri, [Map<String, dynamic>? extras]) async {}
  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {}
  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {}
  @override
  Future<void> updateQueue(List<MediaItem> queue) async {}
  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {}
  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {}
  @override
  Future<void> removeQueueItemAt(int index) async {}
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {}
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {}
}
