import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = "https://reqres.in/api";

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(Uri.parse("$baseUrl/users"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"];
    }
    return [];
  }

  Future<bool> createUser(String name, String job) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users"),
      body: jsonEncode({"name": name, "job": job}),
      headers: {"Content-Type": "application/json"},
    );
    return response.statusCode == 201;
  }

  Future<bool> updateUser(int id, String name, String job) async {
    final response = await http.put(
      Uri.parse("$baseUrl/users/$id"),
      body: jsonEncode({"name": name, "job": job}),
      headers: {"Content-Type": "application/json"},
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteUser(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/users/$id"));
    return response.statusCode == 204;
  }
}
