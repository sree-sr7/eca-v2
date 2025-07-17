class Caregiver {
  final String id;
  final String name;
  final String phone;
  final String category;
  final String imageUrl;
  final String email;
  final String address;
  final String? specialization;
  final String? experience;
  final String? relation;

  Caregiver({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
    required this.imageUrl,
    required this.email,
    required this.address,
    this.specialization,
    this.experience,
    this.relation,
  });

  // Convert caregiver to a map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'category': category,
      'imageUrl': imageUrl,
      'email': email,
      'address': address,
      'specialization': specialization,
      'experience': experience,
      'relation': relation,
    };
  }

  // Create a Caregiver object from a database map
  factory Caregiver.fromMap(Map<String, dynamic> map) {
    return Caregiver(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? 'assets/images/default_caregiver.jpg',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      specialization: map['specialization'],
      experience: map['experience']?.toString(),
      relation: map['relation'],
    );
  }
}