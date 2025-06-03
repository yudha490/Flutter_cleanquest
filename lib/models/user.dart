import 'user_mission.dart'; // Import UserMission model

class User {
  final int id;
  final String username;
  final String email;
  final int points;
  final String phoneNumber;
  final DateTime birthDate;
  final List<UserMission> missions; // Add missions list

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.points,
    required this.phoneNumber,
    required this.birthDate,
    this.missions = const [], // Initialize with empty list
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Parse user_missions if available
    List<UserMission> userMissions = [];
    if (json['user_missions'] != null) {
      userMissions = (json['user_missions'] as List)
          .map((e) => UserMission.fromJson(e))
          .toList();
    }

    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      points: json['points'],
      phoneNumber: json['phone_number'],
      birthDate: DateTime.parse(json['birth_date']),
      missions: userMissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'points': points,
      'phone_number': phoneNumber,
      'birth_date': birthDate.toIso8601String().split('T')[0], // Format to 'YYYY-MM-DD'
      'user_missions': missions.map((m) => m.toJson()).toList(),
    };
  }
}

