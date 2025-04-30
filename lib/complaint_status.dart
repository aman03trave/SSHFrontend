import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'refreshtoken.dart';
import 'storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.storage.isGranted) return true;

    if (await Permission.storage.request().isGranted) {
      return true;
    }

    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    return false;
  }
  return true; // iOS doesn't need this
}


Future<void> downloadAndOpenDocument(String url, BuildContext context) async {
  try {
    bool permissionGranted = await requestStoragePermission();
    if (!permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Storage permission denied")));
      return;
    }

    Directory directory = Platform.isAndroid
        ? (await getExternalStorageDirectory())!
        : await getApplicationDocumentsDirectory();

    String fileName = url.split('/').last;
    String filePath = "${directory.path}/$fileName";

    Dio dio = Dio();
    await dio.download(url, filePath);

    OpenFile.open(filePath);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
  }
}

class GrievanceDetailPage extends StatelessWidget {
  final Map<String, dynamic> complaint;

  GrievanceDetailPage({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final imagePath = complaint['media']?['image'];
    final docPath = complaint['media']?['document'];
    final imageUrl = imagePath != null && imagePath.isNotEmpty ? "$baseURL/$imagePath" : '';
    final docUrl = docPath != null && docPath.isNotEmpty ? "$baseURL/$docPath" : '';

    return Scaffold(
      appBar: AppBar(title: Text("Complaint Details")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(height: 200, color: Colors.grey[300], child: Icon(Icons.broken_image)),
                ),
              ),
            SizedBox(height: 16),
            Text("Title: ${complaint["title"] ?? "N/A"}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Description: ${complaint["description"] ?? "N/A"}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("Status Code: ${complaint["code"] ?? "N/A"}"),
            Text("Created At: ${complaint["created_at"] ?? "N/A"}"),
            SizedBox(height: 16),

            if (docUrl.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Document Uploaded:", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.remove_red_eye),
                    label: Text("View / Download Document"),
                    onPressed: () => downloadAndOpenDocument(docUrl, context),
                  ),
                ],
              ),


            SizedBox(height: 16),
            Text("Action Log", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
                  ],
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complaint["code"] ?? "No Action", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text("Action ID: ${complaint["action_id"] ?? "N/A"}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      Text("On: ${complaint["action_timestamp"] ?? "Unknown time"}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      SizedBox(height: 10),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _DashboardScreenState extends State<Dashboard> {
  int selectedCategory = 0; // 0: All, 1: In Process, 2: Resolved
  Map<int, bool> expandedState = {};
  List<dynamic> grievances = [];

  void launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch document')),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    fetchGrievances();
  }

  Future<void> fetchGrievances() async {
    String? token = await SecureStorage.getAccessToken();

    final response = await http.get(
      Uri.parse('$baseURL/getgrievance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    print(response.body);

    if (response.statusCode == 401) {
      // Token might be expired, try refreshing
      bool refreshed = await refreshToken();
      if (refreshed) {
        // Get new token and retry once
        token = await SecureStorage.getAccessToken();
        final retryResponse = await http.get(
          Uri.parse('$baseURL/getgrievance'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );

        if (retryResponse.statusCode == 200) {
          final data = json.decode(retryResponse.body);
          setState(() {
            grievances = data['grievance'];
          });
          return;
        } else {
          print("Failed after refresh: ${retryResponse.statusCode}");
          return;
        }
      } else {
        print("Token refresh failed");
        return;
      }
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        grievances = data['grievance'];
      });
    } else {
      print("Failed to fetch grievances: ${response.statusCode}");
    }
  }


  void toggleExpanded(int index) {
    setState(() {
      expandedState[index] = !(expandedState[index] ?? false);
    });
  }

  Widget categoryCard(String title, int category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selectedCategory == category ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildComplaintCard(Map<String, dynamic> complaint, int index) {
    final isExpanded = expandedState[index] ?? false;
    final imagePath = complaint['media']?['image'];
    final imageUrl = imagePath != null && imagePath.isNotEmpty
        ? "$baseURL/$imagePath"
        : '';


    return GestureDetector(
      onTap: () => toggleExpanded(index),
      child: Card(
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Image
            Container(
              height: 200,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Center(child: Icon(Icons.broken_image, size: 50)),
                  );
                },
              ),
            ),
            // Dark overlay
            Container(
              height: 200,
              color: Colors.black.withOpacity(0.4),
            ),
            // Title
            Positioned(
              bottom: 50,
              left: 15,
              child: Text(
                complaint["title"] ?? "No Title",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            // View Action button
            Positioned(
              bottom: 10,
              right: 10,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GrievanceDetailPage(complaint: complaint),
                    ),
                  );
                },

                child: Text("View Action"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              ),
            ),
            if (isExpanded)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Title: ${complaint["title"] ?? "N/A"}",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text("Description: ${complaint["description"] ?? "N/A"}",
                            style: TextStyle(color: Colors.white)),
                        SizedBox(height: 10),
                        Text("Action Status: ${complaint["code"] ?? "N/A"}",
                            style: TextStyle(color: Colors.white)),
                        SizedBox(height: 10),
                        Text("Created At: ${complaint["created_at"] ?? "N/A"}",
                            style: TextStyle(color: Colors.white)),
                        SizedBox(height: 10),

                        if (complaint['media']?['document'] != null &&
                            complaint['media']['document'].toString().isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Document:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () {
                                  final docPath = complaint['media']?['image'];
                                  final docUrl = imagePath != null && imagePath.isNotEmpty
                                      ? "$baseURL/$docPath"
                                      : '';
                                  //final docUrl = "$baseURL/${complaint['media']['document']}";

                                  if (docUrl.isNotEmpty) {
                                    launchURL(context, docUrl);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("No document available")),
                                    );
                                  }
                                },
                                child: Text("View Uploaded Document",
                                    style: TextStyle(color: Colors.blueAccent)),
                              ),
                            ],
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => toggleExpanded(index),
                            child: Text("Close", style: TextStyle(color: Colors.redAccent)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )

          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredGrievances = grievances
        .where((g) {
      if (selectedCategory == 1) return g["action_code_id"] == 2;
      if (selectedCategory == 2) return g["action_code_id"] == 3;
      return true;
    })
        .cast<Map<String, dynamic>>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              categoryCard("Complaints", 0),
              categoryCard("In Process", 1),
              categoryCard("Resolved", 2),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredGrievances.length,
              itemBuilder: (context, index) =>
                  buildComplaintCard(filteredGrievances[index], index),
            ),
          ),
        ],
      ),
    );
  }
}
