package com.hdy.maru.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AiLabExploreRequestDto {
    private String inputText;
    // e.g "tense", "politeness", "negation", "subject", "nuance", "question",
    // "emphasis"
    private String category;
}
