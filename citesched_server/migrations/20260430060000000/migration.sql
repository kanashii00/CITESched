BEGIN;

CREATE TABLE IF NOT EXISTS "chat_sessions" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "roleType" text NOT NULL,
    "title" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS "chat_messages" (
    "id" bigserial PRIMARY KEY,
    "sessionRecordId" bigint NOT NULL,
    "sender" text NOT NULL,
    "message" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chat_messages_fk_0'
    ) THEN
        ALTER TABLE ONLY "chat_messages"
            ADD CONSTRAINT "chat_messages_fk_0"
            FOREIGN KEY ("sessionRecordId")
            REFERENCES "chat_sessions"("id")
            ON DELETE NO ACTION
            ON UPDATE NO ACTION;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS "chat_sessions_user_role_updated_idx"
    ON "chat_sessions" USING btree ("userId", "roleType", "updatedAt");

CREATE INDEX IF NOT EXISTS "chat_messages_session_timestamp_idx"
    ON "chat_messages" USING btree ("sessionRecordId", "timestamp");

COMMIT;
