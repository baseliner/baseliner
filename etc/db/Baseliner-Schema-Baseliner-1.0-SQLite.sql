-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Sep 23 21:47:18 2009
-- 


BEGIN TRANSACTION;

--
-- Table: bali_baseline
--
DROP TABLE bali_baseline;

CREATE TABLE bali_baseline (
  id INTEGER PRIMARY KEY NOT NULL,
  bl VARCHAR2(100) NOT NULL,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(1024)
);

--
-- Table: bali_calendar
--
DROP TABLE bali_calendar;

CREATE TABLE bali_calendar (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR2(100) NOT NULL,
  ns VARCHAR2(100) NOT NULL DEFAULT '/',
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  description VARCHAR2(1024)
);

--
-- Table: bali_chain
--
DROP TABLE bali_chain;

CREATE TABLE bali_chain (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(2000) NOT NULL,
  job_type VARCHAR2(50),
  active NUMBER(126) DEFAULT 1,
  action VARCHAR2(255),
  ns VARCHAR2(1024) DEFAULT '/',
  bl VARCHAR2(50) DEFAULT '*'
);

--
-- Table: bali_chained_service
--
DROP TABLE bali_chained_service;

CREATE TABLE bali_chained_service (
  id INTEGER PRIMARY KEY NOT NULL,
  chain_id NUMBER(126) NOT NULL,
  seq NUMBER(126) NOT NULL,
  key VARCHAR2(255) NOT NULL,
  description VARCHAR2(2000),
  step VARCHAR2(50) DEFAULT 'RUN',
  active NUMBER(126) DEFAULT 1
);

--
-- Table: bali_commonfiles
--
DROP TABLE bali_commonfiles;

CREATE TABLE bali_commonfiles (
  id INTEGER PRIMARY KEY NOT NULL,
  nombre VARCHAR2(64) NOT NULL,
  tipo CHAR(1) NOT NULL,
  descripcion VARCHAR2(4000),
  ns VARCHAR2(100) NOT NULL DEFAULT '/',
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  f_alta DATE(19) DEFAULT SYSDATE,
  f_baja DATE(19)
);

--
-- Table: bali_config
--
DROP TABLE bali_config;

CREATE TABLE bali_config (
  id INTEGER PRIMARY KEY NOT NULL,
  ns VARCHAR2(1000) NOT NULL DEFAULT '/',
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  key VARCHAR2(100) NOT NULL,
  value VARCHAR2(100) DEFAULT NULL,
  ts DATE(19) NOT NULL DEFAULT SYSDATE               ,
  ref NUMBER(126),
  reftable VARCHAR2(100),
  data BLOB,
  parent_id NUMBER(126) NOT NULL DEFAULT '0                     '
);

--
-- Table: bali_config_rel
--
DROP TABLE bali_config_rel;

CREATE TABLE bali_config_rel (
  id INTEGER PRIMARY KEY NOT NULL,
  namespace_id INT(10) NOT NULL,
  plugin_id INT(10) NOT NULL
);

--
-- Table: bali_configset
--
DROP TABLE bali_configset;

CREATE TABLE bali_configset (
  id INTEGER PRIMARY KEY NOT NULL,
  namespace_id INT(10) NOT NULL,
  baseline_id INT(10) NOT NULL,
  wiki_id INT(10) NOT NULL,
  created_on DATETIME(19) NOT NULL
);

--
-- Table: bali_daemon
--
DROP TABLE bali_daemon;

CREATE TABLE bali_daemon (
  id INTEGER PRIMARY KEY NOT NULL,
  service VARCHAR2(255),
  active NUMBER(126) DEFAULT 1,
  config VARCHAR2(255),
  pid NUMBER(126),
  params VARCHAR2(1024),
  hostname VARCHAR2(255) DEFAULT 'localhost'
);

--
-- Table: bali_file_dist
--
DROP TABLE bali_file_dist;

