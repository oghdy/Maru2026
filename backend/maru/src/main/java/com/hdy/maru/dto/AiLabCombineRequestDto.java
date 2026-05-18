package com.hdy.maru.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class AiLabCombineRequestDto {
    private String inputText;
    // e.g ["반말", "과거", "부정문"]
    private List<String> modifiers;
}
