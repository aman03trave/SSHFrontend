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
  String roleName = 'complainant';
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
        showCustomSnackBar(context, "Signup Successful!!");

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

        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
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

                    // Name Field
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      items: ['Male', 'Female', 'Other']
                          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                          .toList(),
                      onChanged: (value) => setState(() => selectedGender = value!),
                      decoration: InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 10),

                    // Age Field
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Age", border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Age is required';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Enter a valid age';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Phone Number Field
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Complainant Category Dropdown
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
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Email Field
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Password Field
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                      onChanged: validatePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Password must have at least one uppercase letter';
                        }
                        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                          return 'Password must have at least one special character';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Confirm Password Field
                    TextFormField(
                      controller: confirmpasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirm your password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // Password Hints
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

                    // Identity Proof Dropdown
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

                    // Identity Proof Value (only visible if selected)
                    if (selectedIdentityProof != null)
                      TextFormField(
                        controller: identityValueController,
                        decoration: InputDecoration(labelText: "Identity Number", border: OutlineInputBorder()),
                        validator: (value) {
                          if (selectedIdentityProof != null && (value == null || value.isEmpty)) {
                            return 'Identity Number is required';
                          }
                          return null;
                        },
                      ),
                    SizedBox(height: 20),

                    // Submit Button
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
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Already Registered ? ",
                            style: TextStyle(color: Colors.black, decoration: TextDecoration.underline),
                          ),
                          SizedBox(width: 5),
                          Text("Login", style: TextStyle(color: Colors.indigo),),

                        ],
                      ),
                    ),
                    SizedBox(height: 20,)
                  ],

              ),
            ),
          ),
        ),
      ),
    );
  }
}