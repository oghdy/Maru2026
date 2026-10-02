-- MSN-1.8.3: mission difficulty (easy / normal / hard) on clearance certificates. Additive, idempotent.
-- JPA ddl-auto=update also creates this; this patch makes the change explicit for Railway.
-- Existing rows keep NULL = "issued before difficulty existed".
ALTER TABLE mission_clearances ADD COLUMN IF NOT EXISTS difficulty VARCHAR(10);
