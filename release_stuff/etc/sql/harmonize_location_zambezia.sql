create database if not exists location_harmonization;
--   STORED PROCEDURE TO HARMONIZE LOCATION -------
-- Criar tabela que tera location por harmonizar 
CREATE TABLE if not exists location_harmonization.location_to_harmonize (
	uuid_old_location varchar(255),
    uuid_actual_location varchar(255)
);

INSERT into location_harmonization.location_to_harmonize (uuid_old_location, uuid_actual_location)
value
('74d94602-3e32-44db-9db8-eed554e9533f', '67daff6b-b013-43ce-9f5d-768233029106'),
('e4dbeb83-4df8-466d-8cf9-340b7b58cce6','75d49478-8ea1-4367-8d84-8b0a6d70898d'),
('b5908e52-7bb5-41cc-b152-0843126d3d0a', '8d6c993e-c2cc-11de-8d13-0010c6dffd0f'),
('848ec6c9-306e-4bf6-954a-e0067feee7ab', '8d6c993e-c2cc-11de-8d13-0010c6dffd0f'),
('82b7c9a9-7ebf-4fbf-b6ac-8282aa197967', '8d6c993e-c2cc-11de-8d13-0010c6dffd0f'),
('af953a53-6f0a-4f36-b323-7817f0dea152', '8d6c993e-c2cc-11de-8d13-0010c6dffd0f'),
('a3de2d6e-2eca-4e12-aaef-fc406899194f', '049db04d-81f0-4581-839f-25fa3d778f6d'),
('7311e455-de89-11e8-a2e5-0242ac120003', '770acffb-cfeb-46dc-92b0-9d6400f851b9'),
('54e3a90e-c7c4-49ea-83a8-fd68b9880045', '770acffb-cfeb-46dc-92b0-9d6400f851b9'),
('5784ddf2-45fe-4d1d-a979-d629c4dbb1f5','8d6c993e-c2cc-11de-8d13-0010c6dffd0f'),
('0e723a71-021b-4935-af59-b8391552a94a','8d6c993e-c2cc-11de-8d13-0010c6dffd0f'),
('6c89c7b6-3e69-4b81-a765-cd0387c31bdf', 'f875a72e-d98b-4c2a-b318-452f21aca1a8');

-- Criar tabela de logs de alteracao
CREATE TABLE if not exists location_harmonization.location_harmonized_logs (
	tablename varchar(255),
    current_location_id int(16),
    old_location_id int(16),
    uuid_actual_location varchar(255),
	uuid_old_location varchar(255),
    table_name_id int(16)
);