CREATE TABLE bali_file_dist (
  id INTEGER PRIMARY KEY NOT NULL,
  ns VARCHAR2(1000) NOT NULL DEFAULT '/',
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  filter VARCHAR2(256) DEFAULT '*.*',
  isrecursive NUMBER(1) DEFAULT '0    ',
  src_dir VARCHAR2(100) NOT NULL DEFAULT '.',
  dest_dir VARCHAR2(100) NOT NULL,
  ssh_host VARCHAR2(100) NOT NULL,
  xtype VARCHAR2(16)
);

--
-- Table: bali_message
--
DROP TABLE bali_message;

CREATE TABLE bali_message (
  id INTEGER PRIMARY KEY NOT NULL,
  subject VARCHAR2(1024) NOT NULL,
  body CLOB(2147483647),
  created DATE(19) DEFAULT SYSDATE,
  active NUMBER(126) DEFAULT 1,
  attach BLOB,
  sender VARCHAR2(255),
  content_type VARCHAR2(50),
  attach_content_type VARCHAR2(50),
  attach_filename VARCHAR2(255)
);

--
-- Table: bali_namespace
--
DROP TABLE bali_namespace;

CREATE TABLE bali_namespace (
  id INTEGER PRIMARY KEY NOT NULL,
  ns VARCHAR2(100) NOT NULL,
  provider VARCHAR2(500)
);

--
-- Table: bali_plugin
--
DROP TABLE bali_plugin;

CREATE TABLE bali_plugin (
  id INTEGER PRIMARY KEY NOT NULL,
  plugin VARCHAR(250) NOT NULL,
  desc_ VARCHAR(500) NOT NULL,
  wiki_id INT(10) NOT NULL
);

--
-- Table: bali_provider
--
DROP TABLE bali_provider;

CREATE TABLE bali_provider (
  id INTEGER PRIMARY KEY NOT NULL,
  plugin VARCHAR(250) NOT NULL
);

--
-- Table: bali_release
--
DROP TABLE bali_release;

CREATE TABLE bali_release (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR2(255) NOT NULL,
  description VARCHAR2(2000),
  active CHAR(1) NOT NULL DEFAULT 1,
  ts DATE(19) DEFAULT SYSDATE,
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  username VARCHAR2(255)
);

--
-- Table: bali_request
--
DROP TABLE bali_request;

CREATE TABLE bali_request (
  id INTEGER PRIMARY KEY NOT NULL,
  ns VARCHAR2(1024) NOT NULL,
  bl VARCHAR2(50) DEFAULT '*',
  requested_on DATE(19),
  finished_on DATE(19),
  status VARCHAR2(50) DEFAULT 'pending',
  finished_by VARCHAR2(255),
  requested_by VARCHAR2(255),
  action VARCHAR2(255),
  id_parent NUMBER(126),
  key VARCHAR2(255),
  name VARCHAR2(255),
  type VARCHAR2(100) DEFAULT 'approval'
);

--
-- Table: bali_role
--
DROP TABLE bali_role;

CREATE TABLE bali_role (
  id INTEGER PRIMARY KEY NOT NULL,
  role VARCHAR2(255) NOT NULL,
  description VARCHAR2(2048)
);

--
-- Table: bali_service
--
DROP TABLE bali_service;

CREATE TABLE bali_service (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(100) NOT NULL,
  desc_ VARCHAR(100) NOT NULL,
  wiki_id INT(10) NOT NULL
);

--
-- Table: bali_ssh_script
--
DROP TABLE bali_ssh_script;

CREATE TABLE bali_ssh_script (
  id INTEGER PRIMARY KEY NOT NULL,
  ns VARCHAR2(1000) NOT NULL DEFAULT '/',
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  script VARCHAR2(100) NOT NULL,
  params VARCHAR2(1000) NOT NULL,
  ssh_host VARCHAR2(100) NOT NULL,
  xorder NUMBER(1) DEFAULT 1
);

