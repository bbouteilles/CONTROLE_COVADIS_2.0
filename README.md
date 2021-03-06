CONTROLE_COVADIS_2.0
====================

Script de contrôle des livraisons des documents d'urbanisme numérisés au standard COVADIS 2.0


*******************************************************************************
  	 PLAN DU PROGRAMME BATCH TEST_COVADISV2_PLU_POS_CC
*******************************************************************************

 00- Module pour déterminer les variables
-------------------------------------------------------------------------------

 01- Module des chemins du répertoire de travail				
-------------------------------------------------------------------------------

 I- Module de contrôle de l'arborescence :				
-------------------------------------------------------------------------------
	 1.1 EXISTENCE DE 38XXX_DOC_AAAAMMJJ 				
	 1.2 EXISTENCE DE Pieces_ecrites 				
	 1.3 EXISTENCE DE Donnees_geographiques 			
	 1.4 1_Rapport_de_presentation (PLU/POS+CC)			
	 1.5 2_PADD							
	 1.6 3_Reglement						
	 1.7 4_Annexes							
	 1.7bis 2_Annexes (CC)						
	 1.8 5_Orientations_amenagement					
	 1.9 6_Documents_graphiques					

	BILAN controle arborescence 					
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
 Choix du controle : 							
-------------------------------------------------------------------------------

 II- Module de contrôle des PDF 					
-------------------------------------------------------------------------------
	 2.0 Detection des PDF (listePDF)				

	 2.1.0 CONTROLE 38XXX_rapport_AAAAMMJJ :			
		 2.1.1 NOMMAGE et CONCATENAGE rapport.pdf		
		 2.1.2 OUVERTURE DU PDF 38XXX_rapport_AAAAMMJJ 		
		
	 2.2.0 CONTROLE 38XXX_padd_AAAAMMJJ :				
		 2.2.1 NOMMAGE et CONCATENAGE padd.pdf 			
		 2.2.2 OUVERTURE DU PDF 38XXX_padd_AAAAMMJJ 		
		
	 2.3.0 CONTROLE 38XXX_reglement_AAAAMMJJ :			
		 2.3.1 NOMMAGE et CONCATENAGE reglement.pdf 		
		 2.3.2 OUVERTURE DU PDF 38XXX_reglement_AAAAMMJJ 	
		
	 2.4.0 CONTROLE 38XXX_annexes_AAAAMMJJ :			
		 2.4.1 NOMMAGE et CONCATENAGE annexes.pdf 		
		 2.4.2 OUVERTURE DU PDF 38XXX_annexes_AAAAMMJJ 		
		
	 2.4.0bis CONTROLE 38XXX_annexes_AAAAMMJJ : (CC)		
		 2.4.1bis NOMMAGE et CONCATENAGE annexes.pdf		
		 2.4.2bis OUVERTURE DU PDF 38XXX_annexes_AAAAMMJJ	
		
	 2.5.0 CONTROLE 38XXX_orientations_AAAAMMJJ :			
		 2.5.1 NOMMAGE et CONCATENAGE orientations.pdf 		
		 2.5.2 OUVERTURE DU PDF 38XXX_orientations_AAAAMMJJ 	

	 2.6.0 CONTROLE 38XXX_docgraphiques_AAAAMMJJ :			
		 2.6.1 NOMMAGE et CONCATENAGE docgraphiques.pdf 	
		 2.6.2 OUVERTURE DU PDF 38XXX_docgraphiques_AAAAMMJJ 	
	
	BILAN controle pdf 						
-------------------------------------------------------------------------------

 III- Module de contrôle des fichiers cartographiques 			
