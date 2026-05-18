-- 1. word_categories (단어장 메타 데이터)
CREATE TABLE IF NOT EXISTS word_categories (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    level VARCHAR(20) NOT NULL,
    deck_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. words (큐레이션된 한국어 단어와 API 파싱 정보 적재)
CREATE TABLE IF NOT EXISTS words (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES word_categories(id) ON DELETE CASCADE,
    korean_word VARCHAR(100) NOT NULL,
    primary_meaning VARCHAR(255) NOT NULL,
    part_of_speech VARCHAR(50),
    example_sentence TEXT,
    example_translation TEXT,
    audio_url TEXT,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. fsrs_progress (FSRS 알고리즘 기반 사용자별 암기 추적)
CREATE TABLE IF NOT EXISTS fsrs_progress (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL, -- User 엔티티의 ID와 매핑 (기존 User ID 타입에 맞춰 BIGINT 사용)
    word_id INTEGER NOT NULL REFERENCES words(id) ON DELETE CASCADE,
    state INTEGER NOT NULL DEFAULT 0, -- 0: New, 1: Learning, 2: Review, 3: Relearning
    stability DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    difficulty DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    reps INTEGER NOT NULL DEFAULT 0,
    lapses INTEGER NOT NULL DEFAULT 0,
    last_review TIMESTAMP,
    next_review_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_word_progress UNIQUE(user_id, word_id)
);

-- 검색 성능 향상을 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_words_category_id ON words(category_id);
CREATE INDEX IF NOT EXISTS idx_fsrs_next_review ON fsrs_progress(next_review_date);
CREATE INDEX IF NOT EXISTS idx_fsrs_user_word ON fsrs_progress(user_id, word_id);
