import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

late TtsWrapper ttsWrapper;

enum TtsState { unavailable, playing, stopped, paused, continued }

class TtsWrapper {
  TtsWrapper();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;

  TtsState _ttsState = TtsState.unavailable;
  bool isCurrentLanguageInstalled = true;

  String? language = "es-ES";
  String? engine = "com.google.android.tts";

  double volume = 0.5;
  double pitch = 1;
  double rate = 1;

  get isPlaying => _ttsState == TtsState.playing;
  get isStopped => _ttsState == TtsState.stopped;
  get isPaused => _ttsState == TtsState.paused;
  get isContinued => _ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  final List<Function(TtsState)> _callbacks = [];

  void registerCallback(Function(TtsState) callback) {
    _callbacks.add(callback);
  }

  void _notifyCallbacks(TtsState data) {
    for (var fun in _callbacks) {
      fun(data);
    }
  }

  initTts() {
    if (_isInitialized) return;

    _isInitialized = true;

    _flutterTts = FlutterTts();

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      _notifyCallbacks(_ttsState);
    });

    if (isAndroid) {
      _flutterTts.setInitHandler(() {
        _ttsState = TtsState.playing;
        _notifyCallbacks(_ttsState);
      });
    }

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      _notifyCallbacks(_ttsState);
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
      _notifyCallbacks(_ttsState);
    });

    _flutterTts.setPauseHandler(() {
      _ttsState = TtsState.paused;
      _notifyCallbacks(_ttsState);
    });

    _flutterTts.setContinueHandler(() {
      _ttsState = TtsState.continued;
      _notifyCallbacks(_ttsState);
    });

    _flutterTts.setErrorHandler((msg) {
      // ignore: avoid_print
      print("error: $msg");
      _ttsState = TtsState.stopped;
      _notifyCallbacks(_ttsState);
    });
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    if (engine == selectedEngine) return;
    await _flutterTts.setEngine(selectedEngine!);
    language = null;
    engine = selectedEngine;
  }

  void changedLanguageDropDownItem(String? selectedType) {
    language = selectedType;
    _flutterTts.setLanguage(language!);
    if (isAndroid) {
      _flutterTts
          .isLanguageInstalled(language!)
          .then((value) => isCurrentLanguageInstalled = (value as bool));
    }
  }

  Future<dynamic> getLanguages() async => await _flutterTts.getLanguages;

  Future<dynamic> getEngines() async => await _flutterTts.getEngines;

  Future<dynamic> getMaxSpeechInputLength() async =>
      await _flutterTts.getMaxSpeechInputLength;

  Future _getDefaultEngine() async {
    var engine = await _flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future _getDefaultVoice() async {
    var voice = await _flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future speak(String text) async {
    if (isPlaying) {
      stop();
    }
    await _flutterTts.setVolume(volume);
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.setPitch(pitch);

    await _flutterTts.speak(text);
  }

  Future _setAwaitOptions() async {
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future stop() async {
    var result = await _flutterTts.stop();
    if (result == 1) {
      (() {
        _ttsState = TtsState.stopped;
        _notifyCallbacks(_ttsState);
      });
    }
  }

  Future pause() async {
    var result = await _flutterTts.pause();
    if (result == 1) {
      (() {
        _ttsState = TtsState.paused;
        _notifyCallbacks(_ttsState);
      });
    }
  }
}
