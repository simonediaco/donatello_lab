import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipient.g.dart';

@JsonSerializable()
class Recipient extends Equatable {
  final int? id;
  final String name;
  final String gender;
  @JsonKey(name: 'birth_date')
  final String? birthDate;
  final String relation;
  final List<String> interests;
  @JsonKey(name: 'favorite_colors')
  final List<String>? favoriteColors;
  final List<String>? dislikes;
  final String? notes;

  const Recipient({
    this.id,
    required this.name,
    required this.gender,
    this.birthDate,
    required this.relation,
    required this.interests,
    this.favoriteColors,
    this.dislikes,
    this.notes,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) => _$RecipientFromJson(json);
  Map<String, dynamic> toJson() => _$RecipientToJson(this);

  int? get age {
    if (birthDate == null) return null;
    final birth = DateTime.parse(birthDate!);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  @override
  List<Object?> get props => [id, name, gender, birthDate, relation, interests, favoriteColors, dislikes, notes];
}