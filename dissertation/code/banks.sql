-- Purpose: SQL script to create a table of bank branches with various attributes and spatial relationships.
-- It also creates a table of hexagons for visualisation purposes.
-- Order:
-- 1. Create empty table
-- 2. Insert data from GLX Open Bank Branches
-- 3. Create 3km buffer
-- 4. Assign IUC to OA's
-- 5. Assign data at OA to banks using 3km buffer
-- 6. Create table which has a bank ID and the closest two banks
-- 7. Assign nearest competitors to banks
-- 8. Assign second nearest competitors to banks
-- 9. Calculate average distance to competitors
-- 10. Create table with distance to home bank
-- 11. Assign it to banks
-- 12. Create table with distance to post office
-- 13. Assign it to banks
-- 14. Create column within RP
-- 15. Find if a bank has an RP ID
-- 16. If it does its within an RP so true else false
-- 17. Create column suburb bank
-- 18. Assign a polygon based on what the bank is within
-- 19. If the bank is within a suburb polygon then true else false
-- 20. Create column SME lending
-- 21. Assign sum of SME lending based on postal sector centroid in 3km catchment
-- 22. Create column estimated value
-- 23. Assign average VOA value based on VOA bank point in the 3km catchment
-- 24. Fill in null values for SME lending and estimated value
-- 25. Select all columns for export
-- 26. Create H3 (Uber) hexes for visualisation
-- 27. Bin incorrect predictions to hexes

---- DATA PREP ----
-- CREATE EMPTY TABLE
create table data.banks (
id integer,
name text,
brand text,
address text,
town text,
region text,
latitude double precision,
longitude double precision,
geom_p_4326 geometry(Point, 4326),
buffer_3km geometry(Polygon, 4326),
avg_urbanity numeric,
avg_iuc numeric,
hhd_census numeric,
pop_census numeric,
workers_current numeric,
ab_perc numeric,
c1_perc numeric,
c2_perc numeric,
de_perc numeric,
age0to17_perc numeric,
age18to24_perc numeric,
age25to44_perc numeric,
age45to59_perc numeric,
age60to74_perc numeric,
age75plus_perc numeric,
students_perc numeric,
white_perc numeric,
non_white_perc numeric,
nearest_comp1_id integer,
distance_to_nearest_comp1 numeric,
nearest_comp2_id integer,
distance_to_nearest_comp2 numeric,
avg_distance_to_comp numeric,
distance_to_nearest_home_bank numeric,
distance_to_postoffice numeric,
closed_q1_2024 boolean
);

-- CREATE SPATIAL INDEXES
create index banks_geom_p_4326_sidx on data.banks using gist (geom_p_4326);
create index banks_buffer_3km_sidx on data.banks using gist (buffer_3km);

-- INSERT DATA FROM GLX OPEN BANK BRANCHES
insert into data.banks (id, name, brand, address, town, region, latitude, longitude, geom_p_4326, closed_q1_2024)
select id, branch_name, brand_full, add_one || ' ' || add_two || ' ' || postcode, town, region, lat_wgs84, long_wgs84, geom_p_4326, case when close_year is null then false else true end
from data.uk_glx_open_bank_branches
where region not in ('Northern Ireland', 'Scotland')
and branch_type = 'Branch'
and open_year is null;


-- CREATE 3KM BUFFER
update data.banks
set buffer_3km = ST_Buffer(geom_p_4326, 3000);

-- SPATIAL INDEXES TO GEOGRAPHY FOR ST_DWITHIN
CREATE INDEX IF NOT EXISTS sidx_uk_glx_geodata_oa_metrics_geog_p
    ON data.uk_glx_geodata_oa_metrics_2023 USING gist
    ((geom_p_4326::geography));

CREATE INDEX IF NOT EXISTS sidx_banks_geom_p_4326
    ON data.banks USING gist
    ((geom_p_4326::geography));


-- ASSIGN IUC TO OA'S
with iuc_to_2021 as (
select
    lsoa.lsoa21cd,
    iuc.iuc_rank_number
from data.iuc_2018 iuc
left join data.lsoa_2011_to_2021 lsoa
on iuc.lsoa_code = lsoa.lsoa11cd
),

iuc_to_oa as (
select
    oa.oa21cd,
    oa.lsoa21cd,
    iuc.iuc_rank_number
from iuc_to_2021 iuc
left join data.oa21_to_lsoa21 oa
on iuc.lsoa21cd = oa.lsoa21cd
)

update data.uk_glx_geodata_oa_metrics_2023 oa
set iuc_rank_number = iuc.iuc_rank_number
from iuc_to_oa iuc
where oa.lsoa_code = iuc.oa21cd;


