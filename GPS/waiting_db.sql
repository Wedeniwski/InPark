-- Datenbankname: db362102872
-- Benutzername: dbo362102872
-- Hostname: db1125.1und1.de

-- Design:
-- 1) insert from client directly into the database
-- 2) daemon creates waiting.txt all 5-10 min
-- Format: {<attraction_id>:<waiting time in min>;}*<MD5>
-- 3) client checks updates of waiting.txt per active park
-- 4) move all data older than 1h to archive table

Format extended!

-- PHP
-- $sql = 'SELECT `park_id`, `attraction_id`, `entry`, `exit` FROM `waiting_time` WHERE `exit` > CURRENT_TIMESTAMP LIMIT 0, 30 ';
-- INSERT INTO  `waiting_time` (  `created` ,  `park_id` ,  `attraction_id` ,  `entry_id` ,  `exit_id` ,  `entry` ,  `exit` ,  `attraction_duration` ,  `app_version` ,  `entry_latitude` ,  `entry_longitude` ,  `entry_accuracy` ,  `exit_latitude` ,  `exit_longitude` , `exit_accuracy` ) 
VALUES (
NOW( ) ,  'ep',  '400',  '400',  '430',  '2011-06-03 23:00:10',  '2011-06-03 23:04:10',  '9',  '1.0.2',  '48.2672077',  '7.7190653',  '4.3',  '48.2665713',  '7.7192010',  '5.2'
);


--
-- Table structure for table `waiting_time`
-- 

CREATE TABLE `waiting_time` (
  `created` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `park_id` char(15) collate utf8_unicode_ci NOT NULL,
  `attraction_id` char(15) collate utf8_unicode_ci NOT NULL,
  `entry_id` char(15) collate utf8_unicode_ci NOT NULL,
  `exit_id` char(15) collate utf8_unicode_ci NOT NULL,
  `entry` timestamp NOT NULL default '0000-00-00 00:00:00',
  `exit` timestamp,
  `closed` SMALLINT NOT NULL,
  `fast_lane_available` SMALLINT,
  `fast_lane_time_from` CHAR(4) collate utf8_unicode_ci,
  `fast_lane_time_to` CHAR(4) collate utf8_unicode_ci,
  `start_times` VARCHAR(200) collate utf8_unicode_ci,
  `attraction_duration` smallint(6) NOT NULL,
  `app_version` char(10) collate utf8_unicode_ci NOT NULL,
  `entry_latitude` double NOT NULL,
  `entry_longitude` double NOT NULL,
  `entry_accuracy` double NOT NULL,
  `exit_latitude` double,
  `exit_longitude` double,
  `exit_accuracy` double,
  `user_name` VARCHAR(20),
  `comment` VARCHAR(100),
  `user_id` CHAR(32),
  `hash` CHAR(32),
  KEY `created` (`created`),
  KEY `park_id` (`park_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- 
-- Dumping data for table `waiting_time`
-- 

INSERT INTO `waiting_time` (`park_id` ,  `attraction_id` ,  `entry_id` ,  `exit_id` ,  `entry` ,  `exit` ,  `attraction_duration` ,  `app_version` ,  `entry_latitude` ,  `entry_longitude` ,  `entry_accuracy` ,  `exit_latitude` ,  `exit_longitude` ,  `exit_accuracy`) VALUES ('ep', '232', '232', '232', '2011-06-04 11:19:28', '2011-06-04 11:19:34', 20, '1.0.2', 48.2692189, 7.7206455, 0, 48.269272, 7.7206931, 0)

INSERT INTO `waiting_time` VALUES ('2011-06-03 23:08:03', 'ep', '400', '400', '430', '2011-06-03 23:00:10', '2011-06-03 23:04:10', 9, '1.0.2', 48.2672077, 7.7190653, 4.3, 48.2665713, 7.719201, 5.2);


CREATE INDEX waiting_time_key ON waiting_time (created, park_id);


CREATE TABLE archive_waiting_time (
  created              TIMESTAMP NOT NULL,

  park_id              CHAR(15) NOT NULL,
  attraction_id        CHAR(15) NOT NULL,
  entry_id             CHAR(15) NOT NULL,
  exit_id              CHAR(15) NOT NULL,
  entry                TIMESTAMP NOT NULL,
  exit                 TIMESTAMP NOT NULL,
  closed               SMALLINT NOT NULL,
  attraction_duration  SMALLINT NOT NULL,
  app_version          CHAR(10) NOT NULL,
  entry_latitude       DOUBLE NOT NULL,
  entry_longitude      DOUBLE NOT NULL,
  entry_accuracy       DOUBLE NOT NULL,
  exit_latitude        DOUBLE NOT NULL,
  exit_longitude       DOUBLE NOT NULL,
  exit_accuracy        DOUBLE NOT NULL,
  user_name            VARCHAR(20),
  comment              VARCHAR(100),
  user_id              CHAR(32),
  hash                 CHAR(32)
);
