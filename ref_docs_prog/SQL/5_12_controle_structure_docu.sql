;
--champs présents:
DROP table champs_docu;
CREATE table champs_docu as
SELECT column_name as nom_champ_test, data_type as type_champ_test
FROM information_schema.columns
WHERE table_name = 'document_urba' 
and column_name not like 'ogc_fid' 
and column_name not like 'the_geom'
and column_name not like 'wkb_geometry';

--champs manquant et type invalid :
DROP table erreurs_champs_docu;
CREATE table erreurs_champs_docu as
SELECT *
    FROM champs_docu t right OUTER JOIN structure_doc_urba r ON (r.nom_champ_ref = t.nom_champ_test);

DELETE from erreurs_champs_docu
   WHERE nom_champ_test=nom_champ_ref and type_champ_test=type_champ_ref;

UPDATE erreurs_champs_docu
    SET nom_champ_test = 'CHAMP',  type_champ_test = 'MANQUANT:'
    WHERE nom_champ_test is null;

UPDATE erreurs_champs_docu 
    SET type_champ_test = '>TYPE A MODIFIER', nom_champ_ref= 'EN:'
    WHERE type_champ_test <> type_champ_ref and type_champ_test not like 'MANQUANT:';
    
--champs à supprimer et/ou renommer :
INSERT INTO erreurs_champs_docu SELECT * FROM (SELECT *
    FROM  champs_docu t left OUTER JOIN structure_doc_urba r ON (r.nom_champ_ref = t.nom_champ_test)) as champs_invalid;
    
DELETE from erreurs_champs_docu
    WHERE nom_champ_test=nom_champ_ref;

UPDATE erreurs_champs_docu
    SET type_champ_test = '>CHAMP', nom_champ_ref = 'A RENOMMER',  type_champ_ref = 'OU A SUPPRIMER', largeur_chaine_ref =''
    WHERE nom_champ_ref is null;

ALTER TABLE erreurs_champs_docu
RENAME nom_champ_test TO LISTE;
ALTER TABLE erreurs_champs_docu 
RENAME type_champ_test TO DES;
ALTER TABLE erreurs_champs_docu  
RENAME nom_champ_ref TO ERREURS;
ALTER TABLE erreurs_champs_docu   
RENAME type_champ_ref TO DE; 
ALTER TABLE erreurs_champs_docu 
RENAME largeur_chaine_ref TO STRUCTURE ;
ALTER TABLE erreurs_champs_docu
ADD column DOCUMENT_URBA character varying;
UPDATE erreurs_champs_docu
    SET DOCUMENT_URBA = 'ERREURdg' where erreurs<>'id_map' or liste='id_map';
--select * from erreurs_champs_docu;
--copy (Select * from erreurs_champs_ht) to 'D:\pg_data\erreurs_structure_document_urba.txt'
