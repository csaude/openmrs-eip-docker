#!/bin/sh
# EIP RELEASES INFO
#

HOME_DIR="/home/eip"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
RELEASE_DIR="$RELEASE_BASE_DIR/release_stuff"
RELEASE_SCRIPTS_DIR="$RELEASE_DIR/scripts"

export RELEASE_NAME="EIP release v3.0.1.0"
export RELEASE_DATE="2023-02-09 14:40:00"
export RELEASE_DESC="New release with several improvments and new feactures"

export OPENMRS_EIP_APP_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v3.0.1.0/openmrs-eip-app-1.1.jar"
export EPTSSYNC_API_RELEASE_URL="https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases/download/v3.0.1.0/eptssync-api-1.0-SNAPSHOT.jar"

applay_updates_to=("01_molocue_gruveta" "01_molocue_nauela" "01_molocue_sede" "03_derre_sede" "04_gile_alto_ligonha" "04_gile_kayane" "04_gile_mamala" "04_gile_moneia" "04_gile_muiane" "04_gile_sede" "04_gile_uape" "05_gurue_lioma" "05_gurue_sede" "06_ile_mugulama" "06_ile_namanda" "06_ile_sede" "06_socone" "07_inhassunge_bingagira" "07_inhassunge_cherimane" "07_inhassunge_gonhane" "07_inhassunge_mucula" "07_inhassunge_olinda" "07_inhassunge_sede" "08_luabo_sede" "09_lugela_mulide" "09_lugela_munhamade" "09_lugela_namagoa" "09_lugela_putine" "09_lugela_sede" "11_maganja_costa_alto_mutola" "11_maganja_costa_cabuir" "11_maganja_costa_cariua_mapira_muzo" "11_maganja_costa_mabala" "11_maganja_costa_mapira" "11_maganja_costa_moneia" "11_maganja_costa_muloa" "11_maganja_costa_muzo" "11_maganja_costa_namurumo" "11_maganja_costa_nante" "11_maganja_costa_sede" "11_maganja_costa_vila_valdez" "12_milange_carico" "12_milange_chitambo" "12_milange_dachudua" "12_milange_dulanha" "12_milange_gurgunha" "12_milange_hr_milange" "12_milange_liciro" "12_milange_majaua" "12_milange_mongue" "12_milange_muanhambo" "12_milange_nambuzi" "12_milange_sabelua" "12_milange_sede" "12_milange_tengua" "12_milange_vulalo" "13_mocuba_16_de_Junho" "13_mocuba_alto_benfica" "13_mocuba_caiave" "13_mocuba_chimbua" "13_mocuba_hd_mocuba" "13_mocuba_intome" "13_mocuba_magogodo" "13_mocuba_mataia" "13_mocuba_mocuba_sisal" "13_mocuba_muanaco" "13_mocuba_muaquiua" "13_mocuba_mugeba" "13_mocuba_muloi" "13_mocuba_munhiba" "13_mocuba_namabida" "13_mocuba_namagoa" "13_mocuba_namanjavira" "13_mocuba_nhaluanda" "13_mocuba_padre_usera" "13_mocuba_pedreira" "13_mocuba_samora_machel" "13_mocuba_sede" "14_mocubela_bajone" "14_mocubela_gurai" "14_mocubela_ilha_idugo" "14_mocubela_maneia" "14_mocubela_missal" "14_mocubela_naico" "14_mocubela_sede" "14_mocubela_tapata" "15_molumbo_corromana" "15_molumbo_namucumua" "15_molumbo_sede" "16_mopeia_chimuara" "16_mopeia_lua_lua" "16_mopeia_sede" "17_morrumbala_cumbapo" "17_morrumbala_megaza" "17_morrumbala_mepinha" "17_morrumbala_pinda" "17_morrumbala_sede" "19_namacurra_furquia" "19_namacurra_macuse" "19_namacurra_malei" "19_namacurra_mbua" "19_namacurra_muceliuia" "19_namacurra_muebele" "19_namacurra_mugubia" "19_namacurra_mutange" "19_namacurra_muxixine" "19_namacurra_sede" "22_qlm_04_dezembro" "22_qlm_17_set" "22_qlm_24_julho" "22_qlm_chabeco" "22_qlm_coalane" "22_qlm_hospital_geral" "22_qlm_icidua" "22_qlm_inhangule" "22_qlm_ionge" "22_qlm_madal" "22_qlm_malanha" "22_qlm_maquival_rio" "22_qlm_maquival_sede" "22_qlm_marrongana" "22_qlm_micajune" "22_qlm_namuinho" "22_qlm_sangarivela" "22_qlm_varela" "22_qlm_zalala" "23_nicoadala_amoro" "23_nicoadala_domela" "23_nicoadala_ilalane" "23_nicoadala_licuane" "23_nicoadala_namacata" "23_nicoadala_q_girassol" "23_nicoadala_sede" "24_pebane_7_abril" "24_pebane_alto_maganha" "24_pebane_impaca" "24_pebane_magiga" "24_pebane_malema" "24_pebane_mulela" "24_pebane_muligode" "24_pebane_naburi" "24_pebane_pele_pele" "24_pebane_sede" "24_pebane_tomea");

cd $RELEASE_SCRIPTS_DIR

./updates.sh 2>&1 | tee -a $LOG_DIR/upgrade.log
