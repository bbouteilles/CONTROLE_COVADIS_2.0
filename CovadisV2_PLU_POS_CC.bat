rem                                        ****************************************************************************
rem                                        *                      BATCH DE CONTROLE DES MISES A JOUR                  *
rem                                        *                                                                          *
rem                                        *                                PLU/POS/CC                                *
rem                                        *                                                                          *
rem                                        *                               COVADIS V2.0                               *
rem                                        *                         (version du %version%)                           *
rem                                        ****************************************************************************

rem ===============================================================================================================================================================
rem VERSIONS DU SCRIPT
rem ===============================================================================================================================================================


rem set version=06/10/2014
rem script réalisé pour la DDT d'Isère, par Florian Luys - Stage de fin d'étude en Master 2 géomatique à l'Université de Montpellier 2 et 3. (mars/août 2014)

set version=01/11/2014
rem modifications de script par Bertrand Bouteilles (DDT Ardèche)
rem 	->ajout et utilisation dans le script de la variable département %dep%
rem 	->suppression des anciens fichiers liste*.txt situés à la racine pendant l'initialisation du script
rem 	->suppression de commentaires doublons (usage DDT / usage local) et de commentaires relatifs à l'identifiant ID_MAP de la DDT38
rem 	->ajout du mot clés ELSE dans certaines boucles IF (sinon pb de script avec seven ?)
rem 	->correction du paramètre PRECISION dans les fonctions d'import des fichiers dans la bases de données
rem 	->export du rapport d'erreur au format html pour améliorer la lisibilité du rapport, avec ajout de balises dans le fichier rapport
rem		->création et appel dans le script d'un fichier Ini.bat situé dans le répertoire ref_docs_prog

rem Test des couches via postgresql 9.3.4 (64bit) extension postgis 2.0.1.
rem Import des couches dans postgresql via OGR2OGR de la bibbliotheque GDAL/OGR 1.10.0
rem Export des couches erreurs topo via PSQL2SHP
rem Requetes SQL sur les couches via PSQL
rem ouverture des couches via QGIS 2.0 (ou programme par defaut)

rem désactiver l'affichage des commandes :
@echo off 
rem remise à blanc de l'écran :
cls

rem ===============================================================================================================================================================
rem *DEFINITION AUTO DU CHEMIN DU DOSSIER RACINE DU BATCH (%cd%) 
rem ===============================================================================================================================================================
set WORKING_DIRECTORY=%cd%

rem ===============================================================================================================================================================
rem *PARAMETRAGE POSTGIS :
rem ===============================================================================================================================================================
rem 1- Creer la base de Controle_COVADIS dans pgadmin (creer schema si different de public).
rem 2- Lancer le batch Config_postgis__2.0.bat pour créer les fichiers de reference en ayant paramétré le batch au préalable (chemin vers base, applis et couches section).

rem ===============================================================================================================================================================
rem **PARAMETRES DE CONNEXION A LA BASE :
rem ===============================================================================================================================================================
rem **Definir le chemin d'acces à la base dans pgpass.conf ds le repertoire AppData du User de la machine (faire une recherche car rep caché): "host:port:base:user:pass"
rem et ici :

call %cd%/ref_docs_prog/Ini.bat

rem ===============================================================================================================================================================
rem Message de départ :
echo.
echo.
echo.
echo             *************************************************************
echo             *                  CONTROLE DES MISES A JOUR                *
echo             *                                                           *
echo             *                         PLU/POS/CC                        *
echo             *                                                           *
echo             *                        COVADIS V2.0                       *
echo             *                  (version du %version%)                   *
echo             *************************************************************
echo.
echo.
echo.

rem ===============================================================================================================================================================
rem ****PARAMETRAGE DU BATCH :
rem ===============================================================================================================================================================
rem ===============================================================================================================================================================
rem 00- Module pour déterminer les variables %insee%/%doc%/%datapro%/%referentiel%/%auteur% à l'aide d'un formulaire :
rem ===============================================================================================================================================================
rem activation de l'extension de variables d'environnement retardées (permet de vérifer les variables rentrées par le controleur):
setlocal enableDelayedExpansion


rem --ACTIVER ou DESACTIVER le formulaire pour les variables %insee% %doc% %datapro% avec "rem" et "set"
rem "set" determine une variable, le "/p" permet de demander le retour de la variable par le controleur, le "/a" determine une variable résultante d'un calcul :
:insee
echo.
echo.
set /p insee= "Quel est le numero INSEE de la commune ? (XXXXX): "
rem set insee=
if "%insee%"=="" goto insee
set long_insee=-1
:long1
set /a long_insee+=1
set test1=!insee:~%long_insee%,1!
if not "%test1%"=="" goto long1
if %long_insee% equ 5 (

goto doc
)
goto insee
:doc
echo.
echo.
set /p doc= "Quel est le type de document d'urbanisme ?(PLU/POS/CC): "
rem  set doc=
if "%doc%"=="" goto doc
if /I "%doc%"=="PLU" (
goto datapro
)
if /I "%doc%"=="POS" (
goto datapro
)
if /I "%doc%"=="CC" (
goto datapro
)
goto doc
:datapro
echo.
echo.
set /p datapro= "Quelle est la date d'approbation du document ?(AAAAMMJJ): "
rem  set datapro=
if "%datapro%"=="" goto datapro
set long_datapro=-1
:long2
set /a long_datapro+=1
set test2=!datapro:~%long_datapro%,1!
if not "%test2%"=="" goto long2
if %long_datapro% equ 8 (
goto suite
)
goto datapro


:suite
echo.
set /p referentiel="Quel est le referentiel ?(PCI/IGN/NC): "
echo.            
set /p auteur= "Auteur du controle ?(Nom+DDT/CG): "
rem set auteur= DDT

rem variable département issue de la saisie du numéro insee
set dep=0%insee:~0,2%

rem variable automatique de la date du jour :
rem date du type JJ/MM/AAAA
set datcontrol1=%date%
rem date du type AAAMMJJ
set datcontrol2=%date:~6,4%%date:~3,2%%date:~0,2%
cls
rem affichage récap avec les variables rentrées :
echo.
echo.
echo Le numero du departement est : %dep%
echo Le code insee de la commune est : %insee%
echo Le type de document d'urbanisme est : %doc% 
echo La date d'approbation est : %datapro%

echo.
rem arrêt puis reprise du batch apres confirmation du contrôleur :
set /p variables="Confirmer les variables en entree ? (o/n) : "
IF "%variables%"=="o" (goto variableOK) else goto insee

:variableOK
cls
rem ===============================================================================================================================================================
rem 01 - Module des chemins du répertoire de travail ("Controle_conformite_COVADIS_V2)
rem ===============================================================================================================================================================
rem *CHEMIN DU RAPPORT(%rappconf%) par defaut dans repertoire de travail
rem ===============================================================================================================================================================
rem chaque ligne suivie de ">> %rappconf%" est inscrite dans le rapport(">" inscrite en écrasant les lignes precedentes)
set rappconf=%insee%_Rapport_conformite_%datcontrol2%.html

rem ----------------------------------------------------
rem variables pour parcourir l'arborescence du dossier :
rem ----------------------------------------------------
set doss=%cd%\Depot_des_fichiers
set plu=%doss%\%insee%_%doc%_%datapro%
set pe=%plu%\Pieces_ecrites
set dg=%plu%\Donnees_geographiques
set Ra=%pe%\1_Rapport_de_presentation
set Pa=%pe%\2_PADD
set Re=%pe%\3_Reglement
set An=%pe%\4_Annexes
set Or=%pe%\5_Orientations_amenagement
set DocG=%pe%\6_Documents_graphiques
set ET=%cd%\Erreurs_topo
set ES=%cd%\Erreurs_structure
set SQL=%cd%\ref_docs_prog\SQL


rem ===============================================================================================================================================================
rem *!*EN SUSPENS*!***DEFINIR CHEMIN DE LA COUCHE DE REF POUR LA COMMUNE (pour verification de la projection) : ... code pr ouvrir deux couches dans QGIS avec "call" sans fermer le batch
rem ===============================================================================================================================================================
set COM=%cd%\ref_docs_prog\ref_cadastre\PCI\SECTION_CADASTRALE.shp  


rem                                   ===================================================================================
rem suppression des fichiers présents dans erreurs_structure et erreurs_topo
del /Q/S "%ES%\*.*"
del /Q/S "%ET%\*.*"

rem                                   ===================================================================================
rem suppression des fichiers Liste* et de l'ancien rapport de conformité présents dans le répertoire racine
del /Q/S ".\Liste*.*"
del /Q/S ".\*Rapport_conformite*.*"


rem DEBUT CONTROLE DES FICHIERS LIVRES :
rem *INFO* : chaque ligne "echo" affiche la chaine qui suit dans la console. si la ligne est suivie de ">> %rappconf%", la chaine est inscrite dans le rapport.
rem ===============================================================================================================================================================
echo. >> %rappconf%
echo ^<html^> >> %rappconf%
echo ^<head^> >> %rappconf%
echo ^<meta content="text/html; charset=UTF-8" http-equiv="Content-Type"^>  >> %rappconf%
echo ^</head^> >> %rappconf%
echo ^<body^> >> %rappconf%
echo ^</br^> >> %rappconf%
echo ^<div align="center"^> ^<h1^> Contrôle de conformité au standard Covadis V2.0 >> %rappconf%
echo ^</br^>Commune n° : %insee%^</h1^>  >> %rappconf%
echo  ---  >> %rappconf%
echo ^</br^>^<b^>Version du %version%^</b^>
echo.
echo ^</br^>Contrôle effectué le %datcontrol1% par %auteur% ^</div^> >> %rappconf%
echo.>> %rappconf%
echo Géostandards Covadis disponibles sur : ^<a href="http://archives.cnig.gouv.fr/Front/index.php?RID=120^> >> %rappconf%
echo.>> %rappconf%
echo ^</br^>^<font color="red"^>ATTENTION : Le présent contrôle n'intègre pas la vérification du contenu des >> %rappconf%
echo ^</br^>données attributaires des tables, ni de la bonne reprise des objets>> %rappconf%
echo ^</br^>figurant sur le plan papier opposable.^</font^> >> %rappconf%
echo.>> %rappconf%
echo.>> %rappconf%
cls
echo.

rem ===============================================================================================================================================================--
rem I- Module de contrôle de l'arborescence : présence selon nommage des répertoires
rem ===============================================================================================================================================================--
echo Controle arborescence...
echo ^<blockquote ^> ^<h2^>1. Contrôle de l'arborescence des répertoires^</h2^>^</blockquote ^>  >> %rappconf%
echo. >> %rappconf%
rem ===============================================================================================================================================================
rem 1.1 EXISTENCE DE XXXXX_DOC_AAAAMMJJ :
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h3^>1.1 Répertoire principal %insee%_%doc%_%datapro%^</h3^>^</blockquote ^>  >> %rappconf%

for /f "delims=" %%a in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\%insee%_%doc%_%datapro%"') do (
set chem=%%a
goto Exist
)
mkdir "%doss%\%insee%_%doc%_%datapro%"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>%insee%_%doc%_%datapro%^</i^> n'a pas été créé. ^</font^>^</br^>   >> %rappconf%
goto Fin
:Exist
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>%insee%_%doc%_%datapro%^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem%" "%doss%"  
:Fin
echo. >> %rappconf%
echo. >> %rappconf%


rem ===============================================================================================================================================================
rem 1.2 EXISTENCE DE Donnees_geographiques :
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h3^>1.2  Répertoire Données géographiques^</h3^>^</blockquote ^>  >> %rappconf%
echo.>> %rappconf%
for /f "delims=" %%c in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\Donnees_geographiques"') do (
set chem2=%%c
goto Exist2
)
mkdir "%plu%\Donnees_geographiques"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>Donnees_geographiques^</i^> n'a pas été créé.  ^</font^>^</br^>   >> %rappconf%
goto Fin2
:Exist2
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>Donnees_geographiques^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem2%" "%plu%"
:Fin2
echo. >> %rappconf%
echo. >> %rappconf%

rem ===============================================================================================================================================================
rem 1.3 EXISTENCE DE Pieces_ecrites :
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h3^>1.3 Répertoire Pièces écrites^</h3^>^</blockquote ^>  >> %rappconf%
echo.>> %rappconf%
for /f "delims=" %%b in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\Pieces_ecrites"') do (
set chem1=%%b
goto Exist1
)
mkdir "%plu%\Pieces_ecrites"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>Pieces_ecrites^</i^> n'a pas été créé.  ^</font^>^</br^> >> %rappconf%
goto Fin1
:Exist1
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>Pieces_ecrites^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem1%" "%plu%" 
:Fin1
echo. >> %rappconf%


rem ===============================================================================================================================================================
rem 1.3.1 1_Rapport_de_presentation (PLU/POS+CC)
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h4^>1.3.1 Sous-répertoire 1_Rapport_de_presentation^</h4^>^</blockquote ^>  >> %rappconf%
echo.>> %rappconf%
for /f "delims=" %%d in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\1_Rapport_de_presentation"') do (
set chem3=%%d
goto Exist3
)
mkdir "%pe%\1_Rapport_de_presentation"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>1_Rapport_de_presentation^</i^> n'a pas été créé. ^</font^>^</br^>   >> %rappconf%
goto Fin3
:Exist3
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>1_Rapport_de_presentation^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem3%" "%pe%"
:Fin3
echo. >> %rappconf%

rem renvoi si CC :
IF "%doc%"=="CC" goto  AnnexesCC
rem ===============================================================================================================================================================
rem 1.3.2 2_PADD
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h4^>1.3.2 Sous-répertoire 2_PADD^</h4^>^</blockquote ^>  >> %rappconf%
echo.>> %rappconf%
for /f "delims=" %%e in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\2_PADD"') do (
set chem4=%%e
goto Exist4
)
mkdir "%pe%\2_PADD"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>2_PADD^</i^> n'a pas été créé. ^</font^>^</br^>   >> %rappconf%
goto Fin4
:Exist4
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>2_PADD^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem4%" "%pe%"
:Fin4
echo. >> %rappconf%

rem ===============================================================================================================================================================
rem 1.3.3 3_Reglement
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h4^>1.3.3 Sous-répertoire 3_Reglement^</h4^>^</blockquote ^>  >> %rappconf%
echo.>> %rappconf%
for /f "delims=" %%f in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\3_Reglement"') do (
set chem5=%%f
goto Exist5
)
mkdir "%pe%\3_Reglement"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>3_Reglement^</i^> n'a pas été créé. ^</font^>^</br^>   >> %rappconf%
goto Fin5
:Exist5
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>3_Reglement^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem5%" "%pe%"
:Fin5
echo. >> %rappconf%

rem ===============================================================================================================================================================
rem 1.3.4 4_Annexes
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h4^>1.3.3 Sous-répertoire 4_Annexes^</h4^>^</blockquote ^>  >> %rappconf%
echo.>> %rappconf%
for /f "delims=" %%g in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\4_Annexes"') do (
set chem6=%%g
goto Exist6
)
mkdir "%pe%\4_Annexes"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>4_Annexes^</i^> n'a pas été créé. ^</font^>^</br^>   >> %rappconf%
goto Fin6
:Exist6
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>4_Annexes^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem6%" "%pe%"
:Fin6
echo. >> %rappconf%
goto Ordoss

rem ===============================================================================================================================================================
rem 1.3.4 bis 2_Annexes (CC)
rem ===============================================================================================================================================================
:AnnexesCC
echo ^<blockquote ^> ^<h4^>1.3.3 Sous-répertoire 2_Annexes^</h4^>^</blockquote ^>  >> %rappconf%
echo.>> %rappconf%
for /f "delims=" %%g in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\2_Annexes"') do (
set chem6bis=%%g
goto Exist6bis
)
mkdir "%pe%\2_Annexes"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>2_Annexes^</i^> n'a pas été créé. ^</font^>^</br^>   >> %rappconf%
goto Fin8
:Exist6bis
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>2_Annexes^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem6bis%" "%pe%"
goto Fin8

:Ordoss
rem ===============================================================================================================================================================
rem 1.3.5 5_Orientations_amenagement
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h4^>1.3.4 Sous-répertoire 5_Orientations_amenagement^</h4^>^</blockquote ^>  >> %rappconf%
echo.>> %rappconf%
for /f "delims=" %%h in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\5_Orientations_amenagement"') do (
set chem7=%%h
goto Exist7
)
mkdir "%pe%\5_Orientations_amenagement"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>5_Orientations_amenagement^</i^> n'a pas été créé. ^</font^>^</br^>   >> %rappconf%
goto Fin7
:Exist7
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>5_Orientations_amenagement^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem7%" "%pe%"
:Fin7
echo. >> %rappconf%

rem ===============================================================================================================================================================
rem 1.3.6 6_Documents_graphiques
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h4^>1.3.5 Sous-répertoire 6_Documents_graphiques (optionnel)^</h4^>^</blockquote ^>  >> %rappconf%
echo.>> %rappconf%
for /f "delims=" %%p in ('dir /s /b /ad "%doss%" 2^>nul ^| findstr /i "\6_Documents_graphiques"') do (
set chem8=%%p
goto Exist8
)
mkdir "%pe%\6_Documents_graphiques"
echo ^<font color="red"^>ERREUR : le répertoire ^<i^>6_Documents_graphiques^</i^> n'a pas été créé. ^</font^>^</br^>   >> %rappconf%
goto Fin8
:Exist8
echo ^<font color="green"^>CONFORME : le répertoire ^<i^>6_Documents_graphiques^</i^> existe.  ^</font^>^</br^>  >> %rappconf%
move "%chem8%" "%pe%"
:Fin8
echo. >> %rappconf%
echo. >> %rappconf%
cls
echo Controle de l'arborescence...

rem ===============================================================================================================================================================
rem BILAN controle arborescence :
rem ===============================================================================================================================================================
for /F "usebackq" %%i in (`type %rappconf% ^|find /c "ERREUR"`) do (
set arbo=%%i
)
echo.
echo %arbo% Erreur(s)
IF %arbo%==0 goto arbo1
IF not %arbo%==0 goto arbo2
:arbo1
echo --------------------------------------------------------------------------------
echo ^<font color="green"^>^<h2^>^<div align="center"^>^<u^>Arborescence : CONFORME^</u^>^</h2^>^</div align="center"^> ^</font^>^</br^>  >> %rappconf%
echo *Arborescence : CONFORME*
goto arbo3
:arbo2
echo --------------------------------------------------------------------------------
echo ^<font color="red"^>^<h2^>^<div align="center"^>^<u^>Arborescence : NON CONFORME^</u^>^</h2^>^</div align="center"^> ^</font^>^</br^>  >> %rappconf%
echo *Arborescence : NON CONFORME*
:arbo3
echo. >> %rappconf%
echo.
echo ...fin
pause
rem ===============================================================================================================================================================


rem ===============================================================================================================================================================
rem Choix du controle :
rem ===============================================================================================================================================================
:question
cls
echo.
echo Que souhaitez vous faire ?
echo  1- Controler seulement les PDF 
echo  2- Controler seulement les Donnees Geographiques 
echo  3- Controler les PDF et les Donnees Geographiques 
echo.
set /p choix="(1 ou 2 ou 3) : "

if /I "%choix%"=="1" (
echo ^<font color="blue"^>ATTENTION : Le controle des données géographiques n'a pas été effectué.^</font^>^</br^>  >> %rappconf%
echo. >> %rappconf%
goto DebutControlePDF
)
if /I "%choix%"=="2" (
echo ^<font color="blue"^>ATTENTION : Le controle des pdf n'a pas été effectué.^</font^>^</br^>  >> %rappconf%
echo. >> %rappconf%
goto DebutControleDG
)
if /I "%choix%"=="3" (goto DebutControlePDF)
goto question

:DebutControlePDF

rem ===============================================================================================================================================================
rem ===============================================================================================================================================================
rem II- Module de contrôle des PDF 
rem ===============================================================================================================================================================

cls
echo Controle des PDF...
echo ^<blockquote ^> ^<h2^>2. Contrôle des fichiers pdf^</h2^>^</blockquote ^>  >> %rappconf%
echo. >> %rappconf%

rem ===============================================================================================================================================================
rem 2.0 Detection des PDF (listePDF)
rem ===============================================================================================================================================================

