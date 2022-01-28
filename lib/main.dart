import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
  EmoMap(this.user);
  final User user;

  @override
  _EmoMapState createState() => _EmoMapState();
}

class _EmoMapState extends State<EmoMap> {
  @override
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
  Future<void> getLocation() async {
    // 現在の位置を返す
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // 北緯がプラス。南緯がマイナス
    print("緯度: " + position.latitude.toString());
    // 東経がプラス、西経がマイナス
    print("経度: " + position.longitude.toString());
    setstate() {
      _location = position.toString();
    }

    ;
  }

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
