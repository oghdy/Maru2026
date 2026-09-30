package com.hdy.maru.controller;

import com.hdy.maru.dto.*;
import com.hdy.maru.service.ChatTurnService;
import com.hdy.maru.service.MissionChatException;
import com.hdy.maru.service.MissionClearanceService;
import com.hdy.maru.service.MissionSetupService;
import com.hdy.maru.service.MissionSuggestionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1/mission-chat")
@RequiredArgsConstructor
public class MissionChatController {

    private final MissionSetupService missionSetupService;
    private final ChatTurnService chatTurnService;
    private final MissionClearanceService missionClearanceService;
    private final MissionSuggestionService missionSuggestionService;

    /**
     * LLM Call #1: Generate persona and mission based on user settings.
     */
    @PostMapping("/setup")
    public ResponseEntity<ApiResponse<MissionSetupResponseDto>> setupMission(
            @AuthenticationPrincipal String oauthId,
            @RequestBody MissionSetupRequestDto request) {

        MissionSetupResponseDto response = missionSetupService.generateMission(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * LLM Call #2: Process one chat turn, evaluate language, and return rabbit/turtle response.
     * Stateless: the client sends the full conversation history and setup every turn.
     */
    @PostMapping("/chat")
    public ResponseEntity<ApiResponse<ChatTurnResponseDto>> chatTurn(
            @AuthenticationPrincipal String oauthId,
            @RequestBody ChatTurnRequestDto request) {

        ChatTurnResponseDto response = chatTurnService.processTurn(request, request.getSetup());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * LLM Call #3: Issue a mission clearance certificate and save to DB.
     */
    @PostMapping("/clearance")
    public ResponseEntity<ApiResponse<MissionClearanceResponseDto>> issueClearance(
            @AuthenticationPrincipal String oauthId,
            @RequestBody MissionClearanceRequestDto request) {

        MissionClearanceResponseDto response = missionClearanceService.issueClearance(
                oauthId,
                request.getSetup(),
                request.getConversationHistory(),
                request.getMissionStatus()
        );
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * GET: Retrieve all mission clearances for the authenticated user.
     */
    @GetMapping("/clearances")
    public ResponseEntity<ApiResponse<List<MissionClearanceResponseDto>>> getClearances(
            @AuthenticationPrincipal String oauthId) {

        List<MissionClearanceResponseDto> response = missionClearanceService.getUserClearances(oauthId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * LLM Call #4: Get turtle suggestions
     */
    @PostMapping("/suggestion")
    public ResponseEntity<ApiResponse<SuggestionResponseDto>> getSuggestion(
            @AuthenticationPrincipal String oauthId,
            @RequestBody SuggestionRequestDto request) {

        SuggestionResponseDto response = missionSuggestionService.getSuggestions(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * Mission chat errors → proper HTTP status + user-facing message (never 200 with data=null).
     */
    @ExceptionHandler(MissionChatException.class)
    public ResponseEntity<ApiResponse<Void>> handleMissionChatException(MissionChatException e) {
        log.warn("Mission chat error {}: {}", e.getStatus().value(), e.getMessage());
        return ResponseEntity.status(e.getStatus())
                .body(ApiResponse.error(e.getStatus().value(), e.getMessage()));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnreadableBody(HttpMessageNotReadableException e) {
        log.warn("Unreadable mission chat request body: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(HttpStatus.BAD_REQUEST.value(), MissionChatException.MSG_BAD_REQUEST));
    }
}
