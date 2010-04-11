-- 
-- Created by SQL::Translator::Producer::Oracle
-- Created on Wed Sep 23 21:47:18 2009
-- 
--
-- Table: bali_baseline
--;

DROP TABLE bali_baseline CASCADE CONSTRAINTS;

CREATE TABLE bali_baseline (
  id number(38) NOT NULL,
  bl varchar2(100) NOT NULL,
  name varchar2(255) NOT NULL,
  description varchar2(1024),
  PRIMARY KEY (id)
);

--
-- Table: bali_calendar
--;

DROP TABLE bali_calendar CASCADE CONSTRAINTS;

CREATE TABLE bali_calendar (
  id number(38) NOT NULL,
  name varchar2(100) NOT NULL,
  ns varchar2(100) DEFAULT ''/'                   ' NOT NULL,
  bl varchar2(100) DEFAULT ''*'                   ' NOT NULL,
  description varchar2(1024),
  PRIMARY KEY (id)
);

--
-- Table: bali_chain
--;

DROP TABLE bali_chain CASCADE CONSTRAINTS;

CREATE TABLE bali_chain (
  id number(38) NOT NULL,
  name varchar2(255) NOT NULL,
  description varchar2(2000) NOT NULL,
  job_type varchar2(50),
  active number(38) DEFAULT '1',
  action varchar2(255),
  ns varchar2(1024) DEFAULT ''/'',
  bl varchar2(50) DEFAULT ''*'',
  PRIMARY KEY (id)
);

--
-- Table: bali_chained_service
--;

DROP TABLE bali_chained_service CASCADE CONSTRAINTS;

CREATE TABLE bali_chained_service (
  id number(38) NOT NULL,
  chain_id number(38) NOT NULL,
  seq number(38) NOT NULL,
  key varchar2(255) NOT NULL,
  description varchar2(2000),
  step varchar2(50) DEFAULT ''RUN'',
  active number(38) DEFAULT '1',
  PRIMARY KEY (id)
);

--
-- Table: bali_commonfiles
--;

DROP TABLE bali_commonfiles CASCADE CONSTRAINTS;

CREATE TABLE bali_commonfiles (
  id number(38) NOT NULL,
  nombre varchar2(64) NOT NULL,
  tipo char(1) NOT NULL,
  descripcion varchar2(4000),
  ns varchar2(100) DEFAULT ''/'                   ' NOT NULL,
  bl varchar2(100) DEFAULT ''*'                   ' NOT NULL,
  f_alta date DEFAULT 'SYSDATE',
  f_baja date,
  PRIMARY KEY (id)
);

--
-- Table: bali_config
--;

DROP TABLE bali_config CASCADE CONSTRAINTS;

CREATE TABLE bali_config (
  id number(38) NOT NULL,
  ns varchar2(1000) DEFAULT ''/'                   ' NOT NULL,
  bl varchar2(100) DEFAULT ''*'                   ' NOT NULL,
  key varchar2(100) NOT NULL,
  value varchar2(100) DEFAULT NULL,
  ts date DEFAULT 'SYSDATE               ' NOT NULL,
  ref number(38),
  reftable varchar2(100),
  data blob(2147483647),
  parent_id number(38) DEFAULT '1' NOT NULL,
  PRIMARY KEY (id)
);

--
-- Table: bali_config_rel
--;

DROP TABLE bali_config_rel CASCADE CONSTRAINTS;

CREATE TABLE bali_config_rel (
  id number NOT NULL,
  namespace_id number(10) NOT NULL,
  plugin_id number(10) NOT NULL,
  PRIMARY KEY (id)
);

--
-- Table: bali_configset
--;

DROP TABLE bali_configset CASCADE CONSTRAINTS;

CREATE TABLE bali_configset (
  id number NOT NULL,
  namespace_id number(10) NOT NULL,
  baseline_id number(10) NOT NULL,
  wiki_id number(10) NOT NULL,
  created_on date NOT NULL,
  PRIMARY KEY (id)
);