rem extraction de la liste des pdf livrés :
dir n/b/s %doss%\*.pdf > liste_pdf_%insee%.txt

rem Compte les pdf livrés :
for /F "usebackq" %%r in (`type liste_pdf_%insee%.txt ^|find /c ".pdf"`) do (
set pdf0=%%r
)
rem conditions si pdf ou non :
IF "%pdf0%"=="0" (goto AucunPDF) else goto PDF

:AucunPDF
cls
echo Controle des PDF...
echo.
echo ...Aucun pdf detectes !
echo ^<font color="red"^>ERREUR : Aucun pdf n'a été livré. ^</font^>^</br^>   >> %rappconf%
del liste_pdf_%insee%.txt
goto BilanPDF

:PDF
echo Liste des fichiers pdf livrés : >> %rappconf% 
rem extraction de la liste des pdf livrés avec nomfichier + extension (parametre ~nx):
for /F %%s in ('type liste_pdf_%insee%.txt^|find /i ".pdf"') do (
echo    ^<blockquote ^> %%~nxs ^</blockquote ^> >> %rappconf%
echo    %%~nxs >> liste_nom_pdf_%insee%.txt
)

rem ===============================================================================================================================================================
rem 2.1.0 CONTROLE XXXXX_rapport_AAAAMMJJ :
rem ===============================================================================================================================================================

echo.>> %rappconf%
echo ^<blockquote ^> ^<h3^>2.1 %insee%_rapport_%datapro%.pdf^</h3^>^</blockquote^>  >> %rappconf%
echo.>> %rappconf%
rem recherche dans les noms des pdf "rapport":
for /f %%j in ('type liste_pdf_%insee%.txt ^| find /i "rapport"') do (
move "%%j" "%Ra%"
)
rem definition du chemin avec nom conforme et verifie son existence :
set pdfRa=%Ra%\%insee%_rapport_%datapro%.pdf
IF EXIST "%pdfRa%" (
goto RaOK
) else goto ConcatRa
rem si oui conforme sinon test concatenage et nommage:
:RaOK
echo ^<font color="green"^>CONFORME : le pdf %insee%_rapport_%datapro% a bien été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto OpenRa

rem ===============================================================================================================================================================
rem 2.1.1 NOMMAGE et CONCATENAGE  XXXXX_rapport_AAAAMMJJ 
rem ===============================================================================================================================================================

:ConcatRa
rem compte des pdf avec "rapport":
for /f %%q in ('type liste_nom_pdf_%insee%.txt ^| find /i /c "rapport"') do (
set NumRa=%%q
)
rem si>1 message affichant les pdf :
IF %NumRa% GTR 1 (
cls
echo Controle des PDF...
echo Il existe %NumRa% pdf nommes avec "rapport":
for /F %%s in ('type liste_nom_pdf_%insee%.txt^|find /i "rapport"') do echo    %%~nxs
set /p concat1="Faut-il proposer la concatenation dans le rapport ? (o/n) : ")
rem question si oui il faut les concatener message dans rapport et passage au suivant sinon test nommage:
IF "%concat1%"=="o" (
echo ^<font color="red"^>ERREUR : le pdf est à concaténer et à renommer : %insee%_rapport_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo.>> %rappconf%
goto FinRa
)
rem test nommage :
:NomRa
IF EXIST  "%Ra%\*rapport*.pdf" (
echo ^<font color="red"^>ERREUR : le pdf est à renommer : %insee%_rapport_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinRa
) else (
echo ^<font color="red"^>ERREUR : le pdf %insee%_rapport_%datapro% n'a pas été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinRa
)

rem ===============================================================================================================================================================
rem 2.1.2 OUVERTURE DU PDF XXXXX_rapport_AAAAMMJJ :
rem ===============================================================================================================================================================

:OpenRa
cls
echo Controle des PDF...
rem ouvrir si pdf détecté :
set /p pdfRap= "Le pdf %insee%_rapport_%datapro% a bien ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des PDF...
IF "%pdfRap%"=="o" (goto ORA) else goto FinRa
:ORA
rem ouverture du pdf :
 "%pdfRa%" /cmd
set /p Raprob= "%insee%_rapport_%datapro% s'ouvre-t-il ? (o/n) : "
IF "%Raprob%"=="n" (
echo ^<font color="red"^>ERREUR : le pdf %insee%_rapport_%datapro% ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
) 
cls
echo Controle des PDF...
rem INDEX :
set /p index1= "Le pdf du rapport de presentation est-il indexe ? (o/n): "
cls
echo Controle des PDF...
IF "%index1%"=="n" (goto index1) else goto FinRa
:index1
echo.>> %rappconf% 
echo ^<font color="red"^>ERREUR : le pdf du rapport de presentation n'est pas indexé.  ^</font^>^</br^>   >> %rappconf% 
:FinRa
cls
echo Controle des PDF...
rem ===============================================================================================================================================================
rem renvoi si "CC":
IF "%doc%"=="CC" goto AnCC

rem ===============================================================================================================================================================
rem 2.2.0 CONTROLE XXXXX_padd_AAAAMMJJ :
rem ===============================================================================================================================================================
echo.>> %rappconf%
echo ^<blockquote ^> ^<h3^>2.2 %insee%_padd_%datapro%.pdf^</h3^>^</blockquote^>  >> %rappconf%
echo.>> %rappconf%

rem recherche dans les noms des pdf "padd":
for /f %%j in ('type liste_pdf_%insee%.txt ^| find /i "padd"') do (
move "%%j" "%Pa%"
)
rem definition du chemin avec nom conforme et verifie son existence :
set pdfPa=%Pa%\%insee%_padd_%datapro%.pdf
IF EXIST "%pdfPa%" (
goto PaOK
) else goto ConcatPa
rem si oui conforme sinon test concatenage et nommage:
:PaOK
echo ^<font color="green"^>CONFORME : le pdf %insee%_padd_%datapro% a bien été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto OpenPa

rem ===============================================================================================================================================================
rem 2.2.1 NOMMAGE et CONCATENAGE XXXXX_padd_AAAAMMJJ
rem ===============================================================================================================================================================

:ConcatPa
rem compte des pdf avec "padd":
for /f %%q in ('type liste_nom_pdf_%insee%.txt ^| find /i /c "padd"') do (
set NumPa=%%q
)
rem si>1 message affichant les pdf :
IF %NumPa% GTR 1 (
cls
echo Controle des PDF...
echo Il existe %NumPa% pdf nommes avec "padd":
for /F %%s in ('type liste_nom_pdf_%insee%.txt^|find /i "padd"') do echo    %%~nxs
set /p concat2="Faut-il proposer la concatenation dans le rapport ? (o/n) : ")
rem question si oui il faut les concatener message dans rapport et passage au suivant sinon test nommage:
IF "%concat2%"=="o" (
echo ^<font color="red"^>ERREUR : le pdf est à concaténer et à renommer : %insee%_padd_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo.>> %rappconf%
goto FinPa
)
rem test nommage :
:NomPa
IF EXIST  "%Pa%\*padd*.pdf" (
echo ^<font color="red"^>ERREUR : le pdf est à renommer : %insee%_padd_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinPa
) else (
echo ^<font color="red"^>ERREUR : le pdf %insee%_padd_%datapro% n'a pas été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinPa
)

rem ===============================================================================================================================================================
rem 2.2.2 OUVERTURE DU PDF XXXXX_padd_AAAAMMJJ :
rem ===============================================================================================================================================================

:OpenPa
cls
echo Controle des PDF...
rem ouvrir si pdf détecté :
set /p pdfPad= "Le pdf %insee%_padd_%datapro% a bien ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des PDF...
IF "%pdfPad%"=="o" goto OPA
IF not "%pdfPad%"=="o" goto FinPa
rem ouverture du pdf :
:OPA
rem ouverture du pdf :
 "%pdfPa%" /cmd
set /p Paprob= "%insee%_padd_%datapro% s'ouvre-t-il ? (o/n) : "
IF "%Paprob%"=="n" (
echo ^<font color="red"^>ERREUR : le pdf %insee%_padd_%datapro% ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
)
cls
echo Controle des PDF...
rem INDEX :
set /p index2= "Le pdf du PADD est-il indexe ? (o/n): "
cls
echo Controle des PDF...
IF "%index2%"=="n" (goto index2) else goto FinPa
:index2
echo.>> %rappconf% 
echo ^<font color="red"^>ERREUR : le pdf du PADD n'est pas indexé.  ^</font^>^</br^>   >> %rappconf% 
:FinPa
cls
echo Controle des PDF...

rem ===============================================================================================================================================================
rem 2.3.0 CONTROLE XXXXX_reglement_AAAAMMJJ
rem ===============================================================================================================================================================

echo.>> %rappconf%
echo ^<blockquote ^> ^<h3^>2.2 %insee%_reglement_%datapro%.pdf^</h3^>^</blockquote^>  >> %rappconf%
echo.>> %rappconf%

rem recherche dans les noms des pdf "reglement":
for /f %%j in ('type liste_pdf_%insee%.txt ^| find /i "reglement"') do (
move "%%j" "%Re%"
)
rem definition du chemin avec nom conforme et verifie son existence :
set pdfRe=%Re%\%insee%_reglement_%datapro%.pdf
IF EXIST "%pdfRe%" (
goto ReOK
) else goto ConcatRe
rem si oui conforme sinon test concatenage et nommage:
:ReOK
echo ^<font color="green"^>CONFORME : le pdf %insee%_reglement_%datapro% a bien été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto OpenRe

rem ===============================================================================================================================================================
rem 2.3.1 NOMMAGE et CONCATENAGE XXXXX_reglement_AAAAMMJJ
rem ===============================================================================================================================================================

:ConcatRe
rem compte des pdf avec "reglement":
for /f %%q in ('type liste_nom_pdf_%insee%.txt ^| find /i /c "reglement"') do (
set NumRe=%%q
)
rem si>1 message affichant les pdf :
IF %NumRe% GTR 1 (
cls
echo Controle des PDF...
echo Il existe %NumRe% pdf nommes avec "reglement":
for /F %%s in ('type liste_nom_pdf_%insee%.txt^|find /i "reglement"') do echo    %%~nxs
set /p concat3="Faut-il proposer la concatenation dans le rapport ? (o/n) : ")
rem question si oui il faut les concatener message dans rapport et passage au suivant sinon test nommage:
IF "%concat3%"=="o" (
echo ^<font color="red"^>ERREUR : le pdf est à concaténer et à renommer : %insee%_reglement_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo.>> %rappconf%
goto FinRe
)
rem test nommage :
:NomRe
IF EXIST  "%Re%\*reglement*.pdf" (
echo ^<font color="red"^>ERREUR : le pdf est à renommer : %insee%_reglement_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinRe
) else (
echo ^<font color="red"^>ERREUR : le pdf %insee%_reglement_%datapro% n'a pas été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinRe
)
rem ===============================================================================================================================================================
rem 2.3.2 OUVERTURE DU PDF XXXXX_reglement_AAAAMMJJ
rem ===============================================================================================================================================================
:OpenRe
cls
echo Controle des PDF...
rem ouvrir si pdf détecté :
set /p pdfReg= "Le pdf %insee%_reglement_%datapro% a bien ete livre. Voulez-vous l'ouvrir ?(o/n): "
cls
echo Controle des PDF...
IF "%pdfReg%"=="o" goto ORE
IF not "%pdfReg%"=="o" goto FinRe
rem ouverture du pdf :
:ORE
 "%pdfRe%" /cmd 
set /p Reprob= "%insee%_reglement_%datapro% s'ouvre-t-il ? (o/n) : "
IF "%Reprob%"=="n" (
echo ^<font color="red"^>ERREUR : le pdf %insee%_reglement_%datapro% ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
goto FinRe
)
cls
echo Controle des PDF...
rem INDEX :
set /p index3= "Le pdf du reglement est-il indexe ? (o/n): "
cls
echo Controle des PDF...
IF "%index3%"=="n" (goto index3) else goto FinRe
:index3
echo.>> %rappconf% 
echo ^<font color="red"^>ERREUR : le pdf du règlement n'est pas indexé.  ^</font^>^</br^>   >> %rappconf% 
:FinRe
cls
echo Controle des PDF...

rem ===============================================================================================================================================================
rem 2.4.0 CONTROLE XXXXX_annexes_AAAAMMJJ
rem ===============================================================================================================================================================

echo.>> %rappconf%
echo ^<blockquote ^> ^<h3^>2.2 %insee%_annexes_%datapro%.pdf^</h3^>^</blockquote^>  >> %rappconf%
echo.>> %rappconf%

rem recherche dans les noms des pdf "annexes":
for /f %%j in ('type liste_pdf_%insee%.txt ^| find /i "annexes"') do (
move "%%j" "%An%"
)
rem definition du chemin avec nom conforme et verifie son existence :
set pdfAn=%An%\%insee%_annexes_%datapro%.pdf
IF EXIST "%pdfAn%" (
goto AnOK
) else goto ConcatAn
rem si oui conforme sinon test concatenage et nommage:
:AnOK
echo ^<font color="green"^>CONFORME : le pdf %insee%_annexe_%datapro% a bien été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto OpenAn
rem ===============================================================================================================================================================
rem 2.4.1 NOMMAGE et CONCATENAGE XXXXX_annexes_AAAAMMJJ
rem ===============================================================================================================================================================
:ConcatAn
rem compte des pdf avec "annexes":
for /f %%q in ('type liste_nom_pdf_%insee%.txt ^| find /i /c "annexes"') do (
set NumAn=%%q
)
rem si>1 message affichant les pdf :
IF %NumAn% GTR 1 (
cls
echo Controle des PDF...
echo Il existe %NumAn% pdf nommes avec "annexes":
for /F %%s in ('type liste_nom_pdf_%insee%.txt^|find /i "annexes"') do echo    %%~nxs
set /p concat4="Faut-il proposer la concatenation dans le rapport ? (o/n) : ")
rem question si oui il faut les concatener message dans rapport et passage au suivant sinon test nommage:
IF "%concat4%"=="o" (
echo ^<font color="red"^>ERREUR : le pdf est à concaténer et à renommer : %insee%_annexes_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo.>> %rappconf%
goto FinAn
)
rem test nommage :
:NomAn
IF EXIST  "%An%\*annexes*.pdf" (
echo ^<font color="red"^>ERREUR : le pdf est à renommer : %insee%_annexes_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinAn
) else (
echo ^<font color="red"^>ERREUR : le pdf %insee%_annexes_%datapro% n'a pas été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinAn
)
rem ===============================================================================================================================================================
rem 2.4.2 OUVERTURE DU PDF XXXXX_annexes_AAAAMMJJ
rem ===============================================================================================================================================================
:OpenAn
cls
echo Controle des PDF...
rem ouvrir si pdf détecté :
set /p pdfAnn= "Le pdf %insee%_annexes_%datapro% a bien ete livre. Voulez-vous l'ouvrir ?(o/n): "
cls
echo Controle des PDF...
IF "%pdfAnn%"=="o" goto OAN
IF not "%pdfAnn%"=="o" goto FinAn
rem ouverture du pdf :
:OAN
rem ouverture du pdf :
 "%pdfAn%" /cmd
set /p Anprob= "%insee%_annexes_%datapro% s'ouvre-t-il ? (o/n) : "
IF "%Anprob%"=="n" (
echo ^<font color="red"^>ERREUR : le pdf %insee%_annexes_%datapro% ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
)
cls
echo Controle des PDF...
rem INDEX :
set /p index4= "Le pdf des annexes est-il indexe ? (o/n): "
cls
echo Controle des PDF...
IF "%index4%"=="n" (goto index4) else goto FinAn
:index4
echo.>> %rappconf% 
echo ^<font color="red"^>ERREUR : le pdf des annexes n'est pas indexé.  ^</font^>^</br^>   >> %rappconf% 
:FinAn 
cls
echo Controle des PDF...
goto PDFOR

:AnCC

rem ===============================================================================================================================================================
rem 2.4bis CONTROLE XXXXX_annexes_AAAAMMJJ (CC)
rem ===============================================================================================================================================================

echo.>> %rappconf%
echo ^<blockquote ^> ^<h3^>2.2 %insee%_annexes_%datapro%.pdf^</h3^>^</blockquote^>  >> %rappconf%
echo.>> %rappconf%

rem recherche dans les noms des pdf "annexes":
for /f %%j in ('type liste_pdf_%insee%.txt ^| find /i "annexes"') do (
move "%%j" "%pe%\2_Annexes"
)
rem definition du chemin avec nom conforme et verifie son existence :
set pdfAnbis=%pe%\2_Annexes\%insee%_annexes_%datapro%.pdf
IF EXIST "%pdfAnbis%" (
goto AnOKbis
) else goto ConcatAnbis
rem si oui conforme sinon test concatenage et nommage:
:AnOKbis
echo ^<font color="green"^>CONFORME : le pdf %insee%_annexe_%datapro% a bien été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto OpenAnbis
rem ===============================================================================================================================================================
rem 2.4.1bis NOMMAGE et CONCATENAGE XXXXX_annexes_AAAAMMJJ (CC)
rem ===============================================================================================================================================================
:ConcatAnbis
rem compte des pdf avec "annexes":
for /f %%q in ('type liste_nom_pdf_%insee%.txt ^| find /i /c "annexes"') do (
set NumAnbis=%%q
)
rem si>1 message affichant les pdf :
IF %NumAnbis% GTR 1 (
cls
echo Controle des PDF...
echo Il existe %NumAnbis% pdf nommes avec "annexes":
for /F %%s in ('type liste_nom_pdf_%insee%.txt^|find /i "annexes"') do echo    %%~nxs
set /p concat4bis="Faut-il proposer la concatenation dans le rapport ? (o/n) : ")
rem question si oui il faut les concatener message dans rapport et passage au suivant sinon test nommage:
IF "%concat4bis%"=="o" (
echo ^<font color="red"^>ERREUR : le pdf est à concaténer et à renommer : %insee%_annexes_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo.>> %rappconf%
goto FinAnbis
)
rem test nommage :
:NomAnbis
IF EXIST  "%pe%\2_Annexes\*annexes*.pdf" (
echo ^<font color="red"^>ERREUR : le pdf est à renommer : %insee%_annexes_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinAnbis
) else (
echo ^<font color="red"^>ERREUR : le pdf %insee%_annexes_%datapro% n'a pas été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinAnbis
)
rem ===============================================================================================================================================================
rem 2.4.2bis OUVERTURE DU PDF XXXXX_annexes_AAAAMMJJ (CC)
rem ===============================================================================================================================================================
:OpenAnbis
cls
echo Controle des PDF...
rem ouvrir si pdf détecté :
set /p pdfAnn= "Le pdf %insee%_annexes_%datapro% a bien ete livre. Voulez-vous l'ouvrir ?(o/n): "
cls
echo Controle des PDF...
IF "%pdfAnnbis%"=="o" goto OANbis
IF not "%pdfAnnbis%"=="o" goto FinAnbis
rem ouverture du pdf :
:OANbis
rem ouverture du pdf :
 "%pdfAnbis%" /cmd
set /p Anprobbis= "%insee%_annexes_%datapro% s'ouvre-t-il ? (o/n) : "
IF "%Anprobbis%"=="n" (
echo ^<font color="red"^>ERREUR : le pdf %insee%_annexes_%datapro% ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
)
rem INDEX :
set /p index= "Le pdf des annexes est-il indexe ? (o/n): "
cls
echo Controle des PDF...
IF "%index%"=="n" (goto index) else goto FinAnbis
:index
echo.>> %rappconf% 
echo ^<font color="red"^>ERREUR : le pdf des annexes n'est pas indexé.  ^</font^>^</br^>   >> %rappconf% 
:FinAnbis 
goto FinDocG
rem ===============================================================================================================================================================



:PDFOR
rem ===============================================================================================================================================================
rem 2.5.0 CONTROLE XXXXX_orientations_AAAAMMJJ
rem ===============================================================================================================================================================
echo.>> %rappconf%
echo ^<blockquote ^> ^<h3^>2.2 %insee%_orientations_%datapro%.pdf^</h3^>^</blockquote^>  >> %rappconf%
echo.>> %rappconf%

