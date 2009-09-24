-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Wed Sep 23 21:47:18 2009
-- 
--
-- Table: bali_baseline
--
DROP TABLE "bali_baseline" CASCADE;
CREATE TABLE "bali_baseline" (
  "id" bigint NOT NULL,
  "bl" character varying(100) NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" character varying(1024),
  PRIMARY KEY ("id")
);

--
-- Table: bali_calendar
--
DROP TABLE "bali_calendar" CASCADE;
CREATE TABLE "bali_calendar" (
  "id" bigint NOT NULL,
  "name" character varying(100) NOT NULL,
  "ns" character varying(100) DEFAULT ''/'                   ' NOT NULL,
  "bl" character varying(100) DEFAULT ''*'                   ' NOT NULL,
  "description" character varying(1024),
  PRIMARY KEY ("id")
);

--
-- Table: bali_chain
--
DROP TABLE "bali_chain" CASCADE;
CREATE TABLE "bali_chain" (
  "id" bigint NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" character varying(2000) NOT NULL,
  "job_type" character varying(50),
  "active" bigint DEFAULT '1',
  "action" character varying(255),
  "ns" character varying(1024) DEFAULT ''/'',
  "bl" character varying(50) DEFAULT ''*'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_chained_service
--
DROP TABLE "bali_chained_service" CASCADE;
CREATE TABLE "bali_chained_service" (
  "id" bigint NOT NULL,
  "chain_id" bigint NOT NULL,
  "seq" bigint NOT NULL,
  "key" character varying(255) NOT NULL,
  "description" character varying(2000),
  "step" character varying(50) DEFAULT ''RUN'',
  "active" bigint DEFAULT '1',
  PRIMARY KEY ("id")
);

--
-- Table: bali_commonfiles
--
DROP TABLE "bali_commonfiles" CASCADE;
CREATE TABLE "bali_commonfiles" (
  "id" bigint NOT NULL,
  "nombre" character varying(64) NOT NULL,
  "tipo" character(1) NOT NULL,
  "descripcion" character varying(4000),
  "ns" character varying(100) DEFAULT ''/'                   ' NOT NULL,
  "bl" character varying(100) DEFAULT ''*'                   ' NOT NULL,
  "f_alta" date DEFAULT 'SYSDATE',
  "f_baja" date,
  PRIMARY KEY ("id")
);

--
-- Table: bali_config
--
DROP TABLE "bali_config" CASCADE;
CREATE TABLE "bali_config" (
  "id" bigint NOT NULL,
  "ns" character varying(1000) DEFAULT ''/'                   ' NOT NULL,
  "bl" character varying(100) DEFAULT ''*'                   ' NOT NULL,
  "key" character varying(100) NOT NULL,
  "value" character varying(100) DEFAULT NULL,
  "ts" date DEFAULT 'SYSDATE               ' NOT NULL,
  "ref" bigint,
  "reftable" character varying(100),
  "data" bytea,
  "parent_id" bigint DEFAULT '0                     ' NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_config_rel
--
DROP TABLE "bali_config_rel" CASCADE;
CREATE TABLE "bali_config_rel" (
  "id" integer NOT NULL,
  "namespace_id" integer NOT NULL,
  "plugin_id" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_configset
--
DROP TABLE "bali_configset" CASCADE;
CREATE TABLE "bali_configset" (
  "id" integer NOT NULL,
  "namespace_id" integer NOT NULL,
  "baseline_id" integer NOT NULL,
  "wiki_id" integer NOT NULL,
  "created_on" timestamp(6) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_daemon
--
DROP TABLE "bali_daemon" CASCADE;
CREATE TABLE "bali_daemon" (
  "id" bigint NOT NULL,
  "service" character varying(255),
  "active" bigint DEFAULT '1',
  "config" character varying(255),
  "pid" bigint,
  "params" character varying(1024),
  "hostname" character varying(255) DEFAULT ''localhost'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_file_dist
--
DROP TABLE "bali_file_dist" CASCADE;
CREATE TABLE "bali_file_dist" (
  "id" bigint NOT NULL,
  "ns" character varying(1000) DEFAULT ''/'                 ' NOT NULL,
  "bl" character varying(100) DEFAULT ''*'                 ' NOT NULL,
  "filter" character varying(256) DEFAULT ''*.*'    ',
  "isrecursive" smallint DEFAULT '0    ',
  "src_dir" character varying(100) DEFAULT ''.'     ' NOT NULL,
  "dest_dir" character varying(100) NOT NULL,
  "ssh_host" character varying(100) NOT NULL,
  "xtype" character varying(16),
  PRIMARY KEY ("id")
);

--
-- Table: bali_message
--
DROP TABLE "bali_message" CASCADE;
CREATE TABLE "bali_message" (
  "id" bigint NOT NULL,
  "subject" character varying(1024) NOT NULL,
  "body" clob,
  "created" date DEFAULT 'SYSDATE',
  "active" bigint DEFAULT '1',
  "attach" bytea,
  "sender" character varying(255),
  "content_type" character varying(50),
  "attach_content_type" character varying(50),
  "attach_filename" character varying(255),
  PRIMARY KEY ("id")
);

--
-- Table: bali_namespace
--
DROP TABLE "bali_namespace" CASCADE;
CREATE TABLE "bali_namespace" (
  "id" bigint NOT NULL,
  "ns" character varying(100) NOT NULL,
  "provider" character varying(500),
  PRIMARY KEY ("id")
);

--
-- Table: bali_plugin
--
DROP TABLE "bali_plugin" CASCADE;
CREATE TABLE "bali_plugin" (
  "id" integer NOT NULL,
  "plugin" character varying(250) NOT NULL,
  "desc_" character varying(500) NOT NULL,
  "wiki_id" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_provider
--
DROP TABLE "bali_provider" CASCADE;
CREATE TABLE "bali_provider" (
  "id" integer NOT NULL,
  "plugin" character varying(250) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_release
--
DROP TABLE "bali_release" CASCADE;
CREATE TABLE "bali_release" (
  "id" bigint NOT NULL,
  "name" character varying(255) NOT NULL,
  "description" character varying(2000),
  "active" character(1) DEFAULT '1                     ' NOT NULL,
  "ts" date DEFAULT 'SYSDATE',
  "bl" character varying(100) DEFAULT ''*'                   ' NOT NULL,
  "username" character varying(255),
  PRIMARY KEY ("id")
);

--
-- Table: bali_request
--
DROP TABLE "bali_request" CASCADE;
CREATE TABLE "bali_request" (
  "id" bigint NOT NULL,
  "ns" character varying(1024) NOT NULL,
  "bl" character varying(50) DEFAULT ''*'',
  "requested_on" date,
  "finished_on" date,
  "status" character varying(50) DEFAULT ''pending'',
  "finished_by" character varying(255),
  "requested_by" character varying(255),
  "action" character varying(255),
  "id_parent" bigint,
  "key" character varying(255),
  "name" character varying(255),
  "type" character varying(100) DEFAULT ''approval'',
  PRIMARY KEY ("id")
);

--
-- Table: bali_role
--
DROP TABLE "bali_role" CASCADE;
CREATE TABLE "bali_role" (
  "id" bigint NOT NULL,
  "role" character varying(255) NOT NULL,
  "description" character varying(2048),
  PRIMARY KEY ("id")
);

--
-- Table: bali_service
--
DROP TABLE "bali_service" CASCADE;
CREATE TABLE "bali_service" (
  "id" integer NOT NULL,
  "name" character varying(100) NOT NULL,
  "desc_" character varying(100) NOT NULL,
  "wiki_id" integer NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_ssh_script
--
DROP TABLE "bali_ssh_script" CASCADE;
CREATE TABLE "bali_ssh_script" (
  "id" bigint NOT NULL,
  "ns" character varying(1000) DEFAULT ''/'                 ' NOT NULL,
  "bl" character varying(100) DEFAULT ''*'                 ' NOT NULL,
  "script" character varying(100) NOT NULL,
  "params" character varying(1000) NOT NULL,
  "ssh_host" character varying(100) NOT NULL,
  "xorder" smallint DEFAULT '1',
  PRIMARY KEY ("id")
);

--
-- Table: bali_user
--
DROP TABLE "bali_user" CASCADE;
CREATE TABLE "bali_user" (
  "id" integer NOT NULL,
  "username" character varying(45) NOT NULL,
  "password" character varying(45) NOT NULL,
  PRIMARY KEY ("id")
);

--
-- Table: bali_wiki
--
DROP TABLE "bali_wiki" CASCADE;
CREATE TABLE "bali_wiki" (
  "id" bigint NOT NULL,
  "text" clob,
  "username" character varying(255),
  "modified_on" date DEFAULT 'SYSDATE',
  "content_type" character varying(255) DEFAULT ''text/plain'
',
  "id_wiki" bigint,
  PRIMARY KEY ("id")
);

--
-- Table: bali_calendar_window
--
DROP TABLE "bali_calendar_window" CASCADE;
CREATE TABLE "bali_calendar_window" (
  "id" bigint DEFAULT '1                     ' NOT NULL,
  "start_time" character varying(20),
  "end_time" character varying(20),
  "day" character varying(20),
  "type" character varying(1),
  "active" character varying(1) DEFAULT ''1'',
  "id_cal" bigint DEFAULT '1                     ' NOT NULL,
  "start_date" date,
  "end_date" date,
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_calendar_window_idx_id_cal" on "bali_calendar_window" ("id_cal");

--
-- Table: bali_commonfiles_values
--
DROP TABLE "bali_commonfiles_values" CASCADE;
CREATE TABLE "bali_commonfiles_values" (
  "fileid" bigint NOT NULL,
  "id" bigint NOT NULL,
  "clave" character varying(256) NOT NULL,
  "valor" character varying(4000) NOT NULL,
  "secordesc" character varying(1024) NOT NULL,
  "ns" character varying(100) DEFAULT ''/'                   ' NOT NULL,
  "bl" character varying(100) DEFAULT ''*'                   ' NOT NULL,
  "f_alta" date DEFAULT 'SYSDATE',
  "f_baja" date DEFAULT 'TO_DATE('99991231','yyyymmdd') 
',
  PRIMARY KEY ("fileid", "id")
);
CREATE INDEX "bali_commonfiles_values_idx_fileid" on "bali_commonfiles_values" ("fileid");

--
-- Table: bali_job
--
DROP TABLE "bali_job" CASCADE;
CREATE TABLE "bali_job" (
  "id" bigint NOT NULL,
  "name" character varying(45),
  "starttime" date DEFAULT 'SYSDATE               ' NOT NULL,
  "maxstarttime" date DEFAULT 'SYSDATE+1             ' NOT NULL,
  "endtime" date,
  "status" character varying(45) DEFAULT ''READY'               ' NOT NULL,
  "ns" character varying(45) DEFAULT ''/'                   ' NOT NULL,
  "bl" character varying(45) DEFAULT ''*'                   ' NOT NULL,
  "runner" character varying(255),
  "pid" bigint,
  "comments" character varying(1024),
  "type" character varying(100),
  "username" character varying(255),
  "ts" date DEFAULT 'SYSDATE
',
  "host" character varying(255) DEFAULT ''localhost'',
  "owner" character varying(255),
  "step" character varying(50) DEFAULT ''PRE'',
  "id_stash" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_job_idx_id_stash" on "bali_job" ("id_stash");

--
-- Table: bali_job_stash
--
DROP TABLE "bali_job_stash" CASCADE;
CREATE TABLE "bali_job_stash" (
  "id" bigint NOT NULL,
  "stash" bytea,
  "id_job" bigint,
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_job_stash_idx_id_job" on "bali_job_stash" ("id_job");

--
-- Table: bali_message_queue
--
DROP TABLE "bali_message_queue" CASCADE;
CREATE TABLE "bali_message_queue" (
  "id" bigint NOT NULL,
  "id_message" bigint,
  "username" character varying(255),
  "destination" character varying(50),
  "sent" date DEFAULT 'SYSDATE',
  "received" date,
  "active" bigint DEFAULT '1',
  "carrier" character varying(50) DEFAULT ''instant'',
  "carrier_param" character varying(50),
  "result" clob,
  "attempts" bigint DEFAULT '0',
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_message_queue_idx_id_message" on "bali_message_queue" ("id_message");

--
-- Table: bali_relationship
--
DROP TABLE "bali_relationship" CASCADE;
CREATE TABLE "bali_relationship" (
  "from_id" bigint NOT NULL,
  "to_id" bigint NOT NULL,
  "type" character varying(45),
  PRIMARY KEY ("to_id", "from_id")
);
CREATE INDEX "bali_relationship_idx_from_id" on "bali_relationship" ("from_id");
CREATE INDEX "bali_relationship_idx_to_id" on "bali_relationship" ("to_id");

--
-- Table: bali_release_items
--
DROP TABLE "bali_release_items" CASCADE;
CREATE TABLE "bali_release_items" (
  "id" bigint NOT NULL,
  "id_rel" bigint NOT NULL,
  "item" character varying(1024),
  "provider" character varying(1024),
  "data" clob,
  "ns" character varying(255),
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_release_items_idx_id_rel" on "bali_release_items" ("id_rel");

--
-- Table: bali_roleaction
--
DROP TABLE "bali_roleaction" CASCADE;
CREATE TABLE "bali_roleaction" (
  "id_role" bigint NOT NULL,
  "action" character varying(255) NOT NULL,
  "bl" character varying(50) DEFAULT ''*'' NOT NULL,
  PRIMARY KEY ("action", "id_role", "bl")
);
CREATE INDEX "bali_roleaction_idx_id_role" on "bali_roleaction" ("id_role");

--
-- Table: bali_roleuser
--
DROP TABLE "bali_roleuser" CASCADE;
CREATE TABLE "bali_roleuser" (
  "username" character varying(255) NOT NULL,
  "id_role" bigint NOT NULL,
  "ns" character varying(100) DEFAULT ''/'                   ' NOT NULL,
  PRIMARY KEY ("username", "id_role")
);
CREATE INDEX "bali_roleuser_idx_id_role" on "bali_roleuser" ("id_role");

--
-- Table: bali_job_items
--
DROP TABLE "bali_job_items" CASCADE;
CREATE TABLE "bali_job_items" (
  "id" bigint NOT NULL,
  "data" clob,
  "item" character varying(1024),
  "provider" character varying(1024),
  "id_job" bigint NOT NULL,
  "service" character varying(255),
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_job_items_idx_id_job" on "bali_job_items" ("id_job");

--
-- Table: bali_log
--
DROP TABLE "bali_log" CASCADE;
CREATE TABLE "bali_log" (
  "id" bigint NOT NULL,
  "text" character varying(2048),
  "lev" character varying(10),
  "id_job" bigint NOT NULL,
  "more" character varying(10),
  "data" bytea,
  "ts" date DEFAULT 'SYSDATE',
  "ns" character varying(255) DEFAULT ''/'',
  "provider" character varying(255),
  "data_name" character varying(1024),
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_log_idx_id_job" on "bali_log" ("id_job");

--
-- Table: bali_scripts_in_file_dist
--
DROP TABLE "bali_scripts_in_file_dist" CASCADE;
CREATE TABLE "bali_scripts_in_file_dist" (
  "id" bigint NOT NULL,
  "file_dist_id" bigint NOT NULL,
  "script_id" bigint NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "bali_scripts_in_file_dist_idx_file_dist_id" on "bali_scripts_in_file_dist" ("file_dist_id");
CREATE INDEX "bali_scripts_in_file_dist_idx_script_id" on "bali_scripts_in_file_dist" ("script_id");

--
-- Foreign Key Definitions
--

ALTER TABLE "bali_calendar_window" ADD FOREIGN KEY ("id_cal")
  REFERENCES "bali_calendar" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_commonfiles_values" ADD FOREIGN KEY ("fileid")
  REFERENCES "bali_commonfiles" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_job" ADD FOREIGN KEY ("id_stash")
  REFERENCES "bali_job_stash" ("id") DEFERRABLE;

ALTER TABLE "bali_job_stash" ADD FOREIGN KEY ("id_job")
  REFERENCES "bali_job" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_message_queue" ADD FOREIGN KEY ("id_message")
  REFERENCES "bali_message" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_relationship" ADD FOREIGN KEY ("from_id")
  REFERENCES "bali_config" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_relationship" ADD FOREIGN KEY ("to_id")
  REFERENCES "bali_config" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_release_items" ADD FOREIGN KEY ("id_rel")
  REFERENCES "bali_release" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_roleaction" ADD FOREIGN KEY ("id_role")
  REFERENCES "bali_role" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_roleuser" ADD FOREIGN KEY ("id_role")
  REFERENCES "bali_role" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_job_items" ADD FOREIGN KEY ("id_job")
  REFERENCES "bali_job" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_log" ADD FOREIGN KEY ("id_job")
  REFERENCES "bali_job" ("id") DEFERRABLE;

ALTER TABLE "bali_scripts_in_file_dist" ADD FOREIGN KEY ("file_dist_id")
  REFERENCES "bali_file_dist" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "bali_scripts_in_file_dist" ADD FOREIGN KEY ("script_id")
  REFERENCES "bali_ssh_script" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

