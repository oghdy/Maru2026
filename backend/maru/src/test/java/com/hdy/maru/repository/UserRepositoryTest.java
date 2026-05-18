package com.hdy.maru.repository;

import com.hdy.maru.entity.User;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test") // Tells Spring to use application-test.yml
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    @DisplayName("User Entity H2 Save & Find Test (TDD Step 3-2)")
    void saveAndFindUserTest() {
        // Given (실패하는 테스트를 통과시키기 위한 셋업)
        User testUser = new User();
        testUser.setOauthProvider("google");
        testUser.setOauthId("123456789");
        testUser.setEmail("test@maru.com");
        testUser.setNickname("TestUser");

        // When (실제 행동)
        User savedUser = userRepository.save(testUser);

        // Then (검증)
        assertThat(savedUser.getId()).isNotNull();

        Optional<User> foundUser = userRepository.findByOauthProviderAndOauthId("google", "123456789");
        assertThat(foundUser).isPresent();
        assertThat(foundUser.get().getNickname()).isEqualTo("TestUser");
    }
}
