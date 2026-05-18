package com.hdy.maru.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MissionSetupRequestDto {
    private String hierarchy;   // 윗사람 / 동년배·친구 / 아랫사람
    private String intimacy;    // 초면 / 아는 사이 / 친한 사이

    private String role;        // 카페 직원 / 교수 / 상사 등 자유 입력
    private String personality; // 엄격한 / 친근한 / 수줍은 등 자유 입력
}
