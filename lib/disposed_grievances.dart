import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'config.dart';
import 'storage_service.dart';
import 'refreshtoken.dart';

class DisposedGrievancesPage extends StatefulWidget {
  @override
  _DisposedGrievancesPageState createState() => _DisposedGrievancesPageState();
}

class _DisposedGrievancesPageState extends State<DisposedGrievancesPage> {
  List<dynamic> grievances = [];
  bool isLoading = true;
  String? roleId;

  @override
  void initState() {
    super.initState();
    fetchGrievances();
  }

  Future<void> fetchGrievances() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    roleId = prefs.getString('role_id');
    print("Role ID: $roleId");

    String apiUrl = '';
    if (roleId == '3') {
      apiUrl = '$baseURL/complainant_disposed_grievances';
    } else if (roleId == '4') {
      apiUrl = '$baseURL/get_disposedl1';
    } else if (roleId == '5') {
      apiUrl = '$baseURL/get_disposedl2';
    }

    try {
      var token = await SecureStorage.getAccessToken();
      print("API URL: $apiUrl");
      var response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      // Handle Token Refresh if Unauthorized
      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
          response = await http.get(
            Uri.parse(apiUrl),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            },
          );
        }
      }

      if (response.statusCode == 200) {
        setState(() {
          grievances = jsonDecode(response.body);
          print(grievances);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load grievances');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  Future<void> downloadAndOpenDocument(String url) async {
    try {
      bool permissionGranted = await requestStoragePermission();
      if (!permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }

      Directory directory = Platform.isAndroid
          ? (await getExternalStorageDirectory())!
          : await getApplicationDocumentsDirectory();

      String fileName = url.split('/').last;
      String filePath = "${directory.path}/$fileName";

      Dio dio = Dio();
      await dio.download(url, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Document downloaded successfully")),
      );

      // Directly open the document
      await OpenFile.open(filePath);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
  String formatDate(String dateStr) {
    final DateTime parsedDate = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
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
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disposed Grievances', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo,
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : grievances.isEmpty
          ? Center(child: Text('No grievances found'))
          : ListView.builder(
        itemCount: grievances.length,
        itemBuilder: (context, index) {
          final grievance = grievances[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(grievance['title'],
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(grievance['description']),
                  SizedBox(height: 10),
                  Text(
                    "📅 Submission Time: ${formatDate(grievance['submission_time'])}",
                  ),
                  Text(
                    "🗓️ Disposed Time: ${formatDate(grievance['disposed_time'])}",
                  ),

                  SizedBox(height: 10),

                  // Image Carousel
                  if (grievance['grievance_media']['images'].isNotEmpty)
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 180,
                        enableInfiniteScroll: false,
                        enlargeCenterPage: true,
                      ),
                      items: grievance['grievance_media']['images'].map<Widget>((relativePath) {
                        final String fullImageUrl = "$baseURL/$relativePath";
                        if (Uri.parse(fullImageUrl).isAbsolute) {
                          return GestureDetector(
                            onTap: () => showFullScreenImage(fullImageUrl),
                            child: Container(
                              margin: EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                image: DecorationImage(
                                  image: NetworkImage(fullImageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Center(child: Text('Invalid Image URL'));
                        }
                      }).toList(),
                    )
                  else
                    Center(child: Text('No Images Available')),

                  SizedBox(height: 10),

// Document List - Directly Open
                  if (grievance['grievance_media']['documents'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Documents:", style: TextStyle(fontWeight: FontWeight.bold)),
                        ...grievance['grievance_media']['documents'].map<Widget>((relativePath) {
                          final String fullDocumentUrl = "$baseURL/$relativePath";
                          return ListTile(
                            leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                            title: Text(relativePath.split('/').last),
                            onTap: () async {
                              if (Uri.parse(fullDocumentUrl).isAbsolute) {
                                await downloadAndOpenDocument(fullDocumentUrl);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Invalid Document URL')),
                                );
                              }
                            },
                          );
                        }).toList(),
                      ],
                    )
                  else
                    Center(child: Text('No Documents Available')),

// 📄 Final ATR Report - New Section
                  SizedBox(height: 10),
                  if (grievance['final_atr_report'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Final ATR Report:", style: TextStyle(fontWeight: FontWeight.bold)),
                        ...grievance['final_atr_report'].map<Widget>((report) {
                          final String fullReportUrl = "$baseURL/${report['document']}";
                          String uploadTime = formatDate(report['uploaded_time']);

                          return ListTile(
                            leading: Icon(Icons.picture_as_pdf, color: Colors.blue),
                            title: Text(report['document'].split('/').last),
                            subtitle: Text("Uploaded on: $uploadTime"),
                            onTap: () async {
                              if (Uri.parse(fullReportUrl).isAbsolute) {
                                await downloadAndOpenDocument(fullReportUrl);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Invalid Report URL')),
                                );
                              }
                            },
                          );
                        }).toList(),
                      ],
                    )
                  else
                    Center(child: Text('No Final ATR Report Available')),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