--
-- Table: bali_daemon
--;

DROP TABLE bali_daemon CASCADE CONSTRAINTS;

CREATE TABLE bali_daemon (
  id number(38) NOT NULL,
  service varchar2(255),
  active number(38) DEFAULT '1',
  config varchar2(255),
  pid number(38),
  params varchar2(1024),
  hostname varchar2(255) DEFAULT ''localhost'',
  PRIMARY KEY (id)
);

--
-- Table: bali_file_dist
--;

DROP TABLE bali_file_dist CASCADE CONSTRAINTS;

CREATE TABLE bali_file_dist (
  id number(38) NOT NULL,
  ns varchar2(1000) DEFAULT ''/'                 ' NOT NULL,
  bl varchar2(100) DEFAULT ''*'                 ' NOT NULL,
  filter varchar2(256) DEFAULT ''*.*'    ',
  isrecursive number(1) DEFAULT '1',
  src_dir varchar2(100) DEFAULT ''.'     ' NOT NULL,
  dest_dir varchar2(100) NOT NULL,
  ssh_host varchar2(100) NOT NULL,
  xtype varchar2(16),
  PRIMARY KEY (id)
);

--
-- Table: bali_message
--;

DROP TABLE bali_message CASCADE CONSTRAINTS;

CREATE TABLE bali_message (
  id number(38) NOT NULL,
  subject varchar2(1024) NOT NULL,
  body clob,
  created date DEFAULT 'SYSDATE',
  active number(38) DEFAULT '1',
  attach blob(2147483647),
  sender varchar2(255),
  content_type varchar2(50),
  attach_content_type varchar2(50),
  attach_filename varchar2(255),
  PRIMARY KEY (id)
);

--
-- Table: bali_namespace
--;

DROP TABLE bali_namespace CASCADE CONSTRAINTS;

CREATE TABLE bali_namespace (
  id number(38) NOT NULL,
  ns varchar2(100) NOT NULL,
  provider varchar2(500),
  PRIMARY KEY (id)
);

--
-- Table: bali_plugin
--;

DROP TABLE bali_plugin CASCADE CONSTRAINTS;

CREATE TABLE bali_plugin (
  id number NOT NULL,
  plugin varchar2(250) NOT NULL,
  desc_ varchar2(500) NOT NULL,
  wiki_id number(10) NOT NULL,
  PRIMARY KEY (id)
);

--
-- Table: bali_provider
--;

DROP TABLE bali_provider CASCADE CONSTRAINTS;

CREATE TABLE bali_provider (
  id number NOT NULL,
  plugin varchar2(250) NOT NULL,
  PRIMARY KEY (id)
);

--
-- Table: bali_release
--;

DROP TABLE bali_release CASCADE CONSTRAINTS;

CREATE TABLE bali_release (
  id number(38) NOT NULL,
  name varchar2(255) NOT NULL,
  description varchar2(2000),
  active char(1) DEFAULT '1                     ' NOT NULL,
  ts date DEFAULT 'SYSDATE',
  bl varchar2(100) DEFAULT ''*'                   ' NOT NULL,
  username varchar2(255),
  PRIMARY KEY (id)
);

--
-- Table: bali_request
--;

DROP TABLE bali_request CASCADE CONSTRAINTS;

CREATE TABLE bali_request (
  id number(38) NOT NULL,
  ns varchar2(1024) NOT NULL,
  bl varchar2(50) DEFAULT ''*'',
  requested_on date,
  finished_on date,
  status varchar2(50) DEFAULT ''pending'',
  finished_by varchar2(255),
  requested_by varchar2(255),
  action varchar2(255),
  id_parent number(38),
  key varchar2(255),
  name varchar2(255),
  type varchar2(100) DEFAULT ''approval'',
  PRIMARY KEY (id)
);

--
-- Table: bali_role
--;

DROP TABLE bali_role CASCADE CONSTRAINTS;

