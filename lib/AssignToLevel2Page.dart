import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ssh/customsnackbar.dart';
import 'dart:convert';
import 'storage_service.dart';
import 'config.dart';
import 'refreshtoken.dart';

void main() {
  runApp(const MaterialApp(home: AssignToLevel2Page()));
}

class GrievanceItem {
  final String grievanceId;
  final String title;
  final String location;
  final String complainantName;
  final String schoolName;
  final String blockName;
  final String duration;

  const GrievanceItem({
    required this.grievanceId,
    required this.title,
    required this.location,
    required this.complainantName,
    required this.schoolName,
    required this.blockName,
    required this.duration,
  });

  factory GrievanceItem.fromJson(Map<String, dynamic> json) {
    return GrievanceItem(
      grievanceId: json['grievance_id'].toString(),
      title: json['title'] ?? 'Untitled',
      location: "${json['block_name'] ?? ''}, ${json['school_name'] ?? ''}",
      complainantName: json['complainant_name'] ?? 'Unknown',
      schoolName: json['school_name'] ?? 'Unknown',
      blockName: json['block_name'] ?? 'Unknown',
      duration: json['duration'] ?? 'N/A',
    );
  }
}

class AssignToLevel2Page extends StatefulWidget {
  const AssignToLevel2Page({super.key});

  @override
  State<AssignToLevel2Page> createState() => _AssignToLevel2PageState();
}

class _AssignToLevel2PageState extends State<AssignToLevel2Page> {
  List<GrievanceItem> grievances = [];
  List<Map<String, dynamic>> officerDataList = [];
  Map<String, String> officerNameToId = {};
  bool isLoading = true;

  final List<Color> cardColors = [
    Colors.white,
    const Color(0xFFE6F0FD),
    const Color(0xFFE0F7FA),
    const Color(0xFFFFF8E1),
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      String? token = await SecureStorage.getAccessToken();

      Future<http.Response> fetchGrievances() => http.get(
        Uri.parse('$baseURL/getGrievancesByDistrict'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      Future<http.Response> fetchOfficers() => http.get(
        Uri.parse('$baseURL/getBlockOfficersWithGrievanceCount'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      var grievanceResponse = await fetchGrievances();
      var officerResponse = await fetchOfficers();

      if (grievanceResponse.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
          grievanceResponse = await fetchGrievances();
          officerResponse = await fetchOfficers();
        }
      }

      if (grievanceResponse.statusCode == 200 && officerResponse.statusCode == 200) {
        final List grievanceData = jsonDecode(grievanceResponse.body);
        final List officerData = jsonDecode(officerResponse.body);

        setState(() {
          grievances = grievanceData.map((item) => GrievanceItem.fromJson(item)).toList();
          officerDataList = List<Map<String, dynamic>>.from(officerData);
          officerNameToId = {
            for (var o in officerData)
              "${o['name']} (Grievances: ${o['grievance_count']})": o['user_id'].toString()
          };
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> assignGrievance(String grievanceId, String officerId) async {
    String? token = await SecureStorage.getAccessToken();

    Future<http.Response> sendAssignment() => http.post(
      Uri.parse('$baseURL/assignGrievance'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        'grievance_id': grievanceId,
        'assigned_to': officerId,
      }),
    );

    var response = await sendAssignment();

    if (response.statusCode == 401) {
      bool refreshed = await refreshToken();
      if (refreshed) {
        token = await SecureStorage.getAccessToken();
        response = await sendAssignment();
      }
    }

    if (response.statusCode == 200) {
      showCustomSnackBar(context, "Grievance Assigned");
      setState(() {});
    } else {
      throw Exception('Failed to assign grievance');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Assign to Level 2"),
        backgroundColor: const Color(0xFF3366CC),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // const Text("Level 2 Officers", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            // const SizedBox(height: 10),
            // Table(
            //   border: TableBorder.all(),
            //   columnWidths: const {
            //     0: FractionColumnWidth(0.7),
            //     1: FractionColumnWidth(0.3),
            //   },
            //   children: [
            //     const TableRow(
            //       children: [
            //         Padding(
            //           padding: EdgeInsets.all(8.0),
            //           child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
            //         ),
            //         Padding(
            //           padding: EdgeInsets.all(8.0),
            //           child: Text('Grievance Count', style: TextStyle(fontWeight: FontWeight.bold)),
            //         ),
            //       ],
            //     ),
            //     ...officerDataList.map((officer) => TableRow(
            //       children: [
            //         Padding(
            //           padding: const EdgeInsets.all(8.0),
            //           child: Text(officer['name'] ?? ''),
            //         ),
            //         Padding(
            //           padding: const EdgeInsets.all(8.0),
            //           child: Text(officer['grievance_count'].toString()),
            //         ),
            //       ],
            //     ))
            //   ],
            // ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: grievances.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return GrievanceAssignCard(
                    item: grievances[index],
                    officerMap: officerNameToId,
                    onAssign: assignGrievance,
                    backgroundColor: cardColors[index % cardColors.length],
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

class GrievanceAssignCard extends StatefulWidget {
  final GrievanceItem item;
  final Map<String, String> officerMap;
  final Function(String, String) onAssign;
  final Color backgroundColor;

  const GrievanceAssignCard({
    super.key,
    required this.item,
    required this.officerMap,
    required this.onAssign,
    required this.backgroundColor,
  });

  @override
  State<GrievanceAssignCard> createState() => _GrievanceAssignCardState();
}

class _GrievanceAssignCardState extends State<GrievanceAssignCard> {
  String? selectedOfficer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

          const SizedBox(height: 4),
          Text("🏫 School: ${widget.item.schoolName}", style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text("📍 Block: ${widget.item.blockName}", style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),

          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedOfficer,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              labelText: "Assign to Block Officer",
              labelStyle: const TextStyle(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: widget.officerMap.keys.map((officerName) {
              return DropdownMenuItem<String>(
                value: officerName,
                child: Text(officerName, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedOfficer = value;
              });
            },
          ),
          if (selectedOfficer != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  try {
                    await widget.onAssign(
                      widget.item.grievanceId,
                      widget.officerMap[selectedOfficer]!,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${widget.item.title} assigned to $selectedOfficer",
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Assignment failed: $e")),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF3366CC),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Assign"),
              ),
            ),
        ],
      ),
    );
  }
}
