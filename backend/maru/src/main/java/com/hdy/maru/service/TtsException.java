package com.hdy.maru.service;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/** TTS 실패. status 는 그대로 HTTP 응답 코드, message 는 사용자용 영어 문장. */
@Getter
public class TtsException extends RuntimeException {
    private final HttpStatus status;

    public TtsException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }
}
