rem                                        ****************************************************************************
rem                                        *                      BATCH DE CONFIGURATION DE POSTGIS                   *
rem                                        *                                                                          *
rem                                        *                                PLU/POS/CC                                *
rem                                        *                                                                          *
rem                                        *                               COVADIS V2.0                               *
rem                                        *                         (version du %version%)                           *
rem                                        ****************************************************************************
rem set version=06/10/2014
rem script réalisé pour la DDT d'Isère, par Florian Luys - Stage de fin d'étude en Master 2 géomatique à l'Université de Montpellier 2 et 3. (mars/août 2014)

set version=01/11/2014
rem modifications de script par Bertrand Bouteilles (DDT Ardèche)
rem		->création et appel dans le script d'un fichier Ini.bat situé dans le répertoire ref_docs_prog



@echo off

rem ===============================================================================================================================================================
rem 0. APPEL DU FICHIER D'INITIALISATION Ini.bat :
rem ===============================================================================================================================================================

call ./Ini.bat

rem ===============================================================================================================================================================
rem 1. EXECUTION DES FICHIERS REQUETE DE CONSTRUCTION DES TABLES :
rem ===============================================================================================================================================================

%PSQL% -d %base% -f %SQL%\00_tables_controle.sql -q -t -h %host% -p %port% -U %user% 
%PSQL% -d %base% -f %SQL%\01_structure_tables_ref.sql -q -t -h %host% -p %port% -U %user% 

rem ===============================================================================================================================================================
rem 2. IMPORT DES COUCHES DEPARTEMENTALES DANS LA BASE :
rem ===============================================================================================================================================================

rem PCI
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln section_dep_DGI "%CADASTREPCI%"
rem BD_PARCELLAIRE
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln section_dep_IGN "%CADASTREIGN%"

pause
