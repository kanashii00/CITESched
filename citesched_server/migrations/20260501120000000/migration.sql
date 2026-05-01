BEGIN;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'student'
          AND column_name = 'academicStatus'
    ) THEN
        RETURN;
    END IF;

    CREATE TABLE "student_rebuild" (
        "id" bigint NOT NULL,
        "name" text NOT NULL,
        "email" text NOT NULL,
        "studentNumber" text NOT NULL,
        "course" text NOT NULL,
        "yearLevel" bigint NOT NULL,
        "section" text,
        "sectionId" bigint,
        "userInfoId" bigint NOT NULL,
        "academicStatus" text NOT NULL DEFAULT 'active'::text,
        "isActive" boolean NOT NULL DEFAULT true,
        "createdAt" timestamp without time zone NOT NULL,
        "updatedAt" timestamp without time zone NOT NULL
    );

    INSERT INTO "student_rebuild" (
        "id",
        "name",
        "email",
        "studentNumber",
        "course",
        "yearLevel",
        "section",
        "sectionId",
        "userInfoId",
        "academicStatus",
        "isActive",
        "createdAt",
        "updatedAt"
    )
    SELECT
        "id",
        "name",
        "email",
        "studentNumber",
        "course",
        "yearLevel",
        "section",
        "sectionId",
        "userInfoId",
        COALESCE("academicstatus", 'active'),
        "isActive",
        "createdAt",
        "updatedAt"
    FROM "student";

    IF EXISTS (
        SELECT 1
        FROM pg_class
        WHERE relkind = 'S'
          AND relname = 'student_id_seq'
    ) THEN
        ALTER SEQUENCE "student_id_seq" OWNED BY NONE;
    END IF;

    DROP TABLE "student";

    ALTER TABLE "student_rebuild" RENAME TO "student";

    IF NOT EXISTS (
        SELECT 1
        FROM pg_class
        WHERE relkind = 'S'
          AND relname = 'student_id_seq'
    ) THEN
        CREATE SEQUENCE "student_id_seq";
    END IF;

    ALTER TABLE ONLY "student"
        ALTER COLUMN "id" SET DEFAULT nextval('student_id_seq'::regclass);

    ALTER SEQUENCE "student_id_seq" OWNED BY "student"."id";

    ALTER TABLE ONLY "student"
        ADD CONSTRAINT "student_pkey" PRIMARY KEY ("id");

    ALTER TABLE ONLY "student"
        ADD CONSTRAINT "student_fk_0"
        FOREIGN KEY ("sectionId")
        REFERENCES "section"("id")
        ON DELETE NO ACTION
        ON UPDATE NO ACTION;

    CREATE UNIQUE INDEX "student_email_unique_idx"
        ON "student" USING btree ("email");

    CREATE UNIQUE INDEX "student_number_unique_idx"
        ON "student" USING btree ("studentNumber");

    PERFORM setval(
        'student_id_seq',
        COALESCE((SELECT MAX("id") FROM "student"), 1),
        true
    );
END $$;

COMMIT;
