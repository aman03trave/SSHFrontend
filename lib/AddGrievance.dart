import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class GrievanceScreen extends StatefulWidget {
  @override
  _GrievanceScreenState createState() => _GrievanceScreenState();
}

class _GrievanceScreenState extends State<GrievanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedDistrict;
  String? selectedBlock;
  String? selectedSchool;
  List<dynamic> districts = [];
  List<dynamic> blocks = [];
  List<dynamic> schools = [];
  File? selectedImage;
  File? selectedDocument;

  @override
  void initState() {
    super.initState();
    fetchDistricts();
  }

  Future<void> fetchDistricts() async {
    final response = await http.get(Uri.parse('http://192.168.1.46:3000/api/districts'));
    if (response.statusCode == 200) {
      setState(() {
        districts = jsonDecode(response.body)['districts'];
      });
    }
  }

  Future<void> fetchBlocks(String districtname) async {
    print("District Name: $districtname");
    final response = await http.post(
      Uri.parse('http://192.168.1.46:3000/api/blocks'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"district_name": districtname}),
    );
    if (response.statusCode == 200) {
      setState(() {
        blocks = jsonDecode(response.body)['blocks'];
        selectedBlock = null;
        selectedSchool = null;
        schools = [];
      });
    }else{
      print("Error Occurred");
    }
  }

  Future<void> fetchSchools(String blockId) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.46:3000/api/schools'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"block_id": blockId}),
    );
    if (response.statusCode == 200) {
      setState(() {
        schools = jsonDecode(response.body)['schools'];
        selectedSchool = null;
      });
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedDocument = File(result.files.single.path!);
      });
    }
  }

  Future<void> submitGrievance() async {
    if (!_formKey.currentState!.validate()) return;

    var request = http.MultipartRequest('POST', Uri.parse('http://192.168.1.46:3000/api/addgrievances'));
    request.fields['district'] = selectedDistrict ?? '';
    request.fields['block'] = selectedBlock ?? '';
    request.fields['school'] = selectedSchool ?? '';
    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;

    if (selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', selectedImage!.path));
    }
    if (selectedDocument != null) {
      request.files.add(await http.MultipartFile.fromPath('document', selectedDocument!.path));
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Grievance Submitted Successfully!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission Failed!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Grievance")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedDistrict,
                hint: Text("Select District"),
                items: districts.map((district) => DropdownMenuItem(
                  value: district['district_name'].toString(),
                  child: Text(district['district_name']),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDistrict = value;
                    fetchBlocks(value!);
                  });
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedBlock,
                hint: Text("Select Block"),
                items: blocks.map((block) => DropdownMenuItem(
                  value: block['block_id'].toString(),
                  child: Text(block['block_name']),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBlock = value;
                    fetchSchools(value!);
                  });
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedSchool,
                hint: Text("Select School"),
                items: schools.map((school) => DropdownMenuItem(
                  value: school['school_id'].toString(),
                  child: Text(school['school_name']),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSchool = value;
                  });
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Title", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Please enter a title" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? "Please enter a description" : null,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: pickImage,
                    child: Text("Pick Image"),
                  ),
                  if (selectedImage != null) Icon(Icons.check, color: Colors.green),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: pickDocument,
                    child: Text("Pick Document"),
                  ),
                  if (selectedDocument != null) Icon(Icons.check, color: Colors.green),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitGrievance,
                child: Text("Submit Grievance"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
