package com.hdy.maru.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class AiLabCombineResponseDto {
    private String text; // e.g "나는 음악을 안 좋아했어"
    private String englishTranslation; // e.g "I didn't like music"
    private String explanation; // e.g "친한 친구나 편한 사이에서, 과거에 좋아하지 않았다는 솔직한 감정을 말할 때"
}
