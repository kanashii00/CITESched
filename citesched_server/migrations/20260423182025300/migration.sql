BEGIN;

--
-- MIGRATION VERSION FOR citesched
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('citesched', '20260423182025300', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260423182025300', "timestamp" = now();

COMMIT;
