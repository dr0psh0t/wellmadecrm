import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:validate/validate.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State createState() => new RegisterState();
}

class Customer {
  String customerName;
  int customerId;
  String idAlpha;

  Customer({this.customerName, this.customerId, this.idAlpha});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerName: json['customerName'] as String,
      customerId: json['customerId'] as int,
      idAlpha: json['idAlpha'] as String,
    );
  }
}

class RegisterState extends State<RegisterScreen> {
  bool _obscureText = true;
  bool _saving = false;

  final Color primaryColor = Color(0xFF4aa0d5);
  final Color backgroundColor = Colors.white;

  final usernameController = TextEditingController();
  final accountNumberController =TextEditingController();
  final passwordController =TextEditingController();
  final repeatPasswordController =TextEditingController();
  final emailController =TextEditingController();
  final codeController =TextEditingController();

  final _scaffoldKey =GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  void _toggle() {
    setState(() { _obscureText = !_obscureText; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: ModalProgressHUD(
        child: buildRegisterWidget(),
        inAsyncCall: _saving,
      ),
    );
  }

  Widget buildRegisterWidget() {
    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
            child: TextField(
              onChanged: (value) {},
              controller: usernameController,
              keyboardType: TextInputType.text,
              inputFormatters: [LengthLimitingTextInputFormatter(16),],
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Username',
                prefixIcon: Icon(Icons.person),
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
              controller: accountNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(9),],
              decoration: InputDecoration(
                labelText: 'Account #',
                hintText: 'Account #',
                prefixIcon: Icon(Icons.format_list_numbered),
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
              obscureText: _obscureText,
              controller: passwordController,
              keyboardType: TextInputType.text,
              inputFormatters: [LengthLimitingTextInputFormatter(32),],
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock),
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

          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
            child: TextFormField(
              obscureText: _obscureText,
              controller: repeatPasswordController,
              keyboardType: TextInputType.text,
              inputFormatters: [LengthLimitingTextInputFormatter(32),],
              decoration: InputDecoration(
                labelText: 'Repeat Password',
                hintText: 'Repeat Password',
                prefixIcon: Icon(Icons.lock),
                errorText: validatePassword(repeatPasswordController.text),
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

          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [LengthLimitingTextInputFormatter(64),],
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Email',
                prefixIcon: Icon(Icons.email),
                errorText: validateEmail(emailController.text),
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
              controller: codeController,
              keyboardType: TextInputType.text,
              inputFormatters: [
                LengthLimitingTextInputFormatter(5),
                WhitelistingTextInputFormatter(RegExp("[a-zA-Z0-9]")),
              ],
              decoration: InputDecoration(
                labelText: 'Code',
                hintText: 'Code',
                prefixIcon: Icon(Icons.code),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0))
                ),
              ),
              style: TextStyle(color: Colors.black54),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(top: 15.0, bottom: 20.0),
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    splashColor: this.primaryColor,
                    color: Colors.blue,
                    child: Padding(
                      padding: const EdgeInsets.all(17.0),
                      child: Text('REGISTER', style: TextStyle(color: Colors.white),),
                    ),
                    onPressed: () {
                      String username =usernameController.text;
                      String accountNo =accountNumberController.text;
                      String password =passwordController.text;
                      String repeatPassword =repeatPasswordController.text;
                      String email =emailController.text;
                      String code =codeController.text;

                      if (username.isEmpty) {
                        return getDialog('Username is required.');
                      }
                      else if (username.length < 5 || username.length > 16) {
                        return getDialog('Username length must be between 8 and 16.');
                      }

                      if (accountNo.isEmpty) {
                        return getDialog('Account No is required.');
                      }

                      if (email.isEmpty) {
                        return getDialog('Email is required.');
                      }

                      try {
                        Validate.isEmail(email);
                      } catch (e) {
                        return getDialog('Invalid email address format.');
                      }

                      if (password.isEmpty) {
                        return getDialog('Password is required.');
                      }

                      if (repeatPassword.isEmpty) {
                        return getDialog('Repeat Password is required.');
                      }

                      if (password !=repeatPassword) {
                        return getDialog('Password and Repeat Password do not match.');
                      }

                      register({
                        'username':username,
                        'accountNo':accountNo,
                        'email':email,
                        'password':password,
                        'repeatPassword':repeatPassword,
                        'code':code,
                        //'deviceToken':deviceToken,
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  String validatePassword(String value) {
    if (value != passwordController.text) {
      return "Password and Repeat password do not match";
    }
    return null;
  }

  String validateEmail(String email) {
    if (email.length > 0) {
      try {
        Validate.isEmail(email);
        return null;
      } catch (e) {
        return 'Invalid email address format.';
      }
    }
    return null;
  }

  Future<String> register(var params) async {
    final SharedPreferences prefs =await SharedPreferences.getInstance();
    String domain = prefs.getString('domain');
    String path = prefs.getString('path');

    try {
      setState(() { _saving = true; });

      final uri = new Uri.http(domain, path+'register', params);

      var response = await http.post(uri, headers: {
        'Accept':'application/json'
      });

      setState(() { _saving = false; });

      String returnMsg = '';

      if (response == null) {
        showSnackbar('Cannot create response object. Cause: null.', 'OK', false);
        returnMsg = 'Cannot create response object. Cause: null.';
      } else if (response.statusCode == 200) {
        var result = json.decode(response.body);
        if (result['success']) {
          usernameController.text = '';
          accountNumberController.text = '';
          passwordController.text = '';
          repeatPasswordController.text = '';
          emailController.text = '';
          codeController.text = '';
          showSnackbar('Successfully registered!', 'Login', true);
          returnMsg = 'Successfully registered!';
        } else {
          showSnackbar(result['reason'], 'OK', false);
          returnMsg = result['reason'];
        }
      } else {
        showSnackbar('Status code is not ok.', 'OK', false);
        returnMsg = 'Status code is not ok.';
      }

      return returnMsg;
    } catch (e) {
      setState(() { _saving = false; });
      if (e.runtimeType.toString() == 'SocketException') {
        showSnackbar('Unable to create connection to the server.', 'OK', false);
        return 'Unable to create connection to the server. SocketException';
      } else {
        print(e.toString());
        showSnackbar(e.toString(), 'OK', false);
        return e.toString();
      }
    } finally {}
  }

  void showSnackbar(String msg, String label, bool popable) {
    _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text(msg),
          action: SnackBarAction(
            label: label,
            onPressed: () {
              if (popable) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
  }

  Future getDialog(String message) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      }
    );
  }
}