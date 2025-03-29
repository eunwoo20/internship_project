import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  /// Fetch Users from API
  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse("https://reqres.in/api/users?page=1"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _users = (data['data'] as List).map((user) => User.fromJson(user)).toList();
      } else {
        throw Exception("Failed to load users");
      }
    } catch (error) {
      print("Error fetching users: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add New User
  Future<void> addUser(String name, String job) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("https://reqres.in/api/users"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "job": job}),
      );

      if (response.statusCode == 201) {
        final newUser = jsonDecode(response.body);
        _users.add(User(
          id: int.tryParse(newUser['id']) ?? DateTime.now().millisecondsSinceEpoch,
          firstName: name.split(" ")[0],
          lastName: name.split(" ").length > 1 ? name.split(" ")[1] : "",
          email: "${name.replaceAll(" ", "").toLowerCase()}@example.com",
          avatar: "https://i.pravatar.cc/150?u=${newUser['id']}",
        ));
      } else {
        throw Exception("Failed to add user");
      }
    } catch (error) {
      print("Error adding user: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete User
  Future<void> deleteUser(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.delete(Uri.parse("https://reqres.in/api/users/$id"));
      if (response.statusCode == 204) {
        _users.removeWhere((user) => user.id == id);
      } else {
        throw Exception("Failed to delete user");
      }
    } catch (error) {
      print("Error deleting user: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update User
  Future<void> updateUser(int id, String name, String job) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse("https://reqres.in/api/users/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "job": job}),
      );

      if (response.statusCode == 200) {
        final index = _users.indexWhere((user) => user.id == id);
        if (index != -1) {
          _users[index] = User(
            id: id,
            firstName: name.split(" ")[0],
            lastName: name.split(" ").length > 1 ? name.split(" ")[1] : "",
            email: _users[index].email, 
            avatar: _users[index].avatar, 
          );
        }
      } else {
        throw Exception("Failed to update user");
      }
    } catch (error) {
      print("Error updating user: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
