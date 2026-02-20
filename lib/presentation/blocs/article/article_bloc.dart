import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/article.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class ArticleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadArticles extends ArticleEvent {
  final int page;
  final int pageSize;
  final String? searchQuery;
  
  LoadArticles({this.page = 0, this.pageSize = 50, this.searchQuery});
  
  @override
  List<Object?> get props => [page, pageSize, searchQuery];
}

class LoadMoreArticles extends ArticleEvent {
  final int page;
  final int pageSize;
  
  LoadMoreArticles({this.page = 1, this.pageSize = 50});
  
  @override
  List<Object?> get props => [page, pageSize];
}

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

class UpdateArticle extends ArticleEvent {
  final Article article;
  UpdateArticle(this.article);
  
  @override
  List<Object?> get props => [article];
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
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final String? searchQuery;
  
  ArticleLoaded(
    this.articles, {
    this.filter = ArticleFilter.all,
    this.currentPage = 0,
    this.pageSize = 50,
    this.totalCount = 0,
    this.hasMore = false,
    this.searchQuery,
  });
  
  @override
  List<Object?> get props => [articles, filter, currentPage, pageSize, totalCount, hasMore, searchQuery];
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
    on<LoadMoreArticles>(_onLoadMoreArticles);
    on<LoadArticlesByFeed>(_onLoadArticlesByFeed);
    on<LoadSavedArticles>(_onLoadSavedArticles);
    on<LoadUnreadArticles>(_onLoadUnreadArticles);
    on<MarkArticleAsRead>(_onMarkArticleAsRead);
    on<ToggleArticleSaved>(_onToggleArticleSaved);
    on<DeleteArticle>(_onDeleteArticle);
    on<UpdateArticle>(_onUpdateArticle);
    on<FilterArticles>(_onFilterArticles);
  }

  Future<void> _onLoadArticles(LoadArticles event, Emitter<ArticleState> emit) async {
    emit(ArticleLoading());
    try {
      final articles = await DatabaseHelper.instance.getAllArticles(
        limit: event.pageSize,
        offset: event.page * event.pageSize,
        searchQuery: event.searchQuery,
      );
      final totalCount = await DatabaseHelper.instance.getArticleCount(searchQuery: event.searchQuery);
      final hasMore = (event.page + 1) * event.pageSize < totalCount;
      
      emit(ArticleLoaded(
        articles,
        filter: _currentFilter,
        currentPage: event.page,
        pageSize: event.pageSize,
        totalCount: totalCount,
        hasMore: hasMore,
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onLoadMoreArticles(LoadMoreArticles event, Emitter<ArticleState> emit) async {
    try {
      final currentState = state;
      if (currentState is ArticleLoaded) {
        final articles = await DatabaseHelper.instance.getAllArticles(
          limit: event.pageSize,
          offset: event.page * event.pageSize,
          searchQuery: currentState.searchQuery,
        );
        final totalCount = await DatabaseHelper.instance.getArticleCount(searchQuery: currentState.searchQuery);
        final hasMore = (event.page + 1) * event.pageSize < totalCount;
        
        emit(ArticleLoaded(
          [...currentState.articles, ...articles],
          filter: _currentFilter,
          currentPage: event.page,
          pageSize: event.pageSize,
          totalCount: totalCount,
          hasMore: hasMore,
          searchQuery: currentState.searchQuery,
        ));
      }
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

  Future<void> _onUpdateArticle(UpdateArticle event, Emitter<ArticleState> emit) async {
    try {
      await DatabaseHelper.instance.updateArticle(event.article);
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
