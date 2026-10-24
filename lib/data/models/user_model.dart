/// Model dasar pengguna (digunakan sebagai sesi login).
class UserModel {
  final String userId;
  final String userType; // 'seller' | 'farmer'

  const UserModel({
    required this.userId,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      userType: json['userType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userType': userType,
    };
  }

  UserModel copyWith({
    String? userId,
    String? userType,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          userType == other.userType;

  @override
  int get hashCode => userId.hashCode ^ userType.hashCode;

  @override
  String toString() => 'UserModel(userId: $userId, userType: $userType)';
}
