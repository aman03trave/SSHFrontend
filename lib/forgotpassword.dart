import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}
class Forgotpassword extends StatelessWidget {
  const Forgotpassword({super.key});

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailExists = false;
  String _message = "";
  int _timerSeconds = 0;
  Timer? _timer;

  Future<void> _checkEmailExists() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _message = "Please enter your email.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = "";
    });

    // Dummy check for testing
    if (email == "test@example.com") {
      setState(() {
        _emailExists = true;
        _message = "Email found! Sending reset link...";
      });
      _sendResetLink();
    } else {
      setState(() {
        _emailExists = false;
        _message = "Email not found in the database.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _sendResetLink() async {
    final String email = _emailController.text.trim();

    // Simulating an API response delay
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _message = "Reset link sent to $email! Check your email.";
      _startResendTimer();
    });
  }

  void _startResendTimer() {
    setState(() {
      _timerSeconds = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text("Forgot Password"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset Your Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 10),
            Text(
              'Enter your email to receive password reset instructions.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email, color: Colors.blue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkEmailExists,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Check Email", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            SizedBox(height: 10),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(fontSize: 16, color: _emailExists ? Colors.green : Colors.red),
              ),
            SizedBox(height: 20),
            if (_emailExists && _timerSeconds == 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("Send Reset Link", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            if (_timerSeconds > 0)
              Center(
                child: Text(
                  "Resend in $_timerSeconds seconds",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Back to Login", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
