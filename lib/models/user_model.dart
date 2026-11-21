class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role;

  final String? teamId;
  final String? phoneNumber;
  final String? organization;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.teamId,
    this.phoneNumber,
    this.organization,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'teamId': teamId,
      'phoneNumber': phoneNumber,
      'organization': organization,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'visitor',
      teamId: map['teamId'],
      phoneNumber: map['phoneNumber'],
      organization: map['organization'],
    );
  }
}