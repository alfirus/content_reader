import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/category.dart';
import '../../../data/datasources/database_helper.dart';

// Events
abstract class CategoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {}

class AddCategory extends CategoryEvent {
  final String name;
  final int color;
  AddCategory(this.name, this.color);
  
  @override
  List<Object?> get props => [name, color];
}

class UpdateCategory extends CategoryEvent {
  final Category category;
  UpdateCategory(this.category);
  
  @override
  List<Object?> get props => [category];
}

class DeleteCategory extends CategoryEvent {
  final int categoryId;
  DeleteCategory(this.categoryId);
  
  @override
  List<Object?> get props => [categoryId];
}

// States
abstract class CategoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  
  CategoryLoaded(this.categories);
  
  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    try {
      final categories = await DatabaseHelper.instance.getAllCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onAddCategory(AddCategory event, Emitter<CategoryState> emit) async {
    try {
      await DatabaseHelper.instance.insertCategory(
        Category(name: event.name, color: event.color),
      );
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onUpdateCategory(UpdateCategory event, Emitter<CategoryState> emit) async {
    try {
      await DatabaseHelper.instance.updateCategory(event.category);
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onDeleteCategory(DeleteCategory event, Emitter<CategoryState> emit) async {
    try {
      await DatabaseHelper.instance.deleteCategory(event.categoryId);
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}
