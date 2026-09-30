-- MSN-1.3.1: mission clearance result (judged cleared / not cleared). Additive, idempotent.
-- JPA ddl-auto=update also creates these; this patch makes the change explicit for Railway.
-- Existing rows keep NULL = "issued before judging existed" (not judged).
ALTER TABLE mission_clearances ADD COLUMN IF NOT EXISTS cleared BOOLEAN;
ALTER TABLE mission_clearances ADD COLUMN IF NOT EXISTS result_reason TEXT;
ALTER TABLE mission_clearances ADD COLUMN IF NOT EXISTS goal_condition TEXT;
