package com.hdy.maru.demo;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** The default configuration (what production runs with): the demo does not exist. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GuestApiOffTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ApplicationContext context;

    @Autowired
    private DemoProperties props;

    @Test
    @DisplayName("Default: demo disabled, guest API is 404 and the controller bean does not exist")
    void guestApi_is404() throws Exception {
        assertThat(props.isEnabled()).isFalse();
        assertThat(context.getBeansOfType(GuestTokenController.class)).isEmpty();

        mockMvc.perform(post("/api/demo/guest"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    @DisplayName("Default CORS: same origins as before, no max-age header, unknown origin refused")
    void cors_defaults() throws Exception {
        mockMvc.perform(options("/api/me")
                        .header(HttpHeaders.ORIGIN, "http://localhost:5085")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:5085"))
                .andExpect(header().doesNotExist(HttpHeaders.ACCESS_CONTROL_MAX_AGE));

        mockMvc.perform(options("/api/me")
                        .header(HttpHeaders.ORIGIN, "https://demo.example.com")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET"))
                .andExpect(status().isForbidden());
    }
}
