import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'storage_service.dart';
import 'refreshtoken.dart';
import 'package:timeago/timeago.dart' as timeago;

class GrievanceDetailPage extends StatefulWidget {
  final Map<String, dynamic> complaint;

  GrievanceDetailPage({required this.complaint});

  @override
  _GrievanceDetailPageState createState() => _GrievanceDetailPageState();
}

class _GrievanceDetailPageState extends State<GrievanceDetailPage> {
  List<dynamic> actionLogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchActionLogs();
  }

  Future<void> fetchActionLogs() async {
    String grievanceId = widget.complaint['grievance_id'];
    String? token = await SecureStorage.getAccessToken();

    var response = await http.post(
      Uri.parse('$baseURL/display_AL'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'grievance_id': grievanceId}),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        actionLogs = data;
        isLoading = false;
      });
      
    } if(response.statusCode == 401){
      bool refreshed = await refreshToken();
      if (refreshed) {
        token = await SecureStorage.getAccessToken();
        response = await http.post(
          Uri.parse('$baseURL/display_AL'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'grievance_id': grievanceId}),
        );
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          setState(() {
            actionLogs = data;
            isLoading = false;});
        }
      }

    }
    
    else {
      print("Failed to fetch action logs: ${response.statusCode}");
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

  String getStatusMessage(Map<String, dynamic> item) {
    final code = item['code'];
    final name = item['officer_name'];

    switch (code) {
      case "Complaint Registered":
        return 'You have registered.';
      case "Assigned to Level 2":
        return '$name has assigned your grievance to Block Educational Officer.';
      case "ATR Report Generated by Level 2":
        return 'ATR report generated by $name.';
      case "ATR Verified by Level 1":
        return '$name verified the ATR.';
      case "ATR Rejected by Level 1":
        return '$name asked for more clarification about the ATR submitted by Block Educational Officer.';
      case "ATR Updated & Resubmitted by Level 2":
        return '$name have updated and resubmitted ATR.';
      case "Complaint Disposed":
        return 'Your grievance has been marked as disposed.';
      case "Grievance Returned by Level 2":
        return '$name has returned the grievance for further clarification.';
      case "Grievance Accepted by Level 2":
        return '$name has accepted your grievance for further investigation.';
      default:
        return 'Update on "$code"';
    }
  }
  String formatToDate(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.complaint['media']?['images'];
    final documentUrls = widget.complaint['media']?['documents'];

    final List<String> images = List<String>.from(imageUrls ?? []);
    final List<String> documents = List<String>.from(documentUrls ?? []);

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
          backgroundColor: Colors.indigo,
          iconTheme: IconThemeData(color: Colors.white),
          titleSpacing: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "${widget.complaint["title"]} (${widget.complaint["grievance_id"]})",
            style: TextStyle(fontSize: 18,// Base size; FittedBox will handle overflow
                fontWeight: FontWeight.w600,
                color: Colors.white)
          ),

        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : widget.complaint.isEmpty
          ? Center(child: Text("No grievance found."))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  enlargeCenterPage: true,
                ),
                items: images.map((imagePath) {
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
            SizedBox(height: 16),
            Text("Description: ${widget.complaint["description"]}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text("Documents:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            documents.isNotEmpty
                ? Column(
              children: documents.map((docUrl) {
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
            SizedBox(height: 16),
            Text("Action Log", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            actionLogs.isNotEmpty
                ? Column(
              children: actionLogs.map((log) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.timeline, color: Colors.blue),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${getStatusMessage(log)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          formatToDate(log['action_timestamp']),
                          style: const TextStyle(color: Colors.black38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
                : Center(child: Text("No action logs available.")),
          ],
        ),
      ),
    );
  }

}
