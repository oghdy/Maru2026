package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VocabularyGameTileDto {
    private String id;       // 타일 고유 ID (예: "T1_KR", "T1_EN")
    private Long pairId;     // 매칭되는 단어 쌍의 공유 ID (Word ID 활용)
    private String text;     // 화면에 표시될 텍스트 (한국어 또는 영어)
    private String type;     // "KOREAN" 또는 "ENGLISH"
    private int totalWords;  // 이 게임의 단어(짝) 수 = 타일 수 / 2. 라운드 수·진행바 계산용 (모든 타일에 같은 값)
}
