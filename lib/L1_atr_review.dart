import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'storage_service.dart';
import 'config.dart';
import 'package:permission_handler/permission_handler.dart';

class ATRReviewListPage extends StatefulWidget {
  const ATRReviewListPage({super.key});

  @override
  _ATRReviewListPageState createState() => _ATRReviewListPageState();
}

class _ATRReviewListPageState extends State<ATRReviewListPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> atrReviews = [];

  @override
  void initState() {
    super.initState();
    fetchATRReviews();
  }

  Future<void> fetchATRReviews() async {
    String? token = await SecureStorage.getAccessToken();
    final url = Uri.parse("$baseURL/getATRL1");

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          atrReviews = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        print("Failed to load ATR Reviews");
      }
    } catch (e) {
      print("Error: $e");
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

  Future<void> submitReview(String grievanceId, String status, String remarks) async {
    String? token = await SecureStorage.getAccessToken();
    final url = Uri.parse("$baseURL/reviewATR");

    if (remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remarks cannot be empty')),
      );
      return;
    }

    final body = jsonEncode({
      "atr_id": grievanceId, // Updated key
      "status": status,
      "remarks": remarks,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
      } else {
        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while submitting the review')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATR Reviews', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: atrReviews.length,
        itemBuilder: (context, index) {
          final data = atrReviews[index];
          return ATRReviewCard(
            data: data,
            onSubmit: submitReview,
            onViewDocument: (String documentPath) {
              final fullUrl = "$baseURL/$documentPath";
              downloadAndOpenDocument(fullUrl, context);
            },
          );
        },
      ),
    );
  }
}

class ATRReviewCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String, String, String) onSubmit;
  final Function(String) onViewDocument;

  const ATRReviewCard({
    super.key,
    required this.data,
    required this.onSubmit,
    required this.onViewDocument,
  });

  @override
  _ATRReviewCardState createState() => _ATRReviewCardState();
}

class _ATRReviewCardState extends State<ATRReviewCard> {
  bool isExpanded = false;
  String selectedStatus = 'accepted';
  final TextEditingController _remarksController = TextEditingController();
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        title: Text(data['title']),
        subtitle: Text("Grievance ID: ${data['grievance_id']}"),
        trailing: Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        ),
        onExpansionChanged: (value) {
          setState(() {
            isExpanded = value;
          });
        },
        children: isExpanded
            ? [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Complainant: ${data['name']}"),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      widget.onViewDocument(data['media']['document']),
                  child: const Text('View Document'),
                ),
                const SizedBox(height: 12),
                const Text("Review Decision:"),
                DropdownButton<String>(
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    // Logging to see if the button is clicked
                    print("Submit button clicked");

                    final grievanceId = data['grievance_id'];
                    final remarks = _remarksController.text;

                    // Validate inputs before calling submit
                    if (grievanceId == null || selectedStatus.isEmpty) {
                      print("Error: Grievance ID or status is missing");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Missing Grievance ID or Review Status')),
                      );
                      return;
                    }

                    setState(() => isSubmitting = true);

                    print("Calling submitReview with:");
                    print("Grievance ID: $grievanceId");
                    print("Status: $selectedStatus");
                    print("Remarks: $remarks");

                    await widget.onSubmit(
                      grievanceId,
                      selectedStatus,
                      remarks,
                    );

                    setState(() => isSubmitting = false);
                  },
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Review'),
                ),


              ],
            ),
          ),
        ]
            : [],
      ),
    );
  }
}