CREATE TABLE bali_role (
  id number(38) NOT NULL,
  role varchar2(255) NOT NULL,
  description varchar2(2048),
  PRIMARY KEY (id)
);

--
-- Table: bali_service
--;

DROP TABLE bali_service CASCADE CONSTRAINTS;

CREATE TABLE bali_service (
  id number NOT NULL,
  name varchar2(100) NOT NULL,
  desc_ varchar2(100) NOT NULL,
  wiki_id number(10) NOT NULL,
  PRIMARY KEY (id)
);

--
-- Table: bali_ssh_script
--;

DROP TABLE bali_ssh_script CASCADE CONSTRAINTS;

CREATE TABLE bali_ssh_script (
  id number(38) NOT NULL,
  ns varchar2(1000) DEFAULT ''/'                 ' NOT NULL,
  bl varchar2(100) DEFAULT ''*'                 ' NOT NULL,
  script varchar2(100) NOT NULL,
  params varchar2(1000) NOT NULL,
  ssh_host varchar2(100) NOT NULL,
  xorder number(1) DEFAULT '1',
  PRIMARY KEY (id)
);

--
-- Table: bali_user
--;

DROP TABLE bali_user CASCADE CONSTRAINTS;

CREATE TABLE bali_user (
  id number NOT NULL,
  username varchar2(45) NOT NULL,
  password varchar2(45) NOT NULL,
  PRIMARY KEY (id)
);

--
-- Table: bali_wiki
--;

DROP TABLE bali_wiki CASCADE CONSTRAINTS;

CREATE TABLE bali_wiki (
  id number(38) NOT NULL,
  text clob,
  username varchar2(255),
  modified_on date DEFAULT 'SYSDATE',
  content_type varchar2(255) DEFAULT ''text/plain'
',
  id_wiki number(38),
  PRIMARY KEY (id)
);

--
-- Table: bali_calendar_window
--;

DROP TABLE bali_calendar_window CASCADE CONSTRAINTS;

CREATE TABLE bali_calendar_window (
  id number(38) DEFAULT '1' NOT NULL,
  start_time varchar2(20),
  end_time varchar2(20),
  day varchar2(20),
  type varchar2(1),
  active varchar2(1) DEFAULT ''1'',
  id_cal number(38) DEFAULT '1' NOT NULL,
  start_date date,
  end_date date,
  PRIMARY KEY (id)
);

--
-- Table: bali_commonfiles_values
--;

DROP TABLE bali_commonfiles_values CASCADE CONSTRAINTS;

CREATE TABLE bali_commonfiles_values (
  fileid number(38) NOT NULL,
  id number(38) NOT NULL,
  clave varchar2(256) NOT NULL,
  valor varchar2(4000) NOT NULL,
  secordesc varchar2(1024) NOT NULL,
  ns varchar2(100) DEFAULT ''/'                   ' NOT NULL,
  bl varchar2(100) DEFAULT ''*'                   ' NOT NULL,
  f_alta date DEFAULT 'SYSDATE',
  f_baja date DEFAULT 'TO_DATE('99991231','yyyymmdd') 
',
  PRIMARY KEY (fileid, id)
);

--
-- Table: bali_job
--;

DROP TABLE bali_job CASCADE CONSTRAINTS;

CREATE TABLE bali_job (
  id number(38) NOT NULL,
  name varchar2(45),
  starttime date DEFAULT 'SYSDATE               ' NOT NULL,
  maxstarttime date DEFAULT 'SYSDATE+1             ' NOT NULL,
  endtime date,
  status varchar2(45) DEFAULT ''READY'               ' NOT NULL,
  ns varchar2(45) DEFAULT ''/'                   ' NOT NULL,
  bl varchar2(45) DEFAULT ''*'                   ' NOT NULL,
  runner varchar2(255),
  pid number(38),
  comments varchar2(1024),
  type varchar2(100),
  username varchar2(255),
  ts date DEFAULT 'SYSDATE
',
  host varchar2(255) DEFAULT ''localhost'',
  owner varchar2(255),
  step varchar2(50) DEFAULT ''PRE'',
  id_stash number(38),
  PRIMARY KEY (id)
);

