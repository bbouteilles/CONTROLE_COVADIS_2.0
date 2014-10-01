;
--champs présents:
DROP table champs_scc;
CREATE table champs_scc as
SELECT column_name as nom_champ_test, data_type as type_champ_test
FROM information_schema.columns
WHERE table_name = 'secteur_cc' 
and column_name not like 'ogc_fid' 
and column_name not like 'the_geom'
and column_name not like 'wkb_geometry';

--champs manquant et type invalid :

DROP table erreurs_champs_scc;
CREATE table erreurs_champs_scc as
SELECT *
    FROM champs_scc t right OUTER JOIN structure_secteur_cc r ON (r.nom_champ_ref = t.nom_champ_test);

DELETE from erreurs_champs_scc
    WHERE nom_champ_test=nom_champ_ref and type_champ_test=type_champ_ref;

UPDATE erreurs_champs_scc
    SET nom_champ_test = 'CHAMP',  type_champ_test = 'MANQUANT:'
    WHERE nom_champ_test is null;

UPDATE erreurs_champs_scc 
    SET type_champ_test = '>TYPE A MODIFIER', nom_champ_ref= 'EN:'
    WHERE type_champ_test <> type_champ_ref and type_champ_test not like 'MANQUANT:';
    
--champs à supprimer et/ou renommer :
INSERT INTO erreurs_champs_scc SELECT * FROM (SELECT *
    FROM  champs_scc t left OUTER JOIN structure_secteur_cc r ON (r.nom_champ_ref = t.nom_champ_test)) as champs_invalid;
    
DELETE from erreurs_champs_scc
    WHERE nom_champ_test=nom_champ_ref;

UPDATE erreurs_champs_scc
    SET type_champ_test = '>CHAMP', nom_champ_ref = 'A RENOMMER',  type_champ_ref = 'OU A SUPPRIMER', largeur_chaine_ref =''
    WHERE nom_champ_ref is null;

ALTER TABLE erreurs_champs_scc 
RENAME nom_champ_test TO LISTE;
ALTER TABLE erreurs_champs_scc 
RENAME type_champ_test TO DES;
ALTER TABLE erreurs_champs_scc  
RENAME nom_champ_ref TO ERREURS;
ALTER TABLE erreurs_champs_scc   
RENAME type_champ_ref TO DE; 
ALTER TABLE erreurs_champs_scc
RENAME largeur_chaine_ref TO STRUCTURE ;
ALTER TABLE erreurs_champs_scc
ADD column SECTEUR_CC character varying;
UPDATE erreurs_champs_scc
    SET SECTEUR_CC = 'ERREURdg' where erreurs<>'id_map' or liste='id_map';

--select * from erreurs_champs_scc copy;
--copy (Select * from erreurs_champs_scc) to 'D:\pg_data\erreurs_structure_secteur_cc.txt'
