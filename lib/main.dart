import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage('Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(this.title, {Key? key}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _player = AudioPlayer();
  final _pasutakutta = AudioPlayer();
  late PlatformFile filePath;
  bool _isSetMusic = false;
  bool _isPlay = false;
  bool _isCanSet = false;

  // RangeValues _currentRangeValues = const RangeValues(0, 100);
  Duration? audioSize;

  // bool _isSetMusic = false;
  // int nowTime = 0;
  // Duration? audioSize = const Duration(seconds: 100);
  final RangeMan _rangeMan = RangeMan(const RangeValues(0, 0));

  void changeIsSet(bool _a) {
    setState(() {
      _isSetMusic = _a;
      _isCanSet = _a;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _player.dispose();
    _pasutakutta.dispose();
  }

  String _fix2(int value) {
    return value.toString().padLeft(2, "0");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0))),
            onPressed: () async {
              _player.stop();
              _player.setVolume(0);
              _pasutakutta.stop();
              _pasutakutta.setVolume(0);

              changeIsSet(false);
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.audio,
                );
                if (result != null) {
                  filePath = result.files.first;
                  audioSize = await _player.setFilePath(filePath.path!);
                  setState(() {
                    _rangeMan.range =
                        RangeValues(0, audioSize?.inSeconds.toDouble() ?? 0);
                  });
                  changeIsSet(true);
                }
              } catch (e) {
                debugPrint('loaderror: ${e.toString()}');
              }
            },
            icon: const Icon(Icons.library_music),
            label: const Text("Select Music"),
          ),
          AbsorbPointer(
            absorbing: !_isCanSet,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: StreamBuilder<Duration?>(
                stream: _player.positionStream,
                builder: (context, snapshot) {
                  return ProgressBar(
                      baseBarColor: _isCanSet ? null : Colors.grey.shade300,
                      progressBarColor: _isCanSet ? null : Colors.grey,
                      thumbColor: _isCanSet ? null : Colors.grey,
                      progress: snapshot.data ?? Duration.zero,
                      total: audioSize ?? Duration.zero,
                      onSeek: (duration) {
                        _player.seek(duration);
                      });
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RoundedIconButton(
                primaryColor: _isCanSet ? Colors.blueAccent : Colors.grey,
                icon: _isPlay
                    ? const Icon(Icons.pause)
                    : const Icon(Icons.play_arrow),
                onPressed: () {
                  if (_isPlay == true) {
                    setState(() {
                      _player.pause();
                      _pasutakutta.stop();
                      _isPlay = false;
                    });
                  } else {
                    setState(() {
                      _player.setVolume(1);
                      _player.play();
                      _isPlay = true;
                    });
                  }
                },
              ),
              RoundedIconButton(
                primaryColor: _isSetMusic ? Colors.blueAccent : Colors.grey,
                icon: const Icon(Icons.restart_alt),
                onPressed: () {
                  if (_isSetMusic) {
                    setState(() {
                      _isPlay = false;
                    });
                    changeIsSet(true);
                    _player.stop();
                    _player.seek(Duration.zero);
                    _pasutakutta.stop();
                    _pasutakutta.seek(Duration.zero);
                  }
                },
              ),
            ],
          ),
          Card(
            child: TextButton(
              onPressed: () async {
                if (_isSetMusic) {
                  await _pasutakutta.setFilePath(filePath.path!);
                  await _pasutakutta.setClip(
                      start: Duration(seconds: _rangeMan.range.start.floor()),
                      end: Duration(seconds: _rangeMan.range.end.floor()));
                  await _pasutakutta.setVolume(1);
                  await _player.setVolume(0);
                  await _pasutakutta.play();
                  await _player.setVolume(1);
                  await _pasutakutta.stop();
                  await _pasutakutta.setVolume(0);
                }
              },
              child: const Icon(
                Icons.music_note,
                size: 80,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "${Duration(seconds: _rangeMan.range.start.floor()).inMinutes}:${_fix2(Duration(seconds: _rangeMan.range.start.floor()).inSeconds % 60)}"),
                      Text(
                          "${Duration(seconds: _rangeMan.range.end.floor()).inMinutes}:${_fix2(Duration(seconds: _rangeMan.range.end.floor()).inSeconds % 60)}")
                    ]),
              ),
              RangeSlider(
                min: 0,
                max: audioSize?.inSeconds.toDouble() ?? 0,
                values: _rangeMan.range,
                onChanged: _isCanSet
                    ? (value) {
                        if (_pasutakutta.playerState.playing == true) {
                          _pasutakutta.stop();
                        }
                        setState(() {
                          final double _rStart = value.start.floorToDouble();
                          final double _rEnd = value.end.floorToDouble();
                          _rangeMan.range = RangeValues(_rStart, _rEnd);
                        });
                      }
                    : null,
                labels: RangeLabels(
                    "${Duration(seconds: _rangeMan.range.start.floor()).inMinutes}:${Duration(seconds: _rangeMan.range.start.floor()).inSeconds % 60}",
                    "${Duration(seconds: _rangeMan.range.end.floor()).inSeconds % 60}:${Duration(seconds: _rangeMan.range.end.floor()).inSeconds % 60}"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RangeMan {
  RangeMan(this.range);
  RangeValues range;
  RangeLabels get label {
    Duration _start = Duration(seconds: range.start.floor());
    Duration _end = Duration(seconds: range.end.floor());
    return RangeLabels("${_start.inMinutes}:${(_dSecond(_start.inSeconds))}",
        "${_end.inMinutes}:${_dSecond(_end.inSeconds)}");
  }

  String _dSecond(int seconds) {
    final _re = "${seconds % 60}";
    return _re.padLeft(2, "0");
  }
}

class RoundedIconButton extends StatelessWidget {
  const RoundedIconButton(
      {Key? key,
      this.onPressed,
      required this.icon,
      this.primaryColor,
      this.onPrimaryColor})
      : super(key: key);
  final VoidCallback? onPressed;
  final Widget icon;
  final Color? onPrimaryColor;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Ink(
        decoration: ShapeDecoration(
            shape: const CircleBorder(),
            color: primaryColor ?? Theme.of(context).primaryColor),
        child: IconButton(
            splashRadius: 100,
            icon: icon,
            color: onPrimaryColor ??
                Theme.of(context).buttonTheme.colorScheme?.onPrimary ??
                Colors.white,
            onPressed: onPressed),
      ),
    );
  }
}
