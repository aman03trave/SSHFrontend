import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'storage_service.dart';
import 'config.dart';
import 'refreshtoken.dart';
import 'customsnackbar.dart';
import 'login.dart';
import 'Level1_dashboard.dart';
import 'Level2_Dashboard.dart';
import 'userdashboard.dart';
import 'logvisit.dart';
import 'user_complaint_status.dart';
// import 'Level2_DisplayAssignedGrievance.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final picker = ImagePicker();
  bool isSaving = false;
  String role_id = "";

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  String gender = "Male";

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    String? token = await SecureStorage.getAccessToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    role_id = prefs.getString("role_id") ?? "";

    var response = await http.get(
      Uri.parse("$baseURL/get-profile"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        token = await SecureStorage.getAccessToken();
        response = await http.get(
          Uri.parse("$baseURL/get-profile"),
          headers: {"Authorization": "Bearer $token"},
        );
      }
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = data['user'];
      final profileData = user['Profile'][0];
      final profilePicture = user['profile_picture']?['profile_pic'];

      setState(() {
        nameController.text = profileData['name'] ?? "";
        emailController.text = profileData['email'] ?? "";
        ageController.text = profileData['age'].toString();
        phoneController.text = profileData['phone_no'] ?? "";
        gender = profileData['gender'] ?? "Male";
        _image = profilePicture != null ? File(profilePicture) : null;
      });
    } else {
      print("Failed to load profile");
    }
  }

  void navigateToHomePage() async{

    final prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool("isLoggedIn");
  print("isLoggedIn: $isLoggedIn");
  print("Inside navigate to home");
    // Prevent navigation if not logged in
    if (isLoggedIn == null || !isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
      return;
    }
    if (role_id == "3") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );}
    else if(role_id == "4"){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GrievanceDashboard()),
      );}
    else if(role_id == "5"){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Level2Dashboard()),
      );
    }
  }
  Future<void> updateProfile() async {
    setState(() => isSaving = true);
    String? token = await SecureStorage.getAccessToken();
    final body = jsonEncode({
      "name": nameController.text,
      "age": int.tryParse(ageController.text),
      "gender": gender,
      "phone": phoneController.text,
    });

    var response = await http.put(
      Uri.parse("$baseURL/update-profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: body,
    );

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        token = await SecureStorage.getAccessToken();
        response = await http.put(
          Uri.parse("$baseURL/update-profile"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: body,
        );
      }
    }

    if (response.statusCode == 200) {
      await fetchProfile();
      showCustomSnackBar(context, "Profile Updated");
      Navigator.pop(context, 'profile_updated');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed!")),
      );
      showCustomSnackBar(context, "Profile Update Failed!");
    }
    setState(() => isSaving = false);
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Show confirmation dialog
      _showImageConfirmationDialog();
    }
  }

  Future<void> _showImageConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Profile Picture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              _image!,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 10),
            Text("Do you want to set this as your profile picture?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _uploadProfilePicture();
            },
            child: Text("Set as Profile Picture"),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadProfilePicture() async {
    String? token = await SecureStorage.getAccessToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseURL/update-profile-picture'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('profile_picture', _image!.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      showCustomSnackBar(context, "Profile Picture Updated");
      fetchProfile(); // Fetch updated profile after upload
    } else {
      setState(() {
        AssetImage('assets/img1.jpg') as ImageProvider;
      });
      showCustomSnackBar(context, "Failed to update profile picture");
    }
  }

  Future<void> logout() async {

    final response = await http.post(
      Uri.parse("$baseURL/logout"),

    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", false);
      await prefs.remove("role_id");
      await SecureStorage.clearToken();
      print("cleared all the tokens");

      // 🎯 Show Snackbar and wait for it to be visible before navigating
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout Successful!')),
      );

      /// Wait for the Snackbar to appear (300ms)
      await Future.delayed(const Duration(milliseconds: 300));

      /// 🎯 Clear the stack and navigate to Login Page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => FirstPage()),
            (Route<dynamic> route) => false,
      );

      print("✅ Successfully navigated to Login Page and cleared stack.");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed!')),
      );
      print("❌ Logout failed with status code: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: navigateToHomePage,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.white),
            tooltip: "Logout",
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _image != null
                          ? NetworkImage("$baseURL${_image!.path}")
                          : AssetImage('assets/img1.jpg') as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildTextField("Name", nameController, Icons.person),
                _buildTextField("Email", emailController, Icons.email, isEmail: true, enabled: false),
                _buildTextField("Age", ageController, Icons.cake, isNumber: true),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.wc, color: Colors.indigo),
                      SizedBox(width: 10),
                      Text("Gender:", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 10),
                      DropdownButton<String>(
                        value: gender,
                        onChanged: (String? newValue) {
                          setState(() {
                            gender = newValue!;
                          });
                        },
                        items: ["Male", "Female", "Other"].map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                _buildTextField("Phone Number", phoneController, Icons.phone, isNumber: true),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSaving ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.indigo,
                  ),
                  child: isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Save", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),

    );

  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {bool isEmail = false, bool isNumber = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.indigo),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        enabled: enabled,
      ),
    );
  }


  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SecureStorage.clearToken();
              logout();
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
