package com.hdy.maru.exception;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.*;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** PM-1.P.8/1.P.5: 요청 형식 오류는 400, 없는 경로는 404 (500 아님) + ApiResponse. 기능 컨트롤러와 무관하게 핸들러만 검증. */
class GlobalExceptionHandlerBadRequestTest {

    @RestController
    static class ProbeController {
        @GetMapping("/probe/{id}")
        String path(@PathVariable Integer id) { return "ok"; }

        @GetMapping("/probe")
        String query(@RequestParam Integer unitId) { return "ok"; }

        @PostMapping("/probe")
        String body(@RequestBody java.util.Map<String, Integer> body) { return "ok"; }
    }

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new ProbeController())
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("경로 변수 타입 불일치 → 400")
    void pathTypeMismatch() throws Exception {
        mockMvc.perform(get("/probe/abc"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.message").value("Invalid value for 'id'"));
    }

    @Test
    @DisplayName("쿼리 파라미터 타입 불일치 → 400")
    void queryTypeMismatch() throws Exception {
        mockMvc.perform(get("/probe").param("unitId", "x"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Invalid value for 'unitId'"));
    }

    @Test
    @DisplayName("필수 쿼리 파라미터 누락 → 400")
    void missingParameter() throws Exception {
        mockMvc.perform(get("/probe"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Missing required parameter 'unitId'"));
    }

    @Test
    @DisplayName("깨진 JSON 본문 → 400")
    void unreadableBody() throws Exception {
        mockMvc.perform(post("/probe").contentType(MediaType.APPLICATION_JSON).content("{not json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Invalid request payload"));
    }

    @Test
    @DisplayName("없는 경로 → 404 (삭제된 debug API 포함)")
    void unknownPath() throws Exception {
        MockMvc withStatic = MockMvcBuilders.standaloneSetup(new ProbeController())
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
        withStatic.perform(get("/api/v1/admin/debug/merge"))
                .andExpect(status().isNotFound());
    }
}
