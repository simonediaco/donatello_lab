import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gift.g.dart';

@JsonSerializable()
class Gift extends Equatable {
  final int? id;
  final String name;
  final double price;
  final int? match;
  final String? image;
  final String? category;
  final String? description;
  final String? notes;
  final int? recipient;
  final String? origin;
  @JsonKey(name: 'amazon_link')
  final String? amazonLink;

  const Gift({
    this.id,
    required this.name,
    required this.price,
    this.match,
    this.image,
    this.category,
    this.description,
    this.notes,
    this.recipient,
    this.origin,
    this.amazonLink,
  });

  factory Gift.fromJson(Map<String, dynamic> json) => _$GiftFromJson(json);
  Map<String, dynamic> toJson() => _$GiftToJson(this);

  @override
  List<Object?> get props => [id, name, price, match, image, category, description, notes, recipient, origin, amazonLink];
}