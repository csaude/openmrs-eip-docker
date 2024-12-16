CREATE DATABASE IF NOT EXISTS epts_etl_stage_area;

USE epts_etl_stage_area;

DROP TABLE IF EXISTS epts_etl_openmrs_re_sync_table;

CREATE TABLE `epts_etl_openmrs_re_sync_table` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `table_name` varchar(60) NOT NULL,
  `primary_key_field` varchar(60) NOT NULL,
  `observation_date_01` varchar(60) NOT NULL,
  `observation_date_02` varchar(60) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `epts_etl_openmrs_re_sync_table_uk` (`table_name`)
 ) ENGINE=InnoDB;
 
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("person","person_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("location","location_id","date_changed","date_retired");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("patient","patient_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("person_address","person_address_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("person_attribute","person_attribute_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("person_name","person_name_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("relationship","relationship_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("patient_identifier","patient_identifier_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("patient_state","patient_state_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("visit","visit_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("visit_attribute","visit_attribute_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("provider","provider_id","date_changed","date_retired");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("encounter","encounter_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("encounter_provider","encounter_provider_id","date_changed","date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("obs","obs_id","date_voided", "date_voided");
insert into epts_etl_openmrs_re_sync_table(table_name,primary_key_field,observation_date_01,observation_date_02) values("clinicalsummary_usage_report","id","date_changed", "date_voided");