-- ASSIGN DATA AT OA TO BANKS USING 3KM BUFFER
with oa_metrics as (
select
    b.id as bank_id,
    avg(oa.urbanity) as avg_urbanity,
    sum(oa.hhd_census) as hhd_census,
    sum(oa.population_census) as pop_census,
    sum(oa.abhrp)/sum(oa.hhd_current) as ab_perc,
    sum(oa.c1hrp)/sum(oa.hhd_current) as c1_perc,
    sum(oa.c2hrp)/sum(oa.hhd_current) as c2_perc,
    sum(oa.dehrp)/sum(oa.hhd_current) as de_perc,
    sum(oa.age0to17)/sum(oa.population_current) as age0to17_perc,
    (sum(oa.age18to19)+sum(oa.age20to24))/sum(oa.population_current) as age18to24_perc,
    (sum(oa.age25to29)+sum(oa.age30to44))/sum(oa.population_current) as age25to44_perc,
    sum(oa.age45to59)/sum(oa.population_current) as age45to59_perc,
    sum(oa.age60to74)/sum(oa.population_current) as age60to74_perc,
    sum(oa.age75plus)/sum(oa.population_current) as age75plus_perc,
    sum(oa.students)/sum(oa.population_current) as students_perc,
    sum(oa.white)/sum(oa.population_current) as white_perc,
    sum(oa.nonwhite)/sum(oa.population_current) as non_white_perc,
    sum(oa.workers_current) as workers_current,
    avg(oa.iuc_rank_number::numeric) as avg_iuc
from data.banks b
left join data.uk_glx_geodata_oa_metrics_2023 oa
on st_dwithin(b.geom_p_4326::geography, oa.geom_p_4326::geography, 3000)
group by b.id
)

update data.banks
set avg_urbanity = oa.avg_urbanity,
    hhd_census = oa.hhd_census,
    pop_census = oa.pop_census,
    ab_perc = oa.ab_perc,
    c1_perc = oa.c1_perc,
    c2_perc = oa.c2_perc,
    de_perc = oa.de_perc,
    age0to17_perc = oa.age0to17_perc,
    age18to24_perc = oa.age18to24_perc,
    age25to44_perc = oa.age25to44_perc,
    age45to59_perc = oa.age45to59_perc,
    age60to74_perc = oa.age60to74_perc,
    age75plus_perc = oa.age75plus_perc,
    students_perc = oa.students_perc,
    white_perc = oa.white_perc,
    non_white_perc = oa.non_white_perc,
    workers_current = oa.workers_current,
    avg_iuc = oa.avg_iuc
from
oa_metrics oa
where data.banks.id = oa.bank_id;



-- CREATE TABLE WHICH HAS A BANK ID AND THE CLOSEST TWO BANKS
TRUNCATE data.closest_banks;
DROP TABLE IF EXISTS data.closest_banks;
CREATE TABLE data.closest_banks AS
SELECT
    banks.id AS bank_id,
    nearest.id AS nearest_id,
    ST_DistanceSphere(banks.geom_p_4326, nearest.geom_p_4326) AS distance
FROM
    data.banks
CROSS JOIN LATERAL (
    SELECT
        other_banks.id,
        other_banks.geom_p_4326
    FROM
        data.banks AS other_banks
    WHERE
        other_banks.id != banks.id -- Exclude the bank of interest
    AND
        other_banks.brand !=  banks.brand -- only 'competition' banks
    ORDER BY
        banks.geom_p_4326 <-> other_banks.geom_p_4326 -- Order by distance between banks
    LIMIT 2
) AS nearest;

-- ASSIGN NEAREST COMPETITORS TO BANKS
UPDATE data.banks AS b
SET nearest_comp1_id = (
        SELECT cb.nearest_id
        FROM data.closest_banks AS cb
        WHERE b.id = cb.bank_id
        ORDER BY cb.distance ASC
        LIMIT 1
    ),
    distance_to_nearest_comp1 = (
        SELECT cb.distance
        FROM data.closest_banks AS cb
        WHERE b.id = cb.bank_id
        ORDER BY cb.distance ASC
        LIMIT 1)
WHERE 1 = 1;

-- ASSIGN SECOND NEAREST COMPETITORS TO BANKS
UPDATE data.banks AS b
SET nearest_comp2_id = (
        SELECT cb.nearest_id
        FROM data.closest_banks AS cb
        WHERE b.id = cb.bank_id
        AND cb.nearest_id != b.nearest_comp1_id
        ORDER BY cb.distance DESC
        LIMIT 1
    ),
    distance_to_nearest_comp2 = (
        SELECT cb.distance
        FROM data.closest_banks AS cb
        WHERE b.id = cb.bank_id
        AND cb.nearest_id != b.nearest_comp1_id
        ORDER BY cb.distance DESC
        LIMIT 1
    )
