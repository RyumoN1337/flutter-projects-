import 'package:json_annotation/json_annotation.dart';

part 'get_posts.g.dart';

@JsonSerializable()
class Posts {
  final int id;
  final String title;
  final String body;

  Posts({
    required this.id,
    required this.title,
    required this.body,
  });

  factory Posts.fromJson(Map<String, dynamic> json) => _$PostsFromJson(json);
  Map<String, dynamic> toJson() => _$PostsToJson(this);
}
