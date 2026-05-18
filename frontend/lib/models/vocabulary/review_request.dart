enum ReviewRating {
  again(1),
  hard(2),
  good(3),
  easy(4);

  final int value;
  const ReviewRating(this.value);
}

class ReviewRequest {
  final int wordId;
  final int rating; // 1: Again, 2: Hard, 3: Good, 4: Easy

  ReviewRequest({
    required this.wordId,
    required this.rating,
  });

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'rating': rating,
    };
  }
}
