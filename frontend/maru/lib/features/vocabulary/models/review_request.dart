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
  final int rating;
  final String reviewMode;

  ReviewRequest({
    required this.wordId,
    required this.rating,
    required this.reviewMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'rating': rating,
      'reviewMode': reviewMode,
    };
  }
}
