package com.hdy.maru.dto;

import com.hdy.maru.entity.FsrsProgress;
import com.hdy.maru.entity.Word;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class WordDueDto {
    private Long id;
    private String koreanWord;
    private String primaryMeaning;
    private String exampleSentence;
    private String exampleTranslation;
    private String partOfSpeech;
    private String audioUrl;
    
    // FSRS 메타데이터
    private int state; // 0: New, 1: Learning, ...
    private int reps;

    public static WordDueDto fromWord(Word word) {
        return WordDueDto.builder()
                .id(word.getId())
                .koreanWord(word.getKoreanWord())
                .primaryMeaning(word.getPrimaryMeaning())
                .exampleSentence(word.getExampleSentence())
                .exampleTranslation(word.getExampleTranslation())
                .partOfSpeech(word.getPartOfSpeech())
                .audioUrl(word.getAudioUrl())
                .state(0) // New
                .reps(0)
                .build();
    }

    public static WordDueDto fromProgress(FsrsProgress progress) {
        Word word = progress.getWord();
        return WordDueDto.builder()
                .id(word.getId())
                .koreanWord(word.getKoreanWord())
                .primaryMeaning(word.getPrimaryMeaning())
                .exampleSentence(word.getExampleSentence())
                .exampleTranslation(word.getExampleTranslation())
                .partOfSpeech(word.getPartOfSpeech())
                .audioUrl(word.getAudioUrl())
                .state(progress.getState())
                .reps(progress.getReps())
                .build();
    }
}
