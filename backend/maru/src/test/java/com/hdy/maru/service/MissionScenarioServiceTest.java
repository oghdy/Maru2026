package com.hdy.maru.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.hdy.maru.demo.DemoAiGate;
import com.hdy.maru.demo.DemoLimitException;
import com.hdy.maru.demo.DemoProperties;
import com.hdy.maru.dto.MissionScenarioDto;
import com.hdy.maru.dto.MissionSetupResponseDto;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class MissionScenarioServiceTest {

    private final MissionScenarioService service = new MissionScenarioService(new ObjectMapper());

    @AfterEach
    void clearLogin() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void allAgreedSituationsAreThere() {
        Set<String> ids = service.list().stream().map(MissionScenarioDto::getId).collect(Collectors.toSet());
        assertThat(ids).contains("cafe", "restaurant", "convenience_store", "taxi", "directions", "hospital",
                "friend_plans", "roommate", "boss", "professor", "exchange", "hotel");
    }

    @Test
    void everyLevel_followsItsOwnLimits() {
        for (MissionScenarioDto s : service.list()) {
            assertThat(List.of(s.getIcon(), s.getTitle(), s.getDescription(), s.getRole(), s.getPersonality(), s.getRoleEn(),
                    s.getPersonalityEn(), s.getHierarchy(), s.getIntimacy(), s.getSpeechStyle()))
                    .as(s.getId()).doesNotContain("").doesNotContainNull();
            assertThat(s.getHonorificLevel()).isIn("존댓말", "반말");
            assertThat(s.getLearnerSpeechLevel()).isIn("존댓말", "반말");
            for (MissionDifficulty d : MissionDifficulty.values()) {
                MissionScenarioDto.Level l = s.getLevels().get(d.apiValue());
                String where = s.getId() + " " + d.apiValue();
                assertThat(MissionDifficulty.countChars(l.getFirstMessage())).as(where).isLessThanOrEqualTo(d.rabbitMaxChars());
                assertThat(l.getFirstMessageEn()).as(where).isNotBlank();
                assertThat(l.getMissionDescription()).as(where).isNotBlank();
                assertThat(l.getLanguageCondition()).as(where).isNotBlank();
                assertThat(l.getSteps()).as(where).hasSizeBetween(2, 3);
                // Card text is English; only firstMessage and the language condition may name Korean forms
                for (String english : List.of(l.getMissionTitle(), l.getMissionDescription(), l.getGoalCondition(), l.getFirstMessageEn())) {
                    assertThat(english).as(where).doesNotContainPattern("\\p{IsHangul}");
                }
                l.getSteps().forEach(step -> {
                    assertThat(step).as(where).doesNotContainPattern("\\p{IsHangul}");
                    assertThat(step.split(" ").length).as(where + " " + step).isLessThanOrEqualTo(6);
                });
            }
        }
    }

    @Test
    void startMission_buildsSetupWithoutAi() {
        MissionSetupResponseDto setup = service.startMission("friend_plans", "HARD");
        assertThat(setup.getDifficulty()).isEqualTo("hard");
        assertThat(setup.getScenarioId()).isEqualTo("friend_plans");
        assertThat(setup.getPersona().getRole()).isEqualTo("친한 친구");
        assertThat(setup.getPersona().getHonorificLevel()).isEqualTo("반말");
        assertThat(setup.getLearnerSpeechLevel()).isEqualTo("반말");
        assertThat(setup.getSteps()).isNotEmpty();
        assertThat(setup.getMission().getClearCondition().getGoalCondition()).isNotBlank();
        assertThat(setup.getMission().getMinTurns()).isEqualTo(5);
    }

    @Test
    void missingDifficulty_isEasy() {
        assertThat(service.startMission("cafe", null).getDifficulty()).isEqualTo("easy");
    }

    @Test
    void unknownId_is400() {
        assertThatThrownBy(() -> service.startMission("moon_base", "easy"))
                .isInstanceOf(MissionChatException.class)
                .hasMessage(MissionScenarioService.MSG_UNKNOWN_SCENARIO)
                .satisfies(e -> assertThat(((MissionChatException) e).getStatus()).isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void demo_countsAsMissionStart_butUnknownIdDoesNot() {
        DemoProperties props = new DemoProperties();
        props.setEnabled(true);
        props.setMissionEasyOnly(false);
        props.setMissionStartsPerUser(1);
        DemoAiGate gate = new DemoAiGate(props);
        ReflectionTestUtils.setField(service, "demoAiGate", gate);
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                "guest_a", null, List.of(new SimpleGrantedAuthority("ROLE_USER"))));

        assertThatThrownBy(() -> service.startMission("moon_base", "hard")).isInstanceOf(MissionChatException.class);
        assertThat(service.startMission("taxi", "hard").getDifficulty()).isEqualTo("hard");
        assertThatThrownBy(() -> service.startMission("taxi", "hard")).isInstanceOf(DemoLimitException.class);
    }
}
