import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

void main() async {
  // 初期化処理を追加
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(EmoBotton());
}

class EmoBotton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // アプリ名
      title: 'EmoBotton',
      theme: ThemeData(
        // テーマカラー
        primarySwatch: Colors.blue,
      ),
      // ログイン画面を表示
      home: LoginPage(),
    );
  }
}

// ログイン画面用Widget
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // メッセージ表示用
  String infoText = '';
  // 入力したメールアドレス・パスワード
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // メールアドレス入力
            TextFormField(
              decoration: InputDecoration(labelText: 'メールアドレス'),
              onChanged: (String value) {
                setState(() {
                  email = value;
                });
              },
            ),
            // パスワード入力
            TextFormField(
              decoration: InputDecoration(labelText: 'パスワード'),
              obscureText: true,
              onChanged: (String value) {
                setState(() {
                  password = value;
                });
              },
            ),
            Container(
              padding: EdgeInsets.all(8),
              // メッセージ表示
              child: Text(infoText),
            ),
            Container(
              width: double.infinity,
              // ユーザー登録ボタン
              child: ElevatedButton(
                child: Text('ユーザー登録'),
                onPressed: () async {
                  try {
                    // メール/パスワードでユーザー登録
                    final FirebaseAuth auth = FirebaseAuth.instance;
                    final result = await auth.createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    await auth.createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    // ユーザー登録に成功した場合
                    // チャット画面に遷移＋ログイン画面を破棄
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) {
                        return EmoMap(result.user!);
                      }),
                    );
                  } catch (e) {
                    // ユーザー登録に失敗した場合
                    setState(() {
                      infoText = "登録に失敗しました:${e.toString()}";
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              // ログイン登録ボタン
              child: OutlinedButton(
                child: Text('ログイン'),
                onPressed: () async {
                  try {
                    // メール/パスワードでログイン
                    final FirebaseAuth auth = FirebaseAuth.instance;
                    final result = await auth.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    await auth.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    // ログインに成功した場合
                    // チャット画面に遷移＋ログイン画面を破棄
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) {
                        return EmoMap(result.user!);
                      }),
                    );
                  } catch (e) {
                    // ログインに失敗した場合
                    setState(() {
                      infoText = "ログインに失敗しました:${e.toString()}";
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// 地図画面用Widget
class EmoMap extends StatefulWidget {
  const EmoMap({Key? key}) : super(key: key);
  EmoMap(this.user);
  final User user;

  @override
  _EmoMapState createState() => _EmoMapState();
}

class _EmoMapState extends State<EmoMap> {
  final Completer<MapboxMapController> _controller = Completer();
  final Location _locationService = Location();
  // 地図スタイル用 Mapbox URL
  final String _style = '【スタイルのURL】'; // 地図を日本語化したときなどに必要
  // Location で緯度経度が取れなかったときのデフォルト値
  final double _initialLat = 35.6895014;
  final double _initialLong = 139.6917337;
  // 現在位置
  LocationData? _yourLocation;
  // GPS 追従？
  bool _gpsTracking = false;

  // 現在位置の監視状況
  StreamSubscription? _locationChangedListen;
  @override
  void initState() {
    super.initState();

    // 現在位置の取得
    _getLocation();

    // 現在位置の変化を監視
    _locationChangedListen =
        _locationService.onLocationChanged.listen((LocationData result) async {
      setState(() {
        _yourLocation = result;
      });
    });
    setState(() {
      _gpsTracking = true;
    });
  }

  @override
  void dispose() {
    super.dispose();

    // 監視を終了
    _locationChangedListen?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _makeMapboxMap(),
      floatingActionButton: _makeGpsIcon(),
    );
  }

  Widget _makeMapboxMap() {
    if (_yourLocation == null) {
      // 現在位置が取れるまではロード中画面を表示
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    // GPS 追従が ON かつ地図がロードされている→地図の中心を移動
    if (_gpsTracking) {
      _controller.future.then((mapboxMap) {
        mapboxMap.moveCamera(CameraUpdate.newLatLng(LatLng(
            _yourLocation!.latitude ?? _initialLat,
            _yourLocation!.longitude ?? _initialLong)));
      });
    }
    // Mapbox ウィジェットを返す
    return MapboxMap(
      // 地図（スタイル）を指定（デフォルト地図の場合は省略可）
      styleString: _style,
      // 初期表示される位置情報を現在位置から設定
      initialCameraPosition: CameraPosition(
        target: LatLng(_yourLocation!.latitude ?? _initialLat,
            _yourLocation!.longitude ?? _initialLong),
        zoom: 13.5,
      ),
      onMapCreated: (MapboxMapController controller) {
        _controller.complete(controller);
      },
      compassEnabled: true,
      // 現在位置を表示する
      myLocationEnabled: true,
      // 地図をタップしたとき
      onMapClick: (Point<double> point, LatLng tapPoint) {
        _controller.future.then((mapboxMap) {
          mapboxMap.moveCamera(CameraUpdate.newLatLng(tapPoint));
        });
        setState(() {
          _gpsTracking = false;
        });
      },
    );
  }

  Widget _makeGpsIcon() {
    return FloatingActionButton(
      backgroundColor: Colors.blue,
      onPressed: () {
        _gpsToggle();
      },
      child: Icon(
        // GPS 追従の ON / OFF に合わせてアイコン表示する
        _gpsTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
      ),
    );
  }

  void _gpsToggle() {
    setState(() {
      _gpsTracking = !_gpsTracking;
    });
    // ここは iOS では不要
    if (_gpsTracking) {
      _controller.future.then((mapboxMap) {
        mapboxMap.moveCamera(CameraUpdate.newLatLng(LatLng(
            _yourLocation!.latitude ?? _initialLat,
            _yourLocation!.longitude ?? _initialLong)));
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EMO MAP'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              // ログアウト処理
              // 内部で保持しているログイン情報等が初期化される
              // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫です）
              await FirebaseAuth.instance.signOut();
              // ログイン画面に遷移＋チャット画面を破棄
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.tag_faces),
        onPressed: () async {
          // 感情投稿画面に遷移
          await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => EmoSelect(widget.user)));
        },
      ),
    );
  }

  void _getLocation() async {
    _yourLocation = await _locationService.getLocation();
  }
}

// 感情画面用Widget
class EmoSelect extends StatefulWidget {
  // 使用するStateを指定
  EmoSelect(this.user);
  final User user;

  @override
  _EmoSelectState createState() => _EmoSelectState();
}

class _EmoSelectState extends State<EmoSelect> {
  int countangry = 0;
  int counthappy = 0;
  int countsad = 0;
  String _location = "no data";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emo botton',
      theme: ThemeData(primarySwatch: Colors.red),
      home: Scaffold(
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 32),
              child: Text('Emotiony'),
            ),
            Container(
              padding: EdgeInsets.only(top: 32),
              child: Text(''),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(countangry.toString()),
                OutlinedButton.icon(
                  //怒ってるよ
                  onPressed: () {
                    print('object');
                    setState(() {
                      countangry = countangry + 1;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    primary: Colors.red,
                  ),
                  icon: Icon(Icons.sentiment_dissatisfied, color: Colors.red),
                  label: Text('angry'),
                ),
                Text(counthappy.toString()),
                OutlinedButton.icon(
                  //喜んでるよ！
                  onPressed: () {
                    print('object');
                    setState(() {
                      counthappy = counthappy + 1;
                    });
                  },

                  style: OutlinedButton.styleFrom(
                    primary: Colors.orange,
                  ),
                  icon: Icon(Icons.mood, color: Colors.orange),
                  label: Text('happy'),
                ),
                Text(countsad.toString()),
                OutlinedButton.icon(
                  //悲しんでるよ
                  onPressed: () {
                    print('object');
                    setState(() {
                      countsad = countsad + 1;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    primary: Colors.blue,
                  ),
                  icon: Icon(Icons.mood_bad, color: Colors.blue),
                  label: Text('sad'),
                ),
              ],
            ),
            Center(
              child: ElevatedButton(
                child: Text('発射'),
                onPressed: () async {
                  final date =
                      DateTime.now().toLocal().toIso8601String(); // 現在の日時
                  final email = widget.user.email; // AddPostPage のデータを参照
                  // 投稿メッセージ用ドキュメント作成
                  await FirebaseFirestore.instance
                      .collection('posts') // コレクションID指定
                      .doc(date) // ドキュメントID自動生成
                      .set({
                    'happy': counthappy,
                    'sad': countsad,
                    'angry': countangry,
                    'email': email,
                    'geopoint': _location,
                    'date': date
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
