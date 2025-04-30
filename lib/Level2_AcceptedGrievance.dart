import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
        title: const Text("Accepted Grievances"),
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
                              builder: (_) => GrievanceDetailPage(item: item),
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
  final String title;
  final String grievance_id;
  final String assigned_by;
  final String assigned_at;
  final String description;
  final String? imageUrl;
  final String? documentUrl;

  GrievanceItem({
    required this.title,
    required this.grievance_id,
    required this.assigned_at,
    required this.assigned_by,
    required this.description,
    this.imageUrl,
    this.documentUrl,
  });

  factory GrievanceItem.fromJson(Map<String, dynamic> json) {
    final media = json['media'] ?? {};
    return GrievanceItem(
      grievance_id: json['grievance_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assigned_by: json['assigned_by'] ?? 'Unknown',
      assigned_at: _formatDuration(json['assigned_at'] ?? ''),
      imageUrl: media['image'] != null ? "$baseURL/${media['image']}" : null,
      documentUrl: media['document'] != null ? "$baseURL/${media['document']}" : null,
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
            "👤 ${item.assigned_by}",
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            "🕒 ${item.assigned_at}",
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
      Uri.parse("$baseURL/addAction"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'grievance_id': grievanceId,
        'action_code_id': actionCodeId,
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
              Text("👤 Assigned By: ${item.assigned_by}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("🕒 Assigned: ${item.assigned_at}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              if (item.imageUrl != null) ...[
                const Text("Attached Image:",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Image.network(item.imageUrl!, height: 200),
                const SizedBox(height: 20),
              ],
              if (item.documentUrl != null) ...[
                const Text("Attached Document:",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Image.network(item.documentUrl!, height: 200),
                const SizedBox(height: 20),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () async {
                      try {
                        await postGrievanceAction(item.grievance_id, 9); // Accepted
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
                        await postGrievanceAction(item.grievance_id, 8); // Rejected
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
                    label: const Text("Reject"),
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

