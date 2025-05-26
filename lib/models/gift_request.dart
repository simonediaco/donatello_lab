import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gift_request.g.dart';

@JsonSerializable()
class GiftRequest extends Equatable {
  final String? name;
  final String? age;
  final String? gender;
  final String? relation;
  final List<String>? interests;
  final String? category;
  @JsonKey(name: 'min_price')
  final String? minPrice;
  @JsonKey(name: 'max_price')
  final String? maxPrice;

  const GiftRequest({
    this.name,
    this.age,
    this.gender,
    this.relation,
    this.interests,
    this.category,
    this.minPrice,
    this.maxPrice,
  });

  factory GiftRequest.fromJson(Map<String, dynamic> json) => _$GiftRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GiftRequestToJson(this);

  @override
  List<Object?> get props => [name, age, gender, relation, interests, category, minPrice, maxPrice];
}