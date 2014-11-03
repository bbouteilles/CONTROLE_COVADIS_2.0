rem                                        ****************************************************************************
rem                                        *                         FICHIER DE CONFIGURATION  DU                     *
rem                                        *                      BATCH DE CONTROLE DES MISES A JOUR                  *
rem                                        *                                                                          *
rem                                        *                                PLU/POS/CC                                *
rem                                        *                                                                          *
rem                                        *                               COVADIS V2.0                               *
rem                                        *                         (version du %version%)                           *
rem                                        ****************************************************************************
rem set version=06/10/2014
rem script réalisé pour la DDT d'Isère, par Florian Luys - Stage de fin d'étude en Master 2 géomatique à l'Université de Montpellier 2 et 3. (mars/août 2014)

set version=01/11/2014
rem création du fichier unique de paramétrage Ini.bat par Bertrand Bouteilles (DDT Ardèche)


@echo off

rem ===============================================================================================================================================================
rem 1. PARAMETRES DE CONNEXION A LA BASE :
rem ===============================================================================================================================================================
rem **Definir le chemin d'acces à la base dans pgpass.conf ds le repertoire AppData du User de la machine (faire une recherche car rep caché): "host:port:base:user:pass"

rem ***DEFINIR** Hôte de la base de données (localhost pour une base en local ou l'adresse IP de la machine qui héberge la base):
set host= localhost
rem ***DEFINIR** Nom de la base
set base= Controle_COVADIS
rem ***DEFINIR** Nom du schéma utilisé s'il est différente de public
rem Dans ce cas modifier dans import OGR2OGR (active_schema=...) ET dans les requetes SQL (nomschema.)nomtable)
rem set schema=
rem ***DEFINIR** Port de la base
set port= 5432
rem ***DEFINIR** Nom de l'utilisateur de la base (doit avoir les droits d'écriture):
set user= postgres
rem ***DEFINIR** Mot de passe de l'utilisateur
set pass= postgres

rem ===============================================================================================================================================================
rem 2. CHEMINS VERS APPLICATIONS :
rem ===============================================================================================================================================================

rem ***DEFINIR** CHEMIN OGR2OGR (import des couches):
set OGR="C:\Program Files (x86)\FWTools2.4.7\bin\ogr2ogr.exe"
rem ***DEFINIR** CHEMIN PSQL (requetes sql):
set PSQL="C:\Program Files\PostgreSQL\9.2\bin\psql.exe" 
rem ***DEFINIR** CHEMIN PGSQL2SHP (export couches erreurs):
set PGSHP= "C:\Program Files\PostgreSQL\9.2\bin\pgsql2shp.exe" 
rem ***DEFINIR** CHEMIN QGIS : (abandon si qgis fichier par defaut pr .shp/.tab/.mif) nécéssaire pour ouvrir plusieurs couches en même temps MAIS quitte le batch...
set QGIS="C:\OSGeo4W64\bin\qgis.bat" 

rem ===============================================================================================================================================================
rem 3. CHEMINS VERS DONNEES CADASTRALES :
rem ===============================================================================================================================================================

rem ***DEFINIR** Chemin vers les couches cadastrales PCI VECTEUR (DGFIP)
set CADASTREPCI=D:\CONTROLE_COVADIS\ref_docs_prog\ref_cadastre\PCI\SECTION_CADASTRALE.shp
rem ***DEFINIR** Chemin vers les couches cadastrales BDPARCELLAIRE (IGN)
set CADASTREIGN=D:\CONTROLE_COVADIS\ref_docs_prog\ref_cadastre\BD_PARCELLAIRE\N_PARCELLE_BDP_007.shp

