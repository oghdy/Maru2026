package com.hdy.maru.controller;

import com.hdy.maru.dto.LessonContentDto;
import com.hdy.maru.dto.LessonResponseDto;
import com.hdy.maru.dto.StepDto;
import com.hdy.maru.service.LessonService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class LessonControllerTest {

        @Autowired
        private MockMvc mockMvc;

        @MockitoBean
        private LessonService lessonService; // Injecting a mock service

        @MockitoBean
        private com.hdy.maru.security.JwtProvider jwtProvider;

        @Test
        @DisplayName("GET /api/units/{unitId}/lessons - Should return a list of lessons matching unitId with 200 OK")
        void getLessonsByUnitId() throws Exception {
                // Given (Mocking the service response)
                LessonContentDto mockContent = new LessonContentDto(
                                List.of(new StepDto("step1", 1, "introduction", "Title", "Instruction",
                                                Map.of("title", "명사란?", "text", "설명입니다."), null)));

                LessonResponseDto mockLesson = new LessonResponseDto(
                                "unit1_lesson1", 1, "한글 기초", 1, "자음", "기본 자음", 1, 10, mockContent, true);

                given(lessonService.getLessonsByUnitId(1)).willReturn(List.of(mockLesson));

                // When & Then (Simulating the HTTP GET request and verifying the JSON response
                // structure)
                mockMvc.perform(get("/api/units/1/lessons"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value(200))
                                .andExpect(jsonPath("$.message").value("Success"))
                                .andExpect(jsonPath("$.data").isArray())
                                .andExpect(jsonPath("$.data[0].lessonId").value("unit1_lesson1"))
                                .andExpect(jsonPath("$.data[0].unitId").value(1))
                                .andExpect(jsonPath("$.data[0].content.steps[0].step_type").value("introduction"))
                                .andExpect(jsonPath("$.data[0].content.steps[0].content.title").value("명사란?"));
        }

        @Test
        @DisplayName("CORS Preflight (OPTIONS) /api/units/1/lessons - Should return allowed origin headers")
        void testCorsPreflight() throws Exception {
                mockMvc.perform(
                                org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                                .options("/api/units/1/lessons")
                                                .header("Origin", "http://localhost:3000")
                                                .header("Access-Control-Request-Method", "GET"))
                                .andExpect(status().isOk())
                                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.header()
                                                .string("Access-Control-Allow-Origin", "http://localhost:3000"))
                                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.header()
                                                .string("Access-Control-Allow-Methods",
                                                                "GET,POST,PUT,DELETE,OPTIONS,PATCH"));
        }
}
