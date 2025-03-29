import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/user_card.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
    searchController.addListener(_filterUsers);
  }

  /// Fetch Users from API
  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("https://reqres.in/api/users?page=1"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = data['data'];
          filteredUsers = users;
        });
      } else {
        throw Exception("Failed to load users");
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $error")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Filter Users based on Search
  void _filterUsers() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        return user['first_name'].toLowerCase().contains(query) ||
               user['last_name'].toLowerCase().contains(query) ||
               user['email'].toLowerCase().contains(query);
      }).toList();
    });
  }

  /// Add New User
  Future<void> addUser() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController jobController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: jobController, decoration: InputDecoration(labelText: "Job")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final response = await http.post(
                  Uri.parse("https://reqres.in/api/users"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({"name": nameController.text, "job": jobController.text}),
                );

                if (response.statusCode == 201) {
                  final newUser = jsonDecode(response.body);
                  setState(() {
                    users.add({
                      "id": int.tryParse(newUser['id']) ?? DateTime.now().millisecondsSinceEpoch,
                      "first_name": nameController.text.split(" ")[0],
                      "last_name": nameController.text.contains(" ") ? nameController.text.split(" ")[1] : "",
                      "email": "${nameController.text.replaceAll(" ", "").toLowerCase()}@example.com",
                      "avatar": "https://i.pravatar.cc/150?u=${newUser['id']}",
                    });
                    filteredUsers = users;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User added successfully!")));
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// Delete User with Confirmation
  void deleteUser(int id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
        ],
      ),
    );

    if (confirmDelete == true) {
      final response = await http.delete(Uri.parse("https://reqres.in/api/users/$id"));
      if (response.statusCode == 204) {
        setState(() {
          users.removeWhere((user) => user['id'] == id);
          filteredUsers = users;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User deleted successfully!")));
      }
    }
  }

  /// Edit User
  void editUser(int id) {
    TextEditingController nameController = TextEditingController();
    TextEditingController jobController = TextEditingController();
    final user = users.firstWhere((user) => user['id'] == id);

    nameController.text = "${user['first_name']} ${user['last_name']}";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: jobController, decoration: InputDecoration(labelText: "Job")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final response = await http.put(
                  Uri.parse("https://reqres.in/api/users/$id"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({"name": nameController.text, "job": jobController.text}),
                );

                if (response.statusCode == 200) {
                  setState(() {
                    final index = users.indexWhere((u) => u['id'] == id);
                    users[index] = {
                      "id": id,
                      "first_name": nameController.text.split(" ")[0],
                      "last_name": nameController.text.contains(" ") ? nameController.text.split(" ")[1] : "",
                      "email": users[index]['email'],
                      "avatar": users[index]['avatar'],
                    };
                    filteredUsers = users;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User updated successfully!")));
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Management")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search users by name or email...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? Center(child: Text("No users found!"))
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return UserCard(
                            name: "${user['first_name']} ${user['last_name']}",
                            email: user['email'],
                            avatarUrl: user['avatar'],
                            onEdit: () => editUser(user['id']),
                            onDelete: () => deleteUser(user['id']),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addUser,
        child: Icon(Icons.add),
      ),
    );
  }
}
