package com.hdy.maru.controller;

import com.hdy.maru.entity.User;
import com.hdy.maru.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/me")
public class MeController {

    private final UserRepository userRepository;

    public MeController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<User> getCurrentUser(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            return ResponseEntity.status(401).build();
        }
        String oauthId = authentication.getName();
        Optional<User> userOpt = userRepository.findByOauthId(oauthId);

        return userOpt.map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(404).build());
    }

    @PutMapping("/profile")
    public ResponseEntity<User> updateProfile(
            Authentication authentication,
            @RequestBody Map<String, String> payload) {
        if (authentication == null || authentication.getName() == null) {
            return ResponseEntity.status(401).build();
        }
        String oauthId = authentication.getName();
        Optional<User> userOpt = userRepository.findByOauthId(oauthId);

        if (userOpt.isPresent()) {
            User user = userOpt.get();
            String nickname = payload.get("nickname");
            String profileImageUrl = payload.get("profileImageUrl");

            if (nickname != null && !nickname.trim().isEmpty()) {
                user.setNickname(nickname.trim());
            }
            if (profileImageUrl != null) {
                user.setProfileImageUrl(profileImageUrl.trim());
            }

            userRepository.save(user);
            return ResponseEntity.ok(user);
        } else {
            return ResponseEntity.status(404).build();
        }
    }
}
