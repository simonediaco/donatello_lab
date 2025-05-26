import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final int? id;
  final String email;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  @JsonKey(name: 'birth_date')
  final String? birthDate;
  final UserProfile? profile;

  const User({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<Object?> get props => [id, email, firstName, lastName, birthDate, profile];
}

@JsonSerializable()
class UserProfile extends Equatable {
  final String? bio;
  final String? avatar;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  const UserProfile({
    this.bio,
    this.avatar,
    this.phoneNumber,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  @override
  List<Object?> get props => [bio, avatar, phoneNumber];
}