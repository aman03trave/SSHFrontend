import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main(){
  runApp(GrievanceScreen());
}

class GrievanceScreen extends StatefulWidget {
  @override
  _GrievanceScreenState createState() => _GrievanceScreenState();
}

class _GrievanceScreenState extends State<GrievanceScreen> {
  File? _proofImage;
  File? _document;
  final picker = ImagePicker();

  String? selectedDistrict;
  String? selectedBlock;
  String? selectedSchool;
  List<String> districts = [];
  List<String> blocks = [];
  List<String> schools = [];

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDistricts();
  }

  Future<void> fetchDistricts() async {
    String apiUrl = "http://192.168.1.46:3000/api/district";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List categories = data['complainant_category'];

        setState(() {
          districts = categories.map<String>((item) => item['category_name']).toList();
        });
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> fetchBlocks(String districtId) async {
    final response = await http.get(Uri.parse('http://192.168.1.46:3000/api/blocks?district_id=$districtId'));
    if (response.statusCode == 200) {
      setState(() {
        blocks = List<String>.from(json.decode(response.body)['blocks']);
        selectedBlock = null;
        schools = [];
        selectedSchool = null;
      });
    }
  }

  Future<void> fetchSchools(String blockId) async {
    final response = await http.get(Uri.parse('http://192.168.1.46:3000/api/schools?block_id=$blockId'));
    if (response.statusCode == 200) {
      setState(() {
        schools = List<String>.from(json.decode(response.body)['schools']);
        selectedSchool = null;
      });
    }
  }

  Future<void> _submitGrievance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not authenticated!")));
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.46:3000/api/grievances'),
    );

    request.headers['Authorization'] = 'Bearer $accessToken';
    request.fields['district'] = selectedDistrict ?? '';
    request.fields['block'] = selectedBlock ?? '';
    request.fields['school'] = selectedSchool ?? '';
    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;

    if (_proofImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _proofImage!.path));
    }
    if (_document != null) {
      request.files.add(await http.MultipartFile.fromPath('document', _document!.path));
    }

    var response = await request.send();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Grievance Submitted Successfully!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to Submit Grievance!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Submit Grievance"), centerTitle: true, backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdown("Select District", selectedDistrict, districts, (value) {
              setState(() {
                selectedDistrict = value;
                fetchBlocks(value!);
              });
            }),
            _buildDropdown("Select Block", selectedBlock, blocks, (value) {
              setState(() {
                selectedBlock = value;
                fetchSchools(value!);
              });
            }),
            _buildDropdown("Select School", selectedSchool, schools, (value) {
              setState(() {
                selectedSchool = value;
              });
            }),
            _buildTextField("Title", titleController, Icons.title),
            _buildTextField("Description", descriptionController, Icons.description, maxLines: 3),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitGrievance,
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), backgroundColor: Colors.blue),
              child: Text("Submit", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
