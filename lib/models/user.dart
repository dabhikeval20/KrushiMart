enum UserRole { seller, buyer }

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.role,
  });

  // Create a copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? location,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      role: role ?? this.role,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'role': role.name, // Store as string
    };
  }

  // Create from Firestore document
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.buyer,
      ),
    );
  }
}

// Global user variable to store current logged-in user
User? currentUser;
