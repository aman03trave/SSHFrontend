import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ssh/login.dart';
import 'storage_service.dart';
import 'config.dart';
import 'refreshtoken.dart';
import 'customsnackbar.dart';

class GrievanceScreen extends StatefulWidget {
  @override
  _GrievanceScreenState createState() => _GrievanceScreenState();
}

class _GrievanceScreenState extends State<GrievanceScreen> {
  final _formKey = GlobalKey<FormState>();
  List<XFile> selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedDistrict;
  String? selectedBlock;
  String? selectedSchool, selectedCategory;
  List<dynamic> districts = [];
  List<dynamic> blocks = [];
  List<dynamic> schools = [];
  List<dynamic> categories = [];
  File? selectedDocument;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchDistricts();
    fetchGrievanceCategories();
    refreshToken();
  }

  Future<void> fetchDistricts() async {
    final response = await http.get(Uri.parse('$baseURL/districts'));
    if (response.statusCode == 200) {
      setState(() {
        districts = jsonDecode(response.body)['districts'];
      });
    }
  }

  Future<void> fetchBlocks(String districtname) async {
    final response = await http.post(
      Uri.parse('$baseURL/blocks'),
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
    }
  }

  Future<void> fetchSchools(String blockId) async {
    final response = await http.post(
      Uri.parse('$baseURL/schools'),
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

  Future<void> fetchGrievanceCategories() async {
    final response = await http.get(Uri.parse('$baseURL/grievance_category'));
    if (response.statusCode == 200) {
      setState(() {
        categories = jsonDecode(response.body)['grievance_category'];
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
    if (isSubmitting) return;
    String? token = await SecureStorage.getAccessToken();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    Future<http.StreamedResponse> sendRequest(String? token) async {
      var request = http.MultipartRequest('POST', Uri.parse('$baseURL/addgrievance'));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['district_name'] = selectedDistrict ?? '';
      request.fields['block_id'] = selectedBlock ?? '';
      request.fields['school_id'] = selectedSchool ?? '';
      request.fields['grievance_category'] = selectedCategory ?? '';
      request.fields['title'] = titleController.text;
      request.fields['description'] = descriptionController.text;

      for (var image in selectedImages) {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      if (selectedDocument != null) {
        request.files.add(await http.MultipartFile.fromPath('document', selectedDocument!.path));
      }

      return await request.send();
    }

    var response = await sendRequest(token);

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        token = await SecureStorage.getAccessToken();
        response = await sendRequest(token);
      } else {
        showCustomSnackBar(context, "Session expired. Please log in again.");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        setState(() => isSubmitting = false);
        return;
      }
    }

    if (response.statusCode == 200) {
      _showGrievanceSubmittedSheet(titleController.text);
    } else {
      showCustomSnackBar(context, "Submission Failed!");
    }

    setState(() {
      isSubmitting = false;
      titleController.clear();
      descriptionController.clear();
      selectedImages.clear();
      selectedDocument = null;
      selectedDistrict = null;
      selectedBlock = null;
      selectedSchool = null;
      selectedCategory = null;
      blocks = [];
      schools = [];
    });
  }

  void _showGrievanceSubmittedSheet(String grievanceTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Icon(Icons.check_circle, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text('Grievance Submitted!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Your grievance "$grievanceTitle" has been submitted successfully.', textAlign: TextAlign.center),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Grievance"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildDropdown("Select District", selectedDistrict, districts,
                        (item) => item['district_name'], (item) => item['district_name'], (val) {
                      setState(() {
                        selectedDistrict = val;
                        fetchBlocks(val!);
                      });
                    }),
                SizedBox(height: 12),
                buildDropdown("Select Block", selectedBlock, blocks,
                        (item) => item['block_name'], (item) => item['block_id'].toString(), (val) {
                      setState(() {
                        selectedBlock = val;
                        fetchSchools(val!);
                      });
                    }),
                SizedBox(height: 12),
                buildDropdown("Select School", selectedSchool, schools,
                        (item) => item['school_name'], (item) => item['school_id'].toString(), (val) {
                      setState(() => selectedSchool = val);
                    }),
                SizedBox(height: 12),
                buildDropdown("Grievance Category", selectedCategory, categories,
                        (item) => item['grievance_category_name'], (item) => item['grievance_category_name'], (val) {
                      setState(() => selectedCategory = val);
                    }),
                SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.indigo),
                  ),
                  validator: (value) => value!.isEmpty ? 'Title is required' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.indigo),
                  ),
                  validator: (value) => value!.isEmpty ? 'Description is required' : null,
                ),
                SizedBox(height: 20),
                Text("Attach Images (optional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                SizedBox(height: 6),
                ElevatedButton.icon(
                  icon: Icon(Icons.photo_library, color: Colors.white),
                  label: Text("Pick Images"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final images = await _picker.pickMultiImage();
                    if (images != null) {
                      setState(() {
                        selectedImages = images;
                      });
                    }
                  },
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedImages
                      .map((img) => Image.file(
                    File(img.path),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ))
                      .toList(),
                ),
                SizedBox(height: 20),
                Text("Attach Document (optional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                SizedBox(height: 6),
                ElevatedButton.icon(
                  icon: Icon(Icons.attach_file, color:Colors.white),
                  label: Text("Pick Document"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: pickDocument,
                ),
                if (selectedDocument != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedDocument!.path.split('/').last,
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    label: Text("Submit Grievance"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        submitGrievance();
                      }
                    },
                    icon: Icon(Icons.send,color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildDropdown(
    String label,
    String? value,
    List<dynamic> items,
    String Function(dynamic) getLabel,
    String Function(dynamic) getValue,
    void Function(String?) onChanged,
    ) {
  return DropdownButtonFormField<String>(
    isExpanded: true,
    value: value,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
    ),
    validator: (val) => val == null ? 'Required field' : null,
    items: items.map<DropdownMenuItem<String>>((item) {
      return DropdownMenuItem<String>(
        value: getValue(item),
        child: Text(getLabel(item)),
      );
    }).toList(),
    onChanged: onChanged,
  );
}
