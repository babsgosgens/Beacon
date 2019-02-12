-- diet_contents should update the diets last_update column.

CREATE EXTENSION "uuid-ossp";
CREATE EXTENSION pgcrypto;
CREATE EXTENSION citext;

-- Updates: Build info and release notes
CREATE TABLE updates (
	update_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	build_number INTEGER NOT NULL UNIQUE,
	build_display TEXT NOT NULL,
	notes TEXT NOT NULL,
	preview TEXT NOT NULL DEFAULT '',
	stage INTEGER NOT NULL DEFAULT 0,
	mac_url TEXT NOT NULL,
	mac_signature CITEXT NOT NULL,
	win_url TEXT NOT NULL,
	win_signature CITEXT NOT NULL
);
GRANT SELECT ON TABLE updates TO thezaz_website;
-- End Updates

-- Domains that will be useful later
CREATE DOMAIN email AS citext CHECK (value ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
CREATE DOMAIN hex AS citext CHECK (value ~ '^[a-fA-F0-9]+$');
-- End domains

-- Email Addresses
CREATE TABLE email_addresses (
	email_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	address TEXT NOT NULL,
	group_key hex NOT NULL,
	group_key_precision INTEGER NOT NULL
);
GRANT SELECT, INSERT ON TABLE email_addresses TO thezaz_website;

CREATE TABLE email_verification (
	email_id UUID NOT NULL PRIMARY KEY REFERENCES email_addresses(email_id) ON UPDATE CASCADE ON DELETE CASCADE,
	code hex NOT NULL
);
GRANT SELECT, INSERT, UPDATE, DELETE ON email_verification TO thezaz_website;

CREATE OR REPLACE FUNCTION group_key_for_email(p_address email, p_precision INTEGER) RETURNS hex AS $$
DECLARE
	v_user TEXT;
	v_domain TEXT;
	v_kvalue TEXT;
BEGIN
	v_user := SUBSTRING(p_address, '^([^@]+)@.+$');
	v_domain := SUBSTRING(p_address, '^[^@]+@(.+)$');
	
	IF LENGTH(v_user) <= p_precision THEN
		v_kvalue := '@' || v_domain;
	ELSE
		v_kvalue := SUBSTRING(v_user, 1, p_precision) || '*@' || v_domain;
	END IF;
	
	RETURN MD5(LOWER(v_kvalue));
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

CREATE OR REPLACE FUNCTION uuid_for_email(p_address email) RETURNS UUID AS $$
DECLARE
	v_uuid UUID;
BEGIN
	SELECT email_id INTO v_uuid FROM email_addresses WHERE group_key = group_key_for_email(p_address, email_addresses.group_key_precision) AND CRYPT(LOWER(p_address), address) = address;
	IF FOUND THEN
		RETURN v_uuid;
	ELSE
		RETURN NULL;
	END IF;
END;
$$ LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION uuid_for_email(p_address email, p_create BOOLEAN) RETURNS UUID AS $$
DECLARE
	v_uuid UUID;
	v_precision INTEGER;
	k_target_precision CONSTANT INTEGER := 5;
BEGIN
	v_uuid := uuid_for_email(p_address);
	IF v_uuid IS NULL THEN
		IF p_create = TRUE THEN
			INSERT INTO email_addresses (address, group_key, group_key_precision) VALUES (CRYPT(LOWER(p_address), GEN_SALT('bf')), group_key_for_email(p_address, k_target_precision), k_target_precision) RETURNING email_id INTO v_uuid;
		END IF;
	ELSE
		SELECT group_key_precision INTO v_precision FROM email_addresses WHERE email_id = v_uuid;
		IF v_precision != k_target_precision THEN
			UPDATE email_addresses SET group_key = group_key_for_email(p_address, k_target_precision), group_key_precision = k_target_precision WHERE email_id = v_uuid;
		END IF;
	END IF;
	RETURN v_uuid;	
END;
$$ LANGUAGE 'plpgsql' VOLATILE;
-- End Email Addresses

-- Users: The absolute minimum we need to track, with "hard-coded" value for the developer.
CREATE TABLE users (
	user_id UUID NOT NULL PRIMARY KEY,
	email_id UUID UNIQUE REFERENCES email_addresses(email_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	username CITEXT,
	public_key TEXT NOT NULL,
	private_key hex,
	private_key_salt hex,
	private_key_iterations INTEGER,
	patreon_id INTEGER,
	is_patreon_supporter BOOLEAN NOT NULL DEFAULT FALSE,
	CHECK ((email_id IS NULL AND username IS NULL AND private_key_iterations IS NULL AND private_key_salt IS NULL AND private_key IS NULL) OR (email_id IS NOT NULL AND username IS NOT NULL AND private_key_iterations IS NOT NULL AND private_key_salt IS NOT NULL AND private_key IS NOT NULL))
);
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE users TO thezaz_website;
-- End Users

-- Documents: Files that are shareable in the community (time to rethink this?)
CREATE TYPE publish_status AS ENUM (
	'Private',
	'Requested',
	'Approved',
	'Approved But Private',
	'Denied'
);

CREATE TABLE documents (
	document_id UUID NOT NULL PRIMARY KEY,
	user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	title TEXT NOT NULL,
	description TEXT NOT NULL,
	published publish_status NOT NULL,
	map INTEGER NOT NULL,
	difficulty NUMERIC(8, 4) NOT NULL,
	console_safe BOOLEAN NOT NULL,
	last_update TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
	revision INTEGER NOT NULL DEFAULT 1,
	download_count INTEGER NOT NULL DEFAULT 0,
	contents JSONB NOT NULL
);
GRANT SELECT, INSERT, UPDATE, DELETE ON documents TO thezaz_website;

CREATE OR REPLACE FUNCTION documents_maintenance_function() RETURNS TRIGGER AS $$
DECLARE
	p_update_meta BOOLEAN;
	p_console_safe_known BOOLEAN;
	p_rec RECORD;
BEGIN
	IF TG_OP = 'INSERT' THEN
		NEW.document_id = (NEW.contents->>'Identifier')::UUID;
		p_update_meta = TRUE;
	ELSIF TG_OP = 'UPDATE' THEN
		IF NEW.document_id != OLD.document_id OR NEW.contents->>'Identifier' != OLD.contents->>'Identifier' THEN
			RAISE EXCEPTION 'Cannot change document identifier';
		END IF;
		IF NEW.contents != OLD.contents THEN
			NEW.last_update = clock_timestamp();
			NEW.revision = NEW.revision + 1;
			p_update_meta = TRUE;
		ELSE
			IF NEW.title != OLD.title OR NEW.description != OLD.description OR NEW.map != OLD.map OR NEW.difficulty != OLD.difficulty OR NEW.console_safe != OLD.console_safe THEN
				RAISE EXCEPTION 'Do not change meta properties. Change the contents JSON instead.';
			END IF;
		END IF;
	END IF;
	IF p_update_meta = TRUE THEN
		NEW.map = coalesce((NEW.contents->>'Map')::integer, 1);
		NEW.console_safe = TRUE;
		p_console_safe_known = FALSE;
		IF coalesce((NEW.contents->>'Version')::numeric, 2) = 3 THEN
			NEW.title = coalesce(NEW.contents->'Configs'->'Metadata'->>'Title', 'Untitled Document');
			NEW.description = coalesce(NEW.contents->'Configs'->'Metadata'->>'Description', '');
			NEW.difficulty = coalesce((NEW.contents->'Configs'->'Difficulty'->>'MaxDinoLevel')::numeric, 150) / 30;
			FOR p_rec IN SELECT DISTINCT mods.console_safe FROM (SELECT DISTINCT jsonb_array_elements(jsonb_array_elements(jsonb_array_elements(jsonb_array_elements(NEW.contents->'Configs'->'LootDrops'->'Contents')->'ItemSets')->'ItemEntries')->'Items')->>'Path' AS path) AS items LEFT JOIN (engrams INNER JOIN mods ON (engrams.mod_id = mods.mod_id)) ON (items.path = engrams.path) LOOP
				NEW.console_safe = NEW.console_safe AND coalesce(p_rec.console_safe, FALSE);
				p_console_safe_known = TRUE;
			END LOOP;
		ELSE
			NEW.title = coalesce(NEW.contents->>'Title', 'Untitled Document');
			NEW.description = coalesce(NEW.contents->>'Description', '');
			NEW.difficulty = coalesce((NEW.contents->>'DifficultyValue')::numeric, 4.0);
			FOR p_rec IN SELECT DISTINCT mods.console_safe FROM (SELECT DISTINCT jsonb_array_elements(jsonb_array_elements(jsonb_array_elements(jsonb_array_elements(NEW.contents->'LootSources')->'ItemSets')->'ItemEntries')->'Items')->>'Path' AS path) AS items LEFT JOIN (engrams INNER JOIN mods ON (engrams.mod_id = mods.mod_id)) ON (items.path = engrams.path) LOOP
				NEW.console_safe = NEW.console_safe AND coalesce(p_rec.console_safe, FALSE);
				p_console_safe_known = TRUE;
			END LOOP;
		END IF;
		IF NOT p_console_safe_known THEN
			NEW.console_safe = FALSE;
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER documents_maintenance_trigger BEFORE INSERT OR UPDATE ON documents FOR EACH ROW EXECUTE PROCEDURE documents_maintenance_function();
-- End Documents

-- Mods: The three core packs are now listed as mods. They have been "hard coded" into this database.
CREATE TABLE mods (
	mod_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	workshop_id BIGINT NOT NULL,
	user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	name TEXT NOT NULL DEFAULT 'Unknown Mod',
	confirmed BOOLEAN NOT NULL DEFAULT FALSE,
	confirmation_code UUID NOT NULL DEFAULT gen_random_uuid(),
	pull_url TEXT,
	last_pull_hash TEXT,
	console_safe BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE UNIQUE INDEX mods_workshop_id_user_id_uidx ON mods(workshop_id, user_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE mods TO thezaz_website;

CREATE OR REPLACE FUNCTION enforce_mod_owner() RETURNS trigger AS $$
DECLARE
	confirmed_count INTEGER := 0;
BEGIN
	IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE' AND NEW.confirmed = TRUE AND OLD.confirmed = FALSE) THEN
		SELECT INTO confirmed_count COUNT(mod_id) FROM mods WHERE confirmed = TRUE AND workshop_id = NEW.workshop_id;
		IF confirmed_count > 0 THEN
			RAISE EXCEPTION 'Mod is already confirmed by another user.';
		END IF;
		IF NEW.confirmed THEN
			DELETE FROM mods WHERE workshop_id = NEW.workshop_id AND mod_id != NEW.mod_id;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER enforce_mod_owner BEFORE INSERT OR UPDATE ON mods FOR EACH ROW EXECUTE PROCEDURE enforce_mod_owner();
-- End Mods

-- Sessions: PHP/Website sessions
CREATE TABLE sessions (
	session_id CITEXT NOT NULL PRIMARY KEY,
	user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
	valid_until TIMESTAMP WITH TIME ZONE
);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE sessions TO thezaz_website;
-- End Sessions

-- OAuth Tokens: So the server can periodically refresh connected accounts.
CREATE TABLE oauth_tokens (
	access_token TEXT NOT NULL PRIMARY KEY,
	user_id UUID NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
	valid_until TIMESTAMP WITH TIME ZONE,
	refresh_token TEXT NOT NULL
);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE oauth_tokens TO thezaz_website;
-- End OAuth Tokens

-- Delete Tracking Functions: These functions allow the update JSON to include a section for deleted objects, since they'd be otherwise missing.
CREATE OR REPLACE FUNCTION object_insert_trigger () RETURNS TRIGGER AS $$
BEGIN
	EXECUTE 'DELETE FROM deletions WHERE object_id = $1;' USING NEW.object_id;
	NEW.last_update = CURRENT_TIMESTAMP(0);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION object_update_trigger () RETURNS TRIGGER AS $$
BEGIN
	NEW.last_update = CURRENT_TIMESTAMP(0);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION object_delete_trigger () RETURNS TRIGGER AS $$
BEGIN
	EXECUTE 'INSERT INTO deletions (object_id, from_table, label, min_version) VALUES ($1, $2, $3, $4);' USING OLD.object_id, TG_TABLE_NAME, OLD.label, OLD.min_version;
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- End Delete Tracking Functions

-- This function takes the value of the path column and computes the class into the class_string column.
CREATE OR REPLACE FUNCTION compute_class_trigger () RETURNS TRIGGER AS $$
BEGIN
	NEW.class_string = SUBSTRING(NEW.path, '\.([a-zA-Z0-9\-\_]+)$') || '_C';
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Enums
CREATE TYPE loot_source_kind AS ENUM (
	'Standard',
	'Bonus',
	'Cave',
	'Sea'
);

CREATE TYPE taming_methods AS ENUM (
	'None',
	'Knockout',
	'Passive',
	'Trap'
);
-- End Enums

-- Core Object Structure: Most objects will inherit from the objects table, which allows the website to determine changes for delta updates.
CREATE TABLE objects (
	object_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	label CITEXT NOT NULL,
	min_version INTEGER NOT NULL DEFAULT 0,
	last_update TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
	mod_id UUID NOT NULL DEFAULT '30bbab29-44b2-4f4b-a373-6d4740d9d3b5' REFERENCES mods(mod_id) ON DELETE CASCADE ON UPDATE CASCADE
);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE objects to thezaz_website;

CREATE TABLE deletions (
	object_id UUID NOT NULL PRIMARY KEY,
	from_table CITEXT NOT NULL,
	label CITEXT NOT NULL,
	min_version INTEGER NOT NULL,
	action_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
	tag TEXT
);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE deletions TO thezaz_website;
-- End Core Object Structure

-- Loot Sources: All the lootable objects that Beacon can customize
CREATE TABLE loot_source_icons (
	PRIMARY KEY (object_id),
	FOREIGN KEY (mod_id) REFERENCES mods(mod_id) ON DELETE CASCADE ON UPDATE CASCADE,
	icon_data BYTEA NOT NULL
) INHERITS (objects);
GRANT SELECT ON TABLE loot_source_icons TO thezaz_website;
CREATE TRIGGER loot_source_icons_before_insert_trigger BEFORE INSERT ON loot_source_icons FOR EACH ROW EXECUTE PROCEDURE object_insert_trigger();
CREATE TRIGGER loot_source_icons_before_update_trigger BEFORE UPDATE ON loot_source_icons FOR EACH ROW EXECUTE PROCEDURE object_update_trigger();
CREATE TRIGGER loot_source_icons_after_delete_trigger AFTER DELETE ON loot_source_icons FOR EACH ROW EXECUTE PROCEDURE object_delete_trigger();

CREATE OR REPLACE FUNCTION loot_source_icons_update_loot_source() RETURNS TRIGGER AS $$
BEGIN
	UPDATE loot_sources SET last_update = CURRENT_TIMESTAMP(0) WHERE icon = NEW.object_id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER loot_source_icons_after_update_trigger AFTER UPDATE ON loot_source_icons FOR EACH ROW EXECUTE PROCEDURE loot_source_icons_update_loot_source();

CREATE TABLE loot_sources (
	PRIMARY KEY (object_id),
	FOREIGN KEY (mod_id) REFERENCES mods(mod_id) ON DELETE CASCADE ON UPDATE CASCADE,
	path CITEXT NOT NULL UNIQUE,
	class_string CITEXT NOT NULL,
	availability INTEGER NOT NULL,
	multiplier_min NUMERIC(6,4) NOT NULL,
	multiplier_max NUMERIC(6,4) NOT NULL,
	uicolor TEXT NOT NULL CHECK (uicolor ~* '^[0-9a-fA-F]{8}$'),
	icon UUID NOT NULL REFERENCES loot_source_icons(object_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	sort INTEGER NOT NULL UNIQUE,
	experimental BOOLEAN NOT NULL DEFAULT FALSE,
	notes TEXT NOT NULL DEFAULT '',
	requirements JSONB NOT NULL DEFAULT '{}',
	CHECK (class_string LIKE '%_C')
) INHERITS (objects);
GRANT SELECT ON TABLE loot_sources TO thezaz_website;
CREATE TRIGGER loot_sources_before_insert_trigger BEFORE INSERT ON loot_sources FOR EACH ROW EXECUTE PROCEDURE object_insert_trigger();
CREATE TRIGGER loot_sources_before_update_trigger BEFORE UPDATE ON loot_sources FOR EACH ROW EXECUTE PROCEDURE object_update_trigger();
CREATE TRIGGER loot_sources_after_delete_trigger AFTER DELETE ON loot_sources FOR EACH ROW EXECUTE PROCEDURE object_delete_trigger();
-- End Loot Sources

-- Engrams: Any item that can find its way into a loot source.
-- Note: uses custom delete trigger to track the path for legacy versions.
CREATE TABLE engrams (
	PRIMARY KEY (object_id),
	FOREIGN KEY (mod_id) REFERENCES mods(mod_id) ON DELETE CASCADE ON UPDATE CASCADE,
	path CITEXT NOT NULL UNIQUE,
	class_string CITEXT NOT NULL,
	availability INTEGER NOT NULL DEFAULT 0,
	can_blueprint BOOLEAN NOT NULL DEFAULT TRUE,
	CHECK (path LIKE '/%')
) INHERITS (objects);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE engrams TO thezaz_website;
CREATE OR REPLACE FUNCTION engram_delete_trigger () RETURNS TRIGGER AS $$
BEGIN
	EXECUTE 'INSERT INTO deletions (object_id, from_table, label, min_version, tag) VALUES ($1, $2, $3, $4, $5);' USING OLD.object_id, TG_TABLE_NAME, OLD.label, OLD.min_version, OLD.path;
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE UNIQUE INDEX engrams_classstring_mod_id_uidx ON engrams(class_string, mod_id);
CREATE TRIGGER engrams_before_insert_trigger BEFORE INSERT ON engrams FOR EACH ROW EXECUTE PROCEDURE object_insert_trigger();
CREATE TRIGGER engrams_before_update_trigger BEFORE UPDATE ON engrams FOR EACH ROW EXECUTE PROCEDURE object_update_trigger();
CREATE TRIGGER engrams_after_delete_trigger AFTER DELETE ON engrams FOR EACH ROW EXECUTE PROCEDURE engram_delete_trigger();
CREATE TRIGGER engrams_compute_class_trigger BEFORE INSERT OR UPDATE ON engrams FOR EACH ROW EXECUTE PROCEDURE compute_class_trigger();
-- End Engrams

-- Diets: Creatures each a variety of foods, this isn't just carnivores vs herbivores.
CREATE TABLE diets (
	PRIMARY KEY (object_id),
	FOREIGN KEY (mod_id) REFERENCES mods(mod_id) ON DELETE CASCADE ON UPDATE CASCADE
) INHERITS (objects);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE diets TO thezaz_website;
CREATE TRIGGER diets_before_insert_trigger BEFORE INSERT ON diets FOR EACH ROW EXECUTE PROCEDURE object_insert_trigger();
CREATE TRIGGER diets_before_update_trigger BEFORE UPDATE ON diets FOR EACH ROW EXECUTE PROCEDURE object_update_trigger();
CREATE TRIGGER diets_after_delete_trigger AFTER DELETE ON diets FOR EACH ROW EXECUTE PROCEDURE object_delete_trigger();

CREATE TABLE diet_contents (
	diet_entry_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	diet_id UUID NOT NULL REFERENCES diets(object_id) ON DELETE CASCADE ON UPDATE CASCADE,
	engram_id UUID NOT NULL REFERENCES engrams(object_id) ON DELETE CASCADE ON UPDATE CASCADE,
	preference_order INTEGER NOT NULL,
	UNIQUE (diet_id, preference_order),
	UNIQUE (diet_id, engram_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE diet_contents TO thezaz_website;
-- End Diets

-- Creatures: Complete list of all creatures on Ark. Detailed, but not wiki-detailed.
CREATE TABLE creatures (
	PRIMARY KEY (object_id),
	FOREIGN KEY (mod_id) REFERENCES mods(mod_id) ON DELETE CASCADE ON UPDATE CASCADE,
	path CITEXT NOT NULL UNIQUE,
	class_string CITEXT NOT NULL,
	availability INTEGER NOT NULL,
	tamable BOOLEAN NOT NULL,
	taming_diet UUID REFERENCES diets(object_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	taming_method taming_methods NOT NULL,
	tamed_diet UUID REFERENCES diets(object_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	rideable BOOLEAN NOT NULL,
	carryable BOOLEAN NOT NULL,
	breedable BOOLEAN NOT NULL,
	CHECK (path LIKE '/%')
) INHERITS (objects);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE creatures TO thezaz_website;
CREATE UNIQUE INDEX creatures_classstring_mod_id_uidx ON creatures(class_string, mod_id);
CREATE TRIGGER creatures_before_insert_trigger BEFORE INSERT ON creatures FOR EACH ROW EXECUTE PROCEDURE object_insert_trigger();
CREATE TRIGGER creatures_before_update_trigger BEFORE UPDATE ON creatures FOR EACH ROW EXECUTE PROCEDURE object_update_trigger();
CREATE TRIGGER creatures_after_delete_trigger AFTER DELETE ON creatures FOR EACH ROW EXECUTE PROCEDURE object_delete_trigger();
CREATE TRIGGER creatures_compute_class_trigger BEFORE INSERT OR UPDATE ON creatures FOR EACH ROW EXECUTE PROCEDURE compute_class_trigger();
-- End Creatures

-- Creature Engrams: Saddles, produced items, drops, eggs, kibble, etc. but not the stuff eaten by the creature.
CREATE TABLE creature_engrams (
	relation_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	creature_id UUID NOT NULL REFERENCES creatures(object_id) ON DELETE CASCADE ON UPDATE CASCADE,
	engram_id UUID NOT NULL REFERENCES engrams(object_id) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE (creature_id, engram_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE creature_engrams TO thezaz_website;
-- End Creature Engrams

-- Computed Engram Availabilities
-- Use like SELECT object_id, bit_or(availability) FROM computed_engram_availabilities GROUP BY object_id;
CREATE VIEW computed_engram_availabilities AS SELECT engrams.object_id, engrams.class_string, creatures.availability FROM creature_engrams, creatures, engrams WHERE creature_engrams.creature_id = creatures.object_id AND creature_engrams.engram_id = engrams.object_id;
GRANT SELECT ON TABLE computed_engram_availabilities TO thezaz_website;

-- Presets
CREATE TABLE presets (
	PRIMARY KEY (object_id),
	FOREIGN KEY (mod_id) REFERENCES mods(mod_id) ON DELETE CASCADE ON UPDATE CASCADE,
	contents JSONB NOT NULL
) INHERITS (objects);
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE presets TO thezaz_website;

CREATE OR REPLACE FUNCTION presets_json_sync_function () RETURNS TRIGGER AS $$
BEGIN
	NEW.label = NEW.contents->>'Label';
	NEW.object_id = (NEW.contents->>'ID')::UUID;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER presets_before_insert_trigger BEFORE INSERT ON presets FOR EACH ROW EXECUTE PROCEDURE object_insert_trigger();
CREATE TRIGGER presets_before_update_trigger BEFORE UPDATE ON presets FOR EACH ROW EXECUTE PROCEDURE object_update_trigger();
CREATE TRIGGER presets_after_delete_trigger AFTER DELETE ON presets FOR EACH ROW EXECUTE PROCEDURE object_delete_trigger();
CREATE TRIGGER presets_json_sync_trigger BEFORE INSERT OR UPDATE ON presets FOR EACH ROW EXECUTE PROCEDURE presets_json_sync_function();

CREATE TABLE preset_modifiers (
	PRIMARY KEY (object_id),
	FOREIGN KEY (mod_id) REFERENCES mods(mod_id) ON DELETE CASCADE ON UPDATE CASCADE,
	pattern TEXT NOT NULL UNIQUE
) INHERITS (objects);
GRANT SELECT ON TABLE preset_modifiers TO thezaz_website;

CREATE TRIGGER preset_modifiers_before_insert_trigger BEFORE INSERT ON preset_modifiers FOR EACH ROW EXECUTE PROCEDURE object_insert_trigger();
CREATE TRIGGER preset_modifiers_before_update_trigger BEFORE UPDATE ON preset_modifiers FOR EACH ROW EXECUTE PROCEDURE object_update_trigger();
CREATE TRIGGER preset_modifiers_after_delete_trigger AFTER DELETE ON preset_modifiers FOR EACH ROW EXECUTE PROCEDURE object_delete_trigger();
-- End Presets

-- Articles
CREATE TYPE article_type AS ENUM (
	'Blog',
	'Help'
);

CREATE TABLE articles (
	article_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	publish_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	last_update TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	title TEXT NOT NULL,
	body TEXT NOT NULL,
	type article_type NOT NULL
);
GRANT SELECT ON TABLE articles TO thezaz_website;
-- End Articles

-- Blueprints
CREATE OR REPLACE VIEW blueprints AS (SELECT object_id, label, tableoid, min_version, last_update, mod_id, path, class_string, availability FROM creatures) UNION (SELECT object_id, label, tableoid, min_version, last_update, mod_id, path, class_string, availability FROM engrams) UNION (SELECT object_id, label, tableoid, min_version, last_update, mod_id, path, class_string, availability FROM loot_sources);
GRANT SELECT ON TABLE blueprints TO thezaz_website;
-- End Blueprints

-- Search
CREATE OR REPLACE VIEW search_contents AS (SELECT article_id AS id, title, body, setweight(to_tsvector(title), 'A') || ' ' || setweight(to_tsvector(body), 'B') AS lexemes, 'Article' AS type, '/read/' || article_id AS uri FROM articles) UNION (SELECT object_id AS id, label AS title, '' AS body, setweight(to_tsvector(label), 'A') AS lexemes, 'Object' AS type, '/object/' || class_string AS uri FROM blueprints) UNION (SELECT mod_id AS id, name AS title, '' AS body, setweight(to_tsvector(name), 'C') AS lexemes, 'Mod' AS type, '/mods/info.php?mod_id=' || mod_id AS uri FROM mods WHERE confirmed = TRUE) UNION (SELECT document_id, title, description AS body, setweight(to_tsvector(title), 'A') || ' ' || setweight(to_tsvector(description), 'B') AS lexemes, 'Document' AS type, '/browse/' || document_id AS uri FROM documents WHERE published = 'Approved');
GRANT SELECT ON TABLE search_contents TO thezaz_website;
-- End Search

-- Config Help Topics
CREATE TABLE help_topics (
	config_name CITEXT NOT NULL PRIMARY KEY,
	title TEXT NOT NULL,
	body TEXT NOT NULL,
	detail_url TEXT NOT NULL DEFAULT '',
	last_update TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP(0)
);
GRANT SELECT ON TABLE help_topics TO thezaz_website;

CREATE OR REPLACE FUNCTION generic_update_trigger () RETURNS TRIGGER AS $$
BEGIN
	NEW.last_update = CURRENT_TIMESTAMP(0);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER help_topics_before_update_trigger BEFORE INSERT OR UPDATE ON help_topics FOR EACH ROW EXECUTE PROCEDURE generic_update_trigger();
-- End Config Help Topics

-- Client Notices
CREATE TABLE client_notices (
	notice_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	message TEXT NOT NULL,
	secondary_message TEXT NOT NULL,
	action_url TEXT NOT NULL,
	min_version INTEGER,
	max_version INTEGER,
	last_update TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP(0)
);
GRANT SELECT ON TABLE client_notices TO thezaz_website;

CREATE TRIGGER client_notices_before_update_trigger BEFORE INSERT OR UPDATE ON client_notices FOR EACH ROW EXECUTE PROCEDURE generic_update_trigger();
-- End Client Notices

-- Exception Reporting
CREATE TABLE exceptions (
	exception_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	exception_hash HEX NOT NULL,
	exception_type CITEXT NOT NULL CHECK (TRIM(both FROM exception_type) != ''),
	build INTEGER NOT NULL CHECK (build >= 34),
	reason CITEXT NOT NULL,
	location CITEXT NOT NULL,
	trace CITEXT NOT NULL,
	solution_details TEXT,
	solution_min_build INTEGER,
	CHECK((solution_details IS NULL AND solution_min_build IS NULL) OR (solution_details IS NOT NULL AND solution_min_build >= 34))
);
GRANT SELECT, INSERT ON exceptions TO thezaz_website;
CREATE UNIQUE INDEX exceptions_exception_hash_build_uidx ON exceptions (exception_hash, build);

CREATE TABLE exception_comments (
	comment_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	exception_hash HEX NOT NULL,
	build INTEGER NOT NULL,
	comments TEXT NOT NULL,
	date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (exception_hash, build) REFERENCES exceptions (exception_hash, build) ON DELETE CASCADE ON UPDATE CASCADE
);
GRANT INSERT ON exception_comments TO thezaz_website;
-- End Exception Reporting

-- Game Variables
CREATE TABLE game_variables (
	key TEXT NOT NULL PRIMARY KEY,
	value TEXT NOT NULL,
	last_update TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
GRANT SELECT ON game_variables TO thezaz_website;

CREATE TRIGGER game_variables_before_update_trigger BEFORE INSERT OR UPDATE ON game_variables FOR EACH ROW EXECUTE PROCEDURE generic_update_trigger();
-- End Game Variables

-- Omni purchases
CREATE TABLE products (
	product_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	product_name TEXT NOT NULL,
	retail_price NUMERIC(6,2) NOT NULL,
	stripe_sku TEXT NOT NULL UNIQUE
);
GRANT SELECT ON products TO thezaz_website;
INSERT INTO products(product_id, product_name, retail_price, stripe_sku) VALUES ('972f9fc5-ad64-4f9c-940d-47062e705cc5', 'Omni', 10, 'sku_E5V8BaWFlmvLGG');

CREATE TABLE purchases (
	purchase_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	purchaser_email UUID NOT NULL REFERENCES email_addresses(email_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	purchase_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	subtotal NUMERIC(6,2) NOT NULL,
	discount NUMERIC(6,2) NOT NULL,
	tax NUMERIC(6,2) NOT NULL,
	total_paid NUMERIC(6,2) NOT NULL,
	merchant_reference CITEXT NOT NULL UNIQUE,
	client_reference_id TEXT
);
CREATE INDEX purchases_purchaser_email_idx ON purchases(purchaser_email);
GRANT SELECT, INSERT ON purchases TO thezaz_website;

CREATE TABLE purchase_items (
	line_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	purchase_id UUID NOT NULL REFERENCES purchases(purchase_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
	product_id UUID NOT NULL REFERENCES products(product_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	retail_price NUMERIC(6,2) NOT NULL,
	discount NUMERIC(6,2) NOT NULL,
	line_total NUMERIC(6,2) NOT NULL
);
GRANT SELECT, INSERT ON purchase_items TO thezaz_website;

CREATE VIEW purchased_products AS SELECT products.product_id, products.product_name, purchases.purchaser_email FROM purchases INNER JOIN (purchase_items INNER JOIN products ON (purchase_items.product_id = products.product_id)) ON (purchase_items.purchase_id = purchases.purchase_id);
GRANT SELECT ON purchased_products TO thezaz_website;
-- End Omni purchases
