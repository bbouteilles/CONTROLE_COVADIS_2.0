;
--decalage section :

	-- contour des sections :
--Update public.section_com  Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false;
drop table contour_section;
create table contour_section as
select st_geomfromtext(st_astext((st_dumprings(ST_Union(the_geom))).geom))as contours from (select distinct section_dep_dgi.ogc_fid, section_dep_dgi.the_geom, section_dep_dgi.codcomm from section_dep_dgi, secteur_cc where section_dep_dgi.codcomm=secteur_cc.insee) as section_com;

ALTER TABLE contour_section ADD COLUMN id serial primary key;
DELETE from contour_section where id>1;
select UpdateGeometrySRID('contour_section','contours', 2154);
Update public.contour_section  Set contours=st_buffer(contours, 0.0) where ST_isValid(contours)=false; --st_buffer(geom, 0.0) renvoie le même polygone mais OGC compatible)

	-- contour des zonages :
Update public.secteur_cc  Set the_geom=st_buffer(the_geom, 0.0) where ST_isValid(the_geom)=false;
drop table contour_scc;
create table contour_scc as
select st_geomfromtext(st_astext((st_dumprings(ST_Union(the_geom))).geom))as contourscc from public.secteur_cc;

ALTER TABLE contour_scc ADD COLUMN id serial primary key;
Delete from contour_scc where id>1;
select UpdateGeometrySRID('contour_scc','contourscc', 2154);
Update public.contour_scc Set contourscc=st_buffer(contourscc, 0.0) where ST_isValid(contourscc)=false; --st_buffer(geom, 0.0) renvoie le même polygone mais OGC compatible)

	-- difference symétrique contour_scc/contour_section:
drop table decalage_section;
create table decalage_section as
select st_symdifference (contours,contourscc) as decalage from contour_section, contour_scc;

ALTER TABLE decalage_section ADD COLUMN id serial primary key;
select UpdateGeometrySRID('decalage_section','decalage', 2154);

--select * from decalage_section;