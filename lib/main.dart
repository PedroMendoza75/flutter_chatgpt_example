// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'speech_dialog.dart';
import 'constant.dart';
import 'model.dart';
import 'config_tts.dart';
import 'tts.dart';

void main() {
  runApp(const MyApp());
}

final ttsKey = GlobalKey<TtsConfigState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ttsWrapper = TtsWrapper();
    ttsWrapper.initTts();
    return MaterialApp(
      title: 'Speech to I.A.',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ChatPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

const backgroundColor = Color(0xff343541);
const botBackgroundColor = Color(0xff444654);

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

Future<String> generateResponse(String prompt) async {
  const apiKey = apiSecretKey;

  var url = Uri.https("api.openai.com", "/v1/completions");
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey'
    },
    body: jsonEncode({
      "model": "text-davinci-003",
      "prompt": prompt,
      'temperature': 0,
      'max_tokens': 2000,
      'top_p': 1,
      'frequency_penalty': 0.0,
      'presence_penalty': 0.0,
    }),
  );

  // Do something with the response
  Map<String, dynamic> newresponse = jsonDecode(response.body);
  return newresponse['choices'][0]['text'];
}

class _ChatPageState extends State<ChatPage> {
  final _textSubmitController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  late bool isLoading;
  late bool speechVisibity = false;
  late bool configVisibility = false;
  void submitter(String txt) {
    setState(
      () {
        _messages.add(
          ChatMessage(
            text: txt,
            chatMessageType: ChatMessageType.user,
          ),
        );
        isLoading = true;
      },
    );

    var input = txt;
    _textSubmitController.clear();

    Future.delayed(const Duration(milliseconds: 50)).then((_) => _scrollDown());

    generateResponse(input).then((value) {
      setState(() {
        isLoading = false;
        final txt = utf8.decode(value.runes.toList());
        _messages.add(
          ChatMessage(
            text: txt,
            chatMessageType: ChatMessageType.bot,
          ),
        );
        ttsWrapper.speak(txt);
      });
    });
    _textSubmitController.clear();
    Future.delayed(const Duration(milliseconds: 50)).then((_) => _scrollDown());
  }

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  void ttsUpdateMe() {
    setState(() {
      // tts indications change
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "OpenAI's ChatGPT",
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: botBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Color.fromRGBO(142, 142, 160, 1),
            ),
            onPressed: () async {
              setState(() {
                configVisibility = true;
              });
            },
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _buildConversation(),
                ),
                Visibility(
                  visible: isLoading,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      _buildTextEditInput(),
                      _buildTextEditSubmit(_textSubmitController),
                      _buildSpeechRecognitionSubmit(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: speechVisibity,
            child: SpeechDialog(
              submitter: submitter,
              onDismiss: () {
                setState(() {
                  speechVisibity = false;
                });
              },
            ),
          ),
          Visibility(
            visible: configVisibility,
            child: TtsConfig(
              key: ttsKey,
              ownerCallback: ttsUpdateMe,
              onDismiss: () {
                setState(() {
                  configVisibility = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  FloatingActionButton _buildSpeechRecognitionSubmit() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          speechVisibity = true;
        });
      },
      tooltip: 'Listen',
      child: const Icon(Icons.mic),
    );
  }

  Widget _buildTextEditSubmit(TextEditingController tec) {
    return Visibility(
      visible: !isLoading,
      child: Container(
        color: botBackgroundColor,
        child: IconButton(
          icon: const Icon(
            Icons.send_rounded,
            color: Color.fromRGBO(142, 142, 160, 1),
          ),
          onPressed: () async {
            submitter(tec.text);
          },
        ),
      ),
    );
  }

  Expanded _buildTextEditInput() {
    return Expanded(
      child: TextField(
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(color: Colors.white),
        controller: _textSubmitController,
        decoration: const InputDecoration(
          fillColor: botBackgroundColor,
          filled: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  ListView _buildConversation() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        var message = _messages[index];
        return ChatMessageWidget(
          text: message.text,
          chatMessageType: message.chatMessageType,
        );
      },
    );
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  const ChatMessageWidget(
      {super.key, required this.text, required this.chatMessageType});

  final String text;
  final ChatMessageType chatMessageType;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(16),
      color: chatMessageType == ChatMessageType.bot
          ? botBackgroundColor
          : backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          chatMessageType == ChatMessageType.bot
              ? Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(16, 163, 127, 1),
                    child: Image.asset(
                      'assets/chatbot-icon-16.jpg',
                      color: const Color.fromARGB(255, 245, 159, 159),
                      scale: 0.2,
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  child: const CircleAvatar(
                    child: Icon(
                      Icons.person,
                    ),
                  ),
                ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  child: Text(
                    text,
                    // If listening is active show the recognized words
                    // _speechToText.isListening ? _text : text,
                    // If listening isn't active but could be tell the user
                    // how to start it, otherwise indicate that speech
                    // recognition is not yet ready or not supported on
                    // the target device
                    // : _speechEnabled
                    //     ? 'Tap the microphone to start listening...'
                    //     : 'Speech not available',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
