package com.hdy.maru.dto;

import com.hdy.maru.entity.FsrsProgress;
import com.hdy.maru.entity.Word;
import lombok.Builder;
import lombok.Getter;

import java.util.Map;

@Getter
@Builder(toBuilder = true)
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

    // 평가 버튼별 다음 복습까지 간격 라벨 (예: {"AGAIN":"5m","HARD":"1d","GOOD":"4d","EASY":"14d"}).
    // Word Study 에서 가드로 평가가 반영되지 않는 단어(이미 학습 + 복습일 전)는 null.
    private Map<String, String> nextIntervals;

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
