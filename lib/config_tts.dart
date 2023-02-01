// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'tts.dart';

// late TtsConfigState willow;

class TtsConfig extends StatefulWidget {
  final VoidCallback ownerCallback;
  const TtsConfig(
      {required Key key, required this.ownerCallback, required this.onDismiss})
      : super(key: key);
  final VoidCallback onDismiss;

  @override
  TtsConfigState createState() => TtsConfigState();
}

class TtsConfigState extends State<TtsConfig> {
  int _inputLength = 4000;
  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    ttsWrapper.stop();
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(dynamic engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text(type as String)));
    }
    return items;
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      dynamic languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text(type as String)));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    // willow = this;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter TTS'),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.exit_to_app_rounded,
                color: Color.fromRGBO(142, 142, 160, 1),
              ),
              onPressed: () async {
                widget.onDismiss();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              // _inputSection(),
              // _btnSection(),
              _engineSection(),
              _futureBuilder(),
              _buildSliders(),
              if (ttsWrapper.isAndroid) _getMaxSpeechInputLengthSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _engineSection() {
    if (ttsWrapper.isAndroid) {
      return FutureBuilder<dynamic>(
          future: ttsWrapper.getEngines(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return _enginesDropDownSection(snapshot.data);
            } else if (snapshot.hasError) {
              return const Text('Error loading engines...');
            } else {
              return const Text('Loading engines...');
            }
          });
    } else {
      return const SizedBox(width: 0, height: 0);
    }
  }

  Widget _futureBuilder() => FutureBuilder<dynamic>(
      future: ttsWrapper.getLanguages(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return _languageDropDownSection(snapshot.data);
        } else if (snapshot.hasError) {
          return const Text('Error loading languages...');
        } else {
          return const Text('Loading Languages...');
        }
      });

  Widget _enginesDropDownSection(dynamic engines) => Container(
        padding: const EdgeInsets.only(top: 50.0),
        child: DropdownButton(
          value: ttsWrapper.engine,
          items: getEnginesDropDownMenuItems(engines),
          onChanged: changedEnginesDropDownItem,
        ),
      );

  void changedEnginesDropDownItem(String? selectedEngine) async {
    ttsWrapper.changedEnginesDropDownItem(selectedEngine);
    setState(() {});
  }

  Widget _languageDropDownSection(dynamic languages) => Container(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: ttsWrapper.language,
          items: getLanguageDropDownMenuItems(languages),
          onChanged: changedLanguageDropDownItem,
        ),
        // Visibility(
        //   visible: ttsWrapper.isAndroid,
        //   child: Text("Is installed: $ttsWrapper.isCurrentLanguageInstalled"),
        // ),
      ]));

  void changedLanguageDropDownItem(String? selectedType) {
    ttsWrapper.changedLanguageDropDownItem(selectedType);
    setState(() {});
  }

  Widget _getMaxSpeechInputLengthSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: const Text('Get max speech input length'),
          onPressed: () async {
            _inputLength = await ttsWrapper.getMaxSpeechInputLength();
            setState(() {});
          },
        ),
        Text("$_inputLength characters"),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      children: [_volume(), _pitch(), _rate()],
    );
  }

  Widget _volume() {
    return Slider(
        value: ttsWrapper.volume,
        onChanged: (newVolume) {
          setState(() => ttsWrapper.volume = newVolume);
        },
        min: 0.0,
        max: 1.0,
        divisions: 10,
        label: "Volume: $ttsWrapper.volume");
  }

  Widget _pitch() {
    return Slider(
      value: ttsWrapper.pitch,
      onChanged: (newPitch) {
        setState(() => ttsWrapper.pitch = newPitch);
      },
      min: 0.5,
      max: 2.0,
      divisions: 15,
      label: "Pitch: $ttsWrapper.pitch",
      activeColor: Colors.red,
    );
  }

  Widget _rate() {
    return Slider(
      value: ttsWrapper.rate,
      onChanged: (newRate) {
        setState(() => ttsWrapper.rate = newRate);
      },
      min: 0.0,
      max: 1.0,
      divisions: 10,
      label: "Rate: $ttsWrapper.rate",
      activeColor: Colors.green,
    );
  }

  // Widget _inputSection() => Container(
  //     alignment: Alignment.topCenter,
  //     padding: const EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
  //     child: TextField(
  //       maxLines: 11,
  //       minLines: 6,
  //       onChanged: (String value) {
  //         _onChange(value);
  //       },
  //     ));

  // Widget _btnSection() {
  //   return Container(
  //     padding: const EdgeInsets.only(top: 50.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         _buildButtonColumn(Colors.green, Colors.greenAccent, Icons.play_arrow,
  //             'PLAY', _speak),
  //         _buildButtonColumn(
  //             Colors.red, Colors.redAccent, Icons.stop, 'STOP', _stop),
  //         _buildButtonColumn(
  //             Colors.blue, Colors.blueAccent, Icons.pause, 'PAUSE', _pause),
  //       ],
  //     ),
  //   );
  // }

  // Column _buildButtonColumn(Color color, Color splashColor, IconData icon,
  //     String label, Function func) {
  //   return Column(
  //       mainAxisSize: MainAxisSize.min,
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         IconButton(
  //             icon: Icon(icon),
  //             color: color,
  //             splashColor: splashColor,
  //             onPressed: () => func()),
  //         Container(
  //             margin: const EdgeInsets.only(top: 8.0),
  //             child: Text(label,
  //                 style: TextStyle(
  //                     fontSize: 12.0,
  //                     fontWeight: FontWeight.w400,
  //                     color: color)))
  //       ]);
  // }
}
