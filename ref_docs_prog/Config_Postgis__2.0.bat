@echo off
rem **Definir le chemin d'acces à la base dans pgpass.conf ds le repertoire AppData du User de la machine (faire une recherche car rep caché): "host:port:base:user:pass"
rem et ici :
set host= localhost
set user= postgres
set port= 5432
set base= Controle_COVADISV2
set pass= postgres
rem set schema= (à définir si schema différent de public + modif dans import OGR2OGR (active_schema=...) ET dans les requetes SQL (nomschema.)nomtable)

rem DEFINIR CHEMIN PSQL :  
rem maison
 set PSQL="C:\OpenGeo\pgsql\bin\psql.exe" 
rem DDT
rem set PSQL= "C:\Program Files\PostgreSQL\9.3\bin\psql.exe"

rem DEFINIR CHEMIN OGR2OGR :
rem maison
 set OGR="C:\OpenGeo\pgsql\bin\ogr2ogr.exe"
rem DDT
rem set OGR="C:\OSGeo4W64\bin\ogr2ogr.exe"

rem chemin vers fichier requete:
set SQL=C:\Users\FLO\Desktop\Controle_conformite_COVADIS_V2\ref_docs_prog\SQL

rem execution des fichier requete de construction des tables :
 %PSQL% -d %base% -f %SQL%\00_tables_controle.sql -q -t -h %host% -p %port% -U %user% 
 %PSQL% -d %base% -f %SQL%\01_structure_tables_ref.sql -q -t -h %host% -p %port% -U %user% 

rem ===============================================================================================================================================================
rem --CHEMIN VERS COUCHES SECTION (%section%) et IMPORT DES COUCHES DEPARTEMENTALES DANS LA BASE :
rem ===============================================================================================================================================================
set section=C:\Users\FLO\Desktop\Controle_conformite_COVADIS_V2\ref_docs_prog\ref_cadastre

rem PCI
 %OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln section_dep_DGI "%section%\PCI\N_SECTION_DGI_038.shp"
rem BD_PARCELLAIRE
 %OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln section_dep_IGN "%section%\BD_PARCELLAIRE\N_COMMUNE_BDP_038.shp"

pause