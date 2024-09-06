import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String profilePictureUrl;
  final List<String> subscriptions; // New field for subscribed user IDs

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePictureUrl,
    required this.subscriptions, // Initialize the new field
  });

  // Factory constructor to create a UserModel instance from a map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(

            id: map['\$id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      subscriptions: List<String>.from(map['subscriptions'] ?? []), // Convert to a list of strings
    );
  }

  // Method to convert UserModel instance to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'subscriptions': subscriptions, // Include the new field
    };
  }

  // Method to convert UserModel instance to a JSON string
  String toJson() => json.encode(toMap());

  // Factory constructor to create a UserModel instance from JSON
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}
