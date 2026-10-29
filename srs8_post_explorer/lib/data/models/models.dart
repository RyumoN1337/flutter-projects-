import 'package:json_annotation/json_annotation.dart';
part 'models.g.dart';

@JsonSerializable(checked: true)
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;
  final bool local;
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.local = false,
  });
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}

@JsonSerializable(checked: true)
class Comment {
  final int id;
  final int postId;
  final String name;
  final String? email;
  final String body;
  const Comment({
    required this.id,
    required this.postId,
    required this.name,
    this.email,
    required this.body,
  });
  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}

@JsonSerializable(checked: true, explicitToJson: true)
class User {
  final int id;
  final String name;
  final String? email;
  final Address? address;
  const User({required this.id, required this.name, this.email, this.address});
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(checked: true)
class Address {
  final String? street;
  final String? city;
  const Address({this.street, this.city});
  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
}