CREATE TABLE if not exists location_harmonization.location_execution_logs (
	execution_id int(16) NOT NULL AUTO_INCREMENT,
	tablename varchar(255),
    location_uuid varchar(255),
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

--DELIMITER $$ 
CREATE PROCEDURE location_harmonization.update_harmonized_location()
BEGIN
	
	DECLARE done INT DEFAULT FALSE;
	DECLARE uuid_old_location varchar(255);
    DECLARE uuid_actual_location varchar(255);
    DECLARE current_location_id int DEFAULT(0);
    DECLARE old_location_id int DEFAULT(0);
    
	DECLARE location_cursor CURSOR FOR SELECT lo.uuid_old_location, lo.uuid_actual_location FROM location_harmonization.location_to_harmonize lo;
	
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	-- Log Harmonization execution status
	insert into location_harmonization.harmonization_execution_status(type, status, start_date) values 
	('harmonization', 'running', now());
	-- Log Harmonization execution status

	OPEN location_cursor;
    
	   locations_cursor:
       LOOP
			FETCH location_cursor INTO uuid_old_location, uuid_actual_location;
            
			IF done THEN LEAVE locations_cursor;
			END IF;

				SET old_location_id = (Select l.location_id from openmrs.location l where l.uuid = uuid_old_location);
            	SET current_location_id = (Select l.location_id from openmrs.location l where l.uuid = uuid_actual_location);
 
			IF (old_location_id IS NOT NULL) AND (current_location_id IS NOT NULL) THEN	
            
				BEGIN
					-- PERCORRER TODAS TABELAS QUE TEM REFERENCIA DE LOCATION 
					DECLARE finished INT DEFAULT FALSE;							

						-- Percorrer appointmentscheduling_appointment_block
						BEGIN
								DECLARE done_app INT DEFAULT FALSE;
								DECLARE app_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE appointment_block_id INT DEFAULT(0);

								DECLARE appointment_cursor CURSOR FOR SELECT app.appointment_block_id, app.location_id as app_location_id, app.uuid FROM openmrs.appointmentscheduling_appointment_block app where app.location_id=old_location_id;

								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_app = TRUE;
								
								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('appointmentscheduling_appointment_block', uuid_old_location, now());
								-- Log Execution

									OPEN appointment_cursor;
		
										appointments_cursor:
											LOOP
												FETCH appointment_cursor INTO appointment_block_id, app_location_id, uuid;
												
												IF done_app THEN LEAVE appointments_cursor;
												END IF;

												BEGIN
												 -- Settar o novo location 
												 update openmrs.appointmentscheduling_appointment_block set location_id=current_location_id where appointment_block_id = appointment_block_id;

												 -- Logar a alteracao
												 insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('appointmentscheduling_appointment_block', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, appointment_block_id);
												
												END;
									END LOOP appointments_cursor;
								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='appointmentscheduling_appointment_block' and location_uuid = uuid_old_location;
								-- Log Execution	

						END;
						-- Percorrer appointmentscheduling_appointment_block

						-- Percorrer appointmentscheduling_provider_schedule
						BEGIN
								DECLARE done_app INT DEFAULT FALSE;
								DECLARE prov_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE provider_schedule_id INT DEFAULT(0);

								DECLARE provider_cursor CURSOR FOR SELECT pro.provider_schedule_id, pro.location_id as prov_location_id, pro.uuid FROM openmrs.appointmentscheduling_provider_schedule pro where pro.location_id=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_app = TRUE;

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('appointmentscheduling_provider_schedule', uuid_old_location, now());
								-- Log Execution	

									OPEN provider_cursor;
		
										providers_cursor:
											LOOP
												FETCH provider_cursor INTO provider_schedule_id, prov_location_id, uuid;
												
												IF done_app THEN LEAVE providers_cursor;
												END IF;

												BEGIN
												 -- Settar o novo location 
												 update openmrs.appointmentscheduling_provider_schedule set location_id=current_location_id where provider_schedule_id = provider_schedule_id;

												 -- Logar a alteracao
												 insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('appointmentscheduling_provider_schedule', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, provider_schedule_id);
												
												END;
									END LOOP providers_cursor;
								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='appointmentscheduling_provider_schedule' and location_uuid = uuid_old_location;
								-- Log Execution	

						END;
						-- Percorrer appointmentscheduling_provider_schedule

						-- Percorrer encounter
						BEGIN
								DECLARE done_enc INT DEFAULT FALSE;
								DECLARE enc_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE encounter_id INT DEFAULT(0);

								DECLARE encounter_cursor CURSOR FOR SELECT enc.encounter_id, enc.location_id as enc_location_id, enc.uuid FROM openmrs.encounter enc where enc.location_id=old_location_id;

							    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_enc = TRUE;

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('encounter', uuid_old_location, now());
								-- Log Execution

									OPEN encounter_cursor;
		
										encounters_cursor:
											LOOP
												FETCH encounter_cursor INTO encounter_id, enc_location_id, uuid;
												
												IF done_enc THEN LEAVE encounters_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.encounter set location_id=current_location_id where encounter_id = encounter_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('encounter', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, encounter_id);

												END;
									END LOOP encounters_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='encounter' and location_uuid = uuid_old_location;
								-- Log Execution		

						END;
						-- Percorrer encounter

						-- Percorrer gaac
						BEGIN
								DECLARE done_gac INT DEFAULT FALSE;
								DECLARE gac_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE gaac_id INT DEFAULT(0);

								DECLARE gac_cursor CURSOR FOR SELECT gc.gaac_id, gc.location_id as gac_location_id, gc.uuid FROM openmrs.gaac gc where gc.location_id=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_gac = TRUE;


								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('gaac', uuid_old_location, now());
								-- Log Execution
	
									OPEN gac_cursor;
		
										gacs_cursor:
											LOOP
												FETCH gac_cursor INTO gaac_id, gac_location_id, uuid;
												
												IF done_gac THEN LEAVE gacs_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.gaac set location_id=current_location_id where gaac_id = gaac_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('gaac', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, gaac_id);

												END;
									END LOOP gacs_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='gaac' and location_uuid = uuid_old_location;
								-- Log Execution	

						END;
						-- Percorrer gaac

						-- Percorrer gaac_family
						BEGIN
								DECLARE done_gcf INT DEFAULT FALSE;
								DECLARE gcf_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE family_id INT DEFAULT(0);

								DECLARE gac_family_cursor CURSOR FOR SELECT gcf.family_id, gcf.location_id as gcf_location_id, gcf.uuid FROM openmrs.gaac_family gcf where gcf.location_id=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_gcf = TRUE;

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('gaac_family', uuid_old_location, now());
								-- Log Execution

									OPEN gac_family_cursor;
		
										gacs_family_cursor:
											LOOP
												FETCH gac_family_cursor INTO family_id, gcf_location_id, uuid;
												
												IF done_gcf THEN LEAVE gacs_family_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.gaac_family set location_id=current_location_id where family_id = family_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('gaac_family', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, family_id);

												END;
									END LOOP gacs_family_cursor;
								
								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='gaac_family' and location_uuid = uuid_old_location;
								-- Log Execution	

						END;
						-- Percorrer gaac_family

						-- Percorrer location
						BEGIN
								DECLARE done_loc INT DEFAULT FALSE;
								DECLARE loc_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE parent_location_id INT DEFAULT(0);

								DECLARE loc_cursor CURSOR FOR SELECT loc.location_id as parent_location_id, loc.location_id as loc_location_id, loc.uuid FROM openmrs.location loc where loc.parent_location=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_loc = TRUE;

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('location', uuid_old_location, now());
								-- Log Execution
	
									OPEN loc_cursor;
		
										locs_cursor:
											LOOP
												FETCH loc_cursor INTO parent_location_id, loc_location_id, uuid;
												
												IF done_loc THEN LEAVE locs_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.location set parent_location=current_location_id where location_id = parent_location_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('location', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, parent_location_id);

												END;
									END LOOP locs_cursor;
								
								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='location' and location_uuid = uuid_old_location;
								-- Log Execution

						END;
						-- Percorrer location

						-- Percorrer location_attribute
						BEGIN
								DECLARE done_att INT DEFAULT FALSE;
								DECLARE att_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE location_attribute_id INT DEFAULT(0);

								DECLARE location_attribute_cursor CURSOR FOR SELECT att.location_attribute_id, att.location_id as att_location_id, att.uuid FROM openmrs.location_attribute att where att.location_id=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_att = TRUE;	

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('location_attribute', uuid_old_location, now());
								-- Log Execution	

									OPEN location_attribute_cursor;
		
										locations_attribute_cursor:
											LOOP
												FETCH location_attribute_cursor INTO location_attribute_id ,att_location_id, uuid;
												
												IF done_att THEN LEAVE locations_attribute_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.location_attribute set location_id=current_location_id where location_attribute_id = location_attribute_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('location_attribute', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, location_attribute_id);

												END;
									END LOOP locations_attribute_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='location_attribute' and location_uuid = uuid_old_location;
								-- Log Execution

						END;
						-- Percorrer location_attribute
						
						-- Percorrer muzima_error_data
						BEGIN
								DECLARE done_muzima INT DEFAULT FALSE;
								DECLARE muzima_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE error_id INT DEFAULT(0);

								DECLARE muzima_error_data_cursor CURSOR FOR SELECT muz.id as error_id, muz.location as muzima_location_id,  muz.uuid FROM openmrs.muzima_error_data muz where muz.location=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_muzima = TRUE;

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('muzima_error_data', uuid_old_location, now());
								-- Log Execution

									OPEN muzima_error_data_cursor;
		
										muzimas_error_data_cursor:
											LOOP
												FETCH muzima_error_data_cursor INTO error_id, muzima_location_id, uuid;
												
												IF done_muzima THEN LEAVE muzimas_error_data_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.muzima_error_data set location=current_location_id where id = error_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('muzima_error_data', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, error_id);

												END;
									END LOOP muzimas_error_data_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='muzima_error_data' and location_uuid = uuid_old_location;
								-- Log Execution

						END;
						-- Percorrer muzima_error_data

						-- Percorrer muzima_queue_data
						BEGIN
								DECLARE done_queue INT DEFAULT FALSE;
								DECLARE muzima_queue_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE queue_id INT DEFAULT(0);

								DECLARE muzima_queue_data_cursor CURSOR FOR SELECT qu.id as queue_id, qu.location as muzima_queue_location_id, qu.uuid FROM openmrs.muzima_queue_data qu where qu.location=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_queue = TRUE;

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('muzima_queue_data', uuid_old_location, now());
								-- Log Execution

									OPEN muzima_queue_data_cursor;
		
										muzimas_queue_data_cursor:
											LOOP
												FETCH muzima_queue_data_cursor INTO queue_id, muzima_queue_location_id, uuid;
												
												IF done_queue THEN LEAVE muzimas_queue_data_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.muzima_queue_data set location=current_location_id where id = queue_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('muzima_queue_data', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, queue_id);

												END;
									END LOOP muzimas_queue_data_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='muzima_queue_data' and location_uuid = uuid_old_location;
								-- Log Execution

						END;
						-- Percorrer muzima_queue_data

						-- Percorrer obs
						BEGIN
								DECLARE done_obs INT DEFAULT FALSE;
								DECLARE obs_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE obs_id INT DEFAULT(0);

								DECLARE obs_cursor CURSOR FOR SELECT ob.obs_id, ob.location_id as obs_location_id, ob.uuid FROM openmrs.obs ob where ob.location_id=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_obs = TRUE;

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('obs', uuid_old_location, now());
								-- Log Execution

									OPEN obs_cursor;
		
										obss_cursor:
											LOOP
												FETCH obs_cursor INTO obs_id, obs_location_id, uuid;
												
												IF done_obs THEN LEAVE obss_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.obs set location_id=current_location_id where obs_id = obs_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('obs', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, obs_id);

												END;
									END LOOP obss_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='obs' and location_uuid = uuid_old_location;
								-- Log Execution

						END;
						-- Percorrer obs

						-- Percorrer patient_identifier
						BEGIN
								DECLARE done_identifier INT DEFAULT FALSE;
								DECLARE patient_identifier_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE patient_identifier_id INT DEFAULT(0);

								DECLARE patient_identifier_cursor CURSOR FOR SELECT ide.patient_identifier_id, ide.location_id as patient_identifier_location_id, ide.uuid FROM openmrs.patient_identifier ide where ide.location_id=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_identifier = TRUE;


								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('patient_identifier', uuid_old_location, now());
								-- Log Execution

									OPEN patient_identifier_cursor;
		
										patients_identifier_cursor:
											LOOP
												FETCH patient_identifier_cursor INTO patient_identifier_id, patient_identifier_location_id, uuid;
												
												IF done_identifier THEN LEAVE patients_identifier_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.patient_identifier set location_id=current_location_id where patient_identifier_id = patient_identifier_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('patient_identifier', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, patient_identifier_id);

												END;
									END LOOP patients_identifier_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='patient_identifier' and location_uuid = uuid_old_location;
								-- Log Execution

						END;
						-- Percorrer patient_identifier

						-- Percorrer patient_program
						BEGIN
								DECLARE done_program INT DEFAULT FALSE;
								DECLARE patient_program_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE patient_program_id 	INT DEFAULT(0);
								

								DECLARE patient_program_cursor CURSOR FOR SELECT pro.patient_program_id, pro.location_id as patient_program_location_id, pro.uuid FROM openmrs.patient_program pro where pro.location_id=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_program = TRUE;	

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('patient_program', uuid_old_location, now());
								-- Log Execution

									OPEN patient_program_cursor;
		
										patients_program_cursor:
											LOOP
												FETCH patient_program_cursor INTO patient_program_id, patient_program_location_id, uuid;
												
												IF done_program THEN LEAVE patients_program_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.patient_program set location_id=current_location_id where patient_program_id = patient_program_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('patient_program', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, patient_program_id);
													
												END;
									END LOOP patients_program_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='patient_program' and location_uuid = uuid_old_location;
								-- Log Execution

						END;
						-- Percorrer patient_program

						-- Percorrer visit
						BEGIN
								DECLARE done_visit INT DEFAULT FALSE;
								DECLARE visit_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE visit_id Int DEFAULT(0);

								DECLARE visit_cursor CURSOR FOR SELECT v.visit_id, v.location_id as visit_location_id, v.uuid FROM openmrs.visit v where v.location_id=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_visit = TRUE;

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('visit', uuid_old_location, now());
								-- Log Execution

									OPEN visit_cursor;
		
										visits_cursor:
											LOOP
												FETCH visit_cursor INTO visit_id, visit_location_id, uuid;
												
												IF done_visit THEN LEAVE visits_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.visit set location_id=current_location_id where visit_id = visit_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('visit', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, visit_id);
													
												END;
									END LOOP visits_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='visit' and location_uuid = uuid_old_location;
								-- Log Execution

						END;
						-- Percorrer visit

						-- Percorrer person_attribute
						BEGIN
								DECLARE done_person_attribute INT DEFAULT FALSE;
								DECLARE person_attribute_location_id varchar(255);
								DECLARE uuid varchar(255);
								DECLARE person_attribute_id INT DEFAULT(0);

								DECLARE person_attribute_cursor CURSOR FOR SELECT peatt.person_attribute_id, peatt.uuid FROM openmrs.person_attribute peatt where peatt.person_attribute_type_id=7 and peatt.value=old_location_id;
								DECLARE CONTINUE HANDLER FOR NOT FOUND SET done_person_attribute = TRUE;

								-- Log Execution
								insert into location_harmonization.location_execution_logs(tablename, location_uuid, start_date) values
								('person_attribute', uuid_old_location, now());
								-- Log Execution

									OPEN person_attribute_cursor;
		
										persons_attribute_cursor:
											LOOP
												FETCH person_attribute_cursor INTO person_attribute_id, uuid;
												
												IF done_person_attribute THEN LEAVE persons_attribute_cursor;
												END IF;

												BEGIN
													-- Settar o novo location 
													update openmrs.person_attribute set value=current_location_id where person_attribute_id = person_attribute_id;

													-- Logar a alteracao
													insert into location_harmonization.location_harmonized_logs(tablename, current_location_id, old_location_id, uuid_actual_location, uuid_old_location, table_name_id) values ('person_attribute', current_location_id , old_location_id, uuid_actual_location,uuid_old_location, person_attribute_id);
													
												END;
									END LOOP persons_attribute_cursor;

								-- Log Execution
								update location_harmonization.location_execution_logs set end_date=now()
								where tablename='person_attribute' and location_uuid = uuid_old_location;
								-- Log Execution

						END;
						-- Percorrer person_attribute

						-- Retire old location 
						update openmrs.location set retired=1, 
											retired_by=1, 
											date_retired=now(),
											retire_reason='Location Harmonization'
										where location_id = old_location_id;

				END;
			-- 	End of general for 
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


