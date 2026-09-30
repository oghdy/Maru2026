import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vocabulary_provider.dart';
import '../repository/vocabulary_errors.dart';
import '../widgets/vocabulary_error_view.dart';
import 'vocabulary_lesson_list_screen.dart';

class VocabularyCategoryScreen extends ConsumerWidget {
  const VocabularyCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Vocabulary Decks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ref.watch(vocabularyCategoriesProvider('Beginner')).when(
            data: (categories) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      title: Text(
                        category.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        // 서버 level 은 14개 덱 모두 'Beginner' 고정(B·C 등급 단어 포함, 실사 §4-C)이라 표시하지 않음
                        '${category.koreanTitle} · ${category.totalWords} words',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VocabularyLessonListScreen(category: category),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
            error: (err, stack) => VocabularyErrorView(
              message: friendlyVocabularyError(err),
              onRetry: () => ref.invalidate(vocabularyCategoriesProvider('Beginner')),
            ),
          ),
    );
  }
}
