import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ssh/refreshtoken.dart';
import 'config.dart';
import 'package:ssh/officer_G_detail_page.dart';

void main() {
  runApp(const MaterialApp(home: NewGrievancePage()));
}

class NewGrievancePage extends StatefulWidget {
  const NewGrievancePage({super.key});

  @override
  State<NewGrievancePage> createState() => _NewGrievancePageState();
}

class _NewGrievancePageState extends State<NewGrievancePage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<List<GrievanceItem>> fetchGrievances() async {
    var token = await secureStorage.read(key: "accessToken");
    var response = await http.get(
      Uri.parse("$baseURL/getGrievancesByDistrict"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if(response.statusCode == 401){
      bool refreshed = await refreshToken();
      if(refreshed){
        token = await secureStorage.read(key: "accessToken");
        response = await http.get(
          Uri.parse("$baseURL/getGrievancesByDistrict"),
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
        backgroundColor: const Color(0xFF4285F4),
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
    );
  }

  static String _formatDuration(String createdAt) {
    final DateTime createdTime = DateTime.parse(createdAt).toLocal();
    final Duration diff = DateTime.now().difference(createdTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
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
          Text(
            item.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "👤 ${item.complainantName}",
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          Text(
            "🏫 ${item.schoolName}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            "📍 ${item.blockName}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            "🕒 ${item.duration}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// class GrievanceDetailPage extends StatelessWidget {
//   final GrievanceItem item;
//
//   const GrievanceDetailPage({super.key, required this.item});
//
//   String getStatusText(GrievanceStatus status) {
//     switch (status) {
//       case GrievanceStatus.completed:
//         return "Completed";
//       case GrievanceStatus.inProgress:
//         return "In Progress";
//       case GrievanceStatus.pending:
//         return "Pending";
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Grievance Details"),
//         backgroundColor: const Color(0xFF4285F4),
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             Text("👤 Complainant: ${item.complainantName}", style: const TextStyle(fontSize: 16)),
//             const SizedBox(height: 4),
//             Text("🏫 School: ${item.schoolName}", style: const TextStyle(fontSize: 16)),
//             const SizedBox(height: 4),
//             Text("📍 Block: ${item.blockName}", style: const TextStyle(fontSize: 16)),
//             const SizedBox(height: 8),
//             Text("🕒 Submitted: ${item.duration}", style: const TextStyle(fontSize: 16)),
//             const SizedBox(height: 8),
//             Text("📌 Status: ${getStatusText(item.status)}", style: const TextStyle(fontSize: 16)),
//             const SizedBox(height: 20),
//             const Divider(),
//             const SizedBox(height: 20),
//             const Text(
//               "Description",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               item.description,
//               style: const TextStyle(fontSize: 14, color: Colors.black87),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