rem recherche dans les noms des pdf "orientations":
for /f %%j in ('type liste_pdf_%insee%.txt ^| find /i "orientations"') do (
move "%%j" "%Or%"
)
rem definition du chemin avec nom conforme et verifie son existence :
set pdfOr=%Or%\%insee%_orientations_%datapro%.pdf
IF EXIST "%pdfOr%" (
goto OrOK
) else goto ConcatOr
rem si oui conforme sinon test concatenage et nommage:
:OrOK
echo ^<font color="green"^>CONFORME : le pdf %insee%_orientations_%datapro% a bien été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto OpenOr
rem ===============================================================================================================================================================
rem 2.5.1 NOMMAGE et CONCATENAGE XXXXX_orientations_AAAAMMJJ
rem ===============================================================================================================================================================
:ConcatOr
rem compte des pdf avec "orientations":
for /f %%q in ('type liste_nom_pdf_%insee%.txt ^| find /i /c "orientations"') do (
set NumOr=%%q
)
rem si>1 message affichant les pdf :
IF %NumOr% GTR 1 (
cls
echo Controle des PDF...
echo Il existe %NumOr% pdf nommes avec "orientations":
for /F %%s in ('type liste_nom_pdf_%insee%.txt^|find /i "orientations"') do echo    %%~nxs
set /p concat5="Faut-il proposer la concatenation dans le rapport ? (o/n) : ")
rem question si oui il faut les concatener message dans rapport et passage au suivant sinon test nommage:
IF "%concat5%"=="o" (
echo ^<font color="red"^>ERREUR : le pdf est à concaténer et à renommer : %insee%_orientations_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo.>> %rappconf%
goto FinOr
)
rem test nommage :
:NomOr
IF EXIST  "%Or%\*orientations*.pdf" (
echo ^<font color="red"^>ERREUR : le pdf est à renommer : %insee%_orientations_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinOr
) else (
echo ^<font color="red"^>ERREUR : le pdf %insee%_orientations_%datapro% n'a pas été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinOr
)
rem ===============================================================================================================================================================
rem 2.5.2 OUVERTURE DU PDF XXXXX_orientations_AAAAMMJJ
rem ===============================================================================================================================================================
:OpenOr
cls
echo Controle des PDF...
rem ouvrir si pdf détecté :
set /p pdfOri= "Le pdf %insee%_orientations_%datapro% a bien ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des PDF...
IF "%pdfOri%"=="o" goto OOR
IF not "%pdfOri%"=="o" goto FinOr
rem ouverture du pdf :
:OOR
 "%pdfOr%" /cmd
set /p Orprob= "%insee%_orientations_%datapro% s'ouvre-t-il ? (o/n) : "
IF "%Orprob%"=="n" (
echo ^<font color="red"^>ERREUR : le pdf %insee%_orientations_%datapro% ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
)
cls
echo Controle des PDF...
rem INDEX :
set /p index5= "Le pdf des orientations d'amenagement est-il indexe ? (o/n): "
cls
echo Controle des PDF...
IF "%index5%"=="n" (goto index5) else goto FinOr
:index5
echo.>> %rappconf% 
echo ^<font color="red"^>ERREUR : le pdf des orientations n'est pas indexé.  ^</font^>^</br^>   >> %rappconf% 
:FinOr 
cls
echo Controle des PDF...
rem ===============================================================================================================================================================



rem ===============================================================================================================================================================
rem 2.6.0 CONTROLE XXXXX_docgraphiques_AAAAMMJJ
rem ===============================================================================================================================================================
echo.>> %rappconf%
echo ^<blockquote ^> ^<h3^>2.2 %insee%_docgraphiques_%datapro%.pdf^</h3^>^</blockquote^>  >> %rappconf%
echo.>> %rappconf%

rem recherche dans les noms des pdf "docgraphiques":
for /f %%j in ('type liste_pdf_%insee%.txt ^| find /i "graphiques"') do (
move "%%j" "%DocG%"
)
rem definition du chemin avec nom conforme et verifie son existence :
set pdfDocG=%Or%\%insee%_docgraphiques_%datapro%.pdf
IF EXIST "%pdfDocG%" (
goto DocGOK
) else goto ConcatDocG
rem si oui conforme sinon test concatenage et nommage:
:DocGOK
echo ^<font color="green"^>CONFORME : le pdf %insee%_docgraphiques_%datapro% a bien été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto OpenDocG
rem ===============================================================================================================================================================
rem 2.6.1 NOMMAGE et CONCATENAGE XXXXX_docgraphiques_AAAAMMJJ
rem ===============================================================================================================================================================
:ConcatDocG
rem compte des pdf avec "docgraphiques":
for /f %%q in ('type liste_nom_pdf_%insee%.txt ^| find /i /c "graphique"') do (
set NumDocG=%%q
)
rem si>1 message affichant les pdf :
IF %NumDocG% GTR 1 (
cls
echo Controle des PDF...
echo Il existe %NumDocG% pdf nommes avec "graphique":
for /F %%s in ('type liste_nom_pdf_%insee%.txt^|find /i "graphique"') do echo    %%~nxs
set /p concat6="Faut-il proposer la concatenation dans le rapport ? (o/n) : ")
rem question si oui il faut les concatener message dans rapport et passage au suivant sinon test nommage:
IF "%concat6%"=="o" (
echo ^<font color="red"^>ERREUR : le pdf est à concaténer et à renommer : %insee%_docgraphiques_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo.>> %rappconf%
goto FinDocG
)
rem test nommage :
:NomDocG
IF EXIST  "%DocG%\*graphique*.pdf" (
echo ^<font color="red"^>ERREUR : le pdf est à renommer : %insee%_docgraphiques_%datapro%.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinDocG
) else (
echo ^<font color="red"^>ERREUR : le pdf %insee%_docgraphiques_%datapro% n'a pas été livré.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
goto FinDocG
)
rem ===============================================================================================================================================================
rem 2.6.2 OUVERTURE DU PDF XXXXX_docgraphiques_AAAAMMJJ
rem ===============================================================================================================================================================
:OpenDocG
cls
echo Controle des PDF...
rem ouvrir si pdf détecté :
set /p pdfDocGraph= "Le pdf %insee%_docgraphiques_%datapro% a bien ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des PDF...
IF "%pdfDocGraph%"=="o" goto ODocG
IF not "%pdfDocGraph%"=="o" goto FinDocG
rem ouverture du pdf :
:ODocG
 "%pdfDocG%" /cmd
set /p DocGprob= "%insee%_docgraphiques_%datapro% s'ouvre-t-il ? (o/n) : "
IF "%DocGprob%"=="n" (
echo ^<font color="red"^>ERREUR : le pdf %insee%_docgraphiques_%datapro% ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
)
cls
echo Controle des PDF...
rem INDEX :
set /p index6= "Le pdf des documents graphiques est-il indexe ? (o/n): "
cls
echo Controle des PDF...
IF "%index6%"=="n" (goto index6) else goto FinDocG
:index6
echo.>> %rappconf% 
echo ^<font color="red"^>ERREUR : le pdf des docs graphiques n'est pas indexé.  ^</font^>^</br^>   >> %rappconf% 
:FinDocG
cls
echo Controle des PDF...
rem ===============================================================================================================================================================

rem suppression des listes de pdf
del liste_nom_pdf_%insee%.txt
del liste_pdf_%insee%.txt

rem ===============================================================================================================================================================
rem BILAN controle pdf :
rem ===============================================================================================================================================================
:BilanPDF
for /F "usebackq" %%o in (`type %rappconf% ^|find /c "ERREUR"`) do (
set pdf=%%o
)
echo.
echo %pdf% Erreur(s)
IF %pdf%==0 goto pdfa
IF not %pdf%==0 goto pdfb
:pdfa
echo --------------------------------------------------------------------------------

echo ^<font color="green"^>^<h2^>^<div align="center"^>^<u^> Arborescence : CONFORME^</u^>^</h2^>^</div align="center"^> ^</font^>^</br^>  >> %rappconf%

echo *PDF : CONFORME*
goto pdfc
:pdfb
echo --------------------------------------------------------------------------------
echo ^<font color="red"^>^<h2^>^<div align="center"^>^<u^> Arborescence : NON CONFORME^</u^>^</h2^>^</div align="center"^> ^</font^>^</br^>  >> %rappconf%
echo ^<font color="red"^>^<h2^>^<div align="center"^>%pdf% Erreur(s) ^</h2^>^</div align="center"^> ^</font^>^</br^>  >> %rappconf%
echo. >> %rappconf%
echo *PDF : NON CONFORME*
:pdfc
echo. >> %rappconf%
echo.
echo ...fin
pause
cls
rem ===============================================================================================================================================================
rem renvoi si controle que pdf :
if /I "%choix%"=="1" (goto FIN)
rem ===============================================================================================================================================================




:DebutControleDG
rem ===============================================================================================================================================================
rem III- Module de contrôle des fichiers cartographiques 
rem ===============================================================================================================================================================
echo ^<blockquote ^> ^<h2^>3. Contrôle des données géographiques ^</h2^>^</blockquote ^>  >> %rappconf%
echo. >> %rappconf%

rem ===============================================================================================================================================================
rem 3.0 Controle des Formats livrés (listesDG):
rem ===============================================================================================================================================================
rem liste shape :
dir n/b/s %doss%\*.shp > liste_shape_%insee%.txt
dir n/b/s %doss%\*.dbf >> liste_shape_%insee%.txt
dir n/b/s %doss%\*.shx >> liste_shape_%insee%.txt
dir n/b/s %doss%\*.prj >> liste_shape_%insee%.txt
rem liste mapinfo :
dir n/b/s %doss%\*.tab > liste_mapinfo_%insee%.txt
dir n/b/s %doss%\*.dat >> liste_mapinfo_%insee%.txt
dir n/b/s %doss%\*.id >> liste_mapinfo_%insee%.txt
dir n/b/s %doss%\*.map >> liste_mapinfo_%insee%.txt
rem liste MIF/MID :
dir n/b/s %doss%\*.mif > liste_mif_mid_%insee%.txt
dir/b/s %doss%\*.mid >> liste_mif_mid_%insee%.txt
rem liste EDIGEO :
dir n/b/s %doss%\*.thf > liste_edigeo_%insee%.txt
dir n/b/s %doss%\*.gen >> liste_edigeo_%insee%.txt
dir n/b/s %doss%\*.geo >> liste_edigeo_%insee%.txt
dir n/b/s %doss%\*.mat >> liste_edigeo_%insee%.txt
dir n/b/s %doss%\*.dic >> liste_edigeo_%insee%.txt
dir n/b/s %doss%\*.scd >> liste_edigeo_%insee%.txt
dir n/b/s %doss%\*.vec >> liste_edigeo_%insee%.txt
cls
echo Controle des donnees geographiques...
echo.

rem Compte les docs livrés :
echo Detection des formats livres :

rem shp
for /F "usebackq" %%t in (`type liste_shape_%insee%.txt ^|find /i /c ".SHP"`) do (
set shp0=%%t
)
IF %shp0%==0 del liste_shape_%insee%.txt
IF not %shp0%==0 echo %shp0% couche(s) shp.

rem tab
for /F "usebackq" %%u in (`type liste_mapinfo_%insee%.txt ^|find /i /c ".TAB"`) do (
set tab0=%%u
)
IF %tab0%==0 del liste_mapinfo_%insee%.txt
IF not %tab0%==0 echo %tab0% couche(s) tab.

rem mif/mid
for /F "usebackq" %%v in (`type liste_mif_mid_%insee%.txt ^|find /i /c ".mif"`) do (
set mif0=%%v
)
IF %mif0%==0 del liste_mif_mid_%insee%.txt
IF not %mif0%==0 echo %mif0% couche(s) mif/mid.

rem thf
for /F "usebackq" %%w in (`type liste_edigeo_%insee%.txt ^|find /i /c ".THF"`) do (
set thf0=%%w
)
IF %thf0%==0 del liste_edigeo_%insee%.txt
IF not %thf0%==0 echo %thf0% couche(s) edigeo.

rem additionne tout les résultats dans une seule valeur :
set /a cch=%thf0%+%mif0%+%tab0%+%shp0%
echo.

rem conditions si nbr couches=0 ou non :
IF %cch%==0 (goto AucunDG) else goto Listes

:AucunDG
cls
echo Controle des donnees geographiques...
 echo.
 echo ...Aucune couche detectee !
echo ^<font color="red"^>ERREUR : Aucune couche n'a été livrée. ^</font^>^</br^>   >> %rappconf%
 echo.
goto BilanDG

:Listes
pause
echo Liste des couches géographiques livrées : >> %rappconf% 
IF %shp0%==0 goto TAB
IF not %shp0%==0 goto ListeSHP
:TAB
IF %tab0%==0 goto MIF
IF not %tab0%==0 goto ListeTAB
:MIF
IF %mif0%==0 goto EDI
IF not %mif0%==0 goto ListeMIF
:EDI
IF %thf0%==0 goto DebutControleCouche
IF not %thf0%==0 goto ListeEDI

rem ===============================================================================================================================================================
rem Affichage liste dg par type dans rapport :
rem ===============================================================================================================================================================
:ListeSHP

echo ^<blockquote ^>Format Shape :^</blockquote ^> >> %rappconf% 
rem extraction de la liste des couches livrées avec nomfichier+extension :
for /F %%y in ('type liste_shape_%insee%.txt ^|find /i ".shp"') do (
echo  ^<blockquote ^>^<blockquote ^>  %%~nxy ^</blockquote ^>^</blockquote ^>  >> %rappconf%
)
echo ^<blockquote ^>^<blockquote ^> + dbf,prj,shx ^</blockquote ^>^</blockquote ^> >> %rappconf% 


goto TAB
:ListeTAB
echo ^<blockquote ^>Format MapInfo :^</blockquote ^> >> %rappconf% 
rem extraction de la liste des couches livrées avec nomfichier+extension :
for /F %%y in ('type liste_mapinfo_%insee%.txt ^|find ".TAB"') do (
echo  ^<blockquote ^>^<blockquote ^>  %%~nxy ^</blockquote ^>^</blockquote ^>  >> %rappconf%
)
echo ^<blockquote ^>^<blockquote ^> + map,dat,id  ^</blockquote ^>^</blockquote ^> >> %rappconf% 


goto MIF
:ListeMIF
echo ^<blockquote ^>Format Mif/Mid :^</blockquote ^> >> %rappconf% 
rem extraction de la liste des couches livrées avec nomfichier+extension :
for /F %%y in ('type liste_mif_mid_%insee%.txt ^|find ".mif"') do (
echo  ^<blockquote ^>^<blockquote ^>  %%~nxy ^</blockquote ^>^</blockquote ^>  >> %rappconf%
)
echo ^<blockquote ^>^<blockquote ^> + mid ^</blockquote ^>^</blockquote ^> >> %rappconf% 


goto EDI
:ListeEDI
echo ^<blockquote ^>Format Edigéo :^</blockquote ^> >> %rappconf% 
rem extraction de la liste des couches livrées avec nomfichier+extension :
for /F %%y in ('type liste_edigeo_%insee%.txt ^|find /i ".THF"') do (
echo  ^<blockquote ^>^<blockquote ^>  %%~nxy ^</blockquote ^>^</blockquote ^>  >> %rappconf%
)
echo ^<blockquote ^>^<blockquote ^> + gen,geo,mat,qal,dic,scd,vec ^</blockquote ^>^</blockquote ^> >> %rappconf% 
echo !Ce test ne traite pas le format EDIGEO! convertir en .shp, .tab, ou .mif/mid. 


rem ===============================================================================================================================================================
rem Controle des couches (nommage, structure, topo) :
rem ===============================================================================================================================================================
:DebutControleCouche
rem liste totale des docs geo et efface liste par type:
type liste_shape_%insee%.txt > ListeDG_%insee%.txt
del liste_shape_%insee%.txt
type liste_mapinfo_%insee%.txt>> ListeDG_%insee%.txt
del liste_mapinfo_%insee%.txt
type liste_mif_mid_%insee%.txt>> ListeDG_%insee%.txt
del liste_mif_mid_%insee%.txt
type liste_edigeo_%insee%.txt>> ListeDG_%insee%.txt
del liste_edigeo_%insee%.txt

cls
echo Controle des donnees geographiques...
echo.

rem ===============================================================================================================================================================
rem renvoi si "CC" :
IF "%doc%"=="CC" goto SecteurCC




rem ===============================================================================================================================================================
rem 3.1.0 TEST ZONE_URBA :
rem ===============================================================================================================================================================
echo *N_ZONE_URBA_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.1 Contrôle de la couche N_ZONE_URBA_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%q in ('type ListeDG_%insee%.txt ^| find /i "ZONE"') do (
set ZUnom=%%~nq
move "%%q" "%dg%"
)
rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%ZUnom%.shp" ( 
set ZU=%ZUnom%.shp
goto NomZU
)
IF EXIST "%dg%\%ZUnom%.tab" ( 
set ZU=%ZUnom%.tab
goto NomZU
)
IF EXIST "%dg%\%ZUnom%.mif" ( 
set ZU=%ZUnom%.mif
goto NomZU
)
goto NOZU

rem ===============================================================================================================================================================
rem 3.1.1 CONTROLE NOMMAGE ZONE_URBA: 
rem ===============================================================================================================================================================
:NomZU
IF EXIST "%dg%\*ZONE*URBA*CORRIGE*.shp" ( 
goto ZU1
) else (
goto ZU2
)
:ZU1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenZU 
:ZU2
IF EXIST "%dg%\*ZONE*URBA*CORRIGE*.tab" (
goto ZU3
) else (
goto ZU4
)
:ZU3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenZU
:ZU4
IF EXIST "%dg%\*ZONE*URBA*CORRIGE*.mif" ( 
goto ZU5
) else (
goto ZU6
)
:ZU5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenZU 
:ZU6
IF EXIST "%dg%\N_ZONE_URBA_%insee%_%dep%.shp" ( 
goto ZU7
) else (
goto ZU8
)
:ZU7
	echo ^<font color="green"^>CONFORME : La couche N_ZONE_URBA_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenZU
:ZU8
IF EXIST "%dg%\*ZONE*URBA*.shp" ( 
goto ZU9
) else (
goto ZU10
)
:ZU9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_ZONE_URBA_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenZU 
:ZU10
IF EXIST "%dg%\N_ZONE_URBA_%insee%_%dep%.tab" ( 
goto ZU11
) else (
goto ZU12
)
:ZU11
	echo ^<font color="green"^>CONFORME : La couche N_ZONE_URBA_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenZU
:ZU12
IF EXIST "%dg%\*ZONE*URBA*.tab" ( 
goto ZU13
) else (
goto ZU14
)
:ZU13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_ZONE_URBA_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenZU	
:ZU14
IF EXIST "%dg%\N_ZONE_URBA_%insee%_%dep%.mif" ( 
goto ZU15
) else (
goto ZU16
)
:ZU15
	echo ^<font color="green"^>CONFORME : La couche N_ZONE_URBA_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenZU
:ZU16
IF EXIST "%dg%\*ZONE*URBA*.mif" ( 
goto ZU17
) else (
goto NOZU
)
:ZU17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_ZONE_URBA_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenZU 
:NOZU
	echo ^<font color="red"^> ERREUR : La couche N_ZONE_URBA_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto PSURF

rem ===============================================================================================================================================================
rem 3.1.2 CONTROLE PROJECTION et ENCODAGE ZONE_URBA :
rem ===============================================================================================================================================================
:OpenZU 
cls
echo Controle des donnees geographiques...
echo.
echo *N_ZONE_URBA_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpZU= "La couche %ZU% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_ZONE_URBA_%insee%_%dep% :

IF "%OpZU%"=="o" (goto OZU) else goto TopoZU

:OZU
rem ouverture de la couche ZU dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%ZU%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvZU="La couche %ZU% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvZU%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ1="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ1%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO1="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO1%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem1="Remarque(s) : "
 IF NOT "%Rem1%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem1%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )

rem ===============================================================================================================================================================
rem 3.1.3 CONTROLE TOPOLOGIQUE ZONE_URBA :
rem ===============================================================================================================================================================
:TopoZU
rem IMPORT DE LA COUCHE shape ZONE_URBA DS POSTGRES:
rem --------------------------------------------------------------------------------------------
echo.
echo IMPORT de la couche : %ZU%
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln zone_urba "%dg%\%ZU%"
echo.
echo ...fin
echo.
rem pause

