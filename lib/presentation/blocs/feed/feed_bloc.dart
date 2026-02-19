import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/feed.dart';
import '../../../data/datasources/database_helper.dart';
import '../../../data/datasources/rss_service.dart';

// Events
abstract class FeedEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFeeds extends FeedEvent {}

class LoadFeedsByCategory extends FeedEvent {
  final int? categoryId;
  LoadFeedsByCategory(this.categoryId);
  
  @override
  List<Object?> get props => [categoryId];
}

class AddFeed extends FeedEvent {
  final String url;
  final int? categoryId;
  AddFeed(this.url, {this.categoryId});
  
  @override
  List<Object?> get props => [url, categoryId];
}

class UpdateFeed extends FeedEvent {
  final Feed feed;
  UpdateFeed(this.feed);
  
  @override
  List<Object?> get props => [feed];
}

class DeleteFeed extends FeedEvent {
  final int feedId;
  DeleteFeed(this.feedId);
  
  @override
  List<Object?> get props => [feedId];
}

class RefreshFeeds extends FeedEvent {}

// States
abstract class FeedState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final List<Feed> feeds;
  final Map<int, int> unreadCounts;
  final int? currentCategoryId;
  
  FeedLoaded(this.feeds, {this.unreadCounts = const {}, this.currentCategoryId});
  
  @override
  List<Object?> get props => [feeds, unreadCounts, currentCategoryId];
}

class FeedError extends FeedState {
  final String message;
  FeedError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final RssService _rssService = RssService();
  int? _currentCategoryId;

  FeedBloc() : super(FeedInitial()) {
    on<LoadFeeds>(_onLoadFeeds);
    on<LoadFeedsByCategory>(_onLoadFeedsByCategory);
    on<AddFeed>(_onAddFeed);
    on<UpdateFeed>(_onUpdateFeed);
    on<DeleteFeed>(_onDeleteFeed);
    on<RefreshFeeds>(_onRefreshFeeds);
  }

  Future<void> _onLoadFeeds(LoadFeeds event, Emitter<FeedState> emit) async {
    _currentCategoryId = null;
    emit(FeedLoading());
    try {
      final feeds = await DatabaseHelper.instance.getAllFeeds();
      Map<int, int> unreadCounts = {};
      for (var feed in feeds) {
        if (feed.id != null) {
          unreadCounts[feed.id!] = await DatabaseHelper.instance.getUnreadCount(feed.id!);
        }
      }
      emit(FeedLoaded(feeds, unreadCounts: unreadCounts));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onLoadFeedsByCategory(LoadFeedsByCategory event, Emitter<FeedState> emit) async {
    _currentCategoryId = event.categoryId;
    emit(FeedLoading());
    try {
      final feeds = await DatabaseHelper.instance.getFeedsByCategory(event.categoryId);
      Map<int, int> unreadCounts = {};
      for (var feed in feeds) {
        if (feed.id != null) {
          unreadCounts[feed.id!] = await DatabaseHelper.instance.getUnreadCount(feed.id!);
        }
      }
      emit(FeedLoaded(feeds, unreadCounts: unreadCounts, currentCategoryId: event.categoryId));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onAddFeed(AddFeed event, Emitter<FeedState> emit) async {
    try {
      final feed = await _rssService.fetchFeed(event.url);
      if (feed != null) {
        final feedWithCategory = feed.copyWith(categoryId: event.categoryId);
        final id = await DatabaseHelper.instance.insertFeed(feedWithCategory);
        
        // Fetch articles for the new feed
        final articles = await _rssService.fetchArticles(event.url, id);
        for (var article in articles) {
          await DatabaseHelper.instance.insertArticle(article);
        }
        
        if (_currentCategoryId != null) {
          add(LoadFeedsByCategory(_currentCategoryId));
        } else {
          add(LoadFeeds());
        }
      } else {
        emit(FeedError('Invalid RSS feed URL'));
        add(LoadFeeds());
      }
    } catch (e) {
      emit(FeedError(e.toString()));
      add(LoadFeeds());
    }
  }

  Future<void> _onUpdateFeed(UpdateFeed event, Emitter<FeedState> emit) async {
    try {
      await DatabaseHelper.instance.updateFeed(event.feed);
      if (_currentCategoryId != null) {
        add(LoadFeedsByCategory(_currentCategoryId));
      } else {
        add(LoadFeeds());
      }
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onDeleteFeed(DeleteFeed event, Emitter<FeedState> emit) async {
    try {
      await DatabaseHelper.instance.deleteFeed(event.feedId);
      if (_currentCategoryId != null) {
        add(LoadFeedsByCategory(_currentCategoryId));
      } else {
        add(LoadFeeds());
      }
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onRefreshFeeds(RefreshFeeds event, Emitter<FeedState> emit) async {
    if (state is FeedLoaded) {
      final currentState = state as FeedLoaded;
      try {
        for (var feed in currentState.feeds) {
          if (feed.id != null && feed.url.isNotEmpty) {
            final articles = await _rssService.fetchArticles(feed.url, feed.id!);
            for (var article in articles) {
              await DatabaseHelper.instance.insertArticle(article);
            }
          }
        }
        if (_currentCategoryId != null) {
          add(LoadFeedsByCategory(_currentCategoryId));
        } else {
          add(LoadFeeds());
        }
      } catch (e) {
        emit(FeedError(e.toString()));
      }
    }
  }
}
