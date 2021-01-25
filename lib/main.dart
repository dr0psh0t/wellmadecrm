import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';
import 'package:wellmadecrm/main_page.dart';
import 'login_screen.dart';
//import 'package:flutter/services.dart';

void main() {
  /*
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new MaterialApp(home: new MyApp(),));
  });*/

  WidgetsFlutterBinding.ensureInitialized();
  //runApp(new MaterialApp(home: new MyApp(),));
  runApp(new MaterialApp(home: new MainPage(),));
}

/*
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return LoginScreen();
  }
}*/