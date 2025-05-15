import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

import 'config.dart';
import 'storage_service.dart';
import 'refreshtoken.dart';
import 'userdashboard.dart';

void main() {
  runApp(const UserReminder());
}

class UserReminder extends StatelessWidget {
  const UserReminder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notifications',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Color(0xFFF8FAFF), // Very light blue-ish white
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const ReminderPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<Map<String, dynamic>> grievanceList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReminders();
  }

  Future<void> fetchReminders() async {
    try {
      String? token = await SecureStorage.getAccessToken();

      var response = await http.get(
        Uri.parse('$baseURL/checkReminder'),
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
            Uri.parse('$baseURL/getReminder'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
          );
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          grievanceList = data
              .where((item) =>
          !(item['notification_type'] == 'Reminder Eligibility' &&
              item['can_send_reminder'] == false))
              .map<Map<String, dynamic>>((item) {
            final title = item['title'] ?? '';
            final timestamp = item['timestamp'] ?? '';
            final grievanceId = item['grievance_id'] ?? '';
            final notificationType = item['notification_type'] ?? '';
            final canSend = item['can_send_reminder'] ?? false;

            final messages = <String>[
              if (notificationType == 'Complaint Registered')
                'You have lodged a grievance titled "$title".'
              else if (notificationType == 'Reminder Eligibility')
                'You are now eligible to send a reminder for "$title".'
              else if (notificationType == 'Reminder Sent')
                  'You have sent a reminder.'
                else
                  'Update on "$title": $notificationType'
            ];

            return {
              'title': title,
              'timestamp': timestamp,
              'grievance_id': grievanceId,
              'messages': messages,
              'showReminderSection': canSend,
              'reminderStatus':
              canSend ? 'Reminder can be sent' : 'Reminder not eligible',
              'canSendReminder': canSend,
            };
          }).toList();
          isLoading = false;
        });
      } else {
        print('Failed to fetch reminders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reminders: $e');
    }
  }

  Future<void> sendReminder(String grievanceId) async {
    final token = await SecureStorage.getAccessToken();
    final requestBody = {"grievanceId": grievanceId};

    try {
      final response = await http.post(
        Uri.parse('$baseURL/addReminder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        setState(() {
          final grievance = grievanceList.firstWhere(
                  (g) => g['grievance_id'] == grievanceId,
              orElse: () => {});
          grievance['messages']
              .add('You have sent a reminder for "${grievance['title']}".');
          grievance['reminderStatus'] = 'Reminder sent';
          grievance['canSendReminder'] = false;
        });

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _buildReminderSentModal(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reminder')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending reminder')),
      );
    }
  }

  Widget _buildReminderSentModal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 48),
          const SizedBox(height: 12),
          Text('Reminder Sent!',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Your reminder has been sent successfully.',
            style: GoogleFonts.poppins(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text('Close',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String formatTimeDifference(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${(diff.inDays / 7).floor()}w';
    return '${(diff.inDays / 365).floor()}y';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : grievanceList.isEmpty
          ? const Center(child: Text("No notifications available."))
          : ListView.builder(
        itemCount: grievanceList.length,
        itemBuilder: (context, index) {
          final grievance = grievanceList[index];
          return _buildReminderCard(grievance);
        },
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> grievance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFE8F0FF), // light indigo for cards
      elevation: 2,
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
                    '${grievance['title']} (${grievance['grievance_id']})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
                Text(
                  formatTimeDifference(DateTime.parse(grievance['timestamp'])),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...grievance['messages'].map<Widget>(
                  (msg) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  msg,
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ),
            ),
            if (grievance['showReminderSection'] &&
                grievance['canSendReminder'])
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 150,
                      maxWidth: 220,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => sendReminder(grievance['grievance_id']),
                      child: Text(
                        'Send Reminder',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

  }
}
