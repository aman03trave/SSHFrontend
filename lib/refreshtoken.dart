import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'config.dart';

Future<bool> refreshToken() async {
  String? refreshToken = await SecureStorage.getRefreshToken();

  if (refreshToken == null) {
    print("⚠️ No refresh token found.");
    return false;
  }

  final response = await http.post(
    Uri.parse("$baseURL/refresh"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"refreshToken": refreshToken}),
  );

  print("🔄 Refresh Token Request Sent.");
  print("📥 Response Status: \${response.statusCode}");
  print("📥 Response Body: \${response.body}");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['newAccessToken'] != null) {
      await SecureStorage.saveAccessToken(data['newAccessToken']);
      print("✅ Tokens refreshed successfully.");
      return true;
    } else {
      print("❌ Missing tokens in response.");
    }
  } else {
    print("❌ Failed to refresh token. Clearing storage.");
    await SecureStorage.clearToken();
  }

  return false;
}