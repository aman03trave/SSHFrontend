import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'signup.dart';
import 'customsnackbar.dart';
import 'userdashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'forgotpassword.dart';
import 'config.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'Level1_dashboard.dart';

void main() {
  runApp(LoginPage());
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirstPage(),
    );
  }
}

class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoggingIn = false;

  @override

  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
    String role_id = prefs.getString("role_id") ?? "";
    if (isLoggedIn ) {
      // Redirect to dashboard if already logged in
      Future.delayed(Duration.zero, () {
        if (role_id == "1") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
          } else if (role_id == "3") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );}
          else if(role_id == "4")
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GrievanceDashboard()),
        );
      });
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoggingIn) return;
    setState(() => isLoggingIn = true);

    if (!_formKey.currentState!.validate()) {
      setState(() => isLoggingIn = false);
      return;
    }

    final url = Uri.parse("$baseURL/login");
    Map<String, dynamic> requestBody = {
      "email": emailController.text.trim(),
      "password": passwordController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == true && jsonResponse.containsKey('accessToken')) {
          final accessToken = jsonResponse['accessToken'];
          final refreshToken = jsonResponse['refreshToken'];

          await SecureStorage.saveAccessToken(accessToken);
          await SecureStorage.saveRefreshToken(refreshToken);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool("isLoggedIn", true);

          // Decode JWT to extract role_id
          Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
          String roleId = decodedToken['role_id'].toString();
          await prefs.setString("role_id", roleId);

          showCustomSnackBar(context, "Signin Successful!");

          Future.delayed(Duration(milliseconds: 300), () {
            if (roleId == "1") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
            // } else if (roleId == "2") {
            //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Level1OfficerDashboard()));
            } else if (roleId == "3") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
            } else if(roleId == "4") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GrievanceDashboard()));
            }

          });
        } else {
          showCustomSnackBar(context, "Invalid credentials or response format.");
        }
      } else {
        showCustomSnackBar(context, "Login failed. Please check your credentials.");
      }
    } catch (e) {
      showCustomSnackBar(context, "Failed to connect to the server.");
    } finally {
      setState(() => isLoggingIn = false);
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
                Icon(Icons.account_circle, size: 80, color: Colors.blue),
                SizedBox(height: 10),
                Text("Aasha Sethu", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                SizedBox(height: 20),
                Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? "Please enter your email" : null,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.isEmpty ? "Please enter your password" : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                    child: Text("Forgot Password?", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoggingIn ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: isLoggingIn
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Login", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                SizedBox(height: 20),
                Text("- Or sign up with -"),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.google, size: 40, color: Colors.red),
                    SizedBox(width: 20),
                    Icon(FontAwesomeIcons.facebook, size: 40, color: Colors.blue),
                    SizedBox(width: 20),
                    Icon(FontAwesomeIcons.apple, size: 40, color: Colors.black),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SignupPage()));
                      },
                      child: Text("Sign Up", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