--
-- Table: bali_user
--
DROP TABLE bali_user;

CREATE TABLE bali_user (
  id INTEGER PRIMARY KEY NOT NULL,
  username VARCHAR(45) NOT NULL,
  password VARCHAR(45) NOT NULL
);

--
-- Table: bali_wiki
--
DROP TABLE bali_wiki;

CREATE TABLE bali_wiki (
  id INTEGER PRIMARY KEY NOT NULL,
  text CLOB(2147483647),
  username VARCHAR2(255),
  modified_on DATE(19) DEFAULT SYSDATE,
  content_type VARCHAR2(255) DEFAULT 'text/plain'
  id_wiki NUMBER(126)
);

--
-- Table: bali_calendar_window
--
DROP TABLE bali_calendar_window;

CREATE TABLE bali_calendar_window (
  id INTEGER PRIMARY KEY NOT NULL DEFAULT 1,
  start_time VARCHAR2(20),
  end_time VARCHAR2(20),
  day VARCHAR2(20),
  type VARCHAR2(1),
  active VARCHAR2(1) DEFAULT 1,
  id_cal NUMBER(126) NOT NULL DEFAULT 1,
  start_date DATE(19),
  end_date DATE(19)
);

CREATE INDEX bali_calendar_window_idx_id_cal ON bali_calendar_window (id_cal);

--
-- Table: bali_commonfiles_values
--
DROP TABLE bali_commonfiles_values;

CREATE TABLE bali_commonfiles_values (
  fileid NUMBER(126) NOT NULL,
  id NUMBER(126) NOT NULL,
  clave VARCHAR2(256) NOT NULL,
  valor VARCHAR2(4000) NOT NULL,
  secordesc VARCHAR2(1024) NOT NULL,
  ns VARCHAR2(100) NOT NULL DEFAULT '/',
  bl VARCHAR2(100) NOT NULL DEFAULT '*',
  f_alta DATE(19) DEFAULT SYSDATE,
  f_baja DATE(19) DEFAULT TO_DATE('99991231','yyyymmdd') 
  PRIMARY KEY (fileid, id)
);

CREATE INDEX bali_commonfiles_values_idx_fileid ON bali_commonfiles_values (fileid);

--
-- Table: bali_job
--
DROP TABLE bali_job;

CREATE TABLE bali_job (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR2(45),
  starttime DATE(19) NOT NULL DEFAULT SYSDATE               ,
  maxstarttime DATE(19) NOT NULL DEFAULT SYSDATE+1             ,
  endtime DATE(19),
  status VARCHAR2(45) NOT NULL DEFAULT 'READY',
  ns VARCHAR2(45) NOT NULL DEFAULT '/',
  bl VARCHAR2(45) NOT NULL DEFAULT '*',
  runner VARCHAR2(255),
  pid NUMBER(126),
  comments VARCHAR2(1024),
  type VARCHAR2(100),
  username VARCHAR2(255),
  ts DATE(19) DEFAULT SYSDATE
  host VARCHAR2(255) DEFAULT 'localhost',
  owner VARCHAR2(255),
  step VARCHAR2(50) DEFAULT 'PRE',
  id_stash NUMBER(126)
);

CREATE INDEX bali_job_idx_id_stash ON bali_job (id_stash);

--
-- Table: bali_job_stash
--
DROP TABLE bali_job_stash;

CREATE TABLE bali_job_stash (
  id INTEGER PRIMARY KEY NOT NULL,
  stash BLOB,
  id_job NUMBER(126)
);

CREATE INDEX bali_job_stash_idx_id_job ON bali_job_stash (id_job);

--
-- Table: bali_message_queue
--
DROP TABLE bali_message_queue;

