// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gift _$GiftFromJson(Map<String, dynamic> json) => Gift(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      match: (json['match'] as num?)?.toInt(),
      image: json['image'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      recipient: (json['recipient'] as num?)?.toInt(),
      origin: json['origin'] as String?,
      amazonLink: json['amazon_link'] as String?,
    );

Map<String, dynamic> _$GiftToJson(Gift instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'match': instance.match,
      'image': instance.image,
      'category': instance.category,
      'description': instance.description,
      'notes': instance.notes,
      'recipient': instance.recipient,
      'origin': instance.origin,
      'amazon_link': instance.amazonLink,
    };
