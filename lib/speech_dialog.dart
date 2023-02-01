// ignore_for_file: avoid_print

import 'package:avatar_glow/avatar_glow.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechDialog extends StatefulWidget {
  final Function(String) submitter;
  final VoidCallback onDismiss;
  const SpeechDialog(
      {super.key, required this.submitter, required this.onDismiss});

  @override
  SpeechDialogState createState() => SpeechDialogState();
}

class SpeechDialogState extends State<SpeechDialog> {
  final _speechToText = SpeechToText();
  late bool isLoading;
  bool isListening = false;
  double confidence = 0;
  String speechedText = "Please don't be silly";
  String lastSpeech = '';
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    isLoading = false;
  }

  get errorListener => null;

  get statusListener => null;

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
        //_speechEnabled
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
        options: [SpeechToText.androidNoBluetooth]);
    setState(() {
      if (_speechEnabled) {
        _toogleListening();
      }
    });
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      speechedText = "$lastSpeech\n${result.recognizedWords}";
      if (result.hasConfidenceRating && result.confidence > 0) {
        confidence = result.confidence;
      }
      if (result.finalResult) {
        lastSpeech = speechedText;
        isListening = false;
      }
    });
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      isListening = true;
    });
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      isListening = false;
    });
  }

  void _toogleListening() {
    if (isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _clearText() {
    setState(() {
      lastSpeech = speechedText = '';
    });
  }

  final Map<String, HighlightedWord> highlights = {
    'flutter': HighlightedWord(
      onTap: () => print('flutter'),
      textStyle: const TextStyle(
        fontSize: 32.0,
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    ),
    'voice': HighlightedWord(
      onTap: () => print('voice'),
      textStyle: const TextStyle(
        fontSize: 32.0,
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
    'subscribe': HighlightedWord(
      onTap: () => print('subscribe'),
      textStyle: const TextStyle(
        fontSize: 32.0,
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
    ),
    'like': HighlightedWord(
      onTap: () => print('like'),
      textStyle: const TextStyle(
        fontSize: 32.0,
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
    ),
    'comment': HighlightedWord(
      onTap: () => print('comment'),
      textStyle: const TextStyle(
        fontSize: 32.0,
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confidence: ${(confidence * 100.0).toStringAsFixed(1)}%'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.exit_to_app_rounded,
              color: Color.fromRGBO(142, 142, 160, 1),
            ),
            onPressed: () async {
              _stopListening();
              _clearText();
              widget.onDismiss();
            },
          ),
        ],
      ),
      persistentFooterButtons: [
        // any widget here
        Visibility(
          visible: !isLoading,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Color.fromRGBO(142, 142, 160, 1),
                ),
                onPressed: () async {
                  _stopListening();
                  widget.submitter(speechedText);
                  _clearText();
                  widget.onDismiss();
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Color.fromRGBO(142, 142, 160, 1),
                ),
                onPressed: () async {
                  _clearText();
                },
              ),
            ],
          ),
        ),
        //const SizedBox(width: 15),
        // const SizedBox(width: 10),
      ],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: isListening,
        glowColor: Colors.lightBlue,
        endRadius: 75.0,
        duration: const Duration(milliseconds: 2000),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,
        child: FloatingActionButton(
          onPressed: () {
            if (_speechEnabled) {
              _toogleListening();
            }
          },
          child: Icon(isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: TextHighlight(
            text: speechedText,
            words: highlights,
            textStyle: const TextStyle(
              fontSize: 32.0,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