WHERE 1 = 1;

-- CALCULATE AVERAGE DISTANCE TO COMPETITORS
update data.banks
set avg_distance_to_comp = (distance_to_nearest_comp1 + distance_to_nearest_comp2) / 2;

-- CREATE TABLE WITH DISTANCE TO HOME BANK
CREATE TABLE data.closest_home_bank AS
SELECT
    banks.id AS bank_id,
    nearest.id AS nearest_id,
    ST_DistanceSphere(banks.geom_p_4326, nearest.geom_p_4326) AS distance
FROM
    data.banks
CROSS JOIN LATERAL (
    SELECT
        other_banks.id,
        other_banks.geom_p_4326
    FROM
        data.banks AS other_banks
    WHERE
        other_banks.id != banks.id -- Exclude the bank of interest
    AND
        other_banks.brand =  banks.brand -- only 'home' banks
    ORDER BY
        banks.geom_p_4326 <-> other_banks.geom_p_4326 -- Order by distance between banks
    LIMIT 1
) AS nearest;

-- ASSIGN IT TO BANKS
UPDATE data.banks AS b
SET distance_to_nearest_home_bank = (
        SELECT cb.distance
        FROM data.closest_home_bank AS cb
        WHERE b.id = cb.bank_id
);

-- CREATE TABLE WITH DISTANCE TO POST OFFICE
DROP TABLE IF EXISTS data.closest_postoffice;
CREATE TABLE data.closest_postoffice AS
SELECT
    banks.id AS bank_id,
    postoffice.id AS postoffice_id,
    ST_DistanceSphere(banks.geom_p_4326, postoffice.geom_p_4326) AS distance
FROM
    data.banks
CROSS JOIN LATERAL (
    SELECT
        postoffice.id,
        postoffice.geom_p_4326
    FROM
        data.uk_glx_open_locations_postoffice AS postoffice
    ORDER BY
        banks.geom_p_4326 <-> postoffice.geom_p_4326 -- Order by distance between bank and post office
    LIMIT 1
) AS postoffice;

-- ASSIGN IT TO BANKS
UPDATE data.banks AS b
SET distance_to_postoffice = (
        SELECT po.distance
        FROM data.closest_postoffice as po
        WHERE b.id = po.bank_id
);

-- CREATE COLUMN WITHIN RP
alter table data.banks add column within_rp boolean;

-- FIND IF A BANK HAS AN RP ID
with banks_rp as (
select
    bank.id as bank_id,
    rp.id as rp_id
from data.banks bank
left join data.retail_place rp
on st_intersects(bank.geom_p_4326, rp.geom_4326)
)

-- IF IT DOES ITS WITHIN AN RP SO TRUE ELSE FALSE
update data.banks
set within_rp = case when rp_id is not null then true else false end
from
banks_rp rp
where banks.id = rp.bank_id;

-- CREATE COLUMN SUBURB BANK
alter table data.banks add column suburb_bank boolean;

-- ASSIGN A POLYGON BASED ON WHAT THE BANK IS WITHIN
with banks_suburb as (
select
    bank.id as bank_id,
    suburb.geography as town_suburb
from data.banks bank
left join data.town_suburbs suburb
on st_intersects(bank.geom_p_4326, suburb.geom_4326_5m)
)

-- IF THE BANK IS WITHIN A SUBURB POLYGON THEN TRUE ELSE FALSE
update data.banks
set suburb_bank = case when town_suburb = 'Suburb' then true else false end
from
banks_suburb suburb
where banks.id = suburb.bank_id;

-- CREATE COLUMN SME LENDING
alter table data.banks add column sme_lending numeric;

-- ASSIGN SUM OF SME LENDING BASED ON POSTAL SECTOR CENTROID IN 3KM CATCHMENT
with sme_lending as (
select
    b.id as bank_id,
    sum(sme.total_2021_smelending) as sme_lending
from data.banks b
left join data.postal_sector sme
on st_dwithin(b.geom_p_4326::geography, sme.geom_p_4326::geography, 3000)
group by b.id
)

update data.banks
set sme_lending = sme.sme_lending
from
sme_lending sme
where data.banks.id = sme.bank_id;

-- CREATE COLUMN ESTIMATED VALUE
alter table data.banks add column estimated_value numeric;