echo * Controle topologique...
echo.
rem creation de la table des géométries invalides :
rem --------------------------------------------------------------------------------------------
echo 	*Detection des geometries invalides :
echo.
%PSQL% -d %base% -f %SQL%\1_controle_geom_invalid.sql -q -t -h %host% -p %port% -U %user%  
rem export de la table dans le dossiers erreurs_topo :
%PGSHP% -f %ET%\%insee%_geom_invalid -h %host% -u %user% -P %pass% %base% public.geom_invalid
echo.
echo ...fin du traitement des geometries invalides.
echo.
 pause

rem ouverture de la couche %insee%_geom_invalid.shp ds qgis pour verification :
rem ------------------------------------------------------------------------------------------------
 IF EXIST "%ET%\%insee%_geom_invalid.shp" (
 "%ET%\%insee%_geom_invalid.shp"
 ) else (
 del "%ET%\%insee%_geom_invalid.dbf"
 goto CHEV
 )
 cls
echo Controle des donnees geographiques...
 echo.
 echo *N_ZONE_URBA_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
 echo Ouverture de la couche %insee%_geom_invalid.shp...
 echo.
 echo.
 rem condition pour suppression :
 set /p supprgeo= "Cette erreur merite_t_elle d'etre inscrite dans le rapport ? (o/n): "
 IF "%supprgeo%"=="n" (
 del "%ET%\%insee%_geom_invalid.shp"
  del "%ET%\%insee%_geom_invalid.dbf"
   del "%ET%\%insee%_geom_invalid.prj"
    del "%ET%\%insee%_geom_invalid.shx"
	)
 
:CHEV
rem creation de la table des chevauchements :
rem --------------------------------------------------------------------------------------------
cls
echo Controle des donnees geographiques...
 echo.
 echo *N_ZONE_URBA_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
echo 	*Detection des chevauchements :
echo.
%PSQL% -d %base% -f %SQL%\2_controle_chevauchement.sql -q -t -h %host% -p %port% -U %user%
rem export de la table dans le dossiers erreurs_topo :
%PGSHP% -f %ET%\%insee%_chevauchement -h %host% -u %user% -P %pass% %base% public.chevauchement
echo.
echo ...fin du traitement des chevauchements.
echo.
 pause

rem ouverture de la couche %insee%_chevauchement.shp ds qgis pour verification :
rem ------------------------------------------------------------------------------------------------
 IF EXIST "%ET%\%insee%_chevauchement.shp" (
 "%ET%\%insee%_chevauchement.shp"
 ) else (
 del "%ET%\%insee%_chevauchement.dbf"
 goto TROU
 )
 cls
echo Controle des donnees geographiques...
 echo.
 echo *N_ZONE_URBA_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
 echo Ouverture de la couche %insee%_chevauchement.shp...
 echo.
 echo.
 rem condition pour suppression :
 set /p supprchev= "Cette erreur merite_t_elle d'etre inscrite dans le rapport ? (o/n): "
 IF "%supprchev%"=="n" (
 del "%ET%\%insee%_chevauchement.shp"
  del "%ET%\%insee%_chevauchement.dbf"
   del "%ET%\%insee%_chevauchement.prj"
    del "%ET%\%insee%_chevauchement.shx"
    )
  
:TROU
rem creation de la table des trous :
rem --------------------------------------------------------------------------------------------
cls
 echo Controle des donnees geographiques...
 echo.
 echo *N_ZONE_URBA_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
echo 	*Detection des trous :
echo.
%PSQL% -d %base% -f %SQL%\3_controle_trous.sql -q -t -h %host% -p %port% -U %user% 
rem export de la table dans le dossiers erreurs_topo :
%PGSHP% -f %ET%\%insee%_trous -h %host% -u %user% -P %pass% %base% public.trous
echo.
echo ...fin du traitement des trous.
echo.
 pause

rem ouverture de la couche %insee%_trous.shp ds qgis pour verification :
rem ------------------------------------------------------------------------------------------------
 IF EXIST "%ET%\%insee%_trous.shp" (
 "%ET%\%insee%_trous.shp"
 ) else (
 del "%ET%\%insee%_trous.dbf"
 goto DECA
 )
 cls
echo Controle des donnees geographiques...
 echo.
 echo *N_ZONE_URBA_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
 echo Ouverture de la couche %insee%_trous.shp...
 echo.
 echo.
 rem condition pour suppression :
 set /p supprtrou= "Cette erreur merite_t_elle d'etre inscrite dans le rapport ? (o/n): "
 IF "%supprtrou%"=="n" (
 del "%ET%\%insee%_trous.shp"
  del "%ET%\%insee%_trous.dbf"
   del "%ET%\%insee%_trous.prj"
    del "%ET%\%insee%_trous.shx"
    )
  
:DECA
rem creation de la table des decalages_sections selon le referentiel IGN ou PCI (PCI par defaut):
rem --------------------------------------------------------------------------------------------
cls
echo Controle des donnees geographiques...
 echo.
 echo *N_ZONE_URBA_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
echo 	*Detection des decalages/section :
echo.
 IF "%referentiel%"=="IGN" (
 %PSQL% -d %base% -f %SQL%\4_2_controle_emprise_section_IGN.sql -q -t -h %host% -p %port% -U %user% 
 )else (
 %PSQL% -d %base% -f %SQL%\4_1_controle_emprise_section_PCI.sql -q -t -h %host% -p %port% -U %user%) 
rem pause
rem export de la table dans le dossiers erreurs_topo :
 %PGSHP% -f %ET%\%insee%_decalages_section -h %host% -u %user% -P %pass% %base% public.decalage_section
echo.
echo ...fin du traitement des decalages.
echo.
rem pause

rem ouverture de la couche decalage_section ds qgis pour verification :
rem ------------------------------------------------------------------------------------------------
 IF EXIST "%ET%\%insee%_decalages_section.shp" (
 "%ET%\%insee%_decalages_section.shp"
 ) else (
 del "%ET%\%insee%_decalages_section.dbf"
 goto FinTopoZU
 )
 cls
echo Controle des donnees geographiques...
 echo.
 echo *N_ZONE_URBA_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
 echo Ouverture de la couche %insee%_decalage_section.shp...
 echo.
 echo.
 rem condition pour suppression :
 set /p supprdeca= "Cette erreur merite_t_elle d'etre inscrite dans le rapport ? (o/n): "
 IF "%supprdeca%"=="n" (
 del "%ET%\%insee%_decalages_section.shp"
  del "%ET%\%insee%_decalages_section.dbf"
   del "%ET%\%insee%_decalages_section.prj"
    del "%ET%\%insee%_decalages_section.shx"
    )
 
:FinTopoZU
rem liste shape erreurs topo :
rem ------------------------------------------------------------------------------------------------
dir n/b/s Erreurs_topo\*.shp > liste_couches_erreurs_topo_%insee%.txt

rem compte des shape erreurs :
rem ------------------------------------------------------------------------------------------------
for /f "usebackq" %%t in (`type liste_couches_erreurs_topo_%insee%.txt ^|find /i /c ".shp"`) do (
set toposhp=%%t
)

IF %toposhp%==0 (goto TopoOK) else goto ErreurTopo

:ErreurTopo
cls
echo Controle des donnees geographiques...
echo.
echo *N_ZONE_URBA_%insee%_%dep% :
echo Controle topologique ...
echo         ...fin controle topologique.
echo ------------------------------------
echo *TOPO NON CONFORME*
echo %toposhp% couches erreurs.

echo ^<font color="red"^>ERREUR : TOPOLOGIE NON-CONFORME:   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>%toposhp% couche(s) avec au moins une erreur de topologie : ^</font^> ^</br^> >> %rappconf% 
echo ^<font color="red"^>Couche(s) erreurs générées dans le répertoire %ET% pour vérification : ^</br^> >> %rappconf% 
rem extraction de la liste des couches erreurs avec nomfichier+extension :
for /F %%y in ('type liste_couches_erreurs_topo_%insee%.txt ^|find /i ".shp"') do (
echo  ^<blockquote^>%%~nxy^</blockquote^> >> %rappconf%
)
echo. ^</font^> >> %rappconf% 
echo.
pause
goto StructureZU

:TopoOK
cls
echo Controle des donnees geographiques...
echo.
echo *N_ZONE_URBA_%insee%_%dep% :
echo Controle topologique ...
echo         ...fin controle topologique.
echo ------------------------------------
echo *TOPOLOGIE CONFORME*

echo ^<font color="green"^>CONFORME : TOPOLOGIE CONFORME.   ^</font^>^</br^>   >> %rappconf%              
echo. >> %rappconf% 
pause

rem ===============================================================================================================================================================
rem 3.1.4 CONTROLE STRUCTURE ZONE_URBA :
rem ===============================================================================================================================================================
:StructureZU
del liste_couches_erreurs_topo_%insee%.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_ZONE_URBA_%insee%_%dep% :
echo.
echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_1_controle_structure_zu.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_zone_urba dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_zu) to STDOUT" > %ES%\%insee%_erreurs_structure_zone_urba.txt

rem decompte des lignes erreurs dans erreurs_structure_zone_urba.txt :
for /F "usebackq" %%t in (`type %ES%\%insee%_erreurs_structure_zone_urba.txt ^|find /i /c "ERREUR"`) do (
set structureZU=%%t
)

rem =============================================================================================================================================================
rem PAUSE2 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer) :
rem =============================================================================================================================================================
echo.
echo fin du traitement.
pause
rem =============================================================================================================================================================

IF %structureZU%==0 (goto StructureZUok) else goto StructureZUnok

:StructureZUnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_ZONE_URBA_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureZU% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="blue"^>^<blockquote^>RAPPEL : La couche N_ZONE_URBA_%insee%_%dep% comporte 10 champs :   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>IDURBA (varchar 20)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 12)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELONG (varchar 254)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEZONE (varchar 3)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DESTDOMI (varchar 2)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATAPPRO (date)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATVALID (date)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureZU% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%y in ('type %ES%\%insee%_erreurs_structure_zone_urba.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%y^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf% 
echo.>> %rappconf% 
echo.
pause
goto PSURF 

:StructureZUok
del %ES%\%insee%_erreurs_structure_zone_urba.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_ZONE_URBA_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%             
echo.>> %rappconf% 
echo.>> %rappconf% 
pause
rem ===============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.2.0 TEST PRESCRIPTION_SURF:
rem ===============================================================================================================================================================
:PSURF
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_SURF_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.2 Contrôle de la couche N_PRESCRIPTION_SURF_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%r in ('type ListeDG_%insee%.txt ^| find /i "PRESC"') do (
echo %%r >> ListePresc_%insee%.txt
move "%%r" "%dg%"
)

for /f %%s in ('type ListePresc_%insee%.txt ^| find /i "SURF"') do (
set PSnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%PSnom%.shp" ( 
set PS=%PSnom%.shp
goto NomPS
) ELSE (
IF EXIST "%dg%\%PSnom%.tab" ( 
set PS=%PSnom%.tab
goto NomPS
) ELSE (
IF EXIST "%dg%\%PSnom%.mif" ( 
pause
set PS=%PSnom%.mif
goto NomPS
) ELSE (
goto NOPS
)))
rem ===============================================================================================================================================================
rem 3.2.1 CONTROLE NOMMAGE PRESCRIPTION_SURF: 
rem ===============================================================================================================================================================
:NomPS
IF EXIST "%dg%\*PRESC*SURF*CORRIGE*.shp" ( 
goto PS1
) else (
goto PS2
)
:PS1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPS 
:PS2
IF EXIST "%dg%\*PRESC*SURF*CORRIGE*.tab" (
goto PS3
) else (
goto PS4
)
:PS3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPS
:PS4
IF EXIST "%dg%\*PRESC*SURF*CORRIGE*.mif" ( 
goto PS5
) else (
goto PS6
)
:PS5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPS 
:PS6
IF EXIST "%dg%\N_PRESCRIPTION_SURF_%insee%_%dep%.shp" ( 
goto PS7
) else (
goto PS8
)
:PS7
	echo ^<font color="green"^>CONFORME : La couche N_PRESCRIPTION_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPS
:PS8
IF EXIST "%dg%\*PRESC*SURF*.shp" ( 
goto PS9
) else (
goto PS10
)
:PS9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_PRESCRIPTION_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPS 
:PS10
IF EXIST "%dg%\N_PRESCRIPTION_SURF_%insee%_%dep%.tab" ( 
goto PS11
) else (
goto PS12
)
:PS11
	echo ^<font color="green"^>CONFORME : La couche N_PRESCRIPTION_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPS
:PS12
IF EXIST "%dg%\*PRESC*SURF*.tab" ( 
goto PS13
) else (
goto PS14
)
:PS13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_PRESCRIPTION_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPS	
:PS14
IF EXIST "%dg%\N_PRESCRIPTION_SURF_%insee%_%dep%.mif" ( 
goto PS15
) else (
goto PS16
)
:PS15
	echo ^<font color="green"^>CONFORME : La couche N_PRESCRIPTION_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPS
:PS16
IF EXIST "%dg%\*PRESC*SURF*.mif" ( 
goto PS17
) else (
goto NOPS
)
:PS17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_PRESCRIPTION_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPS 
:NOPS
	echo ^<font color="red"^>ERREUR : La couche N_PRESCRIPTION_SURF_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto PLIN

rem ===============================================================================================================================================================
rem 3.2.2 CONTROLE PROJECTION et ENCODAGE PRESCRIPTION_SURF :
rem ===============================================================================================================================================================
:OpenPS 
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_SURF_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpPS= "La couche %PS% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_SURF_%insee%_%dep% :

IF "%OpPS%"=="o" (goto OPS) else goto StructurePS

:OPS
rem ouverture de la couche PS dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%PS%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvPS="La couche %PS% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvPS%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ2="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ2%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO2="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO2%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem2="Remarque(s) : "
 IF NOT "%Rem2%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem2%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.2.3 CONTROLE STRUCTURE PRESCRIPTION_SURF :
rem ===============================================================================================================================================================
:StructurePS
rem IMPORT DE LA COUCHE shape PRESCRIPTION_SURF DS POSTGRE:
rem -------------------------------------------------------
echo.
echo IMPORT de la couche %PS% :
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln prescription_surf "%dg%\%PS%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_2_controle_structure_ps.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_prescription_surf dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_ps) to STDOUT" > %ES%\%insee%_erreurs_structure_prescription_surf.txt

rem decompte des lignes erreurs dans erreurs_structure_prescription_surf.txt :
for /F "usebackq" %%d in (`type %ES%\%insee%_erreurs_structure_prescription_surf.txt ^|find /i /c "ERREUR"`) do (
set structurePS=%%d
)

rem =============================================================================================================================================================
rem PAUSE3 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structurePS%==0 (goto StructurePSok) else goto StructurePSnok

:StructurePSnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_SURF_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structurePS% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="blue"^>^<blockquote^>RAPPEL : La couche N_PRESCRIPTION_SURF_%insee%_%dep% comporte 10 champs :   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>IDURBA (varchar 20)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 12)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELONG (varchar 254)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEZONE (varchar 3)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DESTDOMI (varchar 2)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATAPPRO (date)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATVALID (date)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureZU% erreur(s) de structuration : ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%v in ('type %ES%\%insee%_erreurs_structure_prescription_surf.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%v ^</blockquote^> ^</br^>   >> %rappconf%
)
echo ^</font^> >> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto PLIN 

:StructurePSok
del %ES%\%insee%_erreurs_structure_prescription_surf.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_SURF_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%          
echo.>> %rappconf%            
echo.>> %rappconf% 
pause
rem ===============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.3.0 TEST PRESCRIPTION_LIN :
rem ===============================================================================================================================================================
:PLIN
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_LIN_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.3 Contrôle de la couche N_PRESCRIPTION_LIN_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListePresc_%insee%.txt ^| find /i "LIN"') do (
set PLnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%PLnom%.shp" ( 
set PL=%PLnom%.shp
goto NomPL
) ELSE (
IF EXIST "%dg%\%PLnom%.tab" ( 
set PL=%PLnom%.tab
goto NomPL
) ELSE (
IF EXIST "%dg%\%PLnom%.mif" ( 
pause
set PL=%PLnom%.mif
goto NomPL
) ELSE (
goto NOPL
)))
rem ===============================================================================================================================================================
rem 3.3.1 CONTROLE NOMMAGE PRESCRIPTION_LIN: 
rem ===============================================================================================================================================================
:NomPL
IF EXIST "%dg%\*PRESC*LIN*CORRIGE*.shp" ( 
goto PL1
) else (
goto PL2
)
:PL1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPL 
:PL2
IF EXIST "%dg%\*PRESC*LIN*CORRIGE*.tab" (
goto PL3
) else (
goto PL4
)
:PL3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPL
:PL4
IF EXIST "%dg%\*PRESC*LIN*CORRIGE*.mif" ( 
goto PL5
) else (
goto PL6
)
:PL5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPL 
:PL6
IF EXIST "%dg%\N_PRESCRIPTION_LIN_%insee%_%dep%.shp" ( 
goto PL7
) else (
goto PL8
)
:PL7
	echo ^<font color="green"^>CONFORME : La couche N_PRESCRIPTION_LIN_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPL
:PL8
IF EXIST "%dg%\*PRESC*LIN*.shp" ( 
goto PL9
) else (
goto PL10
)
:PL9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_PRESCRIPTION_LIN_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPL 
:PL10
IF EXIST "%dg%\N_PRESCRIPTION_LIN_%insee%_%dep%.tab" ( 
goto PL11
) else (
goto PL12
)
:PL11
	echo ^<font color="green"^>CONFORME : La couche N_PRESCRIPTION_LIN_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPL
:PL12
IF EXIST "%dg%\*PRESC*LIN*.tab" ( 
goto PL13
) else (
goto PL14
)
:PL13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_PRESCRIPTION_LIN_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPL	
:PL14
IF EXIST "%dg%\N_PRESCRIPTION_LIN_%insee%_%dep%.mif" ( 
goto PL15
) else (
goto PL16
)
:PL15
	echo ^<font color="green"^>CONFORME : La couche N_PRESCRIPTION_LIN_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPL
:PL16
IF EXIST "%dg%\*PRESC*LIN*.mif" ( 
goto PL17
) else (
goto NOPL
)
:PL17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_PRESCRIPTION_LIN_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPL 
:NOPL
	echo ^<font color="red"^>ERREUR : La couche N_PRESCRIPTION_LIN_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto PPCT


rem ===============================================================================================================================================================
rem 3.3.2 CONTROLE PROJECTION et ENCODAGE PRESCRIPTION_LIN :
rem ===============================================================================================================================================================
:OpenPL
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_LIN_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpPL= "La couche %PL% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_LIN_%insee%_%dep% :

IF "%OpPL%"=="o" (goto OPL) else goto StructurePL

:OPL
rem ouverture de la couche PL dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%PL%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvPL="La couche %PL% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvPL%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ3="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ3%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO3="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO3%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem3="Remarque(s) : "
 IF NOT "%Rem3%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem3%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.3.3 CONTROLE STRUCTURE PRESCRIPTION_LIN :
rem ===============================================================================================================================================================
:StructurePL 
rem IMPORT DE LA COUCHE PRESCRIPTION_LIN DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln prescription_lin "%dg%\%PL%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_3_controle_structure_pl.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_prescription_lin dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_pl) to STDOUT" > %ES%\%insee%_erreurs_structure_prescription_lin.txt

rem table erreur_structure_prescription_lin déplacée vers dossier Erreurs_structure
rem move "%PGDATA%\%insee%_erreurs_structure_prescription_lin.txt" "%ES%"

rem decompte des lignes erreurs dans erreurs_structure_prescription_lin.txt :
for /F "usebackq" %%f in (`type %ES%\%insee%_erreurs_structure_prescription_lin.txt ^|find /i /c "ERREUR"`) do (
set structurePL=%%f
)

rem =============================================================================================================================================================
rem PAUSE4 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structurePL%==0 (goto StructurePLok) else goto StructurePLnok

:StructurePLnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_LIN_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structurePL% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="blue"^>^<blockquote^>RAPPEL COVADIS : La couche N_PRESCRIPTION_LIN_%insee%_%dep% comporte 8 champs :   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 254)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TXT (varchar 10)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEPSC (varchar 2)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATAPPRO (date)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATVALID (date)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structurePL% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%c in ('type %ES%\%insee%_erreurs_structure_prescription_lin.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%c^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto PPCT 

:StructurePLok
del %ES%\%insee%_erreurs_structure_prescription_lin.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_LIN_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%     
echo.>> %rappconf%            
echo.>> %rappconf% 
pause
rem ===============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.4.0 TEST PRESCRIPTION_PCT :
rem ===============================================================================================================================================================
:PPCT
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_PCT_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.4 Contrôle de la couche N_PRESCRIPTION_PCT_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListePresc_%insee%.txt ^| find /i "PCT"') do (
set PPnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%PPnom%.shp" ( 
set PP=%PPnom%.shp
goto NomPP
) ELSE (
IF EXIST "%dg%\%PPnom%.tab" ( 
set PP=%PPnom%.tab
goto NomPP
) ELSE (
IF EXIST "%dg%\%PPnom%.mif" ( 
pause
set PP=%PPnom%.mif
goto NomPP
) ELSE (
goto NOPP
)))
rem ===============================================================================================================================================================
rem 3.4.1 CONTROLE NOMMAGE PRESCRIPTION_PCT: 
rem ===============================================================================================================================================================
:NomPP
IF EXIST "%dg%\*PRESC*PCT*CORRIGE*.shp" ( 
goto PP1
) else (
goto PP2
)
:PP1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPP 
:PP2
IF EXIST "%dg%\*PRESC*PCT*CORRIGE*.tab" (
goto PP3
) else (
goto PP4
)
:PP3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPP
:PP4
IF EXIST "%dg%\*PRESC*PCT*CORRIGE*.mif" ( 
goto PP5
) else (
goto PP6
)
:PP5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPP 
:PP6
IF EXIST "%dg%\N_PRESCRIPTION_PCT_%insee%_%dep%.shp" ( 
goto PP7
) else (
goto PP8
)
:PP7
	echo ^<font color="green"^>CONFORME : La couche N_PRESCRIPTION_PCT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPP
:PP8
IF EXIST "%dg%\*PRESC*PCT*.shp" ( 
goto PP9
) else (
goto PP10
)
:PP9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_PRESCRIPTION_PCT_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPP 
:PP10
IF EXIST "%dg%\N_PRESCRIPTION_PCT_%insee%_%dep%.tab" ( 
goto PP11
) else (
goto PP12
)
:PP11
	echo ^<font color="green"^>CONFORME : La couche N_PRESCRIPTION_PCT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPP
:PP12
IF EXIST "%dg%\*PRESC*PCT*.tab" ( 
goto PP13
) else (
goto PP14
)
:PP13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_PRESCRIPTION_PCT_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPP	
:PP14
IF EXIST "%dg%\N_PRESCRIPTION_PCT_%insee%_%dep%.mif" ( 
goto PP15
) else (
goto PP16
)
:PP15
	echo ^<font color="green"^>CONFORME : La couche N_PRESCRIPTION_PCT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPP
:PP16
IF EXIST "%dg%\*PRESC*PCT*.mif" ( 
goto PP17
) else (
goto NOPP
)
:PP17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_PRESCRIPTION_PCT_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenPP 
:NOPP
	echo ^<font color="red"^>ERREUR : La couche N_PRESCRIPTION_PCT_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto ISURF

rem ===============================================================================================================================================================
rem 3.4.2 CONTROLE PROJECTION et ENCODAGE PRESCRIPTION_PCT :
rem ===============================================================================================================================================================
:OpenPP
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_PCT_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpPP= "La couche %PP% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_PCT_%insee%_%dep% :

IF "%OpPP%"=="o" (goto OPP) else goto StructurePP

:OPP
rem ouverture de la couche PP dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%PP%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvPP="La couche %PP% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvPP%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ4="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ4%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO4="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO4%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem4="Remarque(s) : "
 IF NOT "%Rem4%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem4%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.4.3 CONTROLE STRUCTURE PRESCRIPTION_PCT :
rem ===============================================================================================================================================================
:StructurePP 
rem IMPORT DE LA COUCHE PRESCRIPTION_PCT DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln prescription_pct "%dg%\%PP%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_4_controle_structure_pp.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_prescription_pct dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_pp) to STDOUT" > %ES%\%insee%_erreurs_structure_prescription_pct.txt

rem table erreur_structure_prescription_pct déplacée vers dossier Erreurs_structure
rem move "%PGDATA%\%insee%_erreurs_structure_prescription_pct.txt" "%ES%"

rem decompte des lignes erreurs dans erreurs_structure_prescription_pct.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_prescription_pct.txt ^|find /i /c "ERREUR"`) do (
set structurePP=%%u
)

rem =============================================================================================================================================================
rem PAUSE5 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structurePP%==0 (goto StructurePPok) else goto StructurePPnok

:StructurePPnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_PCT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structurePP% erreur(s).

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="blue"^>^<blockquote^>RAPPEL COVADIS : La couche N_PRESCRIPTION_LIN_%insee%_%dep% comporte 8 champs :   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 254)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TXT (varchar 10) ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEPSC (varchar 2)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80) ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254) ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATAPPRO (date) ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATVALID (date)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structurePP% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_prescription_pct.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%d^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo. >> %rappconf%
echo. >> %rappconf% 
echo.
pause
goto ISURF 

:StructurePPok
del %ES%\%insee%_erreurs_structure_prescription_pct.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_PRESCRIPTION_PCT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%     
echo.>> %rappconf%            
echo.>> %rappconf% 
pause

rem ===============================================================================================================================================================
rem 3.5.0 TEST INFO_SURF:
rem ===============================================================================================================================================================

:ISURF
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.5 Contrôle de la couche N_INFO_SURF_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%
rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%r in ('type ListeDG_%insee%.txt ^| find /i "INF"') do (
echo %%r >> ListeInf_%insee%.txt
move "%%r" "%dg%"
)
for /f %%s in ('type ListeInf_%insee%.txt ^| find /i "SURF"') do (
set ISnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%ISnom%.shp" ( 
set IS=%ISnom%.shp
goto NomIS
) ELSE (
IF EXIST "%dg%\%ISnom%.tab" ( 
set IS=%ISnom%.tab
goto NomIS
) ELSE (
IF EXIST "%dg%\%ISnom%.mif" ( 
pause
set IS=%ISnom%.mif
goto NomIS
) ELSE (
goto NOIS
)))
rem ===============================================================================================================================================================
rem 3.5.1 CONTROLE NOMMAGE INFO_SURF: 
rem ===============================================================================================================================================================
:NomIS
IF EXIST "%dg%\*INF*SURF*CORRIGE*.shp" ( 
goto IS1
) else (
goto IS2
)
:IS1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIS 
:IS2
IF EXIST "%dg%\*INF*SURF*CORRIGE*.tab" (
goto IS3
) else (
goto IS4
)
:IS3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIS
:IS4
IF EXIST "%dg%\*INF*SURF*CORRIGE*.mif" ( 
goto IS5
) else (
goto IS6
)
:IS5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIS 
:IS6
IF EXIST "%dg%\N_INFO_SURF_%insee%_%dep%.shp" ( 
goto IS7
) else (
goto IS8
)
:IS7
	echo ^<font color="green"^>CONFORME : La couche N_INFO_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIS
:IS8
IF EXIST "%dg%\*INF*SURF*.shp" ( 
goto IS9
) else (
goto IS10
)
:IS9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIS 
:IS10
IF EXIST "%dg%\N_INFO_SURF_%insee%_%dep%.tab" ( 
goto IS11
) else (
goto IS12
)
:IS11
	echo ^<font color="green"^>CONFORME : La couche N_INFO_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIS
:IS12
IF EXIST "%dg%\*INF*SURF*.tab" ( 
goto IS13
) else (
goto IS14
)
:IS13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIS	
:IS14
IF EXIST "%dg%\N_INFO_SURF_%insee%_%dep%.mif" ( 
goto IS15
) else (
goto IS16
)
:IS15
	echo ^<font color="green"^>CONFORME : La couche N_INFO_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIS
:IS16
IF EXIST "%dg%\*INF*SURF*.mif" ( 
goto IS17
) else (
goto NOIS
)
:IS17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIS 
:NOIS
	echo ^<font color="red"^>ERREUR : La couche N_INFO_SURF_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto ILIN

rem ===============================================================================================================================================================
rem 3.5.2 CONTROLE PROJECTION et ENCODAGE INFO_SURF :
rem ===============================================================================================================================================================
:OpenIS
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpIS= "La couche %IS% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :

IF "%OpIS%"=="o" (goto OIS) else goto StructureIS

:OIS
rem ouverture de la couche IS dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%IS%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvIS="La couche %IS% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvIS%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ5="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ5%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO5="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO5%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem5="Remarque(s) : "
 IF NOT "%Rem5%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem5%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.5.3 CONTROLE STRUCTURE INFO_SURF :
rem ===============================================================================================================================================================
:StructureIS 
rem IMPORT DE LA COUCHE INFO_SURF DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln info_surf "%dg%\%IS%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_5_controle_structure_is.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_info_surf dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_is) to STDOUT" > %ES%\%insee%_erreurs_structure_info_surf.txt

rem table erreur_structure_info_surf déplacée vers dossier Erreurs_structure
rem move "%PGDATA%\%insee%_erreurs_structure_info_surf.txt" "%ES%"

rem decompte des lignes erreurs dans erreurs_structure_info_surf.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_info_surf.txt ^|find /i /c "ERREUR"`) do (
set structureIS=%%u
)
rem =============================================================================================================================================================
rem PAUSE6 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================
IF %structureIS%==0 (goto StructureISok) else goto StructureISnok

:StructureISnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureIS% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="blue"^>^<blockquote^>RAPPEL : La couche N_INFO_SURF_%insee%_%dep% comporte 6 champs :   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 254)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TXT (varchar 10)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPINF (varchar 2)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureIS% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_info_surf.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%d^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto ILIN

:StructureISok
del %ES%\%insee%_erreurs_structure_info_surf.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%  
echo.>> %rappconf%            
echo.>> %rappconf% 
pause
rem ===============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.6.0 TEST INFO_LIN :
rem ===============================================================================================================================================================
:ILIN
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.6 Contrôle de la couche N_INFO_LIN_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListeINF_%insee%.txt ^| find /i "LIN"') do (
set ILnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%ILnom%.shp" ( 
set IL=%ILnom%.shp
goto NomIL
) ELSE (
IF EXIST "%dg%\%ILnom%.tab" ( 
set IL=%ILnom%.tab
goto NomIL
) ELSE (
IF EXIST "%dg%\%ILnom%.mif" ( 
pause
set IL=%ILnom%.mif
goto NomIL
) ELSE (
goto NOIL
)))
rem ===============================================================================================================================================================
rem 3.6.1 CONTROLE NOMMAGE INFO_LIN: 
rem ===============================================================================================================================================================
:NomIL
IF EXIST "%dg%\*INF*LIN*CORRIGE*.shp" ( 
goto IL1
) else (
goto IL2
)
:IL1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIL 
:IL2
IF EXIST "%dg%\*INF*LIN*CORRIGE*.tab" (
goto IL3
) else (
goto IL4
)
:IL3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIL
:IL4
IF EXIST "%dg%\*INF*LIN*CORRIGE*.mif" ( 
goto IL5
) else (
goto IL6
)
:IL5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIL 
:IL6
IF EXIST "%dg%\N_INFO_LIN_%insee%_%dep%.shp" ( 
goto IL7
) else (
goto IL8
)
:IL7
	echo ^<font color="green"^>CONFORME : La couche N_INFO_LIN_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIL
:IL8
IF EXIST "%dg%\*INF*LIN*.shp" ( 
goto IL9
) else (
goto IL10
)
:IL9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_LIN_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIL 
:IL10
IF EXIST "%dg%\N_INFO_LIN_%insee%_%dep%.tab" ( 
goto IL11
) else (
goto IL12
)
:IL11
	echo ^<font color="green"^>CONFORME : La couche N_INFO_LIN_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIL
:IL12
IF EXIST "%dg%\*INF*LIN*.tab" ( 
goto IL13
) else (
goto IL14
)
:IL13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_LIN_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIL	
:IL14
IF EXIST "%dg%\N_INFO_LIN_%insee%_%dep%.mif" ( 
goto IL15
) else (
goto IL16
)
:IL15
	echo ^<font color="green"^>CONFORME : La couche N_INFO_LIN_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIL
:IL16
IF EXIST "%dg%\*INF*LIN*.mif" ( 
goto IL17
) else (
goto NOIL
)
:IL17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_LIN_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIL 
:NOIL
	echo ^<font color="red"^>ERREUR : La couche N_INFO_LIN_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto IPCT

rem ===============================================================================================================================================================
rem 3.6.2 CONTROLE PROJECTION et ENCODAGE INFO_LIN :
rem ===============================================================================================================================================================
:OpenIL
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpIL= "La couche %IL% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :

IF "%OpIL%"=="o" (goto OIL) else goto StructureIL

:OIL
rem ouverture de la couche IL dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%IL%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvIL="La couche %IL% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvIL%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ6="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ6%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO6="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO6%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem6="Remarque(s) : "
 IF NOT "%Rem6%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem6%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.6.3 CONTROLE STRUCTURE INFO_LIN :
rem ===============================================================================================================================================================
:StructureIL 
rem IMPORT DE LA COUCHE INFO_LIN DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln info_LIN "%dg%\%IL%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_6_controle_structure_il.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_info_lin dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_il) to STDOUT" > %ES%\%insee%_erreurs_structure_info_lin.txt

rem table erreur_structure_info_lin déplacée vers dossier Erreurs_structure
rem move "%PGDATA%\%insee%_erreurs_structure_info_lin.txt" "%ES%"

rem decompte des lignes erreurs dans erreurs_structure_info_lin.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_info_lin.txt ^|find /i /c "ERREUR"`) do (
set structureIL=%%u
)

rem =============================================================================================================================================================
rem PAUSE7 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureIL%==0 (goto StructureILok) else goto StructureILnok

:StructureILnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureIL% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="blue"^>^<blockquote^>RAPPEL : La couche N_INFO_LIN_%insee%_%dep% comporte 6 champs :   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 254)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TXT (varchar 10)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPINF (varchar 2)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%

echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureIL% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_info_lin.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%d^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto IPCT

:StructureILok
del %ES%\%insee%_erreurs_structure_info_lin.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%  
echo.>> %rappconf%            
echo.>> %rappconf% 
pause
rem ===============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.7.0 TEST INFO_PCT :
rem ===============================================================================================================================================================
:IPCT
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.7 Contrôle de la couche N_INFO_PCT_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListeINF_%insee%.txt ^| find /i "PCT"') do (
set IPnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%IPnom%.shp" ( 
set IP=%IPnom%.shp
goto NomIP
) ELSE (
IF EXIST "%dg%\%IPnom%.tab" ( 
set IP=%IPnom%.tab
goto NomIP
) ELSE (
IF EXIST "%dg%\%IPnom%.mif" ( 
pause
set IP=%IPnom%.mif
goto NomIP
) ELSE (
goto NOIP
)))
rem ===============================================================================================================================================================
rem 3.7.1 CONTROLE NOMMAGE INFO_PCT: 
rem ===============================================================================================================================================================
:NomIP
IF EXIST "%dg%\*INF*PCT*CORRIGE*.shp" ( 
goto IP1
) else (
goto IP2
)
:IP1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIP 
:IP2
IF EXIST "%dg%\*INF*PCT*CORRIGE*.tab" (
goto IP3
) else (
goto IP4
)
:IP3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIP
:IP4
IF EXIST "%dg%\*INF*PCT*CORRIGE*.mif" ( 
goto IP5
) else (
goto IP6
)
:IP5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIP 
:IP6
IF EXIST "%dg%\N_INFO_PCT_%insee%_%dep%.shp" ( 
goto IP7
) else (
goto IP8
)
:IP7
	echo ^<font color="green"^>CONFORME : La couche N_INFO_PCT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIP
:IP8
IF EXIST "%dg%\*INF*PCT*.shp" ( 
goto IP9
) else (
goto IP10
)
:IP9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_PCT_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIP 
:IP10
IF EXIST "%dg%\N_INFO_PCT_%insee%_%dep%.tab" ( 
goto IP11
) else (
goto IP12
)
:IP11
	echo ^<font color="green"^>CONFORME : La couche N_INFO_PCT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIP
:IP12
IF EXIST "%dg%\*INF*PCT*.tab" ( 
goto IP13
) else (
goto IP14
)
:IP13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_PCT_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIP	
:IP14
IF EXIST "%dg%\N_INFO_PCT_%insee%_%dep%.mif" ( 
goto IP15
) else (
goto IP16
)
:IP15
	echo ^<font color="green"^>CONFORME : La couche N_INFO_PCT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIP
:IP16
IF EXIST "%dg%\*INF*PCT*.mif" ( 
goto IP17
) else (
goto NOIP
)
:IP17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_PCT_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIP 
:NOIP
	echo ^<font color="red"^>ERREUR : La couche N_INFO_PCT_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto HSURF

rem ===============================================================================================================================================================
rem 3.7.2 CONTROLE PROJECTION et ENCODAGE INFO_PCT :
rem ===============================================================================================================================================================
:OpenIP
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpIP= "La couche %IP% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :

IF "%OpIP%"=="o" (goto OIP) else goto StructureIP

:OIP
rem ouverture de la couche IP dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%IP%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvIP="La couche %IP% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvIP%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ7="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ7%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO7="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO7%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem7="Remarque(s) : "
 IF NOT "%Rem7%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem7%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.7.3 CONTROLE STRUCTURE INFO_PCT :
rem ===============================================================================================================================================================
:StructureIP 
rem IMPORT DE LA COUCHE INFO_PCT DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln info_pct "%dg%\%IP%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_7_controle_structure_ip.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_info_pct dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_ip) to STDOUT" > %ES%\%insee%_erreurs_structure_info_pct.txt

rem table erreur_structure_info_pct déplacée vers dossier Erreurs_structure
rem move "%PGDATA%\%insee%_erreurs_structure_info_pct.txt" "%ES%"

rem decompte des lignes erreurs dans erreurs_structure_info_pct.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_info_pct.txt ^|find /i /c "ERREUR"`) do (
set structureIP=%%u
)

rem =============================================================================================================================================================
rem PAUSE8 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureIP%==0 (goto StructureIPok) else goto StructureIPnok

:StructureIPnok
del ListeInf_%insee%.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureIP% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="blue"^>^<blockquote^>RAPPEL : La couche N_INFO_PCT_%insee%_%dep% comporte 6 champs :   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 254)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TXT (varchar 10)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPINF (varchar 2)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)   ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureIP% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_info_pct.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%d^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto HSURF

:StructureIPok
del ListeInf_%insee%.txt
del %ES%\%insee%_erreurs_structure_info_pct.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%  
echo.>> %rappconf%            
echo.>> %rappconf% 
pause
goto HSURF
rem ===============================================================================================================================================================




:SecteurCC
rem ===============================================================================================================================================================
rem 3.1.0bis TEST SECTEUR_CC : (CC)
rem ===============================================================================================================================================================
echo *N_SECTEUR_CC_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.1 Contrôle de la couche N_SECTEUR_CC_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%q in ('type ListeDG_%insee%.txt ^| find /i "SECTEUR"') do (
set SCCnom=%%~nq
move "%%q" "%dg%"
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%SCCnom%.shp" ( 
set SCC=%SCCnom%.shp
goto NomSCC
)
IF EXIST "%dg%\%SCCnom%.tab" ( 
set SCC=%SCCnom%.tab
goto NomSCC
)
IF EXIST "%dg%\%SCCnom%.mif" ( 
pause
set SCC=%SCCnom%.mif
goto NomSCC
)
goto NOSCC

rem ===============================================================================================================================================================
rem 3.1.1bis CONTROLE NOMMAGE SECTEUR_CC: 
rem ===============================================================================================================================================================
:NomSCC
IF EXIST "%dg%\*SECTEUR*CC*CORRIGE*.shp" ( 
goto SCC1
) else (
goto SCC2
)
:SCC1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenSCC 
:SCC2
IF EXIST "%dg%\*SECTEUR*CC*CORRIGE*.tab" (
goto SCC3
) else (
goto SCC4
)
:SCC3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenSCC
:SCC4
IF EXIST "%dg%\*SECTEUR*CC*CORRIGE*.mif" ( 
goto SCC5
) else (
goto SCC6
)
:SCC5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenSCC 
:SCC6
IF EXIST "%dg%\N_SECTEUR_CC_%insee%_%dep%.shp" ( 
goto SCC7
) else (
goto SCC8
)
:SCC7
	echo ^<font color="green"^>CONFORME : La couche N_SECTEUR_CC_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenSCC
