import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ssh/config.dart';

class GetGrievanceById extends StatelessWidget {
  final Map<String, dynamic> grievanceData;

  const GetGrievanceById({super.key, required this.grievanceData});

  @override
  Widget build(BuildContext context) {
    final title = grievanceData['title'] ?? 'N/A';
    final description = grievanceData['description'] ?? 'No description provided.';
    final createdAt = grievanceData['created_at'] != null
        ? DateFormat.yMMMMd().add_jm().format(DateTime.parse(grievanceData['created_at']))
        : 'Date not available';
    final media = grievanceData['media'];
    final imagePath = media?['image'];
    final documentPath = media?['document'];

    String normalizePath(String? path) {
      return path?.replaceAll('\\', '/') ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grievance Details'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.report_problem, size: 28, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        'Grievance Information',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(label: 'Title', value: title, icon: Icons.title),
                  const Divider(height: 32, color: Colors.grey),
                  _buildSection(label: 'Description', value: description, icon: Icons.description),
                  const Divider(height: 32, color: Colors.grey),
                  _buildSection(label: 'Created At', value: createdAt, icon: Icons.calendar_today),
                  const Divider(height: 32, color: Colors.grey),
                  if (imagePath != null && imagePath.isNotEmpty) ...[
                    const Text(
                      'Attached Image',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '$baseURL/${normalizePath(imagePath)}',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Text("Failed to load image."),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (documentPath != null && documentPath.isNotEmpty) ...[
                    const Text(
                      'Attached Document',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        // You could use `url_launcher` package to open this document
                        // Example: launchUrl(Uri.parse('http://your-server.com/...'));
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              normalizePath(documentPath).split('/').last,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String label, required String value, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'N/A',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
