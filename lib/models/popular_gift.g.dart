// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'popular_gift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PopularGift _$PopularGiftFromJson(Map<String, dynamic> json) => PopularGift(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String?,
      category: json['category'] as String,
      amazonLink: json['amazon_link'] as String?,
      targetGender: json['target_gender'] as String,
      occasions:
          (json['occasions'] as List<dynamic>).map((e) => e as String).toList(),
      ageRange: json['age_range'] as String?,
    );

Map<String, dynamic> _$PopularGiftToJson(PopularGift instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'image': instance.image,
      'category': instance.category,
      'amazon_link': instance.amazonLink,
      'target_gender': instance.targetGender,
      'occasions': instance.occasions,
      'age_range': instance.ageRange,
    };