:SCC8
IF EXIST "%dg%\*SECTEUR*CC*.shp" ( 
goto SCC9
) else (
goto SCC10
)
:SCC9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_SECTEUR_CC_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenSCC 
:SCC10
IF EXIST "%dg%\N_SECTEUR_CC_%insee%_%dep%.tab" ( 
goto SCC11
) else (
goto SCC12
)
:SCC11
	echo ^<font color="green"^>CONFORME : La couche N_SECTEUR_CC_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenSCC
:SCC12
IF EXIST "%dg%\*SECTEUR*CC*.tab" ( 
goto SCC13
) else (
goto SCC14
)
:SCC13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_SECTEUR_CC_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenSCC	
:SCC14
IF EXIST "%dg%\N_SECTEUR_CC_%insee%_%dep%.mif" ( 
goto SCC15
) else (
goto SCC16
)
:SCC15
	echo ^<font color="green"^>CONFORME : La couche N_SECTEUR_CC_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenSCC
:SCC16
IF EXIST "%dg%\*SECTEUR*CC*.mif" ( 
goto SCC17
) else (
goto NOSCC
)
:SCC17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_SECTEUR_CC_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenSCC 
:NOSCC
	echo ^<font color="red"^>ERREUR : La couche N_SECTEUR_CC_%insee%_%dep% n'a pas été livrée. ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto ISURFbis

rem ===============================================================================================================================================================
rem 3.1.2bis CONTROLE PROJECTION et ENCODAGE SECTEUR_CC :
rem ===============================================================================================================================================================
:OpenSCC
cls
echo Controle des donnees geographiques...
echo.
echo *N_SECTEUR_CC_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpSCC= "La couche %SCC% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_SECTEUR_CC_%insee%_%dep% :

IF "%OpSCC%"=="o" (goto OSCC) else goto TopoSCC

:OSCC
rem ouverture de la couche SCC dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%SCC%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvSCC="La couche %SCC% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvSCC%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ1bis="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ1bis%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO1bis="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO1bis%"=="n" (
 echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem1bis="Remarque(s) : "
 IF NOT "%Rem1bis%"=="" (
 echo ^<font color="blue"^>REMARQUE :"%Rem1bis%"  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )

rem ===============================================================================================================================================================
rem 3.1.3bis CONTROLE TOPOLOGIQUE SECTEUR_CC :
rem ===============================================================================================================================================================
:TopoSCC
rem IMPORT DE LA COUCHE shape SECTEUR_CC DS POSTGRE:
rem --------------------------------------------------------------------------------------------
echo.
echo IMPORT de la couche : %SCC%
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln secteur_cc "%dg%\%SCC%"
echo.
echo ...fin
echo.
rem pause

echo * Controle topologique...
echo.
rem creation de la table des géométries invalides :
rem --------------------------------------------------------------------------------------------
echo 	*Detection des geometries invalides :
echo.
%PSQL% -d %base% -f %SQL%\1bis_controle_geom_invalid.sql -q -t -h %host% -p %port% -U %user%  
rem export de la table dans le dossiers erreurs_topo :
%PGSHP% -f %ET%\%insee%_geom_invalid -h %host% -u %user% -P %pass% %base% public.geom_invalid
echo.
echo ...fin du traitement des geometries invalides.
echo.
rem pause

rem ouverture de la couche %insee%_geom_invalid.shp ds qgis pour verification :
rem ------------------------------------------------------------------------------------------------
 IF EXIST "%ET%\%insee%_geom_invalid.shp" (
 "%ET%\%insee%_geom_invalid.shp"
 ) else (
 del "%ET%\%insee%_geom_invalid.dbf"
 goto CHEVbis
 )
 echo.
 echo.
 echo.
 echo Ouverture de la couche %insee%_geom_invalid.shp...
 echo.
 echo.
 rem condition pour suppression :
 set /p supprgeo= "Cette erreur merite_t_elle d'etre inscrite dans le rapport ? (o/n): "
 IF "%supprgeo%"=="n" (
 del "%ET%\%insee%_geom_invalid.shp"
 del "%ET%\%insee%_geom_invalid.dbf"
 del "%ET%\%insee%_geom_invalid.prj"
 del "%ET%\%insee%_geom_invalid.shx"
 )
 
:CHEVbis
rem creation de la table des chevauchements :
rem --------------------------------------------------------------------------------------------
cls
echo Controle des donnees geographiques...
 echo.
 echo *N_SECTEUR_CC_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
echo 	*Detection des chevauchements :
echo.
%PSQL% -d %base% -f %SQL%\2bis_controle_chevauchement_cc.sql -q -t -h %host% -p %port% -U %user%
rem export de la table dans le dossiers erreurs_topo :
%PGSHP% -f %ET%\%insee%_chevauchement -h %host% -u %user% -P %pass% %base% public.chevauchement
echo.
echo ...fin du traitement des chevauchements.
echo.
rem pause

rem ouverture de la couche %insee%_chevauchement.shp ds qgis pour verification :
rem ------------------------------------------------------------------------------------------------
 IF EXIST "%ET%\%insee%_chevauchement.shp" (
 "%ET%\%insee%_chevauchement.shp"
 ) else (
 del "%ET%\%insee%_chevauchement.dbf"
 goto TROUbis
 )
 echo.
 echo.
 echo.
 echo Ouverture de la couche %insee%_chevauchement.shp...
 echo.
 echo.
 rem condition pour suppression :
 set /p supprchev= "Cette erreur merite_t_elle d'etre inscrite dans le rapport ? (o/n): "
 IF "%supprchev%"=="n" (
 del "%ET%\%insee%_chevauchement.shp"
 del "%ET%\%insee%_chevauchement.dbf"
 del "%ET%\%insee%_chevauchement.prj"
 del "%ET%\%insee%_chevauchement.shx"
 )

 
:TROUbis
rem creation de la table des trous :
rem --------------------------------------------------------------------------------------------
cls
 echo Controle des donnees geographiques...
 echo.
 echo *N_SECTEUR_CC_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
echo 	*Detection des trous :
echo.
%PSQL% -d %base% -f %SQL%\3bis_controle_trous_cc.sql -q -t -h %host% -p %port% -U %user% 
rem export de la table dans le dossiers erreurs_topo :
%PGSHP% -f %ET%\%insee%_trous -h %host% -u %user% -P %pass% %base% public.trous
echo.
echo ...fin du traitement des trous.
echo.
rem pause

rem ouverture de la couche %insee%_trous.shp ds qgis pour verification :
rem ------------------------------------------------------------------------------------------------
 IF EXIST "%ET%\%insee%_trous.shp" (
 "%ET%\%insee%_trous.shp"
 ) else (
 del "%ET%\%insee%_trous.dbf"
 goto DECAbis
 )
 echo.
 echo.
 echo.
 echo Ouverture de la couche %insee%_trous.shp...
 echo.
 echo.
 rem condition pour suppression :
 set /p supprtrou= "Cette erreur merite_t_elle d'etre inscrite dans le rapport ? (o/n): "
 IF "%supprtrou%"=="n" (
 del "%ET%\%insee%_trous.shp"
 del "%ET%\%insee%_trous.dbf"
 del "%ET%\%insee%_trous.prj"
 del "%ET%\%insee%_trous.shx"
 )

 
:DECAbis
rem creation de la table des decalages_sections selon le referentiel IGN ou PCI (PCI par defaut):
rem --------------------------------------------------------------------------------------------
cls
echo Controle des donnees geographiques...
 echo.
 echo *N_ZONE_URBA_%insee%_%dep% :
 echo.
 echo Controle topologique...
 echo.
echo 	*Detection des decalages/section :
echo.
 IF "%referentiel%"=="IGN" (
 %PSQL% -d %base% -f %SQL%\4_2bis_controle_emprise_section_IGN_cc.sql -q -t -h %host% -p %port% -U %user% 
 )else (
 %PSQL% -d %base% -f %SQL%\4_1bis_controle_emprise_section_PCI_cc.sql -q -t -h %host% -p %port% -U %user%) 
rem export de la table dans le dossiers erreurs_topo :
 %PGSHP% -f %ET%\%insee%_decalages_section -h %host% -u %user% -P %pass% %base% public.decalage_section
echo.
echo ...fin du traitement des decalages.
echo.
rem pause

rem ouverture de la couche decalage_section ds qgis pour verification :
rem ------------------------------------------------------------------------------------------------
 IF EXIST "%ET%\%insee%_decalages_section.shp" (
 "%ET%\%insee%_decalages_section.shp"
 ) else (
 del "%ET%\%insee%_decalages_section.dbf"
 goto PAUSE
 )
 echo.
 echo.
 echo.
 echo Ouverture de la couche %insee%_decalage_section.shp...
 echo.
 echo.
 rem condition pour suppression :
 set /p supprdeca= "Cette erreur merite_t_elle d'etre inscrite dans le rapport ? (o/n): "
 IF "%supprdeca%"=="n" (
 del "%ET%\%insee%_decalages_section.shp"
 del "%ET%\%insee%_decalages_section.dbf"
 del "%ET%\%insee%_decalages_section.prj"
 del "%ET%\%insee%_decalages_section.shx"
 )
 

:FinTopoSCC
rem liste shape erreurs topo :
rem ------------------------------------------------------------------------------------------------
dir n/b/s Erreurs_topo\*.shp > liste_couches_erreurs_topo_%insee%.txt

rem compte des shape erreurs :
rem ------------------------------------------------------------------------------------------------
for /f "usebackq" %%t in (`type liste_couches_erreurs_topo_%insee%.txt ^|find /i /c ".shp"`) do (
set toposhp=%%t
)

IF %toposhp%==0 (goto TopoOKSCC) else goto ErreurTopoSCC

:ErreurTopoSCC
cls
echo Controle des donnees geographiques...
echo.
echo *N_SECTEUR_CC_%insee%_%dep% :
echo Controle topologique ...
echo         ...fin controle topologique.
echo ------------------------------------
echo *TOPO NON CONFORME*
echo %toposhpSCC% couches erreurs.

echo ^<font color="red"^>ERREUR : TOPOLOGIE NON-CONFORME:   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="red"^>%toposhpSCC% couche(s) avec au moins une erreur de topologie : ^</font^>^</br^> >> %rappconf%
echo ^<font color="red"^>Couche(s) erreurs générées dans le répertoire %ET% pour vérification : ^</br^> >> %rappconf% 
rem extraction de la liste des couches erreurs avec nomfichier+extension :
for /F %%y in ('type liste_couches_erreurs_topo_%insee%.txt ^|find /i "shp"') do (
echo ^<blockquote^> %%~nxy^</blockquote^> ^</br^>   >> %rappconf%
)
echo ^</font^>  >> %rappconf% 
echo.
pause
goto StructureSCC

:TopoOKSCC
cls
echo Controle des donnees geographiques...
echo.
echo *N_SECTEUR_CC_%insee%_%dep% :
echo Controle topologique ...
echo         ...fin controle topologique.
echo ------------------------------------
echo *TOPOLOGIE CONFORME*
echo ^<font color="green"^>CONFORME : TOPOLOGIE CONFORME.   ^</font^>^</br^>   >> %rappconf%                
echo. >> %rappconf% 
pause

rem ===============================================================================================================================================================
rem 3.1.4bis CONTROLE STRUCTURE SECTEUR_CC : (CC)
rem ===============================================================================================================================================================
:StructureSCC
del liste_couches_erreurs_topo_%insee%.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_SECTEUR_CC_%insee%_%dep% :
echo Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_1bis_controle_structure_scc.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_zone_urba dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_scc) to STDOUT" > %ES%\%insee%_erreurs_structure_secteur_cc.txt

rem decompte des lignes erreurs dans erreurs_structure_secteur_cc.txt :
for /F "usebackq" %%t in (`type %ES%\%insee%_erreurs_structure_secteur_cc.txt ^|find /i /c "ERREUR"`) do (
set structureSCC=%%t
)

rem =============================================================================================================================================================
rem PAUSE2bis pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureSCC%==0 (goto StructureSCCok) else goto StructureSCCnok

:StructureSCCnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_SECTEUR_CC_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureSCC% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="blue"^>^<blockquote^>RAPPEL : La couche N_SECTEUR_CC_%insee%_%dep% comporte 10 champs :   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>IDURBA (varchar 20)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 254)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPESECT (varchar 3)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>FERMRECO (varchar 3)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DESTDOMI (varchar 2)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATAPPRO (date)   ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATVALID (date)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureSCC% erreur(s) de structuration :   ^</br^>   >> %rappconf%

rem liste des erreurs dans rapport :
for /F "delims=" %%y in ('type %ES%\%insee%_erreurs_structure_secteur_cc.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%y^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf% 
echo.>> %rappconf% 
echo.
pause
goto ISURFbis 

:StructureSCCok
del %ES%\%insee%_erreurs_structure_secteur_cc.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_SECTEUR_CC_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%                
echo.>> %rappconf% 
echo.>> %rappconf% 
pause



rem ===============================================================================================================================================================
rem 3.5.0bis TEST INFO_SURF: (CC)
rem ===============================================================================================================================================================
:ISURFbis
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.5 Contrôle de la couche N_INFO_SURF_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%
rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%r in ('type ListeDG_%insee%.txt ^| find /i "INF"') do (
echo %%r >> ListeInf_%insee%.txt
move "%%r" "%dg%"
)

for /f %%s in ('type ListeInf_%insee%.txt ^| find /i "SURF"') do (
set ISnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%ISnom%.shp" ( 
set IS=%ISnom%.shp
goto NomISbis
)
IF EXIST "%dg%\%ISnom%.tab" ( 
set IS=%ISnom%.tab
goto NomISbis
)
IF EXIST "%dg%\%ISnom%.mif" ( 
pause
set IS=%ISnom%.mif
goto NomISbis
)
goto NOISbis

rem ===============================================================================================================================================================
rem 3.5.1bis CONTROLE NOMMAGE INFO_SURF: 
rem ===============================================================================================================================================================
:NomISbis
IF EXIST "%dg%\*INF*SURF*CORRIGE*.shp" ( 
goto ISbis1
) else (
goto ISbis2
)
:ISbis1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenISbis 
:ISbis2
IF EXIST "%dg%\*INF*SURF*CORRIGE*.tab" (
goto ISbis3
) else (
goto ISbis4
)
:ISbis3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenISbis
:ISbis4
IF EXIST "%dg%\*INF*SURF*CORRIGE*.mif" ( 
goto ISbis5
) else (
goto ISbis6
)
:ISbis5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenISbis 
:ISbis6
IF EXIST "%dg%\N_INFO_SURF_%insee%_%dep%.shp" ( 
goto ISbis7
) else (
goto ISbis8
)
:ISbis7
	echo ^<font color="green"^>CONFORME : La couche N_INFO_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenISbis
:ISbis8
IF EXIST "%dg%\*INF*SURF*.shp" ( 
goto ISbis9
) else (
goto ISbis10
)
:ISbis9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenISbis 
:ISbis10
IF EXIST "%dg%\N_INFO_SURF_%insee%_%dep%.tab" ( 
goto ISbis11
) else (
goto ISbis12
)
:ISbis11
	echo ^<font color="green"^>CONFORME : La couche N_INFO_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenISbis
:ISbis12
IF EXIST "%dg%\*INF*SURF*.tab" ( 
goto ISbis13
) else (
goto ISbis14
)
:ISbis13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenISbis	
:ISbis14
IF EXIST "%dg%\N_INFO_SURF_%insee%_%dep%.mif" ( 
goto ISbis15
) else (
goto ISbis16
)
:ISbis15
	echo ^<font color="green"^>CONFORME : La couche N_INFO_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenISbis
:ISbis16
IF EXIST "%dg%\*INF*SURF*.mif" ( 
goto ISbis17
) else (
goto NOISbis
)
:ISbis17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenISbis 
:NOISbis
	echo ^<font color="red"^> ERREUR : La couche N_INFO_SURF_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto ILINbis


rem ===============================================================================================================================================================
rem 3.5.2bis CONTROLE PROJECTION et ENCODAGE INFO_SURF :
rem ===============================================================================================================================================================
:OpenISbis
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpIS= "La couche %IS% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :

IF "%OpIS%"=="o" (goto OISbis) else goto StructureISbis

:OISbis
rem ouverture de la couche IS dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%IS%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvIS="La couche %IS% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvIS%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ5bis="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ5bis%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO5bis="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO5bis%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem5bis="Remarque(s) : "
 IF NOT "%Rem5bis%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem5bis%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.5.3bis CONTROLE STRUCTURE INFO_SURF :
rem ===============================================================================================================================================================
:StructureISbis 
rem IMPORT DE LA COUCHE INFO_SURF DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln info_surf "%dg%\%IS%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_5bis_controle_structure_is_cc.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_info_surf_cc dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_is) to STDOUT" > %ES%\%insee%_erreurs_structure_info_surf_cc.txt

rem decompte des lignes erreurs dans erreurs_structure_info_surf_cc.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_info_surf_cc.txt ^|find /i /c "ERREUR"`) do (
set structureISCC=%%u
)

rem =============================================================================================================================================================
rem PAUSE6bis pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureISCC%==0 (goto StructureISokCC) else goto StructureISnokCC

:StructureISnokCC
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureISCC% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="blue"^>^<blockquote^>RAPPEL COVADIS : La couche N_INFO_SURF_%insee%_%dep% comporte 7 champs :  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TXT (varchar 10)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEI (varchar 2)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEP (varchar 2)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureISCC% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_info_surf_cc.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%y^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto IPCTbis

:StructureISok
del %ES%\%insee%_erreurs_structure_info_surf_cc.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_SURF_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf% 
echo.>> %rappconf%            
echo.>> %rappconf% 
pause

rem ===============================================================================================================================================================
rem 3.6.0bis TEST INFO_LIN : (CC)
rem ===============================================================================================================================================================
:ILINbis
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.6 Contrôle de la couche N_INFO_LIN_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListeInf_%insee%.txt ^| find /i "LIN"') do (
set ILnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%ILnom%.shp" ( 
set IL=%ILnom%.shp
goto NomILbis
)
IF EXIST "%dg%\%ILnom%.tab" ( 
set IL=%ILnom%.tab
goto NomILbis
)
IF EXIST "%dg%\%ILnom%.mif" ( 
pause
set IL=%ILnom%.mif
goto NomILbis
)
goto NOILbis

rem ===============================================================================================================================================================
rem 3.6.1bis CONTROLE NOMMAGE INFO_LIN: 
rem ===============================================================================================================================================================
:NomILbis
IF EXIST "%dg%\*INF*LIN*CORRIGE*.shp" ( 
goto ILbis1
) else (
goto ILbis2
)
:ILbis1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenILbis 
:ILbis2
IF EXIST "%dg%\*INF*LIN*CORRIGE*.tab" (
goto ILbis3
) else (
goto ILbis4
)
:ILbis3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenILbis
:ILbis4
IF EXIST "%dg%\*INF*LIN*CORRIGE*.mif" ( 
goto ILbis5
) else (
goto ILbis6
)
:ILbis5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenILbis 
:ILbis6
IF EXIST "%dg%\N_INFO_LIN_%insee%_%dep%.shp" ( 
goto ILbis7
) else (
goto ILbis8
)
:ILbis7
	echo ^<font color="green"^>CONFORME : La couche N_INFO_LIN_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenILbis
:ILbis8
IF EXIST "%dg%\*INF*LIN*.shp" ( 
goto ILbis9
) else (
goto ILbis10
)
:ILbis9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_LIN_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenILbis 
:ILbis10
IF EXIST "%dg%\N_INFO_LIN_%insee%_%dep%.tab" ( 
goto ILbis11
) else (
goto ILbis12
)
:ILbis11
	echo ^<font color="green"^>CONFORME : La couche N_INFO_LIN_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenILbis
:ILbis12
IF EXIST "%dg%\*INF*LIN*.tab" ( 
goto ILbis13
) else (
goto ILbis14
)
:ILbis13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_LIN_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenILbis	
:ILbis14
IF EXIST "%dg%\N_INFO_LIN_%insee%_%dep%.mif" ( 
goto ILbis15
) else (
goto ILbis16
)
:ILbis15
	echo ^<font color="green"^>CONFORME : La couche N_INFO_LIN_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenILbis
:ILbis16
IF EXIST "%dg%\*INF*LIN*.mif" ( 
goto ILbis17
) else (
goto NOILbis
)
:ILbis17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_LIN_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenILbis 
:NOILbis
	echo ^<font color="red"^>ERREUR : La couche N_INFO_LIN_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto IPCTbis

rem ===============================================================================================================================================================
rem 3.6.2bis CONTROLE PROJECTION et ENCODAGE INFO_LIN :
rem ===============================================================================================================================================================
:OpenILbis
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpIL= "La couche %IL% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :

IF "%OpIL%"=="o" (goto OILbis) else goto StructureILbis

:OILbis
rem ouverture de la couche IL dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%IL%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvIL="La couche %IL% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvIL%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ6bis="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ6bis%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO6bis="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO6bis%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem6bis="Remarque(s) : "
 IF NOT "%Rem6bis%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem6bis%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.6.3bis CONTROLE STRUCTURE INFO_LIN :
rem ===============================================================================================================================================================
:StructureILbis 
rem IMPORT DE LA COUCHE INFO_LIN DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln info_lin "%dg%\%IL%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_6bis_controle_structure_il_cc.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_info_lin_cc dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_il) to STDOUT" > %ES%\%insee%_erreurs_structure_info_lin_cc.txt

rem decompte des lignes erreurs dans erreurs_structure_info_lin_cc.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_info_lin_cc.txt ^|find /i /c "ERREUR"`) do (
set structureILCC=%%u
)

