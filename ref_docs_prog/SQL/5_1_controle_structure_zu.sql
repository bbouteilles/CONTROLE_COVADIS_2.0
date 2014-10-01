;
--champs présents:
DROP table champs_zu;
CREATE table champs_zu as
SELECT column_name as nom_champ_test, data_type as type_champ_test
FROM information_schema.columns
WHERE table_name = 'zone_urba' 
and column_name not like 'ogc_fid' 
and column_name not like 'the_geom'
and column_name not like 'wkb_geometry';

--champs manquant et type invalid :

DROP table erreurs_champs_zu;
CREATE table erreurs_champs_zu as
SELECT *
    FROM champs_zu t right OUTER JOIN structure_zone_urba r ON (r.nom_champ_ref = t.nom_champ_test);

DELETE from erreurs_champs_zu
    WHERE nom_champ_test=nom_champ_ref and type_champ_test=type_champ_ref;

UPDATE erreurs_champs_zu
    SET nom_champ_test = 'CHAMP',  type_champ_test = 'MANQUANT:'
    WHERE nom_champ_test is null;

UPDATE erreurs_champs_zu 
    SET type_champ_test = '>TYPE A MODIFIER', nom_champ_ref= 'EN:'
    WHERE type_champ_test <> type_champ_ref and type_champ_test not like 'MANQUANT:';
    
--champs à supprimer et/ou renommer :
INSERT INTO erreurs_champs_zu SELECT * FROM (SELECT *
    FROM  champs_zu t left OUTER JOIN structure_zone_urba r ON (r.nom_champ_ref = t.nom_champ_test)) as champs_invalid;
    
DELETE from erreurs_champs_zu
    WHERE nom_champ_test=nom_champ_ref;

UPDATE erreurs_champs_zu
    SET type_champ_test = '>CHAMP', nom_champ_ref = 'A RENOMMER',  type_champ_ref = 'OU A SUPPRIMER', largeur_chaine_ref =''
    WHERE nom_champ_ref is null;

ALTER TABLE erreurs_champs_zu 
RENAME nom_champ_test TO LISTE;
ALTER TABLE erreurs_champs_zu 
RENAME type_champ_test TO DES;
ALTER TABLE erreurs_champs_zu  
RENAME nom_champ_ref TO ERREURS;
ALTER TABLE erreurs_champs_zu   
RENAME type_champ_ref TO DE; 
ALTER TABLE erreurs_champs_zu 
RENAME largeur_chaine_ref TO STRUCTURE ;
ALTER TABLE erreurs_champs_zu
ADD column ZONE_URBA character varying;
UPDATE erreurs_champs_zu
    SET ZONE_URBA = 'ERREURdg' where erreurs<>'id_map' or liste='id_map';

--select * from erreurs_champs_zu;
--copy (Select * from erreurs_champs_zu) to 'D:\pg_data\erreurs_structure_zone_urba.txt'
