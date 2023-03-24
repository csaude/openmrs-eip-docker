set autocommit=0;

cat openmrs_encounter.sql | docker exec -i refapp-db /usr/bin/mysql -u root --password=root tmp_openmrs_db
cat openmrs_visit.sql | docker exec -i refapp-db /usr/bin/mysql -u root --password=root tmp_openmrs_db
cat openmrs_obs.sql | docker exec -i refapp-db /usr/bin/mysql -u root --password=root tmp_openmrs_db
cat openmrs_patient_program.sql | docker exec -i refapp-db /usr/bin/mysql -u root --password=root tmp_openmrs_db

select location_id, count(*) from openmrs.encounter group by location_id;
select location_id, count(*) from tmp_openmrs_db.encounter group by location_id;

select location_id, count(*) from openmrs.visit group by location_id;
select location_id, count(*) from tmp_openmrs_db.visit group by location_id;

select location_id, count(*) from openmrs.obs group by location_id;
select location_id, count(*) from tmp_openmrs_db.obs group by location_id;

select location_id, count(*) from openmrs.patient_program group by location_id;
select location_id, count(*) from tmp_openmrs_db.patient_program group by location_id;

update openmrs.encounter set location_id = (select encounter_bkp.location_id from tmp_openmrs_db.encounter encounter_bkp where encounter.encounter_id = encounter_bkp.encounter_id) where exists (select * from tmp_openmrs_db.encounter inner_2 where encounter.encounter_id = inner_2.encounter_id); 

update openmrs.encounter set location_id = 229 where location_id is null;

update openmrs.visit set location_id = (select inner_.location_id from tmp_openmrs_db.visit inner_ where visit.visit_id = inner_.visit_id) where exists (select * from tmp_openmrs_db.visit inner_2 where visit.visit_id = inner_2.visit_id); 
update openmrs.visit set location_id = 229 where location_id is null;

update openmrs.obs set location_id = (select inner_.location_id from tmp_openmrs_db.obs inner_ where obs.obs_id = inner_.obs_id) where exists (select * from tmp_openmrs_db.obs inner_2 where obs.obs_id = inner_2.obs_id); 
update openmrs.obs set location_id = 229 where location_id is null;


update openmrs.patient_program set location_id = (select location_id from tmp_openmrs_db.patient_program inner_ where patient_program.patient_program_id = inner_.patient_program_id) where exists (select * from tmp_openmrs_db.patient_program inner_ where obs.patient_program_id = inner_.patient_program_id); 

update openmrs.patient_program_id set location_id = 229 where location_id is null;
