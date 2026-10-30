import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/models.dart';
part 'post_api.g.dart';

@RestApi()
abstract class PostApi {
  factory PostApi(Dio dio, {String? baseUrl}) = _PostApi;
  @GET('/posts')
  Future<List<Post>> posts(
    @Query('_page') int page,
    @Query('_limit') int limit,
    @CancelRequest() CancelToken cancel,
  );
  @GET('/posts/{id}')
  Future<Post> post(@Path('id') int id);
  @GET('/posts')
  Future<List<Post>> authorPosts(
    @Query('userId') int userId,
    @Query('_page') int page,
    @Query('_limit') int limit,
    @CancelRequest() CancelToken cancel,
  );
  @GET('/posts/{id}/comments')
  Future<List<Comment>> comments(@Path('id') int id);
  @POST('/posts')
  Future<Post> create(@Body() Map<String, dynamic> body);
  @GET('/users')
  Future<List<User>> users();
  @GET('/users/{id}')
  Future<User> user(@Path('id') int id);
}
