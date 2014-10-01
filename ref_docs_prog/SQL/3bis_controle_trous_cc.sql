;
--correction des poly invalides :
Update public.secteur_cc Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false; --st_buffer(geom, 0.0) renvoie le même polygone mais OGC compatible)

--détection trous :
drop table trous;
create table trous as
select st_geomfromtext(st_astext((st_dumprings(ST_Union(the_geom))).geom))as trous, st_area(st_geomfromtext(st_astext((st_dumprings(ST_Union(the_geom))).geom))) as trous_en_m² from public.secteur_cc;
ALTER TABLE trous ADD COLUMN id serial primary key;
Delete from trous where id=1;
select UpdateGeometrySRID('trous','trous', 2154);
