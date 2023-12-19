create database if not exists location_harmonization;
--   STORED PROCEDURE TO HARMONIZE LOCATION -------
-- Criar tabela que tera location por harmonizar 

drop table if exists location_harmonization.location_to_harmonize;

CREATE TABLE if not exists location_harmonization.location_to_harmonize (
	uuid_old_location varchar(255),
    uuid_actual_location varchar(255)
);

INSERT into location_harmonization.location_to_harmonize (uuid_old_location, uuid_actual_location)
value
('0890a828-1778-4acf-9e12-e4f04eff5e52', '0e796c31-1799-41b3-9c27-74dd4c371584'),
('5a04df3e-692f-4cc8-8abe-3807ffd0c5bd','cdc12dfb-c561-4106-bcd4-b4ac8f6e069d');

-- Criar tabela de logs de alteracao
CREATE TABLE if not exists location_harmonization.location_harmonized_logs (
	log_id int(16) NOT NULL AUTO_INCREMENT,
	old_changed_by int(11) DEFAULT NULL,
  	old_date_changed datetime DEFAULT NULL,
    	uuid_actual_location varchar(255),
	uuid_old_location varchar(255),
	PRIMARY KEY (log_id)
);

CREATE TABLE if not exists location_harmonization.location_execution_logs (
	execution_id int(16) NOT NULL AUTO_INCREMENT,
	table_name varchar(255),
    	location_uuid varchar(255),
    	logi_text varchar(500),
    	start_date datetime DEFAULT NULL,
	end_date datetime DEFAULT NULL,
	PRIMARY KEY (execution_id)
);

CREATE TABLE if not exists location_harmonization.harmonization_execution_status (
	execution_id int(16) NOT NULL AUTO_INCREMENT,
	type varchar(255), 
    status varchar(255),
    start_date datetime DEFAULT NULL,
	end_date datetime DEFAULT NULL,
	  PRIMARY KEY (execution_id)
);

-- UPDATE HARMONIZED LOCATION
DROP PROCEDURE IF EXISTS location_harmonization.update_harmonized_location;

DELIMITER $$ 
CREATE PROCEDURE location_harmonization.update_harmonized_location()
BEGIN
	
	DECLARE done INT;
	DECLARE uuid_old_location varchar(255);
	DECLARE uuid_actual_location varchar(255);
	DECLARE current_location_id INT;
	DECLARE old_location_id INT;
	DECLARE harmonization_execution_status_recs INT;
   	DECLARE log_msg varchar(500);
	DECLARE oldChangedBy INT;
	DECLARE oldDateChanged datetime;

	SET done = 0;
	SET current_location_id = 0;
	SET old_location_id = 0;

	DECLARE location_cursor CURSOR FOR SELECT lo.uuid_old_location, lo.uuid_actual_location FROM location_harmonization.location_to_harmonize lo;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

	select count(*) into harmonization_execution_status_recs from location_harmonization.harmonization_execution_status;
	
	if harmonization_execution_status_recs = 0 then
		-- Log Harmonization execution status
		insert into location_harmonization.harmonization_execution_status(type, status, start_date) values ('harmonization', 'running', now());
		-- Log Harmonization execution status
	end if;
	
	OPEN location_cursor;
    
   	locations_cursor:
  		LOOP
			FETCH location_cursor INTO uuid_old_location, uuid_actual_location;
            
				IF done THEN 
					LEAVE locations_cursor;
				END IF;

				SET old_location_id = (Select l.location_id from OPENMRS_DATABASE_NAME.location l where l.uuid = uuid_old_location);

				
				IF (old_location_id IS NULL) THEN
					SET log_msg = concat('The old location[', uuid_old_location, '] cannot found in db. Nothing to do!'); 

					insert into location_harmonization.location_execution_logs(table_name, location_uuid, log_text, start_date, end_date) values('location', uuid_old_location, log_msg, now(), now());
		    		ELSE
					BEGIN
						SET oldChangedBy = (Select l.changed_by from OPENMRS_DATABASE_NAME.location l where l.uuid = uuid_old_location);
						SET oldDateChanged = (Select l.date_changed from OPENMRS_DATABASE_NAME.location l where l.uuid = uuid_old_location);

						SET log_msg = concat('Updating location[', uuid_old_location, '] to [', uuid_actual_location, '] ...'); 
						
						insert into location_harmonization.location_execution_logs(table_name, location_uuid, log_text, start_date, end_date) values('location', uuid_old_location, log_msg, now(), now());

						-- DO THE UPDATE
						update 	OPENMRS_DATABASE_NAME.location 
						set 	uuid=uuid_actual_location 
							changed_by=1, 
							date_changed = now()
						where location_id = old_location_id;

						insert into location_harmonization.location_harmonized_logs(uuid_actual_location, uuid_old_location, old_changed_by, old_date_changed) 
						values (uuid_actual_location,uuid_old_location, oldChangedBy, oldDateChanged);


						SET log_msg = concat('Location[', uuid_old_location, '] was updated to [', uuid_actual_location, '] ...'); 
						
						insert into location_harmonization.location_execution_logs(table_name, location_uuid, log_text, start_date, end_date) values('location', uuid_old_location, log_msg, now(), now());

					END;
				END IF;
		END LOOP locations_cursor;
    
	CLOSE location_cursor;

	-- Log Harmonization execution status
	update location_harmonization.harmonization_execution_status set status='finished', end_date=now() where  
	type = 'harmonization' and status='running';
	-- Log Harmonization execution status
END $$ 

DELIMITER ;

CALL location_harmonization.update_harmonized_location();
