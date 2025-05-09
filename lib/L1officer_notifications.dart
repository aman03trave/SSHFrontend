import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'storage_service.dart';
import 'refreshtoken.dart';
import 'Level1_dashboard.dart';
import 'package:timeago/timeago.dart' as timeago;

class LevelReminderPage extends StatefulWidget {
  const LevelReminderPage({super.key});

  @override
  State<LevelReminderPage> createState() => _LevelReminderPageState();
}

class _LevelReminderPageState extends State<LevelReminderPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      String? token = await SecureStorage.getAccessToken();
      var response = await http.get(
        Uri.parse('$baseURL/getRemindersL1'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        bool refreshed = await refreshToken();
        if (refreshed) {
          token = await SecureStorage.getAccessToken();
          response = await http.get(
            Uri.parse('$baseURL/getRemindersL1'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          notifications = data.map<Map<String, dynamic>>((item) {
            return {
              'action_id': item['action_id'],
              'grievance_id': item['grievance_id'],
              'officer_id': item['officer_id'],
              'action_code': item['action_code'],
              'timestamp': item['action_timestamp'],
              'title': item['title'],
              'description': item['description'],
              'level1_officer': item['level1officer'],
              'complainant': item['complainant'],
              'message': generateMessage(item),
            };
          }).toList();
          isLoading = false;
        });
      } else {
        print('Failed to load notifications: ${response.body}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  String generateMessage(Map<String, dynamic> item) {
    final code = item['action_code'];
    final level1 = item['level1officer'];
    final complainant = item['complainant'];
    final title = item['title'];

    switch (code) {
      case "Complaint Registered":
        return '$complainant has registered a new grievance titled "$title".';
      case "Assigned to Level 2":
        return 'Grievance "$title" has been assigned to Level 2 by $level1.';
      case "ATR Report Generated by Level 2":
        return 'ATR report generated by Level 2 for "$title".';
      case "ATR Verified by Level 1":
        return '$level1 verified the ATR for "$title".';
      case "ATR Rejected by Level 1":
        return '$level1 rejected the ATR submitted for "$title".';
      case "ATR Updated & Resubmitted by Level 2":
        return 'Level 2 has updated and resubmitted ATR for "$title".';
      case "Complaint Disposed":
        return 'Grievance "$title" has been marked as disposed.';
      case "Grievance Returned by Level 2":
        return 'Level 2 has returned the grievance "$title" for further clarification.';
      case "Grievance Accepted by Level 2":
        return 'Level 2 accepted the grievance "$title".';
      default:
        return 'Update on "$title"';
    }
  }

  String formatTimeAgo(String timestamp) {
    final time = DateTime.parse(timestamp);
    return timeago.format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GrievanceDashboard()),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No notifications available."))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            color: const Color(0xFFEAF3FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item['title']} (${item['grievance_id']})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        formatTimeAgo(item['timestamp']),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['message'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
