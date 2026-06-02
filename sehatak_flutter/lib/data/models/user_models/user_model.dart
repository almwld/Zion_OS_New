import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatar;
  final String? nationalId;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final String? address;
  final String? city;
  final String? country;
  final String userType;
  final bool isActive;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatar,
    this.nationalId,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.address,
    this.city,
    this.country,
    this.userType = 'patient',
    this.isActive = true,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      nationalId: json['national_id'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      bloodType: json['blood_type'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      userType: json['user_type'] ?? 'patient',
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'national_id': nationalId,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'blood_type': bloodType,
      'address': address,
      'city': city,
      'country': country,
      'user_type': userType,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatar,
    String? nationalId,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    String? address,
    String? city,
    String? country,
    String? userType,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      nationalId: nationalId ?? this.nationalId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      userType: userType ?? this.userType,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        avatar,
        nationalId,
        dateOfBirth,
        gender,
        bloodType,
        address,
        city,
        country,
        userType,
        isActive,
        isVerified,
        createdAt,
        updatedAt,
      ];
}

class AuthResponse extends Equatable {
  final String token;
  final String refreshToken;
  final UserModel user;

  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }

  @override
  List<Object?> get props => [token, refreshToken, user];
}
