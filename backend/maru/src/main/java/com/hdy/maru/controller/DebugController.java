package com.hdy.maru.controller;

import com.hdy.maru.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/debug")
@RequiredArgsConstructor
public class DebugController {

    private final JdbcTemplate jdbcTemplate;

    @GetMapping("/setup-level-column")
    public ApiResponse<String> addLevelColumn() {
        try {
            jdbcTemplate.execute("ALTER TABLE words ADD COLUMN IF NOT EXISTS level VARCHAR(10)");
            return ApiResponse.success("words 테이블에 level 컬럼이 추가되었거나 이미 존재합니다.", null);
        } catch (Exception e) {
            return ApiResponse.error(500, "컬럼 추가 실패: " + e.getMessage());
        }
    }

    @GetMapping("/levels")
    public ApiResponse<List<Map<String, Object>>> getLevelStats() {
        String sql = "SELECT level, COUNT(*) as cnt FROM words GROUP BY level";
        List<Map<String, Object>> result = jdbcTemplate.queryForList(sql);
        return ApiResponse.success("난이도별 단어 수 조회 완료", result);
    }

    @GetMapping("/categories")
    public ApiResponse<List<Map<String, Object>>> getCategoryStats() {
        String sql = """
            SELECT wc.id, wc.title, wc.level, COUNT(w.id) AS word_count
            FROM word_categories wc
            LEFT JOIN words w ON w.category_id = wc.id
            GROUP BY wc.id, wc.title, wc.level
            ORDER BY word_count ASC
            """;
        List<Map<String, Object>> result = jdbcTemplate.queryForList(sql);
        return ApiResponse.success("카테고리 통계 조회 완료", result);
    }

    @GetMapping("/merge")
    public ApiResponse<String> mergeCategories() {
        try {
            // [1단계] 핵심 카테고리(14개) 이름 표준화
            jdbcTemplate.execute("UPDATE word_categories SET title = '장소', level = 'Beginner' WHERE id = 12");
            jdbcTemplate.execute("UPDATE word_categories SET title = '쇼핑/경제', level = 'Beginner' WHERE id = 13");
            jdbcTemplate.execute("UPDATE word_categories SET title = '가족/인물', level = 'Beginner' WHERE id = 14");
            jdbcTemplate.execute("UPDATE word_categories SET title = '기타/사물', level = 'Beginner' WHERE id = 15");
            jdbcTemplate.execute("UPDATE word_categories SET title = '동작/상태', level = 'Beginner' WHERE id = 16");
            jdbcTemplate.execute("UPDATE word_categories SET title = '시간', level = 'Beginner' WHERE id = 17");
            jdbcTemplate.execute("UPDATE word_categories SET title = '감정', level = 'Beginner' WHERE id = 18");
            jdbcTemplate.execute("UPDATE word_categories SET title = '학교/교육', level = 'Beginner' WHERE id = 19");
            jdbcTemplate.execute("UPDATE word_categories SET title = '날씨/자연', level = 'Beginner' WHERE id = 20");
            jdbcTemplate.execute("UPDATE word_categories SET title = '직업/사회', level = 'Beginner' WHERE id = 21");
            jdbcTemplate.execute("UPDATE word_categories SET title = '신체', level = 'Beginner' WHERE id = 22");
            jdbcTemplate.execute("UPDATE word_categories SET title = '음식', level = 'Beginner' WHERE id = 24");
            jdbcTemplate.execute("UPDATE word_categories SET title = '동물/식물', level = 'Beginner' WHERE id = 40");
            jdbcTemplate.execute("UPDATE word_categories SET title = '숫자/수량', level = 'Beginner' WHERE id = 41");

            // [2단계] 특정 키워드 매칭 단어 이동
            // 장소
            jdbcTemplate.execute("UPDATE words SET category_id = 12 WHERE category_id != 12 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%place%' OR title ILIKE '%location%' OR title IN ('건축', '지역', '교통', 'transportation'))");
            // 사람/관계
            jdbcTemplate.execute("UPDATE words SET category_id = 14 WHERE category_id != 14 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%person%' OR title ILIKE '%people%' OR title ILIKE '%human%' OR title IN ('인물', '인간', '관계', 'family', '사람'))");
            // 음식
            jdbcTemplate.execute("UPDATE words SET category_id = 24 WHERE category_id != 24 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%food%' OR title ILIKE '%drink%' OR title = '요리')");
            // 감정/기분
            jdbcTemplate.execute("UPDATE words SET category_id = 18 WHERE category_id != 18 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%emotion%' OR title ILIKE '%feeling%' OR title IN ('기분', 'Feeling'))");
            // 직업/사회/경제
            jdbcTemplate.execute("UPDATE words SET category_id = 21 WHERE category_id != 21 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%job%' OR title ILIKE '%occupation%' OR title ILIKE '%business%' OR title ILIKE '%money%' OR title ILIKE '%finance%' OR title IN ('법률/사회', '정치'))");
            // 시간
            jdbcTemplate.execute("UPDATE words SET category_id = 17 WHERE category_id != 17 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%time%')");
            // 날씨/자연/동식물
            jdbcTemplate.execute("UPDATE words SET category_id = 40 WHERE category_id IN (189, 76, 67, 155, 114, 296)");
            jdbcTemplate.execute("UPDATE words SET category_id = 20 WHERE category_id != 20 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%weather%' OR title ILIKE '%nature%')");
            // 신체
            jdbcTemplate.execute("UPDATE words SET category_id = 22 WHERE category_id != 22 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%body%')");
            // 동작/상태
            jdbcTemplate.execute("UPDATE words SET category_id = 16 WHERE category_id != 16 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%action%' OR title ILIKE '%verb%' OR title ILIKE '%description%' OR title ILIKE '%manner%' OR title IN ('동작 (Actions)', '동작 (Action)', '상태', '형용사', '의류'))");
            // 학교/교육
            jdbcTemplate.execute("UPDATE words SET category_id = 19 WHERE category_id != 19 AND category_id IN (SELECT id FROM word_categories WHERE title ILIKE '%school%' OR title ILIKE '%education%' OR title ILIKE '%language%' OR title = '학문')");

            // [3단계] 그 외의 모든 떨거지(10개 미만 또는 매칭 안 된 영어 덱)를 기타(15)로 강제 통합
            jdbcTemplate.execute("UPDATE words SET category_id = 15 WHERE category_id NOT IN (12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 24, 40, 41)");

            // [4단계] 단어가 하나도 없는 빈 카테고리 삭제
            jdbcTemplate.execute("DELETE FROM word_categories WHERE id NOT IN (SELECT DISTINCT category_id FROM words)");

            return ApiResponse.success("카테고리 최종 병합 및 정제가 완료되었습니다.", "Survived: 14 core categories");
        } catch (Exception e) {
            return ApiResponse.error(500, "SQL Migration Failed: " + e.getMessage());
        }
    }
}
