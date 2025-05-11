import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'customsnackbar.dart';
import 'config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignupPage(),
    );
  }
}

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpasswordController = TextEditingController();
  final TextEditingController identityValueController = TextEditingController();

  String selectedGender = 'Male';
  String roleName = 'Complainant';
  String? selectedCategory;
  List<String> complainantCategories = [];

  String? selectedIdentityProof;
  List<String> identityProofOptions = [];

  bool isLoading = false;
  bool isError = false;
  String errorMessage = '';

  bool hasUppercase = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;
  bool showPasswordHints = false;

  @override
  void initState() {
    super.initState();
    fetchComplainantCategories();
    fetchIdentityProofs();
  }

  Future<void> fetchComplainantCategories() async {
    String apiUrl = "$baseURL/complainant_category";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == true) {
          List categories = data['complainant_category'];
          setState(() {
            complainantCategories = categories.map<String>((item) => item['category_name']).toList();
          });
        } else {
          setState(() {
            isError = true;
            errorMessage = "Failed to fetch categories.";
          });
        }
      } else {
        setState(() {
          isError = true;
          errorMessage = "Failed to fetch categories.";
        });
      }
    } catch (error) {
      setState(() {
        isError = true;
        errorMessage = "Network error. Please try again.";
      });
    }
  }


  Future<void> fetchIdentityProofs() async {
    String apiUrl = "$baseURL/identity_proof";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == true) {
          List proofs = data['identity_proof'];
          setState(() {
            identityProofOptions = proofs.map<String>((item) => item['proof_type']).toList();
          });
        } else {
          setState(() {
            isError = true;
            errorMessage = "Failed to fetch identity proofs.";
          });
        }
      } else {
        setState(() {
          isError = true;
          errorMessage = "Failed to fetch identity proofs.";
        });
      }
    } catch (error) {
      setState(() {
        isError = true;
        errorMessage = "Network error. Please try again.";
      });
    }
  }


  void validatePassword(String password) {
    setState(() {
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      hasMinLength = password.length >= 8;
    });
  }

  String? passwordValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password cannot be empty';
    }
    if (!hasUppercase || !hasSpecialChar || !hasMinLength) {
      setState(() => showPasswordHints = true);
      return 'Password must meet all criteria below';
    }
    return null;
  }

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) {
      showCustomSnackBar(context, "Please fill in all the required fields.");
      return;
    }

    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = '';
    });

    String apiUrl = "$baseURL/register";

    Map<String, dynamic> requestBody = {
      "name": nameController.text.trim(),
      "age": int.tryParse(ageController.text.trim()) ?? 0,
      "gender": selectedGender,
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "password": passwordController.text,
      "role_name": roleName,
      "category": selectedCategory,
    };

    if (selectedIdentityProof != null && identityValueController.text.trim().isNotEmpty) {
      requestBody["identity_proof"] = selectedIdentityProof;
      requestBody["identity_value"] = identityValueController.text.trim();
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        showCustomSnackBar(context, "Signup Successful! Welcome, ${responseData['name']}");

        nameController.clear();
        ageController.clear();
        emailController.clear();
        phoneController.clear();
        passwordController.clear();
        confirmpasswordController.clear();
        identityValueController.clear();

        setState(() {
          selectedGender = 'Male';
          selectedCategory = 'student';
          selectedIdentityProof = null;
          showPasswordHints = false;
        });
      } else {
        var errorResponse = jsonDecode(response.body);
        setState(() {
          isError = true;
          errorMessage = errorResponse['message'] ?? "Signup Failed!";
        });
        showCustomSnackBar(context, errorMessage);
      }
    } catch (error) {
      setState(() {
        isError = true;
        errorMessage = "Network error. Please try again!";
      });
      showCustomSnackBar(context, errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget passwordValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.cancel, color: isValid ? Colors.green : Colors.red),
        SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Icon(Icons.account_circle, size: 80, color: Colors.blue),
                  SizedBox(height: 10),
                  Text("Aasha Sethu", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  SizedBox(height: 20),
                  Text("Create your Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 20),
                  TextFormField(controller: nameController, decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    items: ['Male', 'Female', 'Other'].map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                    onChanged: (value) => setState(() => selectedGender = value!),
                    decoration: InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  TextFormField(controller: ageController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Age", border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  TextFormField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone Number", border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: complainantCategories.contains(selectedCategory) ? selectedCategory : null,
                    hint: Text("Complainant Category"),
                    items: complainantCategories.map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedCategory = value),
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),

                  SizedBox(height: 10),
                  TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  TextFormField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()), onChanged: validatePassword),
                  SizedBox(height: 10),
                  TextFormField(controller: confirmpasswordController, obscureText: true, decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder())),
                  SizedBox(height: 10),
                  if (showPasswordHints)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        passwordValidationItem("At least one uppercase letter", hasUppercase),
                        passwordValidationItem("At least one special character", hasSpecialChar),
                        passwordValidationItem("Minimum 8 characters", hasMinLength),
                      ],
                    ),
                  SizedBox(height: 10),

                  // Optional Identity Proof Section
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedIdentityProof,
                    hint: Text("Identity Proof (Optional)"),
                    items: identityProofOptions.map((proof) =>
                        DropdownMenuItem(value: proof, child: Text(proof))).toList(),
                    onChanged: (value) => setState(() => selectedIdentityProof = value),
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 10),
                  if (selectedIdentityProof != null)
                    TextFormField(
                      controller: identityValueController,
                      decoration: InputDecoration(labelText: "Identity Number", border: OutlineInputBorder()),
                    ),

                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Sign Up", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}