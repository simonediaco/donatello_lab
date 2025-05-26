// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num?)?.toInt(),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      birthDate: json['birth_date'] as String?,
      profile: json['profile'] == null
          ? null
          : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'birth_date': instance.birthDate,
      'profile': instance.profile,
    };

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      bio: json['bio'] as String?,
      avatar: json['avatar'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'bio': instance.bio,
      'avatar': instance.avatar,
      'phone_number': instance.phoneNumber,
    };