-------------------------------------------------------------------------------

	 3.0 Controle des Formats livrés (listesDG)			
	
	 3.1.0 TEST ZONE_URBA :						
		 3.1.1 CONTROLE NOMMAGE 			
		 3.1.2 CONTROLE PROJECTION et ENCODAGE 		
		 3.1.3 CONTROLE TOPOLOGIQUE (+import)	 		
		 3.1.4 CONTROLE STRUCTURE			
		
	 3.2.0 TEST PRESCRIPTION_SURF:					
		 3.2.1 CONTROLE NOMMAGE 		 	
		 3.2.2 CONTROLE PROJECTION et ENCODAGE		
		 3.2.3 CONTROLE STRUCTURE (+import)			
		
	 3.3.0 TEST PRESCRIPTION_LIN :					
		 3.3.1 CONTROLE NOMMAGE 				
		 3.3.2 CONTROLE PROJECTION et ENCODAGE			
		 3.3.3 CONTROLE STRUCTURE (+import)				
			
	 3.4.0 TEST PRESCRIPTION_PCT :					
		 3.4.1 CONTROLE NOMMAGE  				
		 3.4.2 CONTROLE PROJECTION et ENCODAGE 			
		 3.4.3 CONTROLE STRUCTURE (+import) 				
		
	 3.5.0 TEST INFO_SURF:						
		 3.5.1 CONTROLE NOMMAGE					
		 3.5.2 CONTROLE PROJECTION et ENCODAGE			
		 3.5.3 CONTROLE STRUCTURE (+import) 				
		
	 3.6.0 TEST INFO_LIN :						
		 3.6.1 CONTROLE NOMMAGE				
		 3.6.2 CONTROLE PROJECTION et ENCODAGE		
		 3.6.3 CONTROLE STRUCTURE (+import) 			
		
	 3.7.0 TEST INFO_PCT :						
		 3.7.1 CONTROLE NOMMAGE				
		 3.7.2 CONTROLE PROJECTION et ENCODAGE		
		 3.7.3 CONTROLE STRUCTURE (+import) 			
		
	 3.1.0bis TEST SECTEUR_CC : (CC)				
		 3.1.1bis CONTROLE NOMMAGE et FORMAT 	
		 3.1.2bis CONTROLE PROJECTION et ENCODAGE
		 3.1.3bis CONTROLE TOPOLOGIQUE (+import) 			
		 3.1.4bis CONTROLE STRUCTURE 			
		
	 3.5.0bis TEST INFO_SURF: (CC)					
		 3.5.1bis CONTROLE NOMMAGE		
		 3.5.2bis CONTROLE PROJECTION et ENCODAGE	
		 3.5.3bis CONTROLE STRUCTURE (+import) 		
		
	 3.6.0bis TEST INFO_LIN : (CC)					
		 3.6.1bis CONTROLE NOMMAGE 			
		 3.6.2bis CONTROLE PROJECTION et ENCODAGE	
		 3.6.3bis CONTROLE STRUCTURE (+import) 			
		
	 3.7.0bis TEST INFO_PCT : (CC)					
		 3.7.1bis CONTROLE NOMMAGE			
		 3.7.2bis CONTROLE PROJECTION et ENCODAGE	
		 3.7.3bis CONTROLE STRUCTURE (+import) 			
		
	 3.8.0 TEST HABILLAGE_SURF:					
		 3.8.1 CONTROLE NOMMAGE			
		 3.8.2 CONTROLE PROJECTION et ENCODAGE		
		 3.8.3 CONTROLE STRUCTURE (+import)			
		
	 3.9.0 TEST HABILLAGE_LIN :					
		 3.9.1 CONTROLE NOMMAGE			
		 3.9.2 CONTROLE PROJECTION et ENCODAGE		
		 3.9.3 CONTROLE STRUCTURE (+import) 				
		
	 3.10.0 TEST HABILLAGE_PCT :
		 3.10.1 CONTROLE NOMMAGE					
		 3.10.2 CONTROLE PROJECTION et ENCODAGE	
		 3.10.3 CONTROLE STRUCTURE (+import)
  			
	 3.11.0 TEST HABILLAGE_TXT :	
		 3.11.1 CONTROLE NOMMAGE			
		 3.11.2 CONTROLE PROJECTION et ENCODAGE		
		 3.11.3 CONTROLE STRUCTURE (+import) 		
		
	 3.12.0 TEST DOCUMENT_URBA :					
		 3.12.1 CONTROLE NOMMAGE				
		 3.12.2 CONTROLE PROJECTION et ENCODAGE			
		 3.12.3 CONTROLE STRUCTURE (+import) 
	
	BILAN controle données géo
-------------------------------------------------------------------------------	

BILAN GENERAL						
-------------------------------------------------------------------------------	

OUVERTURE DU RAPPORT ET DES DONNEES  						
-------------------------------------------------------------------------------				
