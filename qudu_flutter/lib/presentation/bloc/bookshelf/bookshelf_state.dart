import 'package:equatable/equatable.dart';
import '../../../data/models/book_model.dart';

/// 书架状态
class BookshelfState extends Equatable {
  final List<BookModel> books;
  final List<BookModel> recommendedBooks;
  final bool isLoading;
  final bool isOffline;
  final String selectedLevel;
  final String? errorMessage;

  const BookshelfState({
    this.books = const [],
    this.recommendedBooks = const [],
    this.isLoading = false,
    this.isOffline = false,
    this.selectedLevel = 'L1',
    this.errorMessage,
  });

  /// 推荐文案
  String get recommendedText {
    if (recommendedBooks.isEmpty) return '选择级别，开始阅读';
    return '为你推荐 ${recommendedBooks.map((b) => '《${b.title}》').join('、')}';
  }

  BookshelfState copyWith({
    List<BookModel>? books,
    List<BookModel>? recommendedBooks,
    bool? isLoading,
    bool? isOffline,
    String? selectedLevel,
    String? errorMessage,
  }) {
    return BookshelfState(
      books: books ?? this.books,
      recommendedBooks: recommendedBooks ?? this.recommendedBooks,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      errorMessage: errorMessage, // 注意：null 会清空 error，与 HomeBloc 一致
    );
  }

  @override
  List<Object?> get props => [books, recommendedBooks, isLoading, isOffline, selectedLevel, errorMessage];
}
