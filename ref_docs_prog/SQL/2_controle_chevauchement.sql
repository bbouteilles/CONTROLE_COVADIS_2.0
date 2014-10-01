;
--correction des poly invalides :
Update public.zone_urba Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false; --st_buffer(geom, 0.0) renvoie le même polygone mais OGC compatible)
--detection chevauchement :
Drop table chevauchement;
Create table chevauchement as
SELECT 
	"LISTE_CHEVAUCHE"."poly1" as "Le_POLYGONE", 
	"LISTE_CHEVAUCHE"."geom",
	ARRAY_TO_STRING(ARRAY[ARRAY_AGG("LISTE_CHEVAUCHE"."poly2")],',')as "chevauche"
FROM (select 
p1.ogc_fid-1 as "poly1",p1.the_geom as geom, p2.ogc_fid-1 as "poly2"  
from public.zone_urba p1 join public.zone_urba p2 on (st_overlaps(p1.the_geom, p2.the_geom)) 
where p1.ogc_fid <p2.ogc_fid 
order by p1.ogc_fid)"LISTE_CHEVAUCHE" 
Group by "LISTE_CHEVAUCHE"."poly1", "LISTE_CHEVAUCHE"."geom";

