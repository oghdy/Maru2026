package com.hdy.maru.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class WordCategoryDto {
    private Long id;
    private String title;
    private String level;
    private int totalWords;
}
