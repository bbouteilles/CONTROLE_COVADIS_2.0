;
	--decalage section :
drop table contour_section;
create table contour_section as
select distinct section_dep_ign.ogc_fid, section_dep_ign.the_geom, section_dep_ign.code_insee from section_dep_ign, zone_urba where section_dep_ign.code_insee=zone_urba.insee;
Update public.contour_section  Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false;

	-- contour des zonages :
Update public.zone_urba  Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false;
drop table contour_zu;
create table contour_zu as
select st_geomfromtext(st_astext((st_dumprings(ST_Union(the_geom))).geom))as contourzu from public.zone_urba;
ALTER TABLE contour_zu ADD COLUMN id serial primary key;
Delete from contour_zu where id>1;
select UpdateGeometrySRID('contour_zu','contourzu', 2154);
Update public.contour_zu Set contourzu=st_buffer(contourzu, 0.0) where ST_isValid(contourzu)=false; --st_buffer(geom, 0.0) renvoie le même polygone mais OGC compatible)

	-- difference symétrique contour_zu/section_com:
drop table decalage_section;
create table decalage_section as
select st_symdifference (the_geom,contourzu) as decalage from contour_section, contour_zu;
ALTER TABLE decalage_section ADD COLUMN id serial primary key;
select UpdateGeometrySRID('decalage_section','decalage', 2154);