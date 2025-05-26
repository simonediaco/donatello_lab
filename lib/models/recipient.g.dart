// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recipient _$RecipientFromJson(Map<String, dynamic> json) => Recipient(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      gender: json['gender'] as String,
      birthDate: json['birth_date'] as String?,
      relation: json['relation'] as String,
      interests:
          (json['interests'] as List<dynamic>).map((e) => e as String).toList(),
      favoriteColors: (json['favorite_colors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      dislikes: (json['dislikes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$RecipientToJson(Recipient instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'gender': instance.gender,
      'birth_date': instance.birthDate,
      'relation': instance.relation,
      'interests': instance.interests,
      'favorite_colors': instance.favoriteColors,
      'dislikes': instance.dislikes,
      'notes': instance.notes,
    };
