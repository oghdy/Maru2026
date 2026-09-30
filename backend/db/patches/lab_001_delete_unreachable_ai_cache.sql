-- LAB-1.2.3: remove ai_cache rows that the API can no longer read.
-- Since LAB-1.2.3 the server rejects empty / non-Korean input (400) and looks up the cache with
-- trimmed, whitespace-collapsed text, so these rows are unreachable. The empty-input row also held
-- a Gemini "Error: Input sentence is empty." answer that used to be returned as a normal result.
-- Idempotent: running it again deletes nothing.
BEGIN;

DELETE FROM ai_cache
WHERE btrim(input_text) = ''
   OR input_text <> regexp_replace(btrim(input_text), '\s+', ' ', 'g')
   OR input_text !~ '[가-힣ㄱ-ㆎ]';

COMMIT;
