// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GiftRequest _$GiftRequestFromJson(Map<String, dynamic> json) => GiftRequest(
      name: json['name'] as String?,
      age: json['age'] as String?,
      gender: json['gender'] as String?,
      relation: json['relation'] as String?,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      category: json['category'] as String?,
      minPrice: json['min_price'] as String?,
      maxPrice: json['max_price'] as String?,
    );

Map<String, dynamic> _$GiftRequestToJson(GiftRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'age': instance.age,
      'gender': instance.gender,
      'relation': instance.relation,
      'interests': instance.interests,
      'category': instance.category,
      'min_price': instance.minPrice,
      'max_price': instance.maxPrice,
    };
