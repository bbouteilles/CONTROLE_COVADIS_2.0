;
--decalage section :

	-- contour des sections :
--Update public.section_com  Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false;
drop table contour_section;
create table contour_section as
select st_geomfromtext(st_astext((st_dumprings(ST_Union(the_geom))).geom))as contours from (select distinct section_dep_dgi.ogc_fid, section_dep_dgi.the_geom, section_dep_dgi.codcomm from section_dep_dgi, zone_urba where section_dep_dgi.codcomm=zone_urba.insee) as section_com;

ALTER TABLE contour_section ADD COLUMN id serial primary key;
DELETE from contour_section where id>1;
select UpdateGeometrySRID('contour_section','contours', 2154);
Update public.contour_section  Set contours=st_buffer(contours, 0.0) where ST_isValid(contours)=false; --st_buffer(geom, 0.0) renvoie le même polygone mais OGC compatible)

	-- contour des zonages :
Update public.zone_urba  Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false;
drop table contour_zu;
create table contour_zu as
select st_geomfromtext(st_astext((st_dumprings(ST_Union(the_geom))).geom))as contourzu from public.zone_urba;

ALTER TABLE contour_zu ADD COLUMN id serial primary key;
Delete from contour_zu where id>1;
select UpdateGeometrySRID('contour_zu','contourzu', 2154);
Update public.contour_zu Set contourzu=st_buffer(contourzu, 0.0) where ST_isValid(contourzu)=false; --st_buffer(geom, 0.0) renvoie le même polygone mais OGC compatible)

	-- difference symétrique contour_zu/contour_section:
drop table decalage_section;
create table decalage_section as
select st_symdifference (contours,contourzu) as decalage from contour_section, contour_zu;

ALTER TABLE decalage_section ADD COLUMN id serial primary key;
select UpdateGeometrySRID('decalage_section','decalage', 2154);

--select * from decalage_section;