-- ASSIGN AVERAGE VOA VALUE BASED ON VOA BANK POINT IN THE 3KM CATCHMENT
with estimated_value as (
select
    b.id as bank_id,
    avg(voa.total_value) as estimated_value
from data.banks b
left join data.voa voa
on st_dwithin(b.geom_p_4326::geography, voa.geom_p_4326::geography, 3000)
group by b.id
)

update data.banks
set estimated_value = ev.estimated_value
from
estimated_value ev
where data.banks.id = ev.bank_id;

-- WHERE TOTAL 2021 SME LENDING IS NULL USE AVERAGE OF REGION
-- ADD REGION COLUMN TO POSTAL SECTOR
alter table data.postal_sector add column region text;

-- ASSIGN REGION TO POSTAL SECTOR
update data.postal_sector ps
set region = r.regionname
from data.region r
where st_intersects(ps.geom_p_4326, r.geom_4326_5m);

-- AVG SME LENDING BY REGION
with avg_sme_lending as (
select
    region,
    avg(total_2021_smelending) as avg_sme_lending
from data.postal_sector
group by region
)

-- UPDATE BANKS WHERE SME LENDING IS NULL
update data.postal_sector ps
set total_2021_smelending = avg.avg_sme_lending
from
avg_sme_lending avg
where ps.total_2021_smelending is null
and ps.region = avg.region;


-- WHERE SME LENDING IS NULL BECAUSE OF A LACK OF POSTAL SECTOR CENTROID
-- USE THE POSTAL SECTOR THE BANK IS WITHIN
with sme_lending as (
select
    b.id as bank_id,
    sum(sme.total_2021_smelending) as sme_lending
from data.banks b
left join data.postal_sector sme
on st_intersects(b.geom_p_4326, sme.geom_4326_5m)
where b.sme_lending is null
group by b.id
)

update data.banks
set sme_lending = sme.sme_lending
from
sme_lending sme
where data.banks.id = sme.bank_id;

-- WHERE ESTIMATED VALUE IS NULL USE THE CLOSEST VOA VALUE
with estimated_value as (
select
    b.id as bank_id,
    nearest.total_value as estimated_value
from data.banks b
cross join lateral (
    select
        voa.total_value
    from data.voa voa
    order by b.geom_p_4326 <-> voa.geom_p_4326
    limit 1
) as nearest
where b.estimated_value is null
)

update data.banks
set estimated_value = ev.estimated_value
from
estimated_value ev
where data.banks.id = ev.bank_id;


-- SELECT ALL COLUMNS FOR EXPORT
SELECT
    id,
    name,
    brand,
    address,
    town,
    region,
    latitude,
    longitude,
    avg_urbanity,
    avg_iuc,
    hhd_census,
    pop_census,
    ab_perc,
    c1_perc,
    c2_perc,
    de_perc,
    age0to17_perc,
    age18to24_perc,
    age25to44_perc,
    age45to59_perc,
    age60to74_perc,
    age75plus_perc,
    students_perc,
    white_perc,
    non_white_perc,
    workers_current,
    nearest_comp1_id,
    distance_to_nearest_comp1,
    nearest_comp2_id,
    distance_to_nearest_comp2,
    avg_distance_to_comp,
    distance_to_nearest_home_bank,
    distance_to_postoffice,
    sme_lending,
    estimated_value,
    closed_q1_2024
FROM data.banks;


-- CREATE H3 (UBER) HEXES FOR VISUALISATION --
create table data.eng_wales_hex_res_5 as
(
with
boundary as (
    select
        st_union(geom_4326_5m) as geom_4326
    from
        data_delivery.uk_glx_geodata_admin_region
    where
        regionname != 'Scotland'
    and
        regionname != 'Northern Ireland' -- Just England and Wales
)

select
    h3_polyfill(geom_4326, 5) as h3res5 -- Get all hex IDs at resolution 5 in the boundary
from
boundary
);

-- ADD GEOMETRY TO HEXES
alter table data.eng_wales_hex_res_5 add column geom_4326 geometry(Polygon, 4326);

update data.eng_wales_hex_res_5
set geom_4326 = st_transform(h3_to_geo_boundary_geometry(h3res5), 4326);

-- BIN INCORRECT PREDICTIONS TO HEXES
with count_incorrect as
(
    select h.h3res5, count(p.*) as count_incorrect_predictions
    from data.ew_h3res5 h
    left join data.banks_with_predictions p
    on st_intersects(p.geom_p_4326, h.geom_4326)
    where p.correct_prediction = 0
    group by h.h3res5
)

update data.ew_h3res5
set count_incorrect_predictions = count_incorrect.count_incorrect_predictions
from count_incorrect
where data.ew_h3res5.h3res5 = count_incorrect.h3res5;