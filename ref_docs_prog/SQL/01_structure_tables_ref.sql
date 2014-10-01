;
-- DOC_URBA_REF
Drop table if exists structure_doc_urba;
Create table if not exists structure_doc_urba (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_doc_urba values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_doc_urba values ('idurba','character varying','20');
INSERT INTO structure_doc_urba values ('idurbaprec','character varying','20');
INSERT INTO structure_doc_urba values ('typedoc','character varying','3');
INSERT INTO structure_doc_urba values ('etat','character varying','2');
INSERT INTO structure_doc_urba values ('version','character varying','20');
INSERT INTO structure_doc_urba values ('datappro','date','AAAAMMJJ');
INSERT INTO structure_doc_urba values ('datefin','date','AAAAMMJJ');
INSERT INTO structure_doc_urba values ('interco','character varying','1');
INSERT INTO structure_doc_urba values ('siren','character varying','9');
INSERT INTO structure_doc_urba values ('nomreg','character varying','80');
INSERT INTO structure_doc_urba values ('urlreg','character varying','254');
INSERT INTO structure_doc_urba values ('nomplan','character varying','80');
INSERT INTO structure_doc_urba values ('urlplan','character varying','254');
INSERT INTO structure_doc_urba values ('siteweb','character varying','254');
INSERT INTO structure_doc_urba values ('nomref','character varying','254');
INSERT INTO structure_doc_urba values ('dateref','date','AAAAMMJJ');

-- DOC_URBA_COM_REF
Drop table if exists structure_doc_urba_com;
Create table if not exists structure_doc_urba_com (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_doc_urba_com values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_doc_urba_com values ('idurba','character varying','20');
INSERT INTO structure_doc_urba_com values ('insee','character varying','5');
INSERT INTO structure_doc_urba_com values ('date_cog','date','AAAAMMJJ');


-- ZU_REF
Drop table if exists structure_zone_urba;
Create table if not exists structure_zone_urba (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_zone_urba values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_zone_urba values ('idurba','character varying','20');
INSERT INTO structure_zone_urba values ('libelle','character varying','12');
INSERT INTO structure_zone_urba values ('libelong','character varying','254');
INSERT INTO structure_zone_urba values ('typezone','character varying','3');
INSERT INTO structure_zone_urba values ('destdomi','character varying','2');
INSERT INTO structure_zone_urba values ('nomfic','character varying','80');
INSERT INTO structure_zone_urba values ('urlfic','character varying','254');
INSERT INTO structure_zone_urba values ('insee','character varying','5');
INSERT INTO structure_zone_urba values ('datappro','date','AAAAMMJJ');
INSERT INTO structure_zone_urba values ('datvalid','date','AAAAMMJJ');

-- SCC_REF
Drop table if exists structure_secteur_cc;
Create table if not exists structure_secteur_cc (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_secteur_cc values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_secteur_cc values ('idurba','character varying','20');
INSERT INTO structure_secteur_cc values ('libelle','character varying','254');
INSERT INTO structure_secteur_cc values ('typesect','character varying','3');
INSERT INTO structure_secteur_cc values ('fermreco','character varying','3');
INSERT INTO structure_secteur_cc values ('destdomi','character varying','2');
INSERT INTO structure_secteur_cc values ('nomfic','character varying','80');
INSERT INTO structure_secteur_cc values ('urlfic','character varying','254');
INSERT INTO structure_secteur_cc values ('insee','character varying','5');
INSERT INTO structure_secteur_cc values ('datappro','date','AAAAMMJJ');
INSERT INTO structure_secteur_cc values ('datvalid','date','AAAAMMJJ');

-- PS_REF
Drop table if exists structure_prescription_surf;
Create table if not exists structure_prescription_surf (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_prescription_surf values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_prescription_surf values ('libelle','character varying','254');
INSERT INTO structure_prescription_surf values ('txt','character varying','10');
INSERT INTO structure_prescription_surf values ('typepsc','character varying','2');
INSERT INTO structure_prescription_surf values ('nomfic','character varying','80');
INSERT INTO structure_prescription_surf values ('urlfic','character varying','254');
INSERT INTO structure_prescription_surf values ('insee','character varying','5');
INSERT INTO structure_prescription_surf values ('datappro','date','AAAAMMJJ');
INSERT INTO structure_prescription_surf values ('datvalid','date','AAAAMMJJ');

-- PL_REF
Drop table if exists structure_prescription_lin;
Create table if not exists structure_prescription_lin (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_prescription_lin values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_prescription_lin values ('libelle','character varying','254');
INSERT INTO structure_prescription_lin values ('txt','character varying','10');
INSERT INTO structure_prescription_lin values ('typepsc','character varying','2');
INSERT INTO structure_prescription_lin values ('nomfic','character varying','80');
INSERT INTO structure_prescription_lin values ('urlfic','character varying','254');
INSERT INTO structure_prescription_lin values ('insee','character varying','5');
INSERT INTO structure_prescription_lin values ('datappro','date','AAAAMMJJ');
INSERT INTO structure_prescription_lin values ('datvalid','date','AAAAMMJJ');

-- PP_REF
Drop table if exists structure_prescription_pct;
Create table if not exists structure_prescription_pct (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_prescription_pct values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_prescription_pct values ('libelle','character varying','254');
INSERT INTO structure_prescription_pct values ('txt','character varying','10');
INSERT INTO structure_prescription_pct values ('typepsc','character varying','2');
INSERT INTO structure_prescription_pct values ('nomfic','character varying','80');
INSERT INTO structure_prescription_pct values ('urlfic','character varying','254');
INSERT INTO structure_prescription_pct values ('insee','character varying','5');
INSERT INTO structure_prescription_pct values ('datappro','date','AAAAMMJJ');
INSERT INTO structure_prescription_pct values ('datvalid','date','AAAAMMJJ');

-- IS_REF
Drop table if exists structure_info_surf;
Create table if not exists structure_info_surf (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_info_surf values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_info_surf values ('libelle','character varying','254');
INSERT INTO structure_info_surf values ('txt','character varying','10');
INSERT INTO structure_info_surf values ('typeinf','character varying','2');
INSERT INTO structure_info_surf values ('nomfic','character varying','80');
INSERT INTO structure_info_surf values ('urlfic','character varying','254');
INSERT INTO structure_info_surf values ('insee','character varying','5');

-- IL_REF
Drop table if exists structure_info_lin;
Create table if not exists structure_info_lin (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_info_lin values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_info_lin values ('libelle','character varying','254');
INSERT INTO structure_info_lin values ('txt','character varying','10');
INSERT INTO structure_info_lin values ('typeinf','character varying','2');
INSERT INTO structure_info_lin values ('nomfic','character varying','80');
INSERT INTO structure_info_lin values ('urlfic','character varying','254');
INSERT INTO structure_info_lin values ('insee','character varying','5');

-- IP_REF
Drop table if exists structure_info_pct;
Create table if not exists structure_info_pct (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_info_pct values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_info_pct values ('libelle','character varying','254');
INSERT INTO structure_info_pct values ('txt','character varying','10');
INSERT INTO structure_info_pct values ('typeinf','character varying','2');
INSERT INTO structure_info_pct values ('nomfic','character varying','80');
INSERT INTO structure_info_pct values ('urlfic','character varying','254');
INSERT INTO structure_info_pct values ('insee','character varying','5');

-- IS_REFbis
Drop table if exists structure_info_surf_cc;
Create table if not exists structure_info_surf_cc (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_info_surf_cc values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_info_surf_cc values ('libelle','character varying','254');
INSERT INTO structure_info_surf_cc values ('txt','character varying','10');
INSERT INTO structure_info_surf_cc values ('typei','character varying','2');
INSERT INTO structure_info_surf_cc values ('typep','character varying','2');
INSERT INTO structure_info_surf_cc values ('nomfic','character varying','80');
INSERT INTO structure_info_surf_cc values ('urlfic','character varying','254');
INSERT INTO structure_info_surf_cc values ('insee','character varying','5');

-- IL_REFbis
Drop table if exists structure_info_lin_cc;
Create table if not exists structure_info_lin_cc (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_info_lin_cc values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_info_lin_cc values ('libelle','character varying','254');
INSERT INTO structure_info_lin_cc values ('txt','character varying','10');
INSERT INTO structure_info_lin_cc values ('typei','character varying','2');
INSERT INTO structure_info_lin_cc values ('typep','character varying','2');
INSERT INTO structure_info_lin_cc values ('nomfic','character varying','80');
INSERT INTO structure_info_lin_cc values ('urlfic','character varying','254');
INSERT INTO structure_info_lin_cc values ('insee','character varying','5');

-- IP_REFbis
Drop table if exists structure_info_pct_cc;
Create table if not exists structure_info_pct_cc (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_info_pct_cc values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_info_pct_cc values ('libelle','character varying','254');
INSERT INTO structure_info_pct_cc values ('txt','character varying','10');
INSERT INTO structure_info_pct_cc values ('typei','character varying','2');
INSERT INTO structure_info_pct_cc values ('typep','character varying','2');
INSERT INTO structure_info_pct_cc values ('nomfic','character varying','80');
INSERT INTO structure_info_pct_cc values ('urlfic','character varying','254');
INSERT INTO structure_info_pct_cc values ('insee','character varying','5');


--HS_REF
Drop table if exists structure_habillage_surf;
Create table if not exists structure_habillage_surf (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_habillage_surf values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_habillage_surf values ('nattrac','character varying','40');
INSERT INTO structure_habillage_surf values ('insee','character varying','5');

-- HL_REF
Drop table if exists structure_habillage_lin;
Create table if not exists structure_habillage_lin (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_habillage_lin values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_habillage_lin values ('nattrac','character varying','40');
INSERT INTO structure_habillage_lin values ('insee','character varying','5');

-- HP_REF
Drop table if exists structure_habillage_pct;
Create table if not exists structure_habillage_pct (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_habillage_pct values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_habillage_pct values ('nattrac','character varying','40');
INSERT INTO structure_habillage_pct values ('insee','character varying','5');

-- HT_REF
Drop table if exists structure_habillage_txt;
Create table if not exists structure_habillage_txt (
 nom_champ_ref character varying,
 type_champ_ref character varying,
 largeur_chaine_ref character varying
 ); 

INSERT INTO structure_habillage_txt values ('id_map','integer','(optionnel MEDDE)');
INSERT INTO structure_habillage_txt values ('natecr','character varying','40');
INSERT INTO structure_habillage_txt values ('txt','character varying','80');
INSERT INTO structure_habillage_txt values ('insee','character varying','5');








