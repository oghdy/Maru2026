package com.hdy.maru.service;

import com.hdy.maru.entity.TtsCache;
import com.hdy.maru.repository.TtsCacheRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TtsServiceTest {

    @Mock
    private TtsCacheRepository repository;
    @Mock
    private OpenAiTtsClient client;
    @InjectMocks
    private TtsService service;

    private static final byte[] MP3 = {1, 2, 3};

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "model", "gpt-4o-mini-tts");
        ReflectionTestUtils.setField(service, "voice", "ash");
    }

    @Test
    @DisplayName("캐시 없음 → OpenAI 호출 후 저장, MISS")
    void miss_callsOpenAiAndSaves() {
        when(repository.findByCacheKey(anyString())).thenReturn(Optional.empty());
        when(client.synthesize(eq("저는 학생이에요."), eq("gpt-4o-mini-tts"), eq("ash"), anyString())).thenReturn(MP3);

        TtsService.TtsResult r = service.speak("  저는   학생이에요. ");

        assertThat(r.cacheHit()).isFalse();
        assertThat(r.audio()).isEqualTo(MP3);
        ArgumentCaptor<TtsCache> saved = ArgumentCaptor.forClass(TtsCache.class);
        verify(repository).save(saved.capture());
        assertThat(saved.getValue().getInputText()).isEqualTo("저는 학생이에요."); // 정규화된 텍스트
        assertThat(saved.getValue().getCacheKey()).hasSize(64);
    }

    @Test
    @DisplayName("캐시 있음 → OpenAI 미호출, HIT")
    void hit_doesNotCallOpenAi() {
        TtsCache c = new TtsCache();
        c.setAudio(MP3);
        when(repository.findByCacheKey(anyString())).thenReturn(Optional.of(c));

        TtsService.TtsResult r = service.speak("저는 학생이에요.");

        assertThat(r.cacheHit()).isTrue();
        verifyNoInteractions(client);
        verify(repository, never()).save(any());
    }

    @Test
    @DisplayName("같은 문장은 공백이 달라도 같은 캐시 키")
    void sameKeyAfterNormalization() {
        assertThat(service.cacheKey(TtsService.normalize(" 안녕하세요 ")))
                .isEqualTo(service.cacheKey(TtsService.normalize("안녕하세요")));
    }

    @Test
    @DisplayName("자모 한 글자는 표준 읽기로 합성 (ㅏ → 아, ㄱ → 기역), 캐시 텍스트는 원문")
    void jamoReading() {
        when(repository.findByCacheKey(anyString())).thenReturn(Optional.empty());
        when(client.synthesize(anyString(), anyString(), anyString(), anyString())).thenReturn(MP3);

        service.speak("ㅏ");
        service.speak("ㄱ");

        verify(client).synthesize(eq("아"), anyString(), anyString(), anyString());
        verify(client).synthesize(eq("기역"), anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("빈 텍스트·200자 초과 → 400, OpenAI 미호출")
    void validation() {
        assertThatThrownBy(() -> service.speak("   "))
                .isInstanceOf(TtsException.class)
                .extracting("status").isEqualTo(HttpStatus.BAD_REQUEST);
        assertThatThrownBy(() -> service.speak("가".repeat(201)))
                .isInstanceOf(TtsException.class)
                .extracting("status").isEqualTo(HttpStatus.BAD_REQUEST);
        verifyNoInteractions(client);
    }

    @Test
    @DisplayName("200자 정확히는 허용")
    void exactly200Allowed() {
        when(repository.findByCacheKey(anyString())).thenReturn(Optional.empty());
        when(client.synthesize(anyString(), anyString(), anyString(), anyString())).thenReturn(MP3);
        assertThat(service.speak("가".repeat(200)).audio()).isEqualTo(MP3);
    }

    @Test
    @DisplayName("OpenAI 오류는 그대로 전달 (캐시 저장 안 함)")
    void upstreamError() {
        when(repository.findByCacheKey(anyString())).thenReturn(Optional.empty());
        when(client.synthesize(anyString(), anyString(), anyString(), anyString()))
                .thenThrow(new TtsException(HttpStatus.BAD_GATEWAY, "Could not create audio. Please try again."));
        assertThatThrownBy(() -> service.speak("안녕하세요"))
                .extracting("status").isEqualTo(HttpStatus.BAD_GATEWAY);
        verify(repository, never()).save(any());
    }
}
