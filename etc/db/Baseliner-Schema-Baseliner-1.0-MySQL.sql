-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Wed Sep 23 21:47:18 2009
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `bali_baseline`;

--
-- Table: `bali_baseline`
--
CREATE TABLE `bali_baseline` (
  `id` bigint(126) NOT NULL,
  `bl` varchar(100) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_calendar`;

--
-- Table: `bali_calendar`
--
CREATE TABLE `bali_calendar` (
  `id` bigint(126) NOT NULL,
  `name` varchar(100) NOT NULL,
  `ns` varchar(100) NOT NULL DEFAULT ''/'                   ',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                   ',
  `description` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_chain`;

--
-- Table: `bali_chain`
--
CREATE TABLE `bali_chain` (
  `id` bigint(38) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `job_type` varchar(50),
  `active` bigint(126) DEFAULT '1',
  `action` varchar(255),
  `ns` text DEFAULT ''/'',
  `bl` varchar(50) DEFAULT ''*'',
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_chained_service`;

--
-- Table: `bali_chained_service`
--
CREATE TABLE `bali_chained_service` (
  `id` bigint(126) NOT NULL,
  `chain_id` bigint(126) NOT NULL,
  `seq` bigint(126) NOT NULL,
  `key` varchar(255) NOT NULL,
  `description` text,
  `step` varchar(50) DEFAULT ''RUN'',
  `active` bigint(126) DEFAULT '1',
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_commonfiles`;

--
-- Table: `bali_commonfiles`
--
CREATE TABLE `bali_commonfiles` (
  `id` bigint(126) NOT NULL,
  `nombre` varchar(64) NOT NULL,
  `tipo` CHAR(1) NOT NULL,
  `descripcion` text,
  `ns` varchar(100) NOT NULL DEFAULT ''/'                   ',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                   ',
  `f_alta` DATE DEFAULT 'SYSDATE',
  `f_baja` DATE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_config`;

--
-- Table: `bali_config`
--
CREATE TABLE `bali_config` (
  `id` bigint(126) NOT NULL,
  `ns` text NOT NULL DEFAULT ''/'                   ',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                   ',
  `key` varchar(100) NOT NULL,
  `value` varchar(100) DEFAULT NULL,
  `ts` DATE NOT NULL DEFAULT 'SYSDATE               ',
  `ref` bigint(126),
  `reftable` varchar(100),
  `data` BLOB,
  `parent_id` bigint(126) NOT NULL DEFAULT '0                     ',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_config_rel`;

--
-- Table: `bali_config_rel`
--
CREATE TABLE `bali_config_rel` (
  `id` INTEGER NOT NULL,
  `namespace_id` integer(10) NOT NULL,
  `plugin_id` integer(10) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_configset`;

--
-- Table: `bali_configset`
--
CREATE TABLE `bali_configset` (
  `id` INTEGER NOT NULL,
  `namespace_id` integer(10) NOT NULL,
  `baseline_id` integer(10) NOT NULL,
  `wiki_id` integer(10) NOT NULL,
  `created_on` datetime NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_daemon`;

--
-- Table: `bali_daemon`
--
CREATE TABLE `bali_daemon` (
  `id` bigint(126) NOT NULL,
  `service` varchar(255),
  `active` bigint(126) DEFAULT '1',
  `config` varchar(255),
  `pid` bigint(126),
  `params` text,
  `hostname` varchar(255) DEFAULT ''localhost'',
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_file_dist`;

--
-- Table: `bali_file_dist`
--
CREATE TABLE `bali_file_dist` (
  `id` bigint(126) NOT NULL,
  `ns` text NOT NULL DEFAULT ''/'                 ',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                 ',
  `filter` text DEFAULT ''*.*'    ',
  `isrecursive` tinyint(1) DEFAULT '0    ',
  `src_dir` varchar(100) NOT NULL DEFAULT ''.'     ',
  `dest_dir` varchar(100) NOT NULL,
  `ssh_host` varchar(100) NOT NULL,
  `xtype` varchar(16),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_message`;

--
-- Table: `bali_message`
--
CREATE TABLE `bali_message` (
  `id` bigint(126) NOT NULL,
  `subject` text NOT NULL,
  `body` longtext,
  `created` DATE DEFAULT 'SYSDATE',
  `active` bigint(126) DEFAULT '1',
  `attach` BLOB,
  `sender` varchar(255),
  `content_type` varchar(50),
  `attach_content_type` varchar(50),
  `attach_filename` varchar(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_namespace`;

--
-- Table: `bali_namespace`
--
CREATE TABLE `bali_namespace` (
  `id` bigint(126) NOT NULL,
  `ns` varchar(100) NOT NULL,
  `provider` text,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_plugin`;

--
-- Table: `bali_plugin`
--
CREATE TABLE `bali_plugin` (
  `id` INTEGER NOT NULL,
  `plugin` VARCHAR(250) NOT NULL,
  `desc_` text NOT NULL,
  `wiki_id` integer(10) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_provider`;

--
-- Table: `bali_provider`
--
CREATE TABLE `bali_provider` (
  `id` INTEGER NOT NULL,
  `plugin` VARCHAR(250) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_release`;

--
-- Table: `bali_release`
--
CREATE TABLE `bali_release` (
  `id` bigint(126) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text,
  `active` CHAR(1) NOT NULL DEFAULT '1                     ',
  `ts` DATE DEFAULT 'SYSDATE',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                   ',
  `username` varchar(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_request`;

--
-- Table: `bali_request`
--
CREATE TABLE `bali_request` (
  `id` bigint(126) NOT NULL,
  `ns` text NOT NULL,
  `bl` varchar(50) DEFAULT ''*'',
  `requested_on` DATE,
  `finished_on` DATE,
  `status` varchar(50) DEFAULT ''pending'',
  `finished_by` varchar(255),
  `requested_by` varchar(255),
  `action` varchar(255),
  `id_parent` bigint(126),
  `key` varchar(255),
  `name` varchar(255),
  `type` varchar(100) DEFAULT ''approval'',
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_role`;

--
-- Table: `bali_role`
--
CREATE TABLE `bali_role` (
  `id` bigint(126) NOT NULL,
  `role` varchar(255) NOT NULL,
  `description` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_service`;

--
-- Table: `bali_service`
--
CREATE TABLE `bali_service` (
  `id` INTEGER NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `desc_` VARCHAR(100) NOT NULL,
  `wiki_id` integer(10) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_ssh_script`;

--
-- Table: `bali_ssh_script`
--
CREATE TABLE `bali_ssh_script` (
  `id` bigint(126) NOT NULL,
  `ns` text NOT NULL DEFAULT ''/'                 ',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                 ',
  `script` varchar(100) NOT NULL,
  `params` text NOT NULL,
  `ssh_host` varchar(100) NOT NULL,
  `xorder` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_user`;

--
-- Table: `bali_user`
--
CREATE TABLE `bali_user` (
  `id` INTEGER NOT NULL,
  `username` VARCHAR(45) NOT NULL,
  `password` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_wiki`;

--
-- Table: `bali_wiki`
--
CREATE TABLE `bali_wiki` (
  `id` bigint(126) NOT NULL,
  `text` longtext,
  `username` varchar(255),
  `modified_on` DATE DEFAULT 'SYSDATE',
  `content_type` varchar(255) DEFAULT ''text/plain'
',
  `id_wiki` bigint(126),
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `bali_calendar_window`;

--
-- Table: `bali_calendar_window`
--
CREATE TABLE `bali_calendar_window` (
  `id` bigint(126) NOT NULL DEFAULT '1                     ',
  `start_time` varchar(20),
  `end_time` varchar(20),
  `day` varchar(20),
  `type` varchar(1),
  `active` varchar(1) DEFAULT ''1'',
  `id_cal` bigint(126) NOT NULL DEFAULT '1                     ',
  `start_date` DATE,
  `end_date` DATE,
  INDEX bali_calendar_window_idx_id_cal (`id_cal`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_calendar_window_fk_id_cal` FOREIGN KEY (`id_cal`) REFERENCES `bali_calendar` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_commonfiles_values`;

--
-- Table: `bali_commonfiles_values`
--
CREATE TABLE `bali_commonfiles_values` (
  `fileid` bigint(126) NOT NULL,
  `id` bigint(126) NOT NULL,
  `clave` text NOT NULL,
  `valor` text NOT NULL,
  `secordesc` text NOT NULL,
  `ns` varchar(100) NOT NULL DEFAULT ''/'                   ',
  `bl` varchar(100) NOT NULL DEFAULT ''*'                   ',
  `f_alta` DATE DEFAULT 'SYSDATE',
  `f_baja` DATE DEFAULT 'TO_DATE('99991231','yyyymmdd') 
',
  INDEX bali_commonfiles_values_idx_fileid (`fileid`),
  PRIMARY KEY (`fileid`, `id`),
  CONSTRAINT `bali_commonfiles_values_fk_fileid` FOREIGN KEY (`fileid`) REFERENCES `bali_commonfiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_job`;

--
-- Table: `bali_job`
--
CREATE TABLE `bali_job` (
  `id` bigint(126) NOT NULL,
  `name` varchar(45),
  `starttime` DATE NOT NULL DEFAULT 'SYSDATE               ',
  `maxstarttime` DATE NOT NULL DEFAULT 'SYSDATE+1             ',
  `endtime` DATE,
  `status` varchar(45) NOT NULL DEFAULT ''READY'               ',
  `ns` varchar(45) NOT NULL DEFAULT ''/'                   ',
  `bl` varchar(45) NOT NULL DEFAULT ''*'                   ',
  `runner` varchar(255),
  `pid` bigint(126),
  `comments` text,
  `type` varchar(100),
  `username` varchar(255),
  `ts` DATE DEFAULT 'SYSDATE
',
  `host` varchar(255) DEFAULT ''localhost'',
  `owner` varchar(255),
  `step` varchar(50) DEFAULT ''PRE'',
  `id_stash` bigint(126),
  INDEX bali_job_idx_id_stash (`id_stash`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_job_fk_id_stash` FOREIGN KEY (`id_stash`) REFERENCES `bali_job_stash` (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_job_stash`;

--
-- Table: `bali_job_stash`
--
CREATE TABLE `bali_job_stash` (
  `id` bigint(126) NOT NULL,
  `stash` BLOB,
  `id_job` bigint(126),
  INDEX bali_job_stash_idx_id_job (`id_job`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_job_stash_fk_id_job` FOREIGN KEY (`id_job`) REFERENCES `bali_job` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_message_queue`;

--
-- Table: `bali_message_queue`
--
CREATE TABLE `bali_message_queue` (
  `id` bigint(126) NOT NULL,
  `id_message` bigint(126),
  `username` varchar(255),
  `destination` varchar(50),
  `sent` DATE DEFAULT 'SYSDATE',
  `received` DATE,
  `active` bigint(126) DEFAULT '1',
  `carrier` varchar(50) DEFAULT ''instant'',
  `carrier_param` varchar(50),
  `result` longtext,
  `attempts` bigint(126) DEFAULT '0',
  INDEX bali_message_queue_idx_id_message (`id_message`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_message_queue_fk_id_message` FOREIGN KEY (`id_message`) REFERENCES `bali_message` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_relationship`;

--
-- Table: `bali_relationship`
--
CREATE TABLE `bali_relationship` (
  `from_id` bigint(126) NOT NULL,
  `to_id` bigint(126) NOT NULL,
  `type` varchar(45),
  INDEX bali_relationship_idx_from_id (`from_id`),
  INDEX bali_relationship_idx_to_id (`to_id`),
  PRIMARY KEY (`to_id`, `from_id`),
  CONSTRAINT `bali_relationship_fk_from_id` FOREIGN KEY (`from_id`) REFERENCES `bali_config` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bali_relationship_fk_to_id` FOREIGN KEY (`to_id`) REFERENCES `bali_config` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_release_items`;

--
-- Table: `bali_release_items`
--
CREATE TABLE `bali_release_items` (
  `id` bigint(126) NOT NULL,
  `id_rel` bigint(126) NOT NULL,
  `item` text,
  `provider` text,
  `data` longtext,
  `ns` varchar(255),
  INDEX bali_release_items_idx_id_rel (`id_rel`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_release_items_fk_id_rel` FOREIGN KEY (`id_rel`) REFERENCES `bali_release` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_roleaction`;

--
-- Table: `bali_roleaction`
--
CREATE TABLE `bali_roleaction` (
  `id_role` bigint(126) NOT NULL,
  `action` varchar(255) NOT NULL,
  `bl` varchar(50) NOT NULL DEFAULT ''*'',
  INDEX bali_roleaction_idx_id_role (`id_role`),
  PRIMARY KEY (`action`, `id_role`, `bl`),
  CONSTRAINT `bali_roleaction_fk_id_role` FOREIGN KEY (`id_role`) REFERENCES `bali_role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_roleuser`;

--
-- Table: `bali_roleuser`
--
CREATE TABLE `bali_roleuser` (
  `username` varchar(255) NOT NULL,
  `id_role` bigint(126) NOT NULL,
  `ns` varchar(100) NOT NULL DEFAULT ''/'                   ',
  INDEX bali_roleuser_idx_id_role (`id_role`),
  PRIMARY KEY (`username`, `id_role`),
  CONSTRAINT `bali_roleuser_fk_id_role` FOREIGN KEY (`id_role`) REFERENCES `bali_role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_job_items`;

--
-- Table: `bali_job_items`
--
CREATE TABLE `bali_job_items` (
  `id` bigint(126) NOT NULL,
  `data` longtext,
  `item` text,
  `provider` text,
  `id_job` bigint(126) NOT NULL,
  `service` varchar(255),
  INDEX bali_job_items_idx_id_job (`id_job`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_job_items_fk_id_job` FOREIGN KEY (`id_job`) REFERENCES `bali_job` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_log`;

--
-- Table: `bali_log`
--
CREATE TABLE `bali_log` (
  `id` bigint(126) NOT NULL,
  `text` text,
  `lev` varchar(10),
  `id_job` bigint(126) NOT NULL,
  `more` varchar(10),
  `data` BLOB,
  `ts` DATE DEFAULT 'SYSDATE',
  `ns` varchar(255) DEFAULT ''/'',
  `provider` varchar(255),
  `data_name` text,
  INDEX bali_log_idx_id_job (`id_job`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_log_fk_id_job` FOREIGN KEY (`id_job`) REFERENCES `bali_job` (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `bali_scripts_in_file_dist`;

--
-- Table: `bali_scripts_in_file_dist`
--
CREATE TABLE `bali_scripts_in_file_dist` (
  `id` bigint(126) NOT NULL,
  `file_dist_id` bigint(126) NOT NULL,
  `script_id` bigint(126) NOT NULL,
  INDEX bali_scripts_in_file_dist_idx_file_dist_id (`file_dist_id`),
  INDEX bali_scripts_in_file_dist_idx_script_id (`script_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `bali_scripts_in_file_dist_fk_file_dist_id` FOREIGN KEY (`file_dist_id`) REFERENCES `bali_file_dist` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bali_scripts_in_file_dist_fk_script_id` FOREIGN KEY (`script_id`) REFERENCES `bali_ssh_script` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

