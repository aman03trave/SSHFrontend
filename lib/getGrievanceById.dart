import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ssh/config.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final imagePaths = media?['images'] ?? [];
    final documentPaths = media?['documents'] ?? [];

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
                  const SizedBox(height: 20),
                  _buildSection(label: 'Title', value: title, icon: Icons.title),
                  const Divider(height: 32, color: Colors.grey),
                  _buildSection(label: 'Description', value: description, icon: Icons.description),
                  const Divider(height: 32, color: Colors.grey),
                  _buildSection(label: 'Created At', value: createdAt, icon: Icons.calendar_today),
                  const Divider(height: 32, color: Colors.grey),

                  // ✅ Image Carousel
                  if (imagePaths.isNotEmpty) ...[
                    const Text(
                      'Attached Images',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    CarouselSlider(
                      items: imagePaths.map<Widget>((path) {
                        final fullPath = '$baseURL/${normalizePath(path)}';
                        return GestureDetector(
                          onTap: () {
                            // Open full-screen image on tap
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenImageViewer(imageUrl: fullPath),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              fullPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Text("Failed to load image."),
                            ),
                          ),
                        );
                      }).toList(),
                      options: CarouselOptions(
                        height: 200,
                        enableInfiniteScroll: false,
                        viewportFraction: 0.8,
                        enlargeCenterPage: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ✅ Document List
                  if (documentPaths.isNotEmpty) ...[
                    const Text(
                      'Attached Documents',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    ...documentPaths.map((doc) {
                      final fullPath = '$baseURL/${normalizePath(doc)}';
                      return InkWell(
                        onTap: () async {
                          if (await canLaunchUrl(Uri.parse(fullPath))) {
                            await launchUrl(Uri.parse(fullPath), mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open the document.')),
                            );
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                doc.split('/').last,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
