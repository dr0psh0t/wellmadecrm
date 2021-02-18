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

  void getDeviceInfo() async {
    deviceInfo = DeviceInfoPlugin();
    androidDeviceInfo = await deviceInfo.androidInfo;
  }

  saveSession(String sessionId) async {
    await prefs.setString("sessionId", sessionId);
  }

  storeAk(String ak) async {
    await prefs.setString("ak", ak);
    Utils.toast('Device is registered. Please scan again');
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

        sendRequest({
          'newToken': token,
          'deviceInfo': androidDeviceInfo.model,
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

      } else {
        Utils.toast('Failed to generate token for device');
      }
    });

    _messaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          _showNotificationWithDefaultSound(message['notification']['title'],
              message['notification']['body']);

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
        },
        onResume: (Map<String, dynamic> message) async {
          //_showNotificationWithDefaultSound(message['notification']['title'], message['notification']['body']);
          print('onResume $message');
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
    try {
      var map = json.decode(result);
      var success = map['success'];

      if (success != null) {
        if (map['success']) {
          //{"data":[{"uk":"uVC3-Qd0spM_wcUnwFM5ZAbaIBZTeQIu1Rp2VzUzPgivs","ci":0,"ak":"6G5CHhvNK\/6wIj7lPw+HbvFdJswwVIoeZ10NhpukPnk="}],"success":true}
          storeAk(map['data'][0]['ak']);
        } else {
          Utils.showSnackbar(map['reason'], 'OK', _scaffoldKey);
        }
      }

    } catch (e) {
      Utils.showSnackbar('Exception has occured', 'OK', _scaffoldKey);
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
    setState(() { _loading = true; });

    const domain = Utils.domain;
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
        print('path $path');
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

                        String key = "secretkey123";
                        String dateTimeNow = DateTime.now().toString();
                        var secretKey = utf8.encode(key);
                        var message = utf8.encode(joController.text+qrController.text+dateTimeNow);
                        var sha256Hex = Hmac(sha256, secretKey).convert(message);
                        String localToken = globalToken.toString();
                        String uk = localToken.substring(localToken.length-45, localToken.length);

                        String ak = prefs.getString("ak");
                        String path = '';

                        if (ak == null) {
                          path = '/wellmadecrm/authnewmcrm';
                        } else if (ak.isEmpty){
                          path = '/wellmadecrm/authnewmcrm';
                        } else {
                          path = '/wellmadecrm/processqr';
                        }

                        sendRequest({
                          'fbuk': localToken,
                          'jo': joController.text,
                          'qr': qrController.text,
                          't': dateTimeNow,
                          'h': sha256Hex.toString(),
                          'secretKey': key,
                          'uk': uk,
                        }, path).then((result) {

                          qrController.text = '';
                          joController.text = '';

                          processResult(result);
                        });

                        //if no api key saved, call authnewmcrm and if success, it will return json like this:
                        //{"data":[{"uk":"uVC3-Qd0spM_wcUnwFM5ZAbaIBZTeQIu1Rp2VzUzPgivs","ci":0,"ak":"6G5CHhvNK\/6wIj7lPw+HbvFdJswwVIoeZ10NhpukPnk="}],"success":true}
                        //else call processqr with the api key
                        //if calling authnewmcrm and customer is already registered, it will return json like this:
                        //{"reason":"Customer Already Registered.","success":false}

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