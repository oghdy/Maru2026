package com.hdy.maru;

import org.springframework.test.context.ActiveProfiles;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
@ActiveProfiles("test") // H2 + 테스트용 jwt.secret (application-test.yml). 없으면 로컬 maru DB·JWT_SECRET 에 의존
class MaruApplicationTests {

	@Test
	void contextLoads() {
	}

}
