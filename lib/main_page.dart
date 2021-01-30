import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info/device_info.dart';
import 'dart:convert';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:wellmadecrm/notifications.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:wellmadecrm/utilities/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto/src/hmac.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  bool _loading = false;
  var globalToken;
  var centerTxt = 'Press Start';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  var cookie;
  SharedPreferences prefs;

  TextEditingController joController = TextEditingController();
  TextEditingController uidController = TextEditingController();
  TextEditingController qrController = TextEditingController();

  final FirebaseMessaging _messaging = FirebaseMessaging();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  DeviceInfoPlugin deviceInfo;
  AndroidDeviceInfo androidDeviceInfo;

  void getDeviceInfo() async {
    deviceInfo = DeviceInfoPlugin();
    androidDeviceInfo = await deviceInfo.androidInfo;
  }

  saveSession(String sessionId) async {
    await prefs.setString("sessionId", sessionId);
  }

  void initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();

    initSharedPreferences();
    getDeviceInfo();

    _messaging.getToken().then((token) {
      if (token.isNotEmpty && androidDeviceInfo.model.isNotEmpty) {
        globalToken = token;

        saveNewToken({
          'newToken': token,
          'deviceInfo': androidDeviceInfo.model,
        }).then((result) {
          var map = json.decode(result);
          Utils.toast(map['reason']);

          //  process cookie
          int start = cookie.indexOf('=')+1;
          int end = cookie.indexOf(';');

          saveSession(cookie.substring(start, end));
        });

      } else {
        print('else');
      }
    });

    _messaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          _showNotificationWithDefaultSound(message['notification']['title'],
              message['notification']['body']);
        },
        onResume: (Map<String, dynamic> message) async {
          _showNotificationWithDefaultSound(message['notification']['title'],
              message['notification']['body']);
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

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async {}

  void _showNotificationWithDefaultSound(String title, String body) async {

    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        '3', 'ABS-CBN', 'News', importance: Importance.Max,
        priority: Priority.High);

    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();

    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(0, title, body,
      platformChannelSpecifics, payload: 'Default_Sound',);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()),);
            },
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Request Joborder By', style: TextStyle(color: Colors.black54),),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.sms),
                          title: Text('Text', style: TextStyle(color: Colors.black54),),
                          onTap: () {
                            Navigator.of(context).pop();
                            //_textMe('87777');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.email),
                          title: Text('Email', style: TextStyle(color: Colors.black54),),
                          onTap: () {
                            Navigator.of(context).pop();
                            //_sendMail('87777', 'rjordan', '', 'Attention');
                          },
                        ),
                      ],
                    ),
                  );
                }
              );
            },
          ),
        ],
      ),
      body: ModalProgressHUD(
        child: Center(
          child: Text(centerTxt),
        ),
        inAsyncCall: _loading,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.open_in_new),
        label: Text('Start'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Select', style: TextStyle(color: Colors.black54),),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.add),
                      title: Text('Add', style: TextStyle(color: Colors.black54),),
                      onTap: () {
                        Navigator.of(context).pop();
                        dialogShow(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.scanner),
                      title: Text('Scan QR', style: TextStyle(color: Colors.black54),),
                      onTap: () {
                        Navigator.of(context).pop();
                        barcodeScan(context);

                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Enter', style: TextStyle(color: Colors.black54),),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    TextField(
                                      enabled: false,
                                      controller: qrController,
                                      keyboardType: TextInputType.text,
                                      decoration: InputDecoration(
                                        labelText: 'QR',
                                        hintText: 'QR',
                                        prefixIcon: Icon(Icons.code),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                      ),
                                    ),
                                    Padding(padding: EdgeInsets.only(bottom: 10.0)),
                                    TextField(
                                      onChanged: (value) {},
                                      controller: joController,
                                      keyboardType: TextInputType.text,
                                      maxLength: 9,
                                      maxLengthEnforced: true,
                                      /*inputFormatters: [
                                        WhitelistingTextInputFormatter(RegExp("[A-Za-z0-9]")),
                                      ],*/
                                      decoration: InputDecoration(
                                        labelText: 'JO',
                                        hintText: 'JO',
                                        prefixIcon: Icon(Icons.work),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: <Widget>[
                                          FlatButton(
                                            child: Text('Submit', style: TextStyle(color: Colors.black54),),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              var key = "secretkey123";

                                              var dateTimeNow = DateTime.now().toString();
                                              var secretKey = utf8.encode(key);
                                              var message = utf8.encode(joController.text+qrController.text+dateTimeNow);
                                              var sha256Hex = Hmac(sha256, secretKey).convert(message);

                                              sendQr({
                                                'qrcode': qrController.text,
                                                'jonum': joController.text,
                                                'token': globalToken.toString(),
                                                'datetime': dateTimeNow,
                                                'hex': sha256Hex.toString(),
                                                'secretKey': key,
                                              }).then((result) {
                                                var map = json.decode(result);

                                                setState(() {
                                                  centerTxt = map['reason'];
                                                });
                                              });

                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

  void dialogShow(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter', style: TextStyle(color: Colors.black54),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {},
                controller: joController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'JO#:',
                  hintText: 'JO#:',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                ),
              ),
              Padding(padding: EdgeInsets.only(bottom: 15.0),),
              TextField(
                onChanged: (value) {},
                controller: uidController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'UID:',
                  hintText: 'UID:',
                  prefixIcon: Icon(Icons.assignment_ind),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                ),
              ),
              Padding(padding: EdgeInsets.only(bottom: 15.0),),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FlatButton(
                      child: Text('Close', style: TextStyle(color: Colors.black54),),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    FlatButton(
                      child: Text('OK', style: TextStyle(color: Colors.black54),),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  barcodeScan(BuildContext context) async {
    try {
      String barcode = await BarcodeScanner.scan();

      setState(() {
        qrController.text = barcode;
      });

    } catch (e) {
      Utils.toast(e.toString());
    }
  }

  Future<String> saveNewToken(var params) async {
    setState(() { _loading = true; });

    const domain = Utils.domain;
    const path = '/wellmadecrm/savedevicetoken';

    if (domain == null || path == null) {
      setState(() { _loading = false; });
      return '{"success": false, "reason": "Server address error."}';
    }

    if (domain.isEmpty || path.isEmpty) {
      setState(() { _loading = false; });
      return '{"success": false, "reason": "Server address error."}';
    }

    try {

      final uri = Uri.http(domain, path, params,);
      var response = await http.post(uri, headers: {
        'Accept': 'application/json',}).timeout(const Duration(seconds: 10));

      cookie = response.headers['set-cookie'];

      if (response == null) {
        return '{"success": false, "reason": "The server took long to respond."}';
      } else if (response.statusCode == 200) {
        return response.body;
      } else {
        return '{"success": false, "reason": "Cannot resolve response."}';
      }

    } on SocketException {
      return '{"success": false, "reason": "Failed to connect to the server."}';
    } on TimeoutException {
      return '{"success": false, "reason": "The server took long to respond."}';
    } catch (e) {
      return '{"success": false, "reason": "Cannot login at this time."}';
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<String> sendQr(var params) async {
    setState(() { _loading = true; });

    const domain = Utils.domain;
    const path = '/wellmadecrm/processqr';
    var sessionId = prefs.getString('sessionId');

    if (domain == null || path == null) {
      setState(() { _loading = false; });
      return '{"success": false, "reason": "Server address error."}';
    }

    if (domain.isEmpty || path.isEmpty) {
      setState(() { _loading = false; });
      return '{"success": false, "reason": "Server address error."}';
    }

    try {

      final uri = Uri.http(domain, path, params,);
      var response = await http.post(uri, headers: {
        'Accept': 'application/json',
        'Cookie': 'JSESSIONID='+sessionId,
      }).timeout(const Duration(seconds: 10));

      if (response == null) {
        return '{"success": false, "reason": "The server took long to respond."}';
      } else if (response.statusCode == 200) {
        return response.body;
      } else {
        return '{"success": false, "reason": "Cannot resolve response."}';
      }

    } on SocketException {
      return '{"success": false, "reason": "Failed to connect to the server."}';
    } on TimeoutException {
      return '{"success": false, "reason": "The server took long to respond."}';
    } catch (e) {
      print(e.toString());
      return '{"success": false, "reason": "Cannot process qr at this time."}';
    } finally {
      setState(() { _loading = false; });
    }
  }

  /*
  _sendMail(String joNumber, String csa, String emailAdd, String subject) async {

    // Android and iOS
    var uri = 'mailto:ddagondon@wellmade-motors.com?subject='+subject+' '+csa
        +'&body=Requesting an update for JO Number: '+joNumber+' ';

    if (await canLaunch(uri)) {
      await launch(uri);

    } else {
      throw 'Could not launch uri';
    }
  }

  _textMe(String joNumber) async {

    var uri = 'sms:+09 287 092 780?body=Requesting update for JO Number: '+joNumber+' ';

    if (await canLaunch(uri)) {
      await launch(uri);

    } else {

      // iOS
      const uri = 'sms:0009-287-092-780';

      if (await canLaunch(uri)) {
        await launch(uri);

      } else {
        throw 'Could not launch $uri';
      }
    }
  }*/
}