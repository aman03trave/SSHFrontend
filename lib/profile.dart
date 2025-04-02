import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final picker = ImagePicker();


  TextEditingController nameController = TextEditingController(text: "John Doe");
  TextEditingController emailController = TextEditingController(text: "johndoe@example.com");
  TextEditingController ageController = TextEditingController(text: "25");
  TextEditingController phoneController = TextEditingController(text: "9876543210");

  String gender = "Male"; // Default gender

  // Function to pick an image
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
        onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap outside
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // Dismiss keyboard on scroll
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
                      backgroundImage: _image != null ? FileImage(_image!) : AssetImage('assets/img1.jpg') as ImageProvider,
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.black),
                      onPressed: _pickImage,
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Editable Fields
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

                // Save Button
                ElevatedButton(
                  onPressed: () {

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Profile Updated!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.blue,
                  ),
                  child: Text("Save", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Function for TextFields
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isEmail = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
