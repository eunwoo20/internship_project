import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = "https://reqres.in/api";
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      body: jsonEncode({"email": email, "password": password}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: "token", value: data["token"]);
      return data["token"];
    }
    return null;
  }

   Future<bool> register(String email, String password) async {
    final url = Uri.parse("https://reqres.in/api/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data.containsKey('token')) {
        return true;
      } else {
        print("Registration failed: ${data['error']}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    String? token = await storage.read(key: "token");
    return token != null;
  }

  Future<void> logout() async {
    await storage.delete(key: "token");
  }

  
}
