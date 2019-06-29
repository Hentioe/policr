CREATE TABLE migration_versions (id integer PRIMARY KEY AUTOINCREMENT, version text NOT NULL);
CREATE TABLE reports (id integer PRIMARY KEY AUTOINCREMENT, author_id integer NOT NULL, post_id integer NOT NULL, target_id integer NOT NULL, reason integer NOT NULL, status integer NOT NULL, created_at text NOT NULL, updated_at text NOT NULL, role integer NOT NULL DEFAULT 0, from_chat integer);
