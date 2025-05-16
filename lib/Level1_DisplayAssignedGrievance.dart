import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ssh/refreshtoken.dart';
import 'config.dart';
import 'officer_G_detail_page.dart';

void main() {
  runApp(const MaterialApp(home: AssignedGrievancePage()));
}

class AssignedGrievancePage extends StatefulWidget {
  const AssignedGrievancePage({super.key});

  @override
  State<AssignedGrievancePage> createState() => _AssignedGrievancePageState();
}

class _AssignedGrievancePageState extends State<AssignedGrievancePage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<List<GrievanceItem>> fetchAssignedGrievances() async {
    var token = await secureStorage.read(key: "accessToken");
    var response = await http.get(
      Uri.parse("$baseURL/getAssignedGrievance"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        token = await secureStorage.read(key: "accessToken");
        response = await http.get(
          Uri.parse("$baseURL/getAssignedGrievance"),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => GrievanceItem.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load assigned grievances");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Assigned Grievances"),
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
              child: Text(
                "Grievances assigned to you for further action.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<GrievanceItem>>(
                future: fetchAssignedGrievances(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No assigned grievances found."));
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
                              builder: (_) => GrievanceDetailPage(complaint: {
                                "grievance_id": item.grievanceId,
                                "title": item.title,
                                "description": item.description,
                                "block_name": item.blockName,
                                "school_name": item.schoolName,
                                "name": item.complainantName,
                                "grievance_media": item.grievanceMedia,
                              }),
                            ),
                          );
                        },
                        child: _AssignedGrievanceTile(item: item, index: index),
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

class GrievanceItem {
  final String title;
  final String description;
  final String assignedToName;
  final DateTime assignedAt;
  final String grievanceId;
  final String complainantName;
  final String blockName;
  final String schoolName;
  final String duration;

  final Map<String, dynamic> grievanceMedia;


  GrievanceItem({
    required this.title,
    required this.description,
    required this.assignedToName,
    required this.assignedAt,
    required this.grievanceId,
    required this.complainantName,
    required this.blockName,
    required this.schoolName,
    required this.duration,


    required this.grievanceMedia,
  });

  factory GrievanceItem.fromJson(Map<String, dynamic> json) {
    return GrievanceItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedToName: json['assigned_to_name'] ?? '',
      assignedAt: DateTime.parse(json['assigned_at']),
      grievanceId: json['grievance_id'] ?? '',
      complainantName: json['name'] ?? 'Unknown',
      blockName: json['block_name'] ?? 'Unknown Block',
      schoolName: json['school_name'] ?? 'Unknown School',
      duration: _formatDuration(json['created_at']),
      grievanceMedia: json['grievance_media'] ?? {},
    );
  }
}

String _formatDuration(String createdAt) {
final DateTime createdTime = DateTime.parse(createdAt).toLocal();
final Duration diff = DateTime.now().difference(createdTime);

if (diff.inSeconds < 60) return 'Just now';
if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
if (diff.inHours < 24) return '${diff.inHours} hours ago';
return '${diff.inDays} days ago';
}


class _AssignedGrievanceTile extends StatelessWidget {
  final GrievanceItem item;
  final int index;

  const _AssignedGrievanceTile({required this.item, required this.index});

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
          Text(
            "👨‍💼 Assigned to: ${item.assignedToName}",
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            "🗓️ Assigned at: ${item.assignedAt.toLocal().toString().split('.').first}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}


class AssignedGrievanceDetailPage extends StatelessWidget {
  final GrievanceItem item;

  const AssignedGrievanceDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Grievance"),
        backgroundColor: const Color(0xFF4285F4),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("👨‍💼 Assigned To: ${item.assignedToName}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text("🗓️ Assigned At: ${item.assignedAt.toLocal().toString().split('.').first}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

