import 'mission.dart'; // Import Mission model

class UserMission {
  final int id;
  final int userId;
  final int missionId;
  String? proof; // Nullable string for URL
  bool isCompleted; // Tetap bool
  final Mission? mission; // Optional: to hold the related Mission object

  UserMission({
    required this.id,
    required this.userId,
    required this.missionId,
    this.proof,
    required this.isCompleted,
    this.mission,
  });

  factory UserMission.fromJson(Map<String, dynamic> json) {
    return UserMission(
      id: json['id'],
      userId: json['user_id'],
      missionId: json['mission_id'],
      proof: json['proof'],
      // REVISI: Konversi is_completed secara eksplisit ke boolean
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
      // If 'mission' is nested, parse it
      mission: json['mission'] != null ? Mission.fromJson(json['mission']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mission_id': missionId,
      'proof': proof,
      'is_completed': isCompleted,
      'mission': mission?.toJson(), // Include mission data if available
    };
  }
}

