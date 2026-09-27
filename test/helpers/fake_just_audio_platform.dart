import 'dart:async';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class FakeJustAudioPlatform extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return FakeAudioPlayerPlatform(request.id);
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async =>
      DisposePlayerResponse.fromMap(const <dynamic, dynamic>{});

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async =>
      DisposeAllPlayersResponse.fromMap(const <dynamic, dynamic>{});
}

class FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  FakeAudioPlayerPlatform(super.id);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      StreamController<PlaybackEventMessage>.broadcast().stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream =>
      StreamController<PlayerDataMessage>.broadcast().stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async =>
      LoadResponse(duration: const Duration(minutes: 3));

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();

  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async =>
      SetShuffleModeResponse();
}
