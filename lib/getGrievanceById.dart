import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ssh/config.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class GetGrievanceById extends StatelessWidget {
  final Map<String, dynamic> grievanceData;

  const GetGrievanceById({super.key, required this.grievanceData});

  @override
  @override
  Widget build(BuildContext context) {
    try {
      if (grievanceData.isEmpty || grievanceData['title'] == null) {
        throw Exception("Invalid grievance data");
      }

      final title = grievanceData['title'] ?? 'N/A';
      final description = grievanceData['description'] ?? 'No description provided.';
      final createdAt = grievanceData['created_at'] != null
          ? DateFormat.yMMMMd().add_jm().format(DateTime.tryParse(grievanceData['created_at']) ?? DateTime.now())
          : 'Date not available';

      final media = grievanceData['grievance_media'];
      final imagePaths = (media?['images'] as List?)?.whereType<String>().toList() ?? [];
      final documentPaths = (media?['documents'] as List?)?.whereType<String>().toList() ?? [];

      String normalizePath(String? path) {
        return path?.replaceAll('\\', '/') ?? '';
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          elevation: 2,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width: 4),
              Text(
                'Grievance Details',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            color: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSection(label: 'Title', value: title, icon: Icons.title),
                    Divider(height: 32, color: Colors.indigo.shade200),
                    _buildSection(label: 'Description', value: description, icon: Icons.description),
                    Divider(height: 32, color: Colors.indigo.shade200),
                    _buildSection(label: 'Created At', value: createdAt, icon: Icons.calendar_today),
                    Divider(height: 32, color: Colors.indigo.shade200),

                    if (imagePaths.isNotEmpty) ...[
                      Text(
                        'Attached Images',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CarouselSlider(
                        items: imagePaths.map<Widget>((path) {
                          final fullPath = '$baseURL/${normalizePath(path)}';
                          return GestureDetector(
                            onTap: () {
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
                                errorBuilder: (context, error, stackTrace) =>
                                const Text("Failed to load image."),
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

                    if (documentPaths.isNotEmpty) ...[
                      Text(
                        'Attached Documents',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...documentPaths.map((doc) {
                        final normalizedPath = normalizePath(doc);
                        final fullDocPath = '$baseURL/$normalizedPath';

                        return InkWell(
                          onTap: () async {
                            final uri = Uri.parse(fullDocPath);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open the document.')),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    doc.split('/').last,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.indigo.shade700,
                                      decoration: TextDecoration.underline,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
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
    } catch (e) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Grievance Details"),
          backgroundColor: Colors.indigo,
        ),
        body: const Center(
          child: Text(
            'Invalid or missing grievance data.',
            style: TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
        ),
      );
    }
  }


  Widget _buildSection({required String label, required String value, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.indigo.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.indigo.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'N/A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
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
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}