CREATE TABLE bali_message_queue (
  id INTEGER PRIMARY KEY NOT NULL,
  id_message NUMBER(126),
  username VARCHAR2(255),
  destination VARCHAR2(50),
  sent DATE(19) DEFAULT SYSDATE,
  received DATE(19),
  active NUMBER(126) DEFAULT 1,
  carrier VARCHAR2(50) DEFAULT 'instant',
  carrier_param VARCHAR2(50),
  result CLOB(2147483647),
  attempts NUMBER(126) DEFAULT '0'
);

CREATE INDEX bali_message_queue_idx_id_message ON bali_message_queue (id_message);

--
-- Table: bali_relationship
--
DROP TABLE bali_relationship;

CREATE TABLE bali_relationship (
  from_id NUMBER(126) NOT NULL,
  to_id NUMBER(126) NOT NULL,
  type VARCHAR2(45),
  PRIMARY KEY (to_id, from_id)
);

CREATE INDEX bali_relationship_idx_from_id ON bali_relationship (from_id);

CREATE INDEX bali_relationship_idx_to_id ON bali_relationship (to_id);

--
-- Table: bali_release_items
--
DROP TABLE bali_release_items;

CREATE TABLE bali_release_items (
  id INTEGER PRIMARY KEY NOT NULL,
  id_rel NUMBER(126) NOT NULL,
  item VARCHAR2(1024),
  provider VARCHAR2(1024),
  data CLOB(2147483647),
  ns VARCHAR2(255)
);

CREATE INDEX bali_release_items_idx_id_rel ON bali_release_items (id_rel);

--
-- Table: bali_roleaction
--
DROP TABLE bali_roleaction;

CREATE TABLE bali_roleaction (
  id_role NUMBER(126) NOT NULL,
  action VARCHAR2(255) NOT NULL,
  bl VARCHAR2(50) NOT NULL DEFAULT '*',
  PRIMARY KEY (action, id_role, bl)
);

CREATE INDEX bali_roleaction_idx_id_role ON bali_roleaction (id_role);

--
-- Table: bali_roleuser
--
DROP TABLE bali_roleuser;

CREATE TABLE bali_roleuser (
  username VARCHAR2(255) NOT NULL,
  id_role NUMBER(126) NOT NULL,
  ns VARCHAR2(100) NOT NULL DEFAULT '/',
  PRIMARY KEY (username, id_role)
);

CREATE INDEX bali_roleuser_idx_id_role ON bali_roleuser (id_role);

--
-- Table: bali_job_items
--
DROP TABLE bali_job_items;

CREATE TABLE bali_job_items (
  id INTEGER PRIMARY KEY NOT NULL,
  data CLOB(2147483647),
  item VARCHAR2(1024),
  provider VARCHAR2(1024),
  id_job NUMBER(126) NOT NULL,
  service VARCHAR2(255)
);

CREATE INDEX bali_job_items_idx_id_job ON bali_job_items (id_job);

--
-- Table: bali_log
--
DROP TABLE bali_log;

CREATE TABLE bali_log (
  id INTEGER PRIMARY KEY NOT NULL,
  text VARCHAR2(2048),
  lev VARCHAR2(10),
  id_job NUMBER(126) NOT NULL,
  more VARCHAR2(10),
  data BLOB,
  ts DATE(19) DEFAULT SYSDATE,
  ns VARCHAR2(255) DEFAULT '/',
  provider VARCHAR2(255),
  data_name VARCHAR2(1024)
);

CREATE INDEX bali_log_idx_id_job ON bali_log (id_job);

--
-- Table: bali_scripts_in_file_dist
--
DROP TABLE bali_scripts_in_file_dist;

CREATE TABLE bali_scripts_in_file_dist (
  id INTEGER PRIMARY KEY NOT NULL,
  file_dist_id NUMBER(126) NOT NULL,
  script_id NUMBER(126) NOT NULL
);

CREATE INDEX bali_scripts_in_file_dist_idx_file_dist_id ON bali_scripts_in_file_dist (file_dist_id);

CREATE INDEX bali_scripts_in_file_dist_idx_script_id ON bali_scripts_in_file_dist (script_id);

COMMIT;