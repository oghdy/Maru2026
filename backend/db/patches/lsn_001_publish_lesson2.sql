-- LSN-1.2.10: 레슨 목록 API 가 is_published = true 인 레슨만 반환하도록 바뀜.
-- lesson2("What do you do?")는 is_published 가 NULL 이라 이 패치 없이는 앱에서 사라진다.
-- 멱등: 몇 번 실행해도 결과 동일.
UPDATE lessons
SET is_published = true
WHERE lesson_id = 'lesson2'
  AND is_published IS DISTINCT FROM true;

-- 확인용: 이 쿼리가 0행이어야 한다 (앱에 보여야 하는데 NULL/false 인 레슨)
-- SELECT lesson_id, is_published FROM lessons WHERE is_published IS NOT TRUE;
