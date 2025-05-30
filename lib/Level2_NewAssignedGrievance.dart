import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import 'package:ssh/refreshtoken.dart';
import 'config.dart';
import 'officer_G_detail_page.dart';

void main() {
  runApp(const MaterialApp(home: Level2_NewGrievancePage()));
}

class Level2_NewGrievancePage extends StatefulWidget {
  const Level2_NewGrievancePage({super.key});

  @override
  State<Level2_NewGrievancePage> createState() => _NewGrievancePageState();
}

class _NewGrievancePageState extends State<Level2_NewGrievancePage> {

  Future<List<GrievanceItem>> fetchGrievances() async {
    var token = await SecureStorage.getAccessToken();
    var response = await http.get(
      Uri.parse("$baseURL/getAssignedToMe"),
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
          Uri.parse("$baseURL/getAssignedToMe"),
          headers: {

            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );
      }
    }

    if (response.statusCode == 200) {
      print("Hellow");
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => GrievanceItem.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load grievances");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("New Grievances"),
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Latest grievances submitted by users.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<GrievanceItem>>(
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

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: grievances.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = grievances[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GrievanceDetailPage(item: item
                              ),
                            ),
                          );
                        },
                        child: _GrievanceTile(item: item, index: index),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum GrievanceStatus { completed, inProgress, pending }

class GrievanceItem {
  final String grievanceId;
  final String title;
  final String complainantName;
  final String blockName;
  final String schoolName;
  final String duration;
  final GrievanceStatus status;
  final String description;
  final String assigned_at;
  final Map<String, dynamic> grievanceMedia;


  GrievanceItem({
    required this.grievanceId,
    required this.title,
    required this.complainantName,
    required this.blockName,
    required this.schoolName,
    required this.duration,
    required this.status,
    required this.description,
    required this.grievanceMedia,
    required this.assigned_at
  });

  factory GrievanceItem.fromJson(Map<String, dynamic> json) {
    return GrievanceItem(
      grievanceId: json['grievance_id'] ?? '',
      title: json['title'] ?? '',
      complainantName: json['name'] ?? 'Unknown',
      blockName: json['block_name'] ?? 'Unknown Block',
      schoolName: json['school_name'] ?? 'Unknown School',
      duration: _formatDuration(json['created_at']),
      status: GrievanceStatus.pending, // You can update based on your backend
      description: json['description'] ?? '',
      grievanceMedia: json['grievance_media'] ?? {},
      assigned_at: json['assigned_at'] ?? ''
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

Future<void> downloadAndOpenDocument(String url, BuildContext context) async {
  try {
    bool permissionGranted = await requestStoragePermission();
    if (!permissionGranted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Storage permission denied")));
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Error: $e")));
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

String formatDate(String dateStr) {
  final DateTime parsedDate = DateTime.parse(dateStr);
  return DateFormat('dd/MM/yyyy').format(parsedDate);
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
          Text(
            item.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(item.description),
          const SizedBox(height: 6),
          Text(
            "👤 Assigned By: ${item.complainantName}",
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            "🕒 Assigned On: ${formatDate(item.assigned_at)}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class GrievanceDetailPage extends StatelessWidget {
  final GrievanceItem item;


  const GrievanceDetailPage({super.key, required this.item});


  Future<void> postGrievanceAction(String grievanceId, int actionCodeId) async {
    var token = await SecureStorage.getAccessToken();
    var response = await http.post(
      Uri.parse("$baseURL/return_grievance"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'grievance_id': grievanceId,
        'actioncodeId': actionCodeId,
      }),
    );

    if (response.statusCode == 200) {
      print("Action submitted successfully.");
    } else {
      print("Failed to submit action: ${response.body}");
      throw Exception("Failed to submit action.");
    }
  }


  @override
  Widget build(BuildContext context) {
    final List<dynamic> imageUrl = item.grievanceMedia['images'] ?? [];
    final List<dynamic> documentUrl = item.grievanceMedia['documents'] ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grievance Details"),
        backgroundColor: const Color(0xFF4285F4),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("Description: ${item.description}"),
              const SizedBox(height: 8),
              Text("👤 Assigned By: ${item.complainantName}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("🕒 Assigned: ${item.assigned_at}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              if (imageUrl.isNotEmpty)
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200.0,
                    enlargeCenterPage: true,
                  ),
                  items: imageUrl.map((imagePath) {
                    final imageUrl = "$baseURL/$imagePath";
                    return Builder(
                      builder: (BuildContext context) {
                        return Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              documentUrl.isNotEmpty
                  ? Column(
                children: documentUrl.map((docUrl) {
                  final fullDocUrl = "$baseURL/$docUrl";
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.download),
                      label: Text("Download Document"),
                      onPressed: () => downloadAndOpenDocument(fullDocUrl, context),
                    ),
                  );
                }).toList(),
              )
                  : Text("No documents available."),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () async {
                      try {
                        await postGrievanceAction(item.grievanceId, 9); // Accepted
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Grievance Accepted")),
                        );
                        Navigator.pop(context);
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to accept grievance")),
                        );
                      }
                    },
                    label: const Text("Accept"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: () async {
                      try {
                        await postGrievanceAction(item.grievanceId, 8); // Rejected
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Grievance Rejected")),
                        );
                        Navigator.pop(context);
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to reject grievance")),
                        );
                      }
                    },
                    label: const Text("Return"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

