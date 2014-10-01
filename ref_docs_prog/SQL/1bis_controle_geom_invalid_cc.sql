;
Drop table geom_invalid;
Create table geom_invalid as (
SELECT the_geom as "poly_invalid", ST_IsValidReason(the_geom) as "invalid_reason" FROM public.secteur_cc where ST_isValid(the_geom)=false);
ALTER TABLE geom_invalid ADD COLUMN id serial primary key;

--select * from geom_invalid;
