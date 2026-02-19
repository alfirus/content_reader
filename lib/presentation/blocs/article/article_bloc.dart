import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/article.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class ArticleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadArticles extends ArticleEvent {}

class LoadArticlesByFeed extends ArticleEvent {
  final int feedId;
  LoadArticlesByFeed(this.feedId);
  
  @override
  List<Object?> get props => [feedId];
}

class LoadSavedArticles extends ArticleEvent {}

class LoadUnreadArticles extends ArticleEvent {}

class MarkArticleAsRead extends ArticleEvent {
  final Article article;
  MarkArticleAsRead(this.article);
  
  @override
  List<Object?> get props => [article];
}

class ToggleArticleSaved extends ArticleEvent {
  final Article article;
  ToggleArticleSaved(this.article);
  
  @override
  List<Object?> get props => [article];
}

class DeleteArticle extends ArticleEvent {
  final int articleId;
  DeleteArticle(this.articleId);
  
  @override
  List<Object?> get props => [articleId];
}

class FilterArticles extends ArticleEvent {
  final ArticleFilter filter;
  FilterArticles(this.filter);
  
  @override
  List<Object?> get props => [filter];
}

enum ArticleFilter { all, unread, saved }

// States
abstract class ArticleState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ArticleInitial extends ArticleState {}

class ArticleLoading extends ArticleState {}

class ArticleLoaded extends ArticleState {
  final List<Article> articles;
  final ArticleFilter filter;
  
  ArticleLoaded(this.articles, {this.filter = ArticleFilter.all});
  
  @override
  List<Object?> get props => [articles, filter];
}

class ArticleError extends ArticleState {
  final String message;
  ArticleError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  ArticleFilter _currentFilter = ArticleFilter.all;

  ArticleBloc() : super(ArticleInitial()) {
    on<LoadArticles>(_onLoadArticles);
    on<LoadArticlesByFeed>(_onLoadArticlesByFeed);
    on<LoadSavedArticles>(_onLoadSavedArticles);
    on<LoadUnreadArticles>(_onLoadUnreadArticles);
    on<MarkArticleAsRead>(_onMarkArticleAsRead);
    on<ToggleArticleSaved>(_onToggleArticleSaved);
    on<DeleteArticle>(_onDeleteArticle);
    on<FilterArticles>(_onFilterArticles);
  }

  Future<void> _onLoadArticles(LoadArticles event, Emitter<ArticleState> emit) async {
    emit(ArticleLoading());
    try {
      final articles = await DatabaseHelper.instance.getAllArticles();
      emit(ArticleLoaded(articles, filter: _currentFilter));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onLoadArticlesByFeed(LoadArticlesByFeed event, Emitter<ArticleState> emit) async {
    emit(ArticleLoading());
    try {
      final articles = await DatabaseHelper.instance.getArticlesByFeed(event.feedId);
      emit(ArticleLoaded(articles, filter: _currentFilter));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onLoadSavedArticles(LoadSavedArticles event, Emitter<ArticleState> emit) async {
    emit(ArticleLoading());
    try {
      final articles = await DatabaseHelper.instance.getSavedArticles();
      _currentFilter = ArticleFilter.saved;
      emit(ArticleLoaded(articles, filter: ArticleFilter.saved));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onLoadUnreadArticles(LoadUnreadArticles event, Emitter<ArticleState> emit) async {
    emit(ArticleLoading());
    try {
      final articles = await DatabaseHelper.instance.getUnreadArticles();
      _currentFilter = ArticleFilter.unread;
      emit(ArticleLoaded(articles, filter: ArticleFilter.unread));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onMarkArticleAsRead(MarkArticleAsRead event, Emitter<ArticleState> emit) async {
    try {
      final updatedArticle = event.article.copyWith(isRead: true);
      await DatabaseHelper.instance.updateArticle(updatedArticle);
      _reloadCurrentFilter();
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onToggleArticleSaved(ToggleArticleSaved event, Emitter<ArticleState> emit) async {
    try {
      final updatedArticle = event.article.copyWith(isSaved: !event.article.isSaved);
      await DatabaseHelper.instance.updateArticle(updatedArticle);
      _reloadCurrentFilter();
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onDeleteArticle(DeleteArticle event, Emitter<ArticleState> emit) async {
    try {
      await DatabaseHelper.instance.deleteArticle(event.articleId);
      _reloadCurrentFilter();
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  void _onFilterArticles(FilterArticles event, Emitter<ArticleState> emit) {
    _currentFilter = event.filter;
    switch (event.filter) {
      case ArticleFilter.all:
        add(LoadArticles());
        break;
      case ArticleFilter.unread:
        add(LoadUnreadArticles());
        break;
      case ArticleFilter.saved:
        add(LoadSavedArticles());
        break;
    }
  }

  void _reloadCurrentFilter() {
    switch (_currentFilter) {
      case ArticleFilter.all:
        add(LoadArticles());
        break;
      case ArticleFilter.unread:
        add(LoadUnreadArticles());
        break;
      case ArticleFilter.saved:
        add(LoadSavedArticles());
        break;
    }
  }
}