--
-- Table: bali_job_stash
--;

DROP TABLE bali_job_stash CASCADE CONSTRAINTS;

CREATE TABLE bali_job_stash (
  id number(38) NOT NULL,
  stash blob(2147483647),
  id_job number(38),
  PRIMARY KEY (id)
);

--
-- Table: bali_message_queue
--;

DROP TABLE bali_message_queue CASCADE CONSTRAINTS;

CREATE TABLE bali_message_queue (
  id number(38) NOT NULL,
  id_message number(38),
  username varchar2(255),
  destination varchar2(50),
  sent date DEFAULT 'SYSDATE',
  received date,
  active number(38) DEFAULT '1',
  carrier varchar2(50) DEFAULT ''instant'',
  carrier_param varchar2(50),
  result clob,
  attempts number(38) DEFAULT '0',
  PRIMARY KEY (id)
);

--
-- Table: bali_relationship
--;

DROP TABLE bali_relationship CASCADE CONSTRAINTS;

CREATE TABLE bali_relationship (
  from_id number(38) NOT NULL,
  to_id number(38) NOT NULL,
  type varchar2(45),
  PRIMARY KEY (to_id, from_id)
);

--
-- Table: bali_release_items
--;

DROP TABLE bali_release_items CASCADE CONSTRAINTS;

CREATE TABLE bali_release_items (
  id number(38) NOT NULL,
  id_rel number(38) NOT NULL,
  item varchar2(1024),
  provider varchar2(1024),
  data clob,
  ns varchar2(255),
  PRIMARY KEY (id)
);

--
-- Table: bali_roleaction
--;

DROP TABLE bali_roleaction CASCADE CONSTRAINTS;

CREATE TABLE bali_roleaction (
  id_role number(38) NOT NULL,
  action varchar2(255) NOT NULL,
  bl varchar2(50) DEFAULT ''*'' NOT NULL,
  PRIMARY KEY (action, id_role, bl)
);

--
-- Table: bali_roleuser
--;

DROP TABLE bali_roleuser CASCADE CONSTRAINTS;

CREATE TABLE bali_roleuser (
  username varchar2(255) NOT NULL,
  id_role number(38) NOT NULL,
  ns varchar2(100) DEFAULT ''/'                   ' NOT NULL,
  PRIMARY KEY (username, id_role)
);

--
-- Table: bali_job_items
--;

DROP TABLE bali_job_items CASCADE CONSTRAINTS;

CREATE TABLE bali_job_items (
  id number(38) NOT NULL,
  data clob,
  item varchar2(1024),
  provider varchar2(1024),
  id_job number(38) NOT NULL,
  service varchar2(255),
  PRIMARY KEY (id)
);

--
-- Table: bali_log
--;

DROP TABLE bali_log CASCADE CONSTRAINTS;

CREATE TABLE bali_log (
  id number(38) NOT NULL,
  text varchar2(2048),
  lev varchar2(10),
  id_job number(38) NOT NULL,
  more varchar2(10),
  data blob(2147483647),
  ts date DEFAULT 'SYSDATE',
  ns varchar2(255) DEFAULT ''/'',
  provider varchar2(255),
  data_name varchar2(1024),
  PRIMARY KEY (id)
);

--
-- Table: bali_scripts_in_file_dist
--;

DROP TABLE bali_scripts_in_file_dist CASCADE CONSTRAINTS;

CREATE TABLE bali_scripts_in_file_dist (
  id number(38) NOT NULL,
  file_dist_id number(38) NOT NULL,
  script_id number(38) NOT NULL,
  PRIMARY KEY (id)
);

ALTER TABLE bali_calendar_window ADD CONSTRAINT bali_calendar_window_id_cal_fk FOREIGN KEY (id_cal) REFERENCES bali_calendar (id) ON DELETE CASCADE;

