import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:ui' as ui;

import 'new.dart';

class PasswordPage extends StatefulWidget {
  final String userSignature;
  const PasswordPage({Key? key, required this.userSignature}) : super(key: key);

  @override
  _PasswordPageState createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  SharedPreferences? _prefs;
  final LocalAuthentication _localAuth = LocalAuthentication();
  // static final _auth = LocalAuthentication();
  bool _isPasswordSet = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPassword();
    _authenticateWithBiometrics();
  }

  void _loadSavedPassword() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedPassword = _prefs?.getString('password');

    if (savedPassword != null && savedPassword.isNotEmpty) {
      setState(() {
        _isPasswordSet = true;
      });
    }
  }

  void _savePassword(String password) async {
    await _prefs?.setString('password', password);
    setState(() {
      _isPasswordSet = true;
    });
    navigateToNextScreen();
  }

  void navigateToNextScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NestedListViewDemo(userSignature: widget.userSignature),
      ),
    );

    _passwordController.clear();
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to authenticate',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error authenticating: $e');
      }
    }

    if (authenticated) {
      navigateToNextScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = widget.userSignature;
    return WillPopScope(
      onWillPop: () async {
        // Disable the back button
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey.shade50 ,Colors.indigo.shade400],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Text('مرحبا $userName', style: const TextStyle(fontSize: 37, color: Colors.black, fontWeight: FontWeight.bold)),
                      const Text('قم بتسجيل دخولك', style: TextStyle(fontSize: 29, color: Colors.black)),
                    ],
                  ),
                ),
                const Expanded(child: SizedBox(height: 0)),
                Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'ادخل كلمة المرور',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (_isPasswordSet)
                  IconButton(
                    icon: const Icon(Icons.fingerprint),
                    color: Colors.white,
                    onPressed: () {
                      _authenticateWithBiometrics();
                    },
                    iconSize:80 ,
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String password = _passwordController.text.trim();
                    if (password.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('خطأ في كلمة المرور'),
                          content: const Text('الرجاء إدخال كلمة المرور'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('تم'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      if (_prefs?.getString('password') == null || _prefs!.getString('password')!.isEmpty) {
                        _savePassword(password);
                      } else {
                        if (password == _prefs!.getString('password')) {
                          navigateToNextScreen();
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('خطأ في كلمة المرور'),
                              content: const Text('خطأ في كلمة المرور'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('تم'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('دخول'),
                ),
                const Expanded(child: SizedBox(height: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
