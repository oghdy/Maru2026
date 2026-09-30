-- LSN-1.2.12: 레슨 데이터 정리 (멱등 — 몇 번 실행해도 결과 동일)
-- 1) Unit 0 제목의 괄호 숫자 제거 ("Basic Vowels (5)" → "Basic Vowels")
-- 2) Unit 1 unit_title 통일 → 'Introduce Yourself' (u1-l1 이름 소개, lesson2 직업 소개)
-- 3) lesson2 빈 메타데이터(difficulty/estimated) 채움, completion 본문 {} → text/highlights
-- 4) Unit 0 12개 레슨 끝에 completion 단계 추가 (배운 글자 = 해당 레슨 intro/practice items 의 jamo, u0_l12 는 퀴즈 items)
BEGIN;

UPDATE lessons SET title = regexp_replace(title, '\s*\(\d+\)$', '')
WHERE unit_id = 0 AND title ~ '\s*\(\d+\)$';

UPDATE lessons SET unit_title = 'Introduce Yourself'
WHERE unit_id = 1 AND unit_title IS DISTINCT FROM 'Introduce Yourself';

UPDATE lessons SET difficulty_level = 1 WHERE lesson_id = 'lesson2' AND difficulty_level IS NULL;
UPDATE lessons SET estimated_minutes = 15 WHERE lesson_id = 'lesson2' AND estimated_minutes IS NULL;

-- lesson2 completion(마지막 단계) 본문 채우기: step_type='completion' 인 원소의 content 교체
UPDATE lessons
SET content = jsonb_set(content, '{steps}', (
    SELECT jsonb_agg(CASE WHEN s->>'step_type' = 'completion'
        THEN jsonb_set(s, '{content}', '{"text": "You''ve learned ''저는 [job]이에요/예요.''\nConsonant ending → 이에요 (학생이에요), vowel ending → 예요 (의사예요).", "highlights": ["이에요", "예요"]}'::jsonb)
        ELSE s END ORDER BY i)
    FROM jsonb_array_elements(content->'steps') WITH ORDINALITY AS t(s, i)))
WHERE lesson_id = 'lesson2';

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l1_done", "orderNum": 4, "stepType": "completion", "title": "Basic Vowels Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: ㅏ ㅓ ㅗ ㅜ ㅣ", "highlights": ["ㅏ", "ㅓ", "ㅗ", "ㅜ", "ㅣ"]}}'::jsonb)
WHERE lesson_id = 'u0_l1' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l2_done", "orderNum": 4, "stepType": "completion", "title": "Derived Vowels Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: ㅑ ㅕ ㅛ ㅠ", "highlights": ["ㅑ", "ㅕ", "ㅛ", "ㅠ"]}}'::jsonb)
WHERE lesson_id = 'u0_l2' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l3_done", "orderNum": 4, "stepType": "completion", "title": "Other Vowels Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: ㅐ ㅔ ㅒ ㅖ ㅢ ㅡ", "highlights": ["ㅐ", "ㅔ", "ㅒ", "ㅖ", "ㅢ", "ㅡ"]}}'::jsonb)
WHERE lesson_id = 'u0_l3' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l4_done", "orderNum": 4, "stepType": "completion", "title": "Combined Vowels Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: ㅘ ㅙ ㅚ ㅝ ㅞ ㅟ", "highlights": ["ㅘ", "ㅙ", "ㅚ", "ㅝ", "ㅞ", "ㅟ"]}}'::jsonb)
WHERE lesson_id = 'u0_l4' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l5_done", "orderNum": 5, "stepType": "completion", "title": "Basic Consonants Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: ㄱ ㄴ ㄷ ㄹ ㅁ ㅂ ㅅ 가 나 다 …", "highlights": ["ㄱ", "ㄴ", "ㄷ", "ㄹ", "ㅁ", "ㅂ"]}}'::jsonb)
WHERE lesson_id = 'u0_l5' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l6_done", "orderNum": 4, "stepType": "completion", "title": "Aspirated Consonants Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: ㅋ ㅌ ㅍ ㅊ 가 카 다 타 바 파 …", "highlights": ["ㅋ", "ㅌ", "ㅍ", "ㅊ", "가", "카"]}}'::jsonb)
WHERE lesson_id = 'u0_l6' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l7_done", "orderNum": 5, "stepType": "completion", "title": "Tensed & Special Consonants Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: ㄲ ㄸ ㅃ ㅆ ㅉ 가 까 다 따 바 …", "highlights": ["ㄲ", "ㄸ", "ㅃ", "ㅆ", "ㅉ", "가"]}}'::jsonb)
WHERE lesson_id = 'u0_l7' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l8_done", "orderNum": 4, "stepType": "completion", "title": "Consonants & Vowels Review Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: ㅏ ㅑ ㅐ ㅘ ㄱ ㅋ ㄲ", "highlights": ["ㅏ", "ㅑ", "ㅐ", "ㅘ", "ㄱ", "ㅋ"]}}'::jsonb)
WHERE lesson_id = 'u0_l8' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l9_done", "orderNum": 4, "stepType": "completion", "title": "Basic Final Consonants Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: 간 말 밤 강", "highlights": ["간", "말", "밤", "강"]}}'::jsonb)
WHERE lesson_id = 'u0_l9' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l10_done", "orderNum": 4, "stepType": "completion", "title": "Advanced Final Consonants Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: 밖 꽃 잎 각 곧 낮 입 앞", "highlights": ["밖", "꽃", "잎", "각", "곧", "낮"]}}'::jsonb)
WHERE lesson_id = 'u0_l10' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l11_done", "orderNum": 4, "stepType": "completion", "title": "Complex Matchim Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: 값 닭 앉다 없다 싫다", "highlights": ["값", "닭", "앉다", "없다", "싫다"]}}'::jsonb)
WHERE lesson_id = 'u0_l11' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

UPDATE lessons SET content = jsonb_set(content, '{steps}', (content->'steps') || '{"stepId": "l12_done", "orderNum": 3, "stepType": "completion", "title": "Ultimate Review Complete!", "instruction": "Great work! Here is what you practiced in this lesson.", "contentObj": {"text": "You practiced: 한글 · 각 밖 꽃 값 닭", "highlights": ["각", "밖", "꽃", "값", "닭"]}}'::jsonb)
WHERE lesson_id = 'u0_l12' AND NOT EXISTS (
  SELECT 1 FROM jsonb_array_elements(content->'steps') s WHERE s->>'stepType' = 'completion');

COMMIT;
