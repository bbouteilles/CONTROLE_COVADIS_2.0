;
	--decalage section :
drop table contour_section;
create table contour_section as
select distinct section_dep_ign.ogc_fid, section_dep_ign.the_geom, section_dep_ign.code_insee from section_dep_ign, zone_urba where section_dep_ign.code_insee=zone_urba.insee;
Update public.contour_section  Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false;

	-- contour des zonages :
Update public.secteur_cc  Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false;
drop table contour_scc;
create table contour_scc as
select st_geomfromtext(st_astext((st_dumprings(ST_Union(the_geom))).geom))as contourscc from public.secteur_cc;
ALTER TABLE contour_scc ADD COLUMN id serial primary key;
Delete from contour_scc where id>1;
select UpdateGeometrySRID('contour_scc','contourscc', 2154);
Update public.contour_scc Set contourscc=st_buffer(contourscc, 0.0) where ST_isValid(contourscc)=false; --st_buffer(geom, 0.0) renvoie le même polygone mais OGC compatible)

	-- difference symétrique contour_scc/section_com:
drop table decalage_section;
create table decalage_section as
select st_symdifference (the_geom,contourscc) as decalage from contour_section, contour_scc;
ALTER TABLE decalage_section ADD COLUMN id serial primary key;
select UpdateGeometrySRID('decalage_section','decalage', 2154);