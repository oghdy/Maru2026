package com.hdy.maru.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class OpenAiServiceRequestTest {

    private static Map<String, Object> bodyWith(String effort) {
        OpenAiService service = new OpenAiService(new ObjectMapper());
        ReflectionTestUtils.setField(service, "modelName", "some-model");
        ReflectionTestUtils.setField(service, "reasoningEffort", effort);
        return service.buildRequestBody(List.of(Map.of("role", "system", "content", "x")));
    }

    @Test
    void blankEffort_isNotSent_soGpt4oKeepsItsExactRequest() {
        assertThat(bodyWith("")).containsOnlyKeys("model", "messages", "response_format");
        assertThat(bodyWith("  ")).doesNotContainKey("reasoning_effort");
        assertThat(bodyWith(null)).doesNotContainKey("reasoning_effort");
    }

    @Test
    void effort_isSent_withModelAndJsonMode() {
        Map<String, Object> body = bodyWith(" low ");
        assertThat(body).containsEntry("reasoning_effort", "low").containsEntry("model", "some-model");
        assertThat(body.get("response_format")).isEqualTo(Map.of("type", "json_object"));
    }
}
