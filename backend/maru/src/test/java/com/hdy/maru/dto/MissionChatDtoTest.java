package com.hdy.maru.dto;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class MissionChatDtoTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void testMissionSetupRequestDtoSerialization() throws Exception {
        MissionSetupRequestDto dto = MissionSetupRequestDto.builder()
                .hierarchy("윗사람")
                .intimacy("초면")
                .personality("엄격한")
                .role("직장 상사")
                .build();

        String json = objectMapper.writeValueAsString(dto);
        MissionSetupRequestDto deserialized = objectMapper.readValue(json, MissionSetupRequestDto.class);

        assertThat(deserialized.getHierarchy()).isEqualTo("윗사람");
        assertThat(deserialized.getRole()).isEqualTo("직장 상사");
        assertThat(deserialized.getPersonality()).isEqualTo("엄격한");
    }

    @Test
    void testChatTurnResponseDtoSerialization() throws Exception {
        ChatTurnResponseDto.CorrectionDto correction = ChatTurnResponseDto.CorrectionDto.builder()
                .severity("immediate")
                .issueType("honorific_mismatch")
                .userInputProblematic("안녕")
                .correctExpression("안녕하세요")
                .turtleFeedback("직장 상사에게는 존댓말을 써야 해요.")
                .turtleFeedbackEn("You should use honorifics to your boss.")
                .build();

        ChatTurnResponseDto dto = ChatTurnResponseDto.builder()
                .rabbitReply(null)
                .rabbitReplyEn(null)
                .correction(correction)
                .missionStatus("in_progress")
                .build();

        String json = objectMapper.writeValueAsString(dto);
        ChatTurnResponseDto deserialized = objectMapper.readValue(json, ChatTurnResponseDto.class);

        assertThat(deserialized.getMissionStatus()).isEqualTo("in_progress");
        assertThat(deserialized.getCorrection().getSeverity()).isEqualTo("immediate");
    }
}
