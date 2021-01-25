import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:qr_mobile_vision/qr_mobile_vision.dart';
//import 'slide_right_route.dart';
import 'main_page.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class QrCameraPage extends StatefulWidget {
  QrCameraPage({Key key, this.callback}) : super(key: key);

  final Function callback;

  @override
  QrCameraState createState() => QrCameraState();
}

class QrCameraState extends State<QrCameraPage> {
  List<BarcodeFormats> formats;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isScanned = false;

  @override
  void initState() {
    super.initState();
    formats = [BarcodeFormats.QR_CODE];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: QrCamera(
              formats: formats,
              qrCodeCallback: (code) {

                if (!isScanned) {

                  setState(() {
                    isScanned = true;
                  });

                  /*
                  final alphanumeric = RegExp(r'^\*[a-zA-Z0-9]+\*[a-zA-Z0-9]+\*+$');
                  if (!alphanumeric.hasMatch(code)) {
                    code = 'Will not accept the QR code.';
                  }*/

                  this.widget.callback(code);

                  dialogShow(code);
                }
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/cross-hair.png',
                  width: 200.0,
                  height: 200.0,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 30.0),
                  child: Text('Start scanning QR code', style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void dialogShow(String code) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(code),
          actions: <Widget>[
            FlatButton(
              child: Text('Close'),
              onPressed: () {
                futureDelay();
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                futureDelay();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      }
    ).then((val) {
      futureDelay();
    });
  }

  void futureDelay() {
    Future.delayed(const Duration(milliseconds: 500), (){
      setState(() {
        isScanned = false;
      });
    });
  }

  Future<Map> sendQr(var params) async {

     var returnMap = Map();
     returnMap['success'] = false;

     var domain = 'custcare.wellmade-motors.com:8899';
     var path = '/jo/';

     try {

       final uri = Uri.http(domain, path, params,);
       var response = await http.post(uri, headers: {'Accept': 'application/json'});

       if (response == null) {
         returnMap['reason'] = 'No response received.';
       } else if (response.statusCode == 200) {
         var result = json.decode(response.body);

         returnMap['success'] = result['success'];
         returnMap['reason'] = result['reason'];

         if (result['success']) {

         } else {

         }
       }

     } on SocketException {
       // setstate saving false
       returnMap['reason'] = 'Unable to create connection to the server.';
       return returnMap;
     } catch (e) {
       // setstate saving false
       returnMap['reason'] = e.toString();
       return returnMap;
     }
  }
}