// import 'package:enb_accounting_app3//new.dart';
// import 'package:accounting_app3/passwordScreen.dart';

import 'package:accounting_app2/passwordScreen.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:ui' as ui;
import 'package:flutter_phoenix/flutter_phoenix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.indigo[400],
    systemNavigationBarIconBrightness:
    Brightness.dark, // Set icon color to light
    // systemNavigationBarContrastEnforced: true,
    // Set your desired color here
  ));

//  await AndroidAlarmManager.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if MyInputScreen has been shown before
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isInputScreenShown = prefs.getBool('isInputScreenShown') ?? false;
  String userSignature =
      prefs.getString('userSignature') ?? ''; // Provide a default value
  // Initializes the alarm manager.

  runApp(
    Phoenix(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          useMaterial3: true,
          cardTheme: const CardTheme(
              color: Colors.white, surfaceTintColor: Colors.white),
          cardColor: Colors.white,
          appBarTheme: const AppBarTheme(
              color: Colors.white, elevation: 0, foregroundColor: Colors.black),
        ),
        home: isInputScreenShown
            ? PasswordPage(userSignature: userSignature)
            : const MyInputScreen(),
      ),
    ),
  );
}

class FirstTimeScreen extends StatelessWidget {
  const FirstTimeScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('First   time screen'),
        ),
      ),
    );
  }
}

class MyInputScreen extends StatefulWidget {
  const MyInputScreen({super.key});

  @override
  _MyInputScreenState createState() => _MyInputScreenState();
}

class _MyInputScreenState extends State<MyInputScreen> {
  final TextEditingController _dataController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String userSignature = _dataController.text;
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'مرحبا $userSignature',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 27),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: 500,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: TextField(
                      controller: _dataController,
                      decoration: InputDecoration(
                        hintText: 'ادخل اسمك',
                        floatingLabelAlignment: FloatingLabelAlignment.start,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              10.0), // Adjust the radius as needed
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30.0),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      10.0), // Adjust the radius as needed
                ),
                side: const BorderSide(
                    color: Colors.white), // Add the desired outline color
              ),
              onPressed: () {
                if (_dataController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PasswordPage(userSignature: _dataController.text),
                    ),
                  );
                } else {
                  Fluttertoast.showToast(
                    msg: "Please enter a valid value",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }
                // Set the flag after successful login or user interaction
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setBool('isInputScreenShown', true);
                  prefs.setString('userSignature', _dataController.text);
                });
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Set the flag in SharedPreferences when the screen is disposed
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isInputScreenShown', true);
    });

    super.dispose();
  }
}
