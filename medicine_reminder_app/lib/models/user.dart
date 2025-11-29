class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final int? age;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.age,
  });

  // Factory constructor to create a User from JSON (backend response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // We handle both 'id' and '_id' because MongoDB uses '_id'
      id: json['id'] ?? json['_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      age: json['age'],
    );
  }

  // Convert User object back to JSON (for sending to backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'age': age,
    };
  }
}