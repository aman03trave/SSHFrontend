import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'config.dart';

Future<void> logDashboardVisit(String userId, String coordinates) async {

  final url = Uri.parse('$baseURL/visit');

  await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"user_id": userId, "coordinates": coordinates}),
  );
}