rem =============================================================================================================================================================
rem PAUSE7bis pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureILCC%==0 (goto StructureILokCC) else goto StructureILnokCC

:StructureILnokCC
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureILCC% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo ^<font color="blue"^>^<blockquote^>RAPPEL COVADIS : La couche N_INFO_LIN_%insee%_%dep% comporte 7 champs :  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TXT (varchar 10)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEI (varchar 2)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEP (varchar 2)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureILCC% erreur(s) de structuration :   ^</br^>   >> %rappconf% 
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_info_lin_cc.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%d^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto IPCTbis

:StructureILokCC
del %ES%\%insee%_erreurs_structure_info_lin_cc.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_LIN_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%  
echo.>> %rappconf%            
echo.>> %rappconf% 
pause




rem ===============================================================================================================================================================
rem 3.7.0bis TEST INFO_PCT : (CC)
rem ===============================================================================================================================================================
:IPCTbis
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.7 Contrôle de la couche N_INFO_PCT_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListeInf_%insee%.txt ^| find /i "PCT"') do (
set IPnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%IPnom%.shp" ( 
set IP=%IPnom%.shp
goto NomIPbis
)
IF EXIST "%dg%\%IPnom%.tab" ( 
set IP=%IPnom%.tab
goto NomIPbis
)
IF EXIST "%dg%\%IPnom%.mif" ( 
pause
set IP=%IPnom%.mif
goto NomIPbis
)
goto NOIPbis

rem ===============================================================================================================================================================
rem 3.7.1bis CONTROLE NOMMAGE INFO_PCT: 
rem ===============================================================================================================================================================
:NomIPbis
IF EXIST "%dg%\*INF*PCT*CORRIGE*.shp" ( 
goto IPbis1
) else (
goto IPbis2
)
:IPbis1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIPbis 
:IPbis2
IF EXIST "%dg%\*INF*PCT*CORRIGE*.tab" (
goto IPbis3
) else (
goto IPbis4
)
:IPbis3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIPbis
:IPbis4
IF EXIST "%dg%\*INF*PCT*CORRIGE*.mif" ( 
goto IPbis5
) else (
goto IPbis6
)
:IPbis5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIPbis 
:IPbis6
IF EXIST "%dg%\N_INFO_PCT_%insee%_%dep%.shp" ( 
goto IPbis7
) else (
goto IPbis8
)
:IPbis7
	echo ^<font color="green"^>CONFORME : La couche N_INFO_PCT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIPbis
:IPbis8
IF EXIST "%dg%\*INF*PCT*.shp" ( 
goto IPbis9
) else (
goto IPbis10
)
:IPbis9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_PCT_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIPbis 
:IPbis10
IF EXIST "%dg%\N_INFO_PCT_%insee%_%dep%.tab" ( 
goto IPbis11
) else (
goto IPbis12
)
:IPbis11
	echo ^<font color="green"^>CONFORME : La couche N_INFO_PCT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIPbis
:IPbis12
IF EXIST "%dg%\*INF*PCT*.tab" ( 
goto IPbis13
) else (
goto IPbis14
)
:IPbis13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_PCT_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIPbis	
:IPbis14
IF EXIST "%dg%\N_INFO_PCT_%insee%_%dep%.mif" ( 
goto IPbis15
) else (
goto IPbis16
)
:IPbis15
	echo ^<font color="green"^>CONFORME : La couche N_INFO_PCT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIPbis
:IPbis16
IF EXIST "%dg%\*INF*PCT*.mif" ( 
goto IPbis17
) else (
goto NOIPbis
)
:IPbis17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_INFO_PCT_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenIPbis 
:NOIPbis
	echo ^<font color="red"^>ERREUR : La couche N_INFO_PCT_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto HSURF


rem ===============================================================================================================================================================
rem 3.7.2bis CONTROLE PROJECTION et ENCODAGE INFO_PCT :
rem ===============================================================================================================================================================
:OpenIPbis
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpIP= "La couche %IP% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :

IF "%OpIP%"=="o" (goto OIPbis) else goto StructureIPbis

:OIPbis
rem ouverture de la couche IP dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%IP%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvIP="La couche %IP% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvIP%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ7bis="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ7bis%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO7bis="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO7bis%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem7bis="Remarque(s) : "
 IF NOT "%Rem7bis%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem7bis%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.7.3bis CONTROLE STRUCTURE INFO_PCT :
rem ===============================================================================================================================================================
:StructureIPbis 
rem IMPORT DE LA COUCHE INFO_PCT DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln info_pct "%dg%\%IP%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_7bis_controle_structure_ip_cc.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_info_pct_cc dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_ip_cc) to STDOUT" > %ES%\%insee%_erreurs_structure_info_pct_cc.txt

rem decompte des lignes erreurs dans erreurs_structure_info_pct_cc.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_info_pct_cc.txt ^|find /i /c "ERREUR"`) do (
set structureIPCC=%%u
)

rem =============================================================================================================================================================
rem PAUSE8bis pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureIPCC%==0 (goto StructureIPokCC) else goto StructureIPnokCC

:StructureIPnokCC
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureIPCC% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="blue"^>^<blockquote^>RAPPEL COVADIS : La couche N_INFO_PCT_%insee%_%dep% comporte 7 champs :  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>LIBELLE (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TXT (varchar 10)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEI (varchar 2)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEP (varchar 2)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMFIC (varchar 80)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLFIC (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5) ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureIPCC% erreur(s) de structuration :   ^</br^>   >> %rappconf% 
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_info_pct_cc.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%d^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto HSURF

:StructureIPokCC
del %ES%\%insee%_erreurs_structure_info_pct_cc.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_INFO_PCT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%  
echo.>> %rappconf%            
echo.>> %rappconf% 
pause
rem =============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.8.0 TEST HABILLAGE_SURF
rem ===============================================================================================================================================================
:HSURF
del ListeInf_%insee%.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_SURF_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.8 Contrôle de la couche N_HABILLAGE_SURF_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%r in ('type ListeDG_%insee%.txt ^| find /i "HAB"') do (
echo %%r >> ListeHab_%insee%.txt
move "%%r" "%dg%"
)

for /f %%s in ('type ListeHab_%insee%.txt ^| find /i "SURF"') do (
set HSnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%HSnom%.shp" ( 
set HS=%HSnom%.shp
goto NomHS
)
IF EXIST "%dg%\%HSnom%.tab" ( 
set HS=%HSnom%.tab
goto NomHS
)
IF EXIST "%dg%\%HSnom%.mif" ( 
pause
set HS=%HSnom%.mif
goto NomHS
)
goto NOHS

rem ===============================================================================================================================================================
rem 3.8.1 CONTROLE NOMMAGE HABILLAGE_SURF: 
rem ===============================================================================================================================================================
:NomHS
IF EXIST "%dg%\*HAB*SURF*CORRIGE*.shp" ( 
goto HS1
) else (
goto HS2
)
:HS1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHS 
:HS2
IF EXIST "%dg%\*HAB*SURF*CORRIGE*.tab" (
goto HS3
) else (
goto HS4
)
:HS3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHS
:HS4
IF EXIST "%dg%\*HAB*SURF*CORRIGE*.mif" ( 
goto HS5
) else (
goto HS6
)
:HS5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHS 
:HS6
IF EXIST "%dg%\N_HABILLAGE_SURF_%insee%_%dep%.shp" ( 
goto HS7
) else (
goto HS8
)
:HS7
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHS
:HS8
IF EXIST "%dg%\*HAB*SURF*.shp" ( 
goto HS9
) else (
goto HS10
)
:HS9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_HABILLAGE_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHS 
:HS10
IF EXIST "%dg%\N_HABILLAGE_SURF_%insee%_%dep%.tab" ( 
goto HS11
) else (
goto HS12
)
:HS11
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHS
:HS12
IF EXIST "%dg%\*HAB*SURF*.tab" ( 
goto HS13
) else (
goto HS14
)
:HS13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_HABILLAGE_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHS	
:HS14
IF EXIST "%dg%\N_HABILLAGE_SURF_%insee%_%dep%.mif" ( 
goto HS15
) else (
goto HS16
)
:HS15
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_SURF_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHS
:HS16
IF EXIST "%dg%\*HAB*SURF*.mif" ( 
goto HS17
) else (
goto NOHS
)
:HS17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_HABILLAGE_SURF_%insee%_%dep%.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHS 
:NOHS
	echo ^<font color="red"^> ERREUR : La couche N_HABILLAGE_SURF_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto HLIN

rem ===============================================================================================================================================================
rem 3.8.2 CONTROLE PROJECTION et ENCODAGE HABILLAGE_SURF :
rem ===============================================================================================================================================================
:OpenHS
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_SURF_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpHS= "La couche %HS% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_SURF_%insee%_%dep% :

IF "%OpHS%"=="o" (goto OHS) else goto StructureHS

:OHS
rem ouverture de la couche HS dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%HS%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvHS="La couche %HS% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvHS%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ8="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ8%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO8="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO8%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem8="Remarque(s) : "
 IF NOT "%Rem8%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem8%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.8.3 CONTROLE STRUCTURE HABILLAGE_SURF :
rem ===============================================================================================================================================================
:StructureHS
rem IMPORT DE LA COUCHE HABILLAGE_SURF DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln habillage_surf "%dg%\%HS%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_8_controle_structure_hs.sql -q -t -h %host% -p %port% -U %user%
 
rem export de la table erreur_structure_habillage_surf dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_hs) to STDOUT" > %ES%\%insee%_erreurs_structure_habillage_surf.txt

rem decompte des lignes erreurs dans erreurs_structure_habillage_surf.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_habillage_surf.txt ^|find /i /c "ERREUR"`) do (
set structureHS=%%u
)

rem =============================================================================================================================================================
rem PAUSE9 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureHS%==0 (goto StructureHSok) else goto StructureHSnok

:StructureHSnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_SURF_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureHS% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="blue"^>RAPPEL COVADIS : La couche N_HABILLAGE_SURF_%insee%_%dep% comporte 2 champs :  ^</font^>^</br^>   >> %rappconf%  
echo ^<font color="blue"^>NATTRAC (varchar 40)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)  ^</font^>^</br^>   >> %rappconf%

echo. >> %rappconf% 
echo ^<font color="red"^>%structureHS% erreur(s) de structuration : ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_habillage_surf.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%d^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto HLIN

:StructureHSok
del %ES%\%insee%_erreurs_structure_habillage_surf.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_SURF_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%     
echo.>> %rappconf%            
echo.>> %rappconf% 

pause
rem =============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.9.0 TEST HABILLAGE_LIN :
rem ===============================================================================================================================================================
:HLIN
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_LIN_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.9 Contrôle de la couche N_HABILLAGE_LIN_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListeHab_%insee%.txt ^| find /i "LIN"') do (
set HLnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%HLnom%.shp" ( 
set HL=%HLnom%.shp
goto NomHL
)
IF EXIST "%dg%\%HLnom%.tab" ( 
set HL=%HLnom%.tab
goto NomHL
)
IF EXIST "%dg%\%HLnom%.mif" ( 
pause
set HL=%HLnom%.mif
goto NomHL
)
goto NOHL

rem ===============================================================================================================================================================
rem 3.9.1 CONTROLE NOMMAGE HABILLAGE_LIN: 
rem ===============================================================================================================================================================
:NomHL
IF EXIST "%dg%\*HAB*LIN*CORRIGE*.shp" ( 
goto HL1
) else (
goto HL2
)
:HL1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHL 
:HL2
IF EXIST "%dg%\*HAB*LIN*CORRIGE*.tab" (
goto HL3
) else (
goto HL4
)
:HL3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHL
:HL4
IF EXIST "%dg%\*HAB*LIN*CORRIGE*.mif" ( 
goto HL5
) else (
goto HL6
)
:HL5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHL 
:HL6
IF EXIST "%dg%\N_HABILLAGE_LIN_%insee%_%dep%.shp" ( 
goto HL7
) else (
goto HL8
)
:HL7
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_LIN_%insee%_%dep% a bien été livrée.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHL
:HL8
IF EXIST "%dg%\*HAB*LIN*.shp" ( 
goto HL9
) else (
goto HL10
)
:HL9
	echo ^<font color="red"^> ERREUR : La couche est à renommer : N_HABILLAGE_LIN_%insee%_%dep%.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHL 
:HL10
IF EXIST "%dg%\N_HABILLAGE_LIN_%insee%_%dep%.tab" ( 
goto HL11
) else (
goto HL12
)
:HL11
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_LIN_%insee%_%dep% a bien été livrée.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHL
:HL12
IF EXIST "%dg%\*HAB*LIN*.tab" ( 
goto HL13
) else (
goto HL14
)
:HL13
	echo ^<font color="red"^> ERREUR : La couche est à renommer : N_HABILLAGE_LIN_%insee%_%dep%.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHL	
:HL14
IF EXIST "%dg%\N_HABILLAGE_LIN_%insee%_%dep%.mif" ( 
goto HL15
) else (
goto HL16
)
:HL15
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_LIN_%insee%_%dep% a bien été livrée.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHL
:HL16
IF EXIST "%dg%\*HAB*LIN*.mif" ( 
goto HL17
) else (
goto NOHL
)
:HL17
	echo ^<font color="red"^> ERREUR : La couche est à renommer : N_HABILLAGE_LIN_%insee%_%dep%.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHL 
:NOHL
	echo ^<font color="red"^> ERREUR : La couche N_HABILLAGE_LIN_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%

	echo. >> %rappconf%
	echo. >> %rappconf%
	goto HPCT

rem ===============================================================================================================================================================
rem 3.9.2 CONTROLE PROJECTION et ENCODAGE HABILLAGE_LIN :
rem ===============================================================================================================================================================
:OpenHL
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_LIN_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpHL= "La couche %HL% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_LIN_%insee%_%dep% :

IF "%OpHL%"=="o" (goto OHL) else goto StructureHL

:OHL
rem ouverture de la couche HL dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%HL%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvHL="La couche %HL% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvHL%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ9="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ9%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO9="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO9%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem9="Remarque(s) : "
 IF NOT "%Rem9%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem9%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.9.3 CONTROLE STRUCTURE HABILLAGE_LIN :
rem ===============================================================================================================================================================
:StructureHL
rem IMPORT DE LA COUCHE HABILLAGE_LIN DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln habillage_lin "%dg%\%HL%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_9_controle_structure_hl.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_habillage_lin dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_hl) to STDOUT" > %ES%\%insee%_erreurs_structure_habillage_lin.txt

rem decompte des lignes erreurs dans erreurs_structure_habillage_lin.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_habillage_lin.txt ^|find /i /c "ERREUR"`) do (
set structureHL=%%u
)

rem =============================================================================================================================================================
rem PAUSE10 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureHL%==0 (goto StructureHLok) else goto StructureHLnok

:StructureHLnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_LIN_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureHL% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="blue"^>RAPPEL COVADIS : La couche N_HABILLAGE_LIN_%insee%_%dep% comporte 2 champs :  ^</font^>^</br^>   >> %rappconf%  
echo ^<font color="blue"^>NATTRAC (varchar 40)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)  ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>%structureHL% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_habillage_lin.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^>  %%d^</blockquote^>  ^</font^>^</br^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto HPCT

:StructureHLok
del %ES%\%insee%_erreurs_structure_habillage_lin.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_LIN_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%     
echo.>> %rappconf%            
echo.>> %rappconf% 
set coucou1= "coucou1"
pause
set coucou2= "coucou2"
rem =============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.10.0 TEST HABILLAGE_PCT :
rem ===============================================================================================================================================================
:HPCT
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_PCT_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.10 Contrôle de la couche N_HABILLAGE_PCT_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListeHab_%insee%.txt ^| find /i "PCT"') do (
set HPnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%HPnom%.shp" ( 
set HP=%HPnom%.shp
goto NomHP
)
IF EXIST "%dg%\%HPnom%.tab" ( 
set HP=%HPnom%.tab
goto NomHP
)
IF EXIST "%dg%\%HPnom%.mif" ( 
pause
set HP=%HPnom%.mif
goto NomHP
)
goto NOHP

rem ===============================================================================================================================================================
rem 3.10.1 CONTROLE NOMMAGE HABILLAGE_PCT: 
rem ===============================================================================================================================================================

:NomHP
IF EXIST "%dg%\*HAB*PCT*CORRIGE*.shp" ( 
goto HP1
) else (
goto HP2
)
:HP1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHP 
:HP2
IF EXIST "%dg%\*HAB*PCT*CORRIGE*.tab" (
goto HP3
) else (
goto HP4
)
:HP3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHP
:HP4
IF EXIST "%dg%\*HAB*PCT*CORRIGE*.mif" ( 
goto HP5
) else (
goto HP6
)
:HP5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHP 
:HP6
IF EXIST "%dg%\N_HABILLAGE_PCT_%insee%_%dep%.shp" ( 
goto HP7
) else (
goto HP8
)
:HP7
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_PCT_%insee%_%dep% a bien été livrée.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHP
:HP8
IF EXIST "%dg%\*HAB*PCT*.shp" ( 
goto HP9
) else (
goto HP10
)
:HP9
	echo ^<font color="red"^> ERREUR : La couche est à renommer : N_HABILLAGE_PCT_%insee%_%dep% a bien été livrée.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHP 
:HP10
IF EXIST "%dg%\N_HABILLAGE_PCT_%insee%_%dep%.tab" ( 
goto HP11
) else (
goto HP12
)
:HP11
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_PCT_%insee%_%dep% a bien été livrée.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHP
:HP12
IF EXIST "%dg%\*HAB*PCT*.tab" ( 
goto HP13
) else (
goto HP14
)
:HP13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_HABILLAGE_PCT_%insee%_%dep% a bien été livrée.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHP	
:HP14
IF EXIST "%dg%\N_HABILLAGE_PCT_%insee%_%dep%.mif" ( 
goto HP15
) else (
goto HP16
)
:HP15
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_PCT_%insee%_%dep% a bien été livrée.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHP
:HP16
IF EXIST "%dg%\*HAB*PCT*.mif" ( 
goto HP17
) else (
goto NOHP
)
:HP17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_HABILLAGE_PCT_%insee%_%dep% a bien été livrée.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHP 
:NOHP
	echo ^<font color="red"^>ERREUR : La couche N_HABILLAGE_PCT_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%

	echo. >> %rappconf%
	echo. >> %rappconf%
	goto HTXT

rem ===============================================================================================================================================================
rem 3.10.2 CONTROLE PROJECTION et ENCODAGE HABILLAGE_PCT :
rem ===============================================================================================================================================================
:OpenHP
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_PCT_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpHP= "La couche %HP% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_PCT_%insee%_%dep% :

IF "%OpHP%"=="o" (goto OHP) else goto StructureHP

:OHP
rem ouverture de la couche HP dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%HP%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvHP="La couche %HP% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvHP%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ10="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ10%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO10="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO10%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem10="Remarque(s) : "
 IF NOT "%Rem10%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem10%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.10.3 CONTROLE STRUCTURE HABILLAGE_PCT :
rem ===============================================================================================================================================================
:StructureHP
rem IMPORT DE LA COUCHE HABILLAGE_PCT DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln habillage_pct "%dg%\%HP%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_10_controle_structure_hp.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_habillage_pct dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_hp) to STDOUT" > %ES%\%insee%_erreurs_structure_habillage_pct.txt

rem decompte des lignes erreurs dans erreurs_structure_habillage_pct.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_habillage_pct.txt ^|find /i /c "ERREUR"`) do (
set structureHP=%%u
)

