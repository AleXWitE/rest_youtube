import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() {
  runApp(MyApp());
}

class YoutubeVideos {
  final int ytId;
  final List<YoutubeVideosKeys> ytResults;

  YoutubeVideos({this.ytId, this.ytResults});

  factory YoutubeVideos.fromJson(Map<String, dynamic> json) {
    var list = json['results'] as List;

    List<YoutubeVideosKeys> listVideos =
        list.map((i) => YoutubeVideosKeys.fromJson(i)).toList();
    return YoutubeVideos(
      ytId: json['id'],
      ytResults: listVideos,
    );
  }
}

class YoutubeVideosKeys {
  String ytKey;
  String ytName;

  YoutubeVideosKeys({this.ytKey, this.ytName});

  factory YoutubeVideosKeys.fromJson(Map<String, dynamic> json) {
    return YoutubeVideosKeys(
      ytKey: json['key'],
      ytName: json['name'],
    );
  }
}

List<YoutubeVideosKeys> allYoutubeFromJson(String _str) {
  var jsonData = json.decode(_str);
  // здесь был принт, который отслеживал приходящую строку
  // в формате print("jsonData : $jsonData");
  // который в консоли не появлялся
  return List<YoutubeVideosKeys>.from(
      jsonData.map((i) => YoutubeVideos.fromJson(i).ytResults)).toList();
}

String _key = 'd0066af66423e5666c453b17ce65a444';
String _urlVideos = 'https://api.themoviedb.org/3/movie/';

Future<List<YoutubeVideosKeys>> getAllYoutube(int _id) async {
  _urlVideos = _urlVideos + '$_id/videos';
  final http.Response response =
      await http.get(Uri.parse('$_urlVideos?api_key=$_key'), headers: {
    "Accept": "application/json",
  });
  print("getAllYoutube\n${response.body}");

  return allYoutubeFromJson(response.body);
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'RestAPI Youtube'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<YoutubeVideosKeys>> getVideos;
  int _id = 580489;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(children: [
        Expanded(
            flex: 1,
            child: MaterialButton(
                child: Text("Reset"),
                onPressed: () =>
                     getVideos = getAllYoutube(_id))),
        Expanded(
          flex: 9,
          child: FutureBuilder<List<YoutubeVideosKeys>>(
            future: getVideos,
            initialData: [],
            builder: (context, snapshot) {
              print("snapshot has data ${snapshot.data}");
              int count = snapshot.data.length;
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: count,
                    itemBuilder: (context, i) =>
                        YouTubePlay(yt: snapshot.data, index: i));
              }
              return const CircularProgressIndicator();
            },
          ),
        ),
      ]),
    );
  }
}

class YouTubePlay extends StatefulWidget {
  final List<YoutubeVideosKeys> yt;
  final int index;

  YouTubePlay({Key key, this.yt, this.index}) : super(key: key);

  @override
  _YouTubePlayState createState() => _YouTubePlayState();
}

class _YouTubePlayState extends State<YouTubePlay> {
  YoutubePlayerController _controller; //объявляем контроллер для работы iframe

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.yt[widget.index].ytKey,
      params: const YoutubePlayerParams(
        showControls: true,
        autoPlay: false,
        showFullscreenButton: true,
        desktopMode: true,
      ),
    );
    _controller.onEnterFullscreen = () {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    };
    _controller.onExitFullscreen = () {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    };
    // print(
    //     "key id ${widget.yt[widget.index].ytKey}"); // эта строка тоже ничего не давала
  }

  @override
  Widget build(BuildContext context) {
    const player = YoutubePlayerIFrame(); //определяем под переменную сам iframe
    return YoutubePlayerControllerProvider(
      controller: _controller,
      child: player,
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
