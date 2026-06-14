import 'package:equatable/equatable.dart';
import '../../../data/models/character_model.dart';

/// 识字页状态（Tab1）
class WordLearningState extends Equatable {
  final int selectedLevel;
  final List<CharacterModel> characters;
  final bool isLoading;
  final bool isOffline;
  final String? errorMessage;
  final String? currentChildId;
  final int reviewCount;

  const WordLearningState({
    this.selectedLevel = 1,
    this.characters = const [],
    this.isLoading = false,
    this.isOffline = false,
    this.errorMessage,
    this.currentChildId,
    this.reviewCount = 0,
  });

  /// 级别标签
  String get levelLabel => 'L$selectedLevel';

  /// 字卡计数
  int get characterCount => characters.length;

  /// 是否有待复习字
  bool get hasReview => reviewCount > 0;

  WordLearningState copyWith({
    int? selectedLevel,
    List<CharacterModel>? characters,
    bool? isLoading,
    bool? isOffline,
    String? errorMessage,
    String? currentChildId,
    int? reviewCount,
  }) {
    return WordLearningState(
      selectedLevel: selectedLevel ?? this.selectedLevel,
      characters: characters ?? this.characters,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
      currentChildId: currentChildId ?? this.currentChildId,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  @override
  List<Object?> get props => [
        selectedLevel,
        characters,
        isLoading,
        isOffline,
        errorMessage,
        currentChildId,
        reviewCount,
      ];
}
