
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'popular_gift.g.dart';

@JsonSerializable()
class PopularGift extends Equatable {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? image;
  final String category;
  @JsonKey(name: 'amazon_link')
  final String? amazonLink;
  @JsonKey(name: 'target_gender')
  final String targetGender;
  final List<String> occasions;
  @JsonKey(name: 'age_range')
  final String? ageRange;

  const PopularGift({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.category,
    this.amazonLink,
    required this.targetGender,
    required this.occasions,
    this.ageRange,
  });

  factory PopularGift.fromJson(Map<String, dynamic> json) => _$PopularGiftFromJson(json);
  Map<String, dynamic> toJson() => _$PopularGiftToJson(this);

  @override
  List<Object?> get props => [
    id, name, description, price, image, category, 
    amazonLink, targetGender, occasions, ageRange
  ];
}
