import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';
import 'config.dart';
import 'refreshtoken.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final picker = ImagePicker();
  bool isSaving = false;

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
      setState(() {
        nameController.text = user['name'] ?? "";
        emailController.text = user['email'] ?? "";
        ageController.text = user['age'].toString();
        phoneController.text = user['phone_no'] ?? "";
        gender = user['gender'] ?? "Male";
      });
      print(user);
    } else {
      print("Failed to load profile");
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile Updated!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed!")),
      );
    }
    setState(() => isSaving = false);
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: Colors.blue,
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
                          ? FileImage(_image!)
                          : AssetImage('assets/img1.jpg') as ImageProvider,
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.black),
                      onPressed: _pickImage,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildTextField("Name", nameController, Icons.person),
                _buildTextField("Email", emailController, Icons.email, isEmail: true),
                _buildTextField("Age", ageController, Icons.cake, isNumber: true),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.wc, color: Colors.blue),
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
                    backgroundColor: Colors.blue,
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
      {bool isEmail = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType:
        isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        readOnly: label == "Email",
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}