import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadSavedPassword();
  }

  void _loadSavedPassword() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _savePassword(String password) async {
    await _prefs?.setString('password', password);
    Navigator.pop(context); // Navigate back to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تغيير كلمة المرور'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
              ),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String oldPassword = _oldPasswordController.text.trim();
                String newPassword = _newPasswordController.text.trim();
                String savedPassword = _prefs?.getString('password') ?? '';

                if (oldPassword.isNotEmpty && newPassword.isNotEmpty && oldPassword == savedPassword) {
                  _savePassword(newPassword);
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('خطأ في كلمة المرور'),
                      content: const Text('يرجى التحقق من كلمة المرور الحالية'),
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
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
