import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'storage_service.dart';
import 'refreshtoken.dart';

class ReturnedGrievancePage extends StatefulWidget {
  const ReturnedGrievancePage({super.key});

  @override
  _ReturnedGrievancePageState createState() => _ReturnedGrievancePageState();
}

class _ReturnedGrievancePageState extends State<ReturnedGrievancePage> {
  List<dynamic> grievances = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReturnedGrievances();
  }

  Future<void> fetchReturnedGrievances() async {
    String? token = await SecureStorage.getAccessToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? roleId = prefs.getString('role_id');

    // 🌐 Set the URL based on the role
    String apiUrl = '';
    if (roleId == '4') {
      apiUrl = '$baseURL/returned_grievance';
    } else if (roleId == '5') {
      apiUrl = '$baseURL/get_returnedGrievancel2';
    } else {
      apiUrl = '$baseURL/returned_grievance';
    }

    print("API URL for role $roleId: $apiUrl");

    try {
      var response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          grievances = json.decode(response.body);
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          fetchReturnedGrievances();
        }
      } else {
        print("Failed to fetch grievances: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching grievances: $e");
    }
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
        title: const Text("Returned Grievances", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : grievances.isEmpty
          ? const Center(
        child: Text(
          "No Grievances Found",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          : ListView.builder(
        itemCount: grievances.length,
        itemBuilder: (context, index) {
          final grievance = grievances[index];
          final imageUrls = grievance['media']?['images'] ?? [];
          final documentUrls = grievance['media']?['documents'] ?? [];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ExpansionTile(
              title: Text(grievance['title'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(grievance['description']),
              children: [
                if (imageUrls.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 200.0,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: false,
                    ),
                    items: imageUrls.map<Widget>((imagePath) {
                      final imageUrl = "$baseURL/$imagePath";
                      return GestureDetector(
                        onTap: () {
                          // On image tap, open fullscreen view
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImageViewer(imageUrl: imageUrl),
                            ),
                          );
                        },
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                if (imageUrls.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No images available."),
                  ),
                const SizedBox(height: 10),
                if (documentUrls.isNotEmpty)
                  Column(
                    children: documentUrls.map<Widget>((docUrl) {
                      final fullDocUrl = "$baseURL/$docUrl";
                      final fileName = docUrl.split('/').last;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: Text(fileName),
                          onPressed: () =>
                              downloadAndOpenDocument(fullDocUrl),
                        ),
                      );
                    }).toList(),
                  ),
                if (documentUrls.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No documents available."),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }


}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
