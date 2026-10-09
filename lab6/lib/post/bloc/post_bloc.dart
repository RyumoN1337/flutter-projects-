import 'package:equatable/equatable.dart';
import 'package:flutter_application_1/models/get_posts.dart';
import 'package:flutter_application_1/post/repository/post_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final _repository = PostRepository();

  PostBloc() : super(PostInitial()) {
    on<GetPostEvent>(_repository.getPosts);
  }
}
