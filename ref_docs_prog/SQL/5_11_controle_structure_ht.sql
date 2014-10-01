;
--champs présents:
DROP table champs_ht;
CREATE table champs_ht as
SELECT column_name as nom_champ_test, data_type as type_champ_test
FROM information_schema.columns
WHERE table_name = 'habillage_txt' 
and column_name not like 'ogc_fid' 
and column_name not like 'the_geom'
and column_name not like 'wkb_geometry';

--champs manquant et type invalid :
DROP table erreurs_champs_ht;
CREATE table erreurs_champs_ht as
SELECT *
    FROM champs_ht t right OUTER JOIN structure_habillage_txt r ON (r.nom_champ_ref = t.nom_champ_test);

DELETE from erreurs_champs_ht
   WHERE nom_champ_test=nom_champ_ref and type_champ_test=type_champ_ref;

UPDATE erreurs_champs_ht
    SET nom_champ_test = 'CHAMP',  type_champ_test = 'MANQUANT:'
    WHERE nom_champ_test is null;

UPDATE erreurs_champs_ht 
    SET type_champ_test = '>TYPE A MODIFIER', nom_champ_ref= 'EN:'
    WHERE type_champ_test <> type_champ_ref and type_champ_test not like 'MANQUANT:';
    
--champs à supprimer et/ou renommer :
INSERT INTO erreurs_champs_ht SELECT * FROM (SELECT *
    FROM  champs_ht t left OUTER JOIN structure_habillage_txt r ON (r.nom_champ_ref = t.nom_champ_test)) as champs_invalid;
    
DELETE from erreurs_champs_ht
    WHERE nom_champ_test=nom_champ_ref;

UPDATE erreurs_champs_ht
    SET type_champ_test = '>CHAMP', nom_champ_ref = 'A RENOMMER',  type_champ_ref = 'OU A SUPPRIMER', largeur_chaine_ref =''
    WHERE nom_champ_ref is null;

ALTER TABLE erreurs_champs_ht
RENAME nom_champ_test TO LISTE;
ALTER TABLE erreurs_champs_ht 
RENAME type_champ_test TO DES;
ALTER TABLE erreurs_champs_ht  
RENAME nom_champ_ref TO ERREURS;
ALTER TABLE erreurs_champs_ht   
RENAME type_champ_ref TO DE; 
ALTER TABLE erreurs_champs_ht 
RENAME largeur_chaine_ref TO STRUCTURE ;
ALTER TABLE erreurs_champs_ht
ADD column HABILLAGE_TXT character varying;
UPDATE erreurs_champs_ht
    SET HABILLAGE_TXT = 'ERREURdg' where erreurs<>'id_map' or liste='id_map';

--select * from erreurs_champs_ht;
--copy (Select * from erreurs_champs_ht) to 'D:\pg_data\erreurs_structure_habillage_txt.txt'
