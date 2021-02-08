import 'package:flutter/material.dart';

class JoProgressPage extends StatefulWidget {

  final Map<String, dynamic> message;

  JoProgressPage({this.message});

  @override
  State<StatefulWidget> createState() {
    return JoProgressPageState();
  }
}

class JoProgressPageState extends State<JoProgressPage> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    print(widget.message.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Your Progress'),
      ),
      body: Center(
        child: Text(widget.message.toString()),
      ),
    );
  }
}