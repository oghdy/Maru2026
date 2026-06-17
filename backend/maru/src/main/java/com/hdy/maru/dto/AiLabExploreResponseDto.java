package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiLabExploreResponseDto {
    private String text; // e.g "저는 음악을 좋아했어요"
    private String type; // e.g "과거"
    private String explanation; // e.g "예전에 좋아했던 상태를 나타냅니다."
}
