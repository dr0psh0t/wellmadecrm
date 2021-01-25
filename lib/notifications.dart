import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'model/notification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

class NotificationsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NotificationsPageState();
  }
}

class NotificationsPageState extends State<NotificationsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _loading = false;

  Future<List<Notifs>> notificationFuture;

  final FirebaseMessaging _messaging = FirebaseMessaging();
  FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();

    //  fetch notifications
    notificationFuture = fetchNotifs();

    _messaging.configure(
        onMessage: (Map<String, dynamic> message) async {

          _showNotificationWithDefaultSound(message['notification']['title'],
              message['notification']['body']);

          //  setting again the notificationFuture will update the notification list
          setState(() {
            notificationFuture = fetchNotifs();
          });
        },
        onResume: (Map<String, dynamic> message) async {
          _showNotificationWithDefaultSound(message['notification']['title'],
              message['notification']['body']);

          //  setting again the notificationFuture will update the notification list
          setState(() {
            notificationFuture = fetchNotifs();
          });
        },
        onLaunch: (Map<String, dynamic> message) async {
          print('on launch $message');
        }
    );

    var initializationSettingsAndroid =
    new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS
    );

    _notificationsPlugin = new FlutterLocalNotificationsPlugin();

    _notificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

  } //  end initState()

  Future onSelectNotification(String payload) async {}

  void _showNotificationWithDefaultSound(String title, String body) async {

    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        '3', 'ABS-CBN', 'News', importance: Importance.Max,
        priority: Priority.High);

    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();

    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await _notificationsPlugin.show(0, title, body,
      platformChannelSpecifics, payload: 'Default_Sound',);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Notifications'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                notificationFuture = fetchNotifs();
              });
            },
          ),
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        child: FutureBuilder<List<Notifs>>(
          future: notificationFuture,
          builder: (context, snapshot) {

            if (snapshot.hasError) {
              print(snapshot.error);
            }

            List<Notifs> notificationsList = snapshot.data;

            if (snapshot.hasData) {

              return ListView.separated(
                itemCount: notificationsList.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    leading: Icon(Icons.notifications),
                    selected: true,
                    title: Text(notificationsList[index].title),
                    subtitle: Text(notificationsList[index].body),
                    onTap: () {

                    },
                  );
                },
                padding: EdgeInsets.all(1.0),
                separatorBuilder: (context, index) => Divider(color: Colors.black26,),
              );
            } else {
              return Center(child: new CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Future<List<Notifs>> fetchNotifs() async {

    setState(() {
      _loading = true;
    });

    final uri = Uri.http('192.168.1.30:8080', '/wellmadecrm/getnotifications',
        {'asdasd': 'asdasd'});

    var response = await http.post(uri, headers: {
      'Accept':'application/json',
    });

    setState(() {
      _loading = false;
    });

    if (response == null) {
      return null;
    } else if (response.statusCode == 200) {
      return compute(parseData, response.body);
    } else {
      return null;
    }
  }
}

List<Notifs> parseData(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Notifs>((json) => Notifs.fromJson(json)).toList();
}