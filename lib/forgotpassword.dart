import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'customsnackbar.dart';
import 'login.dart';
void main(){
  runApp(Forgotpassword());
}
class Forgotpassword extends StatelessWidget {
  const Forgotpassword({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forgot Password',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ForgotPasswordPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    if (!_formKey.currentState!.validate()) {
      setState(() => isSubmitting = false);
      return;
    }

    final url = Uri.parse("http://192.168.1.46:3000/api/forgot-password");

    Map<String, dynamic> requestBody = {
      "email": emailController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        showCustomSnackBar(context, "Password reset email sent!");
      } else {
        showCustomSnackBar(context, "Error: Unable to process request.");
      }
    } catch (e) {
      showCustomSnackBar(context, "Failed to connect to server.");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Icon(Icons.lock_reset, size: 80, color: Colors.blue),
                SizedBox(height: 10),
                Text("Forgot Password", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                SizedBox(height: 20),
                Text("Enter your email to receive a password reset link."),
                SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSubmitting ? null : resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Send Reset Link", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                  child: Text("Back to Login", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
