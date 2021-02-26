import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info/device_info.dart';
import 'dart:convert';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wellmadecrm/notifications.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:wellmadecrm/settings_page.dart';
import 'package:wellmadecrm/utilities/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto/src/hmac.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jo_progress_page.dart';
import 'package:permission_handler/permission_handler.dart';

//  https://abeljoo.com/2019/07/31/flutter-zh-cn/

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
  var map;
  static int counter = 0;
  SharedPreferences prefs;

  TextEditingController joController = TextEditingController();
  TextEditingController uidController = TextEditingController();
  TextEditingController qrController = TextEditingController();

  final FirebaseMessaging _messaging = FirebaseMessaging();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  DeviceInfoPlugin deviceInfo;
  AndroidDeviceInfo androidDeviceInfo;

  String domain;
  String path;

  void getDeviceInfo() async {
    deviceInfo = DeviceInfoPlugin();
    androidDeviceInfo = await deviceInfo.androidInfo;
  }

  saveSession(String sessionId) async {
    try {
      if (sessionId.isNotEmpty) {
        await prefs.setString("sessionId", sessionId);
      }
    } catch (e) {
      Utils.toast('Session error.');
    }
  }

  storeAkPid(String ak, String pid) async {
    try {
      if (ak.isNotEmpty && pid.isNotEmpty) {
        await prefs.setString("ak", ak);
        await prefs.setString("pid", pid);
        Utils.toast('Device is registered. Please scan again');
      }
    } catch (e) {
      Utils.toast('Device registration error.');
    }
  }

  void initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    Utils.domain = prefs.getString("domain");
    Utils.path = prefs.getString("path");

    print('ak ${prefs.getString('ak')}');
    print('pid ${prefs.getString('pid')}');
  }

  @override
  void initState() {
    super.initState();

    initSharedPreferences();
    getDeviceInfo();

    _messaging.getToken().then((token) {
      if (token.isNotEmpty && androidDeviceInfo.model.isNotEmpty) {
        globalToken = token;
        tokenRequest(token, androidDeviceInfo.model);
      } else {
        Utils.toast('Failed to generate token for device');
      }
    });

    _messaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        _showNotificationWithDefaultSound(message['notification']['title'],
            message['notification']['body']);
        onMessageDialog(message);
      },
      onResume: (Map<String, dynamic> message) async {
        _showNotificationWithDefaultSound(message['notification']['title'], message['notification']['body']);
        //print('onResume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        _showNotificationWithDefaultSound(message['notification']['title'], message['notification']['body']);
      },
    );

    var initializationSettingsAndroid =
    new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

  } //  initState

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

  void tokenRequest(String token, String deviceInfo) {
    sendRequest({
      'newToken': token,
      'deviceInfo': deviceInfo,
    }, '/wellmadecrm/savedevicetoken').then((result) {

      try {
        var map = json.decode(result);
        Utils.toast(map['reason']);

        //  process cookie
        int start = cookie.indexOf('=') + 1;
        int end = cookie.indexOf(';');

        saveSession(cookie.substring(start, end));
      } catch (e) {
        Utils.toast('Device token problem');
      }
    });
  }

  void onMessageDialog(Map<String, dynamic> message) {
    if (counter % 2 == 0) {
      showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text('Wellmade', style: TextStyle(color: Colors.black87),),
            content: Text('A notification has received.', style: TextStyle(color: Colors.black54),),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Read'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => JoProgressPage(message: message,)));
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          )
      );
    }
    ++counter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home'),
        actions: <Widget>[
          /*IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()),);
            },
          ),*/
          IconButton(
            icon: Icon(Icons.update),
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
                          leading: Icon(Icons.sms,),
                          title: Text('Text', style: TextStyle(color: Colors.black54),),
                          onTap: () {
                            Navigator.of(context).pop();
                            textMe('87777');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.email),
                          title: Text('Email', style: TextStyle(color: Colors.black54),),
                          onTap: () {
                            Navigator.of(context).pop();
                            sendMail('', '', '', 'Attention');
                          },
                        ),
                      ],
                    ),
                  );
                }
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()),);
            },
          ),
        ],
      ),
      body: ModalProgressHUD(
        child: Center(child: Text(centerTxt),),
        inAsyncCall: _loading,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.open_in_new),
        label: Text('Start'),
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (BuildContext context) => CupertinoActionSheet(
              title: Text('Select Option'),
              //message: Text('Which option?'),
              actions: <Widget>[
                CupertinoActionSheetAction(
                  child: Text('Add'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    dialogShow(context);
                  },
                ),
                CupertinoActionSheetAction(
                  child: Text('Invoice Scan'),
                  onPressed: () {
                    Navigator.of(context).pop();

                    askCameraPermission().then((granted) {
                      if (granted) {
                        scanQr().then((result) {
                          var map = json.decode(result);

                          if (map['success']) {
                            qrController.text = map['data'];
                            displayDialog();
                          } else {
                            Utils.toast(map['reason']);
                          }
                        });
                      } else {
                        Utils.toast('Allow application to access camera');
                      }
                    });
                  },
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                child: Text('Cancel'),
                onPressed: () { Navigator.pop(context); },
              ),
            )
          );
        },
      ),
    );
  }

  void processResult(var result) {
    print('result $result');

    try {
      var map = json.decode(result);
      var success = map['success'];

      if (success != null) {
        if (map['success']) {

          /*
          {"data":[{
          "dt":1614161264,
          "uk":"huVC3-Qd0spM_wcUnwFM5ZAbaIBZTeQIu1Rp2VzUzPgiv",
          "ci":18857,
          "hmac":"53450f233569d23ad4c5d42c7a6de4b8f40d5fca07b744e134d8fb3a7e0555b6999e1435ad0457fd3246c3d26d4dcb17f18757f5b7d2ebb290b5d1f6889c94eb",
          "ak":"z+NNW6vTvy1c9s4F2VsAwc3GW0Ey+q+DQPDmUJys0dM="
          "pid":"akjsdashdk182938"}],
          "success":true}
           */

          storeAkPid(map['data'][0]['ak'], map['data'][0]['pid']);
        } else {
          Utils.toast(map['reason']);
        }
      }

    } catch (e) {
      Utils.toast('Exception has occured');
    }
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

  Future<String> scanQr() async {
    try {
      String barcode = await BarcodeScanner.scan();
      return '{"success": true, "reason": "OK", "data": "$barcode"}';

    } on PlatformException {
      return '{"success": false, "reason": "Allow application to access camera."}';
    } catch (e) {
      return '{"success": false, "reason": "An error occurred in scan."}';
    }
  }

  Future<bool> askCameraPermission() async {
    var status = await Permission.camera.status;

    // The user opted to never again see the permission request dialog for this
    // app. The only way to change the permission's status now is to let the
    // user manually enable it in the system settings.
    if (status.isPermanentlyDenied) {

      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text('Camera Permission', style: TextStyle(color: Colors.black87),),
          content: Text(
            'Phone has permanently denied app to use camera. Go to app system settings and turn on camera permission.',
            style: TextStyle(color: Colors.black54),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        )
      );

      return false;
    }

    if (status.isGranted) {
      return status.isGranted;
    } else {
      if (await Permission.camera.request().isGranted) {
        status = await Permission.camera.status;
        return status.isGranted;
      } else {
        return false;
      }
    }
  }

  Future<String> sendRequest(var params, var path) async {
    //print('params ${params.toString()}');

    setState(() { _loading = true; });

    var domain = Utils.domain;
    var sessionId = prefs.getString('sessionId') == null ?
            "E664A728CD9D7A8CF58EA713C8FBB79D" : prefs.getString('sessionId');

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

      cookie = response.headers['set-cookie'];

      if (response == null) {
        return '{"success": false, "reason": "The server took long to respond."}';
      } else if (response.statusCode == 200) {
        print('response.body ${response.body}');
        return response.body;
      } else {
        print(response.body);
        return '{"success": false, "reason": "Cannot resolve response."}';
      }

    } on SocketException {
      return '{"success": false, "reason": "Failed to connect to the server."}';
    } on TimeoutException {
      return '{"success": false, "reason": "The server took long to respond."}';
    } catch (e) {
      print(e.toString());
      return '{"success": false, "reason": "Unknown exception has occurred."}';
    } finally {
      setState(() { _loading = false; });
    }
  }

  void displayDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Enter JO# only', style: TextStyle(color: Colors.black54),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                enabled: false,
                style: TextStyle(color: Colors.black54),
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
                style: TextStyle(color: Colors.black54),
                keyboardType: TextInputType.text,
                maxLength: 9,
                maxLengthEnforced: true,
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
                      child: Icon(Icons.close, color: Colors.black54,),
                      onPressed: () {
                        Navigator.of(context).pop();
                        qrController.text = '';
                        joController.text = '';
                      },
                    ),
                    FlatButton(
                      child: Icon(Icons.send, color: Colors.black54,),
                      onPressed: () {
                        Navigator.of(context).pop();

                        try {

                          int dateTimeNow = DateTime.now().millisecondsSinceEpoch;
                          String key;
                          var message;
                          var secretKey;
                          var sha512Hex;
                          String localToken = globalToken.toString();
                          String uk = localToken.substring(localToken.length-45, localToken.length);
                          //String uk = localToken.substring(localToken.length-49, localToken.length-4);

                          String ak = prefs.getString('ak');
                          String pid = prefs.getString('pid');
                          String path = '';

                          if (ak == null || pid == null) {
                            key = 'secretkey123';
                            secretKey = utf8.encode(key);
                            message = utf8.encode(joController.text+qrController.text+dateTimeNow.toString());
                            sha512Hex = Hmac(sha512, secretKey).convert(message);
                            path = Utils.path+'authnewmcrm';

                          } else if (ak.isEmpty || pid.isEmpty) {
                            key = 'secretkey123';
                            secretKey = utf8.encode(key);
                            message = utf8.encode(joController.text+qrController.text+dateTimeNow.toString());
                            sha512Hex = Hmac(sha512, secretKey).convert(message);
                            path = Utils.path+'authnewmcrm';

                          } else {
                            key = ak;
                            secretKey = utf8.encode(key);
                            message = utf8.encode(joController.text+qrController.text+dateTimeNow.toString()+pid);
                            sha512Hex = Hmac(sha512, secretKey).convert(message);
                            path = Utils.path+'getjoworkstatus';
                          }

                          sendRequest({
                            'fbuk': localToken,
                            'jo': joController.text,
                            'qr': qrController.text,
                            't': dateTimeNow.toString(),
                            'h': sha512Hex.toString(),
                            'secretKey': key,
                            'uk': uk,
                            'pid': pid,
                          }, path).then((result) {
                            qrController.text = joController.text = '';
                            processResult(result);
                          });

                        } catch (e) {
                          //print('exception ${e.toString()}');
                          Utils.toast('Exception has occurred');
                        }
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

  sendMail(String joNumber, String csa, String emailAdd, String subject) async {
    // Android and iOS
    var uri = 'mailto:ddagondon@wellmade-motors.com?subject='+subject+' '+csa
        +'&body=Requesting an update for JO Number: '+joNumber+' ';

    if (await canLaunch(uri)) {
      await launch(uri);

    } else {
      throw 'Could not launch uri';
    }
  }

  textMe(String joNumber) async {
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
  }
}