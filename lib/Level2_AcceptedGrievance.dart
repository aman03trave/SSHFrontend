import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'storage_service.dart';
import 'package:ssh/refreshtoken.dart';
import 'config.dart';

void main() {
  runApp(const MaterialApp(home: Level2_AcceptedGrievancePage()));
}

class Level2_AcceptedGrievancePage extends StatefulWidget {
  const Level2_AcceptedGrievancePage({super.key});

  @override
  State<Level2_AcceptedGrievancePage> createState() => _AcceptedGrievancePageState();
}

class _AcceptedGrievancePageState extends State<Level2_AcceptedGrievancePage> {
  Future<List<GrievanceItem>> fetchGrievances() async {
    var token = await SecureStorage.getAccessToken();
    var response = await http.get(
      Uri.parse("$baseURL/getAcceptedGrievance"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        token = await SecureStorage.getAccessToken();
        response = await http.get(
          Uri.parse("$baseURL/getAcceptedGrievance"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );
      }
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => GrievanceItem.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load grievances");
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
  Future<void> downloadAndOpenDocument(String url, BuildContext context) async {
    try {
      bool permissionGranted = await requestStoragePermission();
      if (!permissionGranted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Storage permission denied")));
        return;
      }

      // 👉 Check if the URL is already absolute, if not, prefix with baseURL
      if (!Uri.parse(url).isAbsolute) {
        url = "$baseURL/$url";
      }

      print("Attempting to download: $url");

      Directory directory = Platform.isAndroid
          ? (await getExternalStorageDirectory())!
          : await getApplicationDocumentsDirectory();

      String fileName = url.split('/').last;
      String filePath = "${directory.path}/$fileName";

      print("Saving file to: $filePath");

      Dio dio = Dio();
      await dio.download(url, filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              print("Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
            }
          });

      if (await File(filePath).exists()) {
        print("File downloaded successfully");
        OpenFile.open(filePath);
      } else {
        print("File not found after download");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File not found after download")));
      }
    } catch (e) {
      print("Error during download: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")));
    }

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accepted Grievances", style: TextStyle(color: Colors.white)),
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
      body: FutureBuilder<List<GrievanceItem>>(
        future: fetchGrievances(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No grievances found."));
          }

          final grievances = snapshot.data!;

          return ListView.builder(
            itemCount: grievances.length,
            itemBuilder: (context, index) {
              final item = grievances[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GrievanceDetailPage(item: item),
                    ),
                  ).then((_) => setState(() {})); // 🔄 Refresh on return
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: _GrievanceTile(item: item, index: index),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusMessage(int actionCodeId) {
    switch (actionCodeId) {
      case 3:
        return Chip(label: Text("Sent for Review", style: TextStyle(color: Colors.indigo.shade800),));
      case 5:
        return Chip(label: Text("Rejected",style: TextStyle(color: Colors.redAccent)));
      case 6:
        return Chip(label: Text("Sent for Review", style: TextStyle(color: Colors.orange)));
      default:
        return const SizedBox.shrink();
    }
  }

}

class GrievanceItem {
  final String grievance_id;
  final String title;
  final String description;
  final String assigned_by;
  final String assigned_at;
  final int actionCodeId;
  final List<String> imageUrls;
  final List<String> documentUrls;
  final List<ATRItem> atrItems;

  GrievanceItem({
    required this.grievance_id,
    required this.title,
    required this.description,
    required this.assigned_by,
    required this.assigned_at,
    required this.actionCodeId,
    required this.imageUrls,
    required this.documentUrls,
    required this.atrItems,
  });

  factory GrievanceItem.fromJson(Map<String, dynamic> json) {
    final media = json['grievance_media'] ?? {};

    return GrievanceItem(
      grievance_id: json['grievance_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assigned_by: json['assigned_by'] ?? 'Unknown',
      assigned_at: _formatDuration(json['assigned_at'] ?? ''),
      actionCodeId: json['action_code_id'] ?? 0,
      imageUrls: (media['images'] as List<dynamic>?)
          ?.map((image) => "$baseURL/$image")
          .toList() ??
          [],
      documentUrls: (media['documents'] as List<dynamic>?)
          ?.map((document) => "$baseURL/$document")
          .toList() ??
          [],
      atrItems: (json['ATR'] as List<dynamic>?)
          ?.map((atr) => ATRItem.fromJson(atr))
          .toList() ??
          [],
    );
  }

  static String _formatDuration(String assignedAt) {
    if (assignedAt.isEmpty) return 'Unknown time';
    try {
      final DateTime assignedTime = DateTime.parse(assignedAt).toLocal();
      final Duration diff = DateTime.now().difference(assignedTime);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

class ATRItem {
  final int version;
  final List<String> documents;

  ATRItem({
    required this.version,
    required this.documents,
  });

  factory ATRItem.fromJson(Map<String, dynamic> json) {
    // ✅ Safely extract the version from the list or default to 1
    int parsedVersion;
    if (json['version'] is List && json['version'].isNotEmpty) {
      parsedVersion = json['version'][0]; // Grab the first element
    } else {
      parsedVersion = 1; // Default to 1 if the list is empty or not available
    }

    return ATRItem(
      version: parsedVersion,
      documents: (json['documents'] as List<dynamic>?)
          ?.map((doc) => "$baseURL/$doc")
          .toList() ??
          [],
    );
  }
}

class _GrievanceTile extends StatelessWidget {
  final GrievanceItem item;
  final int index;

  const _GrievanceTile({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final List<Color> tileColors = [
      const Color(0xFFE6F0FD),
      const Color(0xFFE0F7FA),
      const Color(0xFFFFF8E1),
    ];

    final Color backgroundColor = tileColors[index % tileColors.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Title
          Text(
            item.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),

          // 🔹 Description
          Text(item.description),
          const SizedBox(height: 6),

          // 🔹 Assigned By
          Text("👤 ${item.assigned_by}", style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),

          // 🔹 Assigned At
          Text("🕒 ${item.assigned_at}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),

          // 🔹 Status Message
          Align(
            alignment: Alignment.centerLeft,
            child: _statusMessage(item.actionCodeId),
          ),
        ],
      ),
    );
  }

  // 🔹 Status Message Builder
  Widget _statusMessage(int actionCodeId) {
    switch (actionCodeId) {
      case 3:
        return Chip(
          label: Text(
            "Sent for Review",
            style: TextStyle(color: Colors.indigo.shade800),
          ),
          backgroundColor: Colors.indigo.shade100,
        );
      case 5:
        return Chip(
          label: Text(
            "Rejected",
            style: TextStyle(color: Colors.redAccent),
          ),
          backgroundColor: Colors.red.shade100,
        );
      case 6:
        return Chip(
          label: Text(
            "Sent for Review",
            style: TextStyle(color: Colors.orange),
          ),
          backgroundColor: Colors.orange.shade100,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class GrievanceDetailPage extends StatefulWidget {
  final GrievanceItem item;

  const GrievanceDetailPage({super.key, required this.item});

  @override
  State<GrievanceDetailPage> createState() => _GrievanceDetailPageState();
}

class _GrievanceDetailPageState extends State<GrievanceDetailPage> {
  File? _atrFile;
  bool isActionValid = false;

  @override
  void initState() {
    super.initState();
    // ✅ Check if the action code is valid for ATR upload
    isActionValid = widget.item.actionCodeId == 5 || widget.item.actionCodeId == 9;
  }

  Future<void> pickATRDocument() async {
    if (!isActionValid) return;  // ❌ Prevent if action is not valid
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _atrFile = File(result.files.single.path!);
      });
    }
  }
  Future<void> _fetchUpdatedATRList(String grievanceId) async {
    try {
      var token = await SecureStorage.getAccessToken();
      var response = await http.get(
        Uri.parse("$baseURL/fetchATRDocuments?grievance_id=$grievanceId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> atrData = jsonDecode(response.body);
        final List<ATRItem> updatedATRItems = atrData.map((e) => ATRItem.fromJson(e)).toList();

        // ✅ Update the list of ATR documents
        setState(() {
          widget.item.atrItems.clear();
          widget.item.atrItems.addAll(updatedATRItems);
        });
      } else {
        print("Failed to fetch ATR documents");
      }
    } catch (e) {
      print("Error fetching updated ATR list: $e");
    }
  }

  Future<void> uploadATR(String grievanceId) async {
    if (_atrFile == null || !isActionValid) return;

    // ✅ Disable button immediately after click
    setState(() {
      isActionValid = false;
    });

    try {
      var token = await SecureStorage.getAccessToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseURL/uploadATR"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('atr', _atrFile!.path));
      request.fields['grievance_id'] = grievanceId;

      var response = await request.send();
      if (response.statusCode == 200) {
        // ✅ Show Snackbar for successful upload
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ATR uploaded successfully")),
        );

        // ✅ Clear the selected file
        setState(() {
          _atrFile = null;
        });

        Navigator.push(context, MaterialPageRoute(builder: (context)=>Level2_AcceptedGrievancePage()));

        // ✅ Refresh the ATR List after upload


      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload ATR")),
        );
      }
    } catch (e) {
      print("Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred while uploading.")),
      );
    } finally {
      // ✅ Re-enable button after operation completes
      setState(() {
        isActionValid = widget.item.actionCodeId == 5 || widget.item.actionCodeId == 9;
      });
    }
  }


  @override
  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        // 🔹 AppBar Title displaying the grievance title and ID
        title: Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown, // 🔹 Scales down to fit
            child: Text(
              "${item.title} (${item.grievance_id})",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        backgroundColor: Colors.indigo,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Status Message - Shows the status of the grievance
            Align(
              alignment: Alignment.centerRight,
              child: _statusMessage(item.actionCodeId),
            ),
            const SizedBox(height: 10),

            // 🔹 Title and Description
            Text("Title : ${item.title}"),
            const SizedBox(height: 10),
            Text("Description : ${item.description}"),
            const SizedBox(height: 10),

            // 🔹 Image Carousel Display
            if (item.imageUrls.isNotEmpty) ...[
              const Text("Images:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                ),
                items: item.imageUrls.map((imgUrl) {
                  return GestureDetector(
                    onTap: () => launchUrl(Uri.parse(imgUrl)),
                    child: Image.network(imgUrl, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 🔹 Complainant Documents List
            if (item.documentUrls.isNotEmpty) ...[
              const Text("Complainant Documents:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: item.documentUrls.map((docUrl) {
                  return ListTile(
                    title: Text(docUrl.split('/').last),
                    trailing: const Icon(Icons.open_in_new, color: Colors.indigo),
                    onTap: () => launchUrl(Uri.parse(docUrl)),
                  );
                }).toList(),
              ),
            ],

            // 🔹 ATR Display
            const SizedBox(height: 20),
            if (item.atrItems.isNotEmpty) ...[
              const Text("ATR Documents:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: item.atrItems.map((ATRItem atrItem) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Version: ${atrItem.version}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Column(
                        children: atrItem.documents.map((docUrl) {
                          return ListTile(
                            title: Text(docUrl.split('/').last),
                            trailing: const Icon(Icons.open_in_new, color: Colors.indigo),
                            onTap: () => launchUrl(Uri.parse(docUrl)),
                          );
                        }).toList(),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // 🔹 Pick ATR Document Button
            ElevatedButton.icon(
              onPressed: isActionValid ? pickATRDocument : null,
              icon: const Icon(Icons.attach_file),
              label: const Text("Pick ATR Document"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActionValid ? Colors.indigo : Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),

            // 🔹 Display Selected ATR Document Name
            if (_atrFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Selected: ${_atrFile!.path.split('/').last}",
                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500),
                ),
              ),

            const SizedBox(height: 10),

            // 🔹 Submit ATR Document Button
            ElevatedButton.icon(
              onPressed: isActionValid && _atrFile != null ? () => uploadATR(item.grievance_id) : null,
              icon: const Icon(Icons.upload_file),
              label: const Text("Submit ATR"),
              style: ElevatedButton.styleFrom(
                backgroundColor: (isActionValid && _atrFile != null) ? Colors.indigo : Colors.indigo.shade50,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // 🔹 Status Message Builder
  Widget _statusMessage(int actionCodeId) {
    switch (actionCodeId) {
      case 3:
        return Chip(
          label: Text(
            "Sent for Review",
            style: TextStyle(color: Colors.indigo.shade800),
          ),
          backgroundColor: Colors.indigo.shade100,
        );
      case 5:
        return Chip(
          label: Text(
            "Rejected",
            style: TextStyle(color: Colors.redAccent),
          ),
          backgroundColor: Colors.red.shade100,
        );
      case 6:
        return Chip(
          label: Text(
            "Sent for Review",
            style: TextStyle(color: Colors.orange),
          ),
          backgroundColor: Colors.orange.shade100,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