rem =============================================================================================================================================================
rem PAUSE11 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureHP%==0 (goto StructureHPok) else goto StructureHPnok

:StructureHPnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_PCT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureHP% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="blue"^>RAPPEL COVADIS : La couche N_HABILLAGE_PCT_%insee%_%dep% comporte 2 champs :  ^</font^>^</br^>   >> %rappconf%  
echo ^<font color="blue"^>NATTRAC (varchar 40)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)  ^</font^>^</br^>   >> %rappconf%

echo. >> %rappconf% 
echo ^<font color="red"^>%structureHP% erreur(s) de structuration :  ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_habillage_pct.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^>  %%d^</blockquote^>  ^</font^> ^</br^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto HTXT

:StructureHPok
del %ES%\%insee%_erreurs_structure_habillage_pct.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_PCT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%    
echo.>> %rappconf%            
echo.>> %rappconf% 
pause
rem =============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.11.0 TEST HABILLAGE_TXT :
rem ===============================================================================================================================================================
:HTXT
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_TXT_%insee%_%dep% :
echo ^<blockquote ^> ^<h3^>3.11 Contrôle de la couche N_HABILLAGE_TXT_%insee%_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%

rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListeHab_%insee%.txt ^| find /i "TXT"') do (
set HTnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%HTnom%.shp" ( 
set HT=%HTnom%.shp
goto NomHT
)
IF EXIST "%dg%\%HTnom%.tab" ( 
set HT=%HTnom%.tab
goto NomHT
)
IF EXIST "%dg%\%HTnom%.mif" ( 
pause
set HT=%HTnom%.mif
goto NomHT
)
goto NOHT

rem ===============================================================================================================================================================
rem 3.11.1 CONTROLE NOMMAGE HABILLAGE_TXT: 
rem ===============================================================================================================================================================
:NomHT
IF EXIST "%dg%\*HAB*TXT*CORRIGE*.shp" ( 
goto HT1
) else (
goto HT2
)
:HT1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHT 
:HT2
IF EXIST "%dg%\*HAB*TXT*CORRIGE*.tab" (
goto HT3
) else (
goto HT4
)
:HT3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHT
:HT4
IF EXIST "%dg%\*HAB*TXT*CORRIGE*.mif" ( 
goto HT5
) else (
goto HT6
)
:HT5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHT 
:HT6
IF EXIST "%dg%\N_HABILLAGE_TXT_%insee%_%dep%.shp" ( 
goto HT7
) else (
goto HT8
)
:HT7
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_TXT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHT
:HT8
IF EXIST "%dg%\*HAB*TXT*.shp" ( 
goto HT9
) else (
goto HT10
)
:HT9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_HABILLAGE_TXT_%insee%_%dep%.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHT 
:HT10
IF EXIST "%dg%\N_HABILLAGE_TXT_%insee%_%dep%.tab" ( 
goto HT11
) else (
goto HT12
)
:HT11
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_TXT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHT
:HT12
IF EXIST "%dg%\*HAB*TXT*.tab" ( 
goto HT13
) else (
goto HT14
)
:HT13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_HABILLAGE_TXT_%insee%_%dep%.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHT	
:HT14
IF EXIST "%dg%\N_HABILLAGE_TXT_%insee%_%dep%.mif" ( 
goto HT15
) else (
goto HT16
)
:HT15
	echo ^<font color="green"^>CONFORME : La couche N_HABILLAGE_TXT_%insee%_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHT
:HT16
IF EXIST "%dg%\*HAB*TXT*.mif" ( 
goto HT17
) else (
goto NOHT
)
:HT17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_HABILLAGE_TXT_%insee%_%dep%.^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenHT 
:NOHT
	echo ^<font color="red"^> ERREUR : La couche N_HABILLAGE_TXT_%insee%_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%

	echo. >> %rappconf%
	echo. >> %rappconf%
	goto DOCU

rem ===============================================================================================================================================================
rem 3.11.2 CONTROLE PROJECTION et ENCODAGE HABILLAGE_TXT :
rem ===============================================================================================================================================================
:OpenHT
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_TXT_%insee%_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpHT= "La couche %HT% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_TXT_%insee%_%dep% :

IF "%OpHT%"=="o" (goto OHT) else goto StructureHT

:OHT
rem ouverture de la couche HT dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%HT%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvHT="La couche %HT% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvHT%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ11="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ11%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO11="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO11%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem11="Remarque(s) : "
 IF NOT "%Rem11%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem11%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.11.3 CONTROLE STRUCTURE HABILLAGE_TXT :
rem ===============================================================================================================================================================
:StructureHT
rem IMPORT DE LA COUCHE HABILLAGE_TXT DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln habillage_txt "%dg%\%HT%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_11_controle_structure_ht.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_habillage_txt dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_ht) to STDOUT" > %ES%\%insee%_erreurs_structure_habillage_txt.txt

rem decompte des lignes erreurs dans erreurs_structure_habillage_txt.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_habillage_txt.txt ^|find /i /c "ERREUR"`) do (
set structureHT=%%u
)

rem =============================================================================================================================================================
rem PAUSE12 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureHT%==0 (goto StructureHTok) else goto StructureHTnok

:StructureHTnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_TXT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureHT% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="blue"^>^<blockquote^>RAPPEL COVADIS : La couche N_HABILLAGE_TXT_%insee%_%dep% comporte 3 champs :^</font^>^</br^>   >> %rappconf% 
echo ^<font color="blue"^>NATTRAC (varchar 40)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TXT (varchar 80)^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INSEE (varchar 5)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureHT% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_habillage_txt.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%d^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo.
pause
goto DOCU

:StructureHTok
del %ES%\%insee%_erreurs_structure_habillage_txt.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_HABILLAGE_TXT_%insee%_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%  
echo.>> %rappconf%            
echo.>> %rappconf% 
pause
rem =============================================================================================================================================================




rem ===============================================================================================================================================================
rem 3.12.0 TEST DOCUMENT_URBA :
rem ===============================================================================================================================================================
:DOCU
del ListeHab_%insee%.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_DOCUMENT_URBA_%dep% :
echo ^<blockquote ^> ^<h3^>3.12 Contrôle de la couche N_DOCUMENT_URBA_%dep% ^</h3^>^</blockquote^>  >> %rappconf%
echo. >> %rappconf%
rem recherche du nom de la couche dans la liste des données géographiques et déplacement dans %dg%:
for /f %%s in ('type ListeDG_%insee%.txt ^| find /i "DOC"') do (
set DOCUnom=%%~ns
)

rem recherche du format et ajout de l'extension au nom:
IF EXIST "%dg%\%DOCUnom%.shp" ( 
set DOCU=%DOCUnom%.shp
goto NomDOCU
)
IF EXIST "%dg%\%DOCUnom%.tab" ( 
set DOCU=%DOCUnom%.tab
goto NomDOCU
)
IF EXIST "%dg%\%DOCUnom%.mif" ( 
pause
set DOCU=%DOCUnom%.mif
goto NomDOCU
)
goto NODOCU

rem ===============================================================================================================================================================
rem 3.12.1 CONTROLE NOMMAGE DOCUMENT_URBA: 
rem ===============================================================================================================================================================
:NomDOCU
IF EXIST "%dg%\*DOC*URBA*CORRIGE*.shp" ( 
goto DOCU1
) else (
goto DOCU2
)
:DOCU1
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenDOCU 
:DOCU2
IF EXIST "%dg%\*DOC*URBA*CORRIGE*.tab" (
goto DOCU3
) else (
goto DOCU4
)
:DOCU3
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenDOCU
:DOCU4
IF EXIST "%dg%\*DOC*URBA*CORRIGE*.mif" ( 
goto DOCU5
) else (
goto DOCU6
)
:DOCU5
	echo ^<font color="green"^>CONFORME : La couche testée est une version CORRIGEE (en interne).  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenDOCU 
:DOCU6
IF EXIST "%dg%\N_DOCUMENT_URBA_%dep%.shp" ( 
goto DOCU7
) else (
goto DOCU8
)
:DOCU7
	echo ^<font color="green"^>CONFORME : La couche N_DOCUMENT_URBA_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenDOCU
:DOCU8
IF EXIST "%dg%\*DOC*URBA*.shp" ( 
goto DOCU9
) else (
goto DOCU10
)
:DOCU9
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_DOCUMENT_URBA_%dep%  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenDOCU 
:DOCU10
IF EXIST "%dg%\N_DOCUMENT_URBA_%dep%.tab" ( 
goto DOCU11
) else (
goto DOCU12
)
:DOCU11
	echo ^<font color="green"^>CONFORME : La couche N_DOCUMENT_URBA_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenDOCU
:DOCU12
IF EXIST "%dg%\*DOC*URBA*.tab" ( 
goto DOCU13
) else (
goto DOCU14
)
:DOCU13
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_DOCUMENT_URBA_%dep%  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenDOCU	
:DOCU14
IF EXIST "%dg%\N_DOCUMENT_URBA_%dep%.mif" ( 
goto DOCU15
) else (
goto DOCU16
)
:DOCU15
	echo ^<font color="green"^>CONFORME : La couche N_DOCUMENT_URBA_%dep% a bien été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenDOCU
:DOCU16
IF EXIST "%dg%\*DOC*URBA*.mif" ( 
goto DOCU17
) else (
goto NODOCU
)
:DOCU17
	echo ^<font color="red"^>ERREUR : La couche est à renommer : N_DOCUMENT_URBA_%dep%  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	goto OpenDOCU 
:NODOCU
	echo ^<font color="red"^>ERREUR : La couche N_DOCUMENT_URBA_%dep% n'a pas été livrée.  ^</font^>^</br^>   >> %rappconf%
	echo. >> %rappconf%
	echo. >> %rappconf%
	goto FinDOCU

rem ===============================================================================================================================================================
rem 3.12.2 CONTROLE PROJECTION et ENCODAGE DOCUMENT_URBA :
rem ===============================================================================================================================================================
:OpenDOCU
cls
echo Controle des donnees geographiques...
echo.
echo *N_DOCUMENT_URBA_%dep% :
echo.
rem ouvrir si couche détecté :
set /p OpDOCU= "La couche %DOCU% a ete livre. Voulez-vous l'ouvrir ? (o/n): "
cls
echo Controle des donnees geographiques...
echo.
echo *N_DOCUMENT_URBA_%dep% :

IF "%OpDOCU%"=="o" (goto ODOCU) else goto StructureDOCU

:ODOCU
rem ouverture de la couche DOCU dans Qgis pr verif PROJECTION et ENCODAGE :
rem --------------------------------------------------------------------------------------------
"%dg%\%DOCU%"
echo.
echo Ouverture de la couche...
echo.
echo.
rem notification des remarques PROJECTION et ENCODAGE:
 set /p OuvDOCU="La couche %DOCU% s'ouvre-t-elle ? (o/n) : "
 IF "%OuvDOCU%"=="n" ( 
echo ^<font color="red"^>ERREUR : La couche ne s'ouvre pas.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 ) 
 set /p PROJ12="PROJECTION RGF 93 ? (o/n) : "
 IF "%PROJ12%"=="n" ( 
echo ^<font color="red"^>ERREUR : Projection non conforme : définir en RGF Lambert 93, EPSG : 2154.   ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p ENCO12="ENCODAGE UTF 8 ? (o/n) : " 
 IF "%ENCO12%"=="n" (
echo ^<font color="blue"^>REMARQUE : L'encodage en UTF-8 est fortement conseillé.  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 set /p Rem12="Remarque(s) : "
 IF NOT "%Rem12%"=="" (
echo ^<font color="blue"^>REMARQUE : "%Rem12%" >>  ^</font^>^</br^>   >> %rappconf%
 echo.  >> %rappconf%
 )
 
rem ===============================================================================================================================================================
rem 3.12.3 CONTROLE STRUCTURE DOCUMENT_URBA :
rem ===============================================================================================================================================================
:StructureDOCU 
rem IMPORT DE LA COUCHE DOCUMENT_URBA DS POSTGRE:
rem -------------------------------------------------
echo.
echo IMPORT de la couche...
SET PGCLIENTENCODING=LATIN1
%OGR% --config PGCLIENTENCODING LATIN1 -lco PRECISION=NO -f "PostgreSQL" PG:"host=%host% user=%user% dbname=%base% password=%pass% active_schema=public" -s_srs EPSG:2154 -t_srs EPSG:2154 -lco GEOMETRY_NAME=the_geom -nlt geometry -overwrite -nln document_urba "%dg%\%DOCU%"
echo.
echo ...fin
echo.
rem pause

echo * Controle de structuration de la table...
echo.
rem creation de la table d'erreurs de structure (champs manquants, types invalides, champs à supprimer ou renommer):
%PSQL% -d %base% -f %SQL%\5_12_controle_structure_docu.sql -q -t -h %host% -p %port% -U %user% 

rem export de la table erreur_structure_document_urba dans le dossiers PG_DATA en TXT :
%PSQL% -U %user% -d %base% -c "copy (Select * from erreurs_champs_docu) to STDOUT" > %ES%\%insee%_erreurs_structure_document_urba.txt

rem decompte des lignes erreurs dans erreurs_structure_document_urba.txt :
for /F "usebackq" %%u in (`type %ES%\%insee%_erreurs_structure_document_urba.txt ^|find /i /c "ERREUR"`) do (
set structureDOCU=%%u
)

rem =============================================================================================================================================================
rem PAUSE13 pour voir le traitement structure (ajouter/supprimer "rem" pour désactiver/activer)
rem =============================================================================================================================================================
echo.
echo fin du traitement!
pause
rem =============================================================================================================================================================

IF %structureDOCU%==0 (goto StructureDOCUok) else goto StructureDOCUnok

:StructureDOCUnok
cls
echo Controle des donnees geographiques...
echo.
echo *N_DOCUMENT_URBA_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE NON CONFORME*
echo %structureDOCU% erreurs.

echo ^<font color="red"^>ERREUR : STRUCTURATION NON-CONFORME :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="blue"^>^<blockquote^>RAPPEL COVADIS : La couche N_DOCUMENT_URBA_%dep% comporte 16 champs :  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>IDURBA (varchar 20)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>IDURBAPREC (varchar 20)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>TYPEDOC (varchar 3)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>ETAT (varchar 2)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>VERSION (varchar 20)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATAPPRO (date)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATVALID (date)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>INTERCO (varchar 1)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>SIREN (varchar 9)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMREG (varchar 80)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLREG (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMPLAN (varchar 80)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>URLPLAN (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>SITEWEB (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>NOMREF (varchar 254)  ^</font^>^</br^>   >> %rappconf%
echo ^<font color="blue"^>DATEREF (date)  ^</font^>^</br^>^</blockquote^>   >> %rappconf%
echo. >> %rappconf% 
echo ^<font color="red"^>ERREUR : %structureDOCU% erreur(s) de structuration :   ^</br^>   >> %rappconf%
rem liste des erreurs dans rapport :
for /F "delims=" %%d in ('type %ES%\%insee%_erreurs_structure_document_urba.txt ^|find /i "ERREUR"') do (
echo ^<blockquote^> %%d^</blockquote^> ^</br^>^</font^>   >> %rappconf%
)
echo.>> %rappconf%
echo.>> %rappconf% 
echo. 
pause
goto FinDOCU

:StructureDOCUok
del %ES%\%insee%_erreurs_structure_document_urba.txt
cls
echo Controle des donnees geographiques...
echo.
echo *N_DOCUMENT_URBA_%dep% :
echo Controle de structuration de la table...
echo         ...fin du controle de la structure.
echo ------------------------------------
echo *STRUCTURE CONFORME*
echo ^<font color="green"^>CONFORME : STRUCTURATION DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%  
echo.>> %rappconf%            
echo.>> %rappconf% 
:FinDOCU
cls
echo Controle des donnees geographiques...
rem =============================================================================================================================================================




rem ===============================================================================================================================================================
rem BILAN controle données géo 
rem ===============================================================================================================================================================
:BilanDG

for /F "usebackq" %%o in (`type %rappconf% ^|find /c "ERREUR"`) do (
set dge=%%o
)
echo.
echo %dge% Erreur(s)
IF %dge%==0 goto dga
IF not %dge%==0 goto dgb
:dga
echo --------------------------------------------------------------------------------

echo ^<font color="green"^>CONFORME : DONNEES GEOGRAPHIQUES DE LA TABLE CONFORME.   ^</font^>^</br^>   >> %rappconf%  

echo *DONNEES GEOGRAPHIQUES : CONFORME*
goto dgc
:dgb
echo --------------------------------------------------------------------------------
echo. >> %rappconf%
echo ^<font color="red"^>ERREUR : DONNEES GEOGRAPHIQUES DE LA TABLE NON CONFORME.   ^</font^>^</br^>   >> %rappconf%  
echo ^<font color="red"^>ERREUR : %dge% erreurs de données :   ^</font^>^</br^>   >> %rappconf%
echo. >> %rappconf%
echo *DONNEES GEOGRAPHIQUES : NON CONFORME*
:dgc
echo. >> %rappconf%
echo.
echo ...fin
pause

del ListeDG_%insee%.txt

:FIN
cls
echo.
echo   ********FIN DU CONTROLE DES FICHIERS LIVRES********
echo.


rem ===============================================================================================================================================================
rem **BILAN GENERALE / AVIS CONFORMITE : 
rem ===============================================================================================================================================================
set /a bilan=%arbo%+%pdf%+%dge% 
IF %bilan%==0 (
echo          ** CONFORME AU STANDARD COVADIS V2 **
echo.
echo Les donnees peuvent etre integrees et mises a disposition.
goto rapp
) else (
echo        ** NON CONFORME AU STANDARD COVADIS V2 **)
IF %choix%==1 (
echo ** %pdf% Erreurs sur les pieces ecrites
)
IF %choix%==2 (
echo ** %dge% Erreurs sur les donnees geographiques
)
IF %choix%==3 (
echo ** %pdf% Erreurs sur les pieces ecrites
echo ** %dge% Erreurs sur les donnees geographiques
)

rem ===============================================================================================================================================================
rem OUVERTURE DU RRAPPORT ET DES DONNEES : 
rem ===============================================================================================================================================================
:rapp
echo.
echo.
rem ouverture du rapport :
echo ^</body^> >> %rappconf%
echo ^</html^> >> %rappconf%
"%cd%\%rappconf%"  

rem ouverture du dossier et de toutes les couches :
set geom=%ET%\%insee%_geom_invalid.shp
set chev=%ET%\%insee%_chevauchement.shp
set trou=%ET%\%insee%_trous.shp
set deca=%ET%\%insee%_decalages_section.shp
echo.
set /p OpenAll="Souhaitez-vous afficher toutes les donnees ? (o/n) : "
IF "%OpenAll%"=="o" ( 
explorer %plu%
echo Ouverture des donnees...
%QGIS% %COM% %dg%\%ZU% %dg%\%PS% %dg%\%IS% %dg%\%HS% %dg%\%PL% %dg%\%IL% %dg%\%HL% %dg%\%PP% %dg%\%IP% %dg%\%HP% %dg%\%HT% %plu%\%DOCU% %geom% %chev% %deca% %trou% /cmd/
echo.  >> %rappconf%
 )
 echo.
pause

rem à voir pour ++++++ :
rem format edigeo
rem modif controle nommage pdf
rem interpretation/contraintes/requête sur les valeurs des champs
rem si plusieurs couches nommées avec même mot clé
