import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wellmadecrm/utilities/utils.dart';
import 'register_screen.dart';
import 'main_page.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'dart:async';
import 'package:validate/validate.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      home: LoginPage(),
      routes: {
        "/reg": (_) => RegisterScreen(),/*
        "/mainmenu": (_) => MainMenuApp(),*/
        '/mainpage': (_) => MainPage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => new LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool _saving = false;
  bool _obscureText = true;

  final _scaffoldKey =GlobalKey<ScaffoldState>();
  final controllerEmail =TextEditingController();
  final controllerPassword =TextEditingController();

  @override
  void initState() {
    super.initState();
    showPrefs();

    controllerEmail.text = 'akjsdhakjsd@akljsd.com';
    controllerPassword.text = 'ajsd123akjs';
  }

  void showPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    controllerEmail.text =prefs.getString('email');
    controllerPassword.text =prefs.getString('password');

    await prefs.setString('domain', 'custcare.wellmade-motors.com:8899');
    await prefs.setString('path', '/jo/');
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Widget buildWidget(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(color: Colors.white,),
      child: ListView(
        children: <Widget>[
          Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width,
                height: 220.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage('assets/images/wm_global.jpg'),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 40.0),
            child: TextField(
              onChanged: (value) {},
              controller: controllerEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0))
                ),
              ),
              style: TextStyle(color: Colors.black54),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
            child: TextField(
              onChanged: (value) {},
              controller: controllerPassword,
              keyboardType: TextInputType.text,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Password',
                prefixIcon: Icon(Icons.assignment_ind),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                  onPressed: _toggle,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0))
                ),
              ),
              style: TextStyle(color: Colors.black54),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(top: 20.0),
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FlatButton(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                    splashColor: Colors.blue,
                    color: Colors.blue,
                    child: Padding(
                      padding: const EdgeInsets.all(17.0),
                      child: Text('Login', style: TextStyle(color: Colors.white),),
                    ),
                    onPressed: () {

                      if (controllerEmail.text.isEmpty) {
                        Utils.getDialog('Enter Email.', context);
                      } else {
                        try {
                          Validate.isEmail(controllerEmail.text);
                        } catch (e) {
                          Utils.getDialog('Email address is not valid.', context);
                        }
                      }

                      if (controllerPassword.text.isEmpty) {
                        Utils.getDialog('Enter Password.', context);
                      }

                      login({
                        'email': controllerEmail.text,
                        'password': controllerPassword.text,
                      }).then((result) {
                        print(result);
                        Navigator.of(context).pushReplacementNamed('/mainpage');
                      });

                    },
                  ),
                ),
              ],
            ),
          ),
          FlatButton(
            onPressed: () {
              Navigator.pushNamed(context, "/reg");
            },
            child: Text('Create an account', style: TextStyle(color: Colors.grey),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: ModalProgressHUD(
        child: buildWidget(context),
        inAsyncCall: _saving,
      ),
    );
  }

  saveCredentials(String email, String password, int userId,
      String sessionId, String adminToken, String customerName, String customerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('email', email);
    await prefs.setString('password', password);
    await prefs.setInt('userId', userId);
    await prefs.setString('sessionId', sessionId);
    await prefs.setString('adminToken', adminToken);
    await prefs.setString('customerName', customerName);
    await prefs.setString('customerId', customerId);

    //await prefs.setString('domain', 'custcare.wellmade-motors.com:8899');
    //await prefs.setString('path', '/jo/');
  }

  Future<String> login(var params) async {

    setState(() { _saving = true; });
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String domain = prefs.getString('domain');
    String path = prefs.getString('path');

    if (domain == null || path == null) {
      setState(() { _saving = false; });
      return '{"success": false, "reason": "Server address error."}';
    }

    if (domain.isEmpty || path.isEmpty) {
      setState(() { _saving = false; });
      return '{"success": false, "reason": "Server address error."}';
    }

    try {

      final uri = Uri.http(domain, path+'login', params,);
      var response = await http.post(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      String cookie = response.headers['set-cookie'];

      if (response == null) {
        return '{"success": false, "reason": "The server took long to respond."}';
      } else if (response.statusCode == 200) {
        return '{"body":${response.body.replaceAll("\n", "").trim()}, "cookie":\"$cookie\"}';
      } else {
        return '{"success": false, "reason": "Login failed."}';
      }
    } on SocketException {
      return '{"success": false, "reason": "Failed to connect to the server."}';
    } on TimeoutException {
      return '{"success": false, "reason": "The server took long to respond."}';
    } catch (e) {
      return '{"success": false, "reason": "Cannot login at this time."}';
    } finally {
      setState(() { _saving = false; });
    }
  }
}