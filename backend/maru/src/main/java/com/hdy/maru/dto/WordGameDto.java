package com.hdy.maru.dto;

import com.hdy.maru.entity.Word;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class WordGameDto {
    private Long id;
    private String korean;
    private String meaning;
    private String partOfSpeech;

    public static WordGameDto fromEntity(Word word) {
        return WordGameDto.builder()
                .id(word.getId())
                .korean(word.getKoreanWord())
                .meaning(word.getPrimaryMeaning())
                .partOfSpeech(word.getPartOfSpeech())
                .build();
    }
}