ALTER TABLE bali_commonfiles_values ADD CONSTRAINT bali_commonfiles_values_fileid FOREIGN KEY (fileid) REFERENCES bali_commonfiles (id) ON DELETE CASCADE;

ALTER TABLE bali_job ADD CONSTRAINT bali_job_id_stash_fk FOREIGN KEY (id_stash) REFERENCES bali_job_stash (id);

ALTER TABLE bali_job_stash ADD CONSTRAINT bali_job_stash_id_job_fk FOREIGN KEY (id_job) REFERENCES bali_job (id) ON DELETE CASCADE;

ALTER TABLE bali_message_queue ADD CONSTRAINT bali_message_queue_id_message_ FOREIGN KEY (id_message) REFERENCES bali_message (id) ON DELETE CASCADE;

ALTER TABLE bali_relationship ADD CONSTRAINT bali_relationship_from_id_fk FOREIGN KEY (from_id) REFERENCES bali_config (id) ON DELETE CASCADE;

ALTER TABLE bali_relationship ADD CONSTRAINT bali_relationship_to_id_fk FOREIGN KEY (to_id) REFERENCES bali_config (id) ON DELETE CASCADE;

ALTER TABLE bali_release_items ADD CONSTRAINT bali_release_items_id_rel_fk FOREIGN KEY (id_rel) REFERENCES bali_release (id) ON DELETE CASCADE;

ALTER TABLE bali_roleaction ADD CONSTRAINT bali_roleaction_id_role_fk FOREIGN KEY (id_role) REFERENCES bali_role (id) ON DELETE CASCADE;

ALTER TABLE bali_roleuser ADD CONSTRAINT bali_roleuser_id_role_fk FOREIGN KEY (id_role) REFERENCES bali_role (id) ON DELETE CASCADE;

ALTER TABLE bali_job_items ADD CONSTRAINT bali_job_items_id_job_fk FOREIGN KEY (id_job) REFERENCES bali_job (id) ON DELETE CASCADE;

ALTER TABLE bali_log ADD CONSTRAINT bali_log_id_job_fk FOREIGN KEY (id_job) REFERENCES bali_job (id);

ALTER TABLE bali_scripts_in_file_dist ADD CONSTRAINT bali_scripts_in_file_dist_file FOREIGN KEY (file_dist_id) REFERENCES bali_file_dist (id) ON DELETE CASCADE;

ALTER TABLE bali_scripts_in_file_dist ADD CONSTRAINT bali_scripts_in_file_dist_scri FOREIGN KEY (script_id) REFERENCES bali_ssh_script (id) ON DELETE CASCADE;

CREATE INDEX bali_calendar_window_idx_id_ca on bali_calendar_window (id_cal);

CREATE INDEX bali_commonfiles_values_idx_fi on bali_commonfiles_values (fileid);

CREATE INDEX bali_job_idx_id_stash on bali_job (id_stash);

CREATE INDEX bali_job_stash_idx_id_job on bali_job_stash (id_job);

CREATE INDEX bali_message_queue_idx_id_mess on bali_message_queue (id_message);

CREATE INDEX bali_relationship_idx_from_id on bali_relationship (from_id);

CREATE INDEX bali_relationship_idx_to_id on bali_relationship (to_id);

CREATE INDEX bali_release_items_idx_id_rel on bali_release_items (id_rel);

CREATE INDEX bali_roleaction_idx_id_role on bali_roleaction (id_role);

CREATE INDEX bali_roleuser_idx_id_role on bali_roleuser (id_role);

CREATE INDEX bali_job_items_idx_id_job on bali_job_items (id_job);

CREATE INDEX bali_log_idx_id_job on bali_log (id_job);

CREATE INDEX bali_scripts_in_file_dist_idx_ on bali_scripts_in_file_dist (file_dist_id);

CREATE INDEX bali_scripts_in_file_dist_id01 on bali_scripts_in_file_dist (script_id);

