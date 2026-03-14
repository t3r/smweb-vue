--
-- PostgreSQL database dump
--

\restrict 2ogUer4OVSEoOrHl2FbeZR645gELNwseGtScRDvXNGMByqz4X7bLIPKr4HnxWuL

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13 (Homebrew)

-- Started on 2026-03-10 22:01:37 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: t3r
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO t3r;

--
-- TOC entry 2 (class 3079 OID 4857014)
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- TOC entry 5371 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- TOC entry 3 (class 3079 OID 4857142)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 5372 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 4 (class 3079 OID 4858218)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 5373 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 1791 (class 1247 OID 4858230)
-- Name: fgs_navtype; Type: TYPE; Schema: public; Owner: t3r_flightgear
--

CREATE TYPE public.fgs_navtype AS ENUM (
    'NDB',
    'VOR',
    'LOC',
    'LOC-ILS',
    'GS',
    'OM',
    'MM',
    'IM',
    'DME-ILS',
    'DME'
);


ALTER TYPE public.fgs_navtype OWNER TO t3r_flightgear;

--
-- TOC entry 1794 (class 1247 OID 4858252)
-- Name: fgs_procedure_types; Type: TYPE; Schema: public; Owner: t3r_flightgear
--

CREATE TYPE public.fgs_procedure_types AS ENUM (
    'Sid',
    'Star',
    'Approach',
    'Sid_Transition',
    'Star_Transition',
    'Runway_Transition'
);


ALTER TYPE public.fgs_procedure_types OWNER TO t3r_flightgear;

--
-- TOC entry 1797 (class 1247 OID 4858266)
-- Name: fgs_waypoint_altitude_restriction; Type: TYPE; Schema: public; Owner: t3r_flightgear
--

CREATE TYPE public.fgs_waypoint_altitude_restriction AS ENUM (
    'at',
    'above',
    'below',
    'none'
);


ALTER TYPE public.fgs_waypoint_altitude_restriction OWNER TO t3r_flightgear;

--
-- TOC entry 1800 (class 1247 OID 4858276)
-- Name: fgs_waypoint_type; Type: TYPE; Schema: public; Owner: t3r_flightgear
--

CREATE TYPE public.fgs_waypoint_type AS ENUM (
    'Normal',
    'Runway',
    'Hold',
    'Vectors',
    'Intc',
    'VorRadialIntc',
    'DmeIntc',
    'ConstHdgtoAlt',
    'PBD'
);


ALTER TYPE public.fgs_waypoint_type OWNER TO t3r_flightgear;

--
-- TOC entry 404 (class 1255 OID 4858295)
-- Name: fn_alignendpylon(public.geometry, public.geometry); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_alignendpylon(p1 public.geometry, p2 public.geometry) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    RETURN degrees(ST_Azimuth(p1,p2));
END;
$$;


ALTER FUNCTION public.fn_alignendpylon(p1 public.geometry, p2 public.geometry) OWNER TO t3r_flightgear;

--
-- TOC entry 803 (class 1255 OID 4858296)
-- Name: fn_alignmiddlepylon(public.geometry, public.geometry, public.geometry); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_alignmiddlepylon(p1 public.geometry, p2 public.geometry, p3 public.geometry) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    RETURN (degrees(ST_Azimuth(p1,p2))+degrees(ST_Azimuth(p2,p3)))/2;
END;
$$;


ALTER FUNCTION public.fn_alignmiddlepylon(p1 public.geometry, p2 public.geometry, p3 public.geometry) OWNER TO t3r_flightgear;

--
-- TOC entry 443 (class 1255 OID 4858297)
-- Name: fn_boundingbox(public.geometry); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_boundingbox(public.geometry) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        min_lon integer;
        min_lat integer;
        max_lon integer;
        max_lat integer;
    BEGIN
        min_lon := floor(floor(ST_X($1)) / 10) * 10;
        min_lat := floor(floor(ST_Y($1)) / 10) * 10;
        max_lon := min_lon + 10;
        max_lat := min_lat + 10;
        return concat('ST_SetSRID(''BOX3D(', min_lon, ' ',  min_lat, ', ', max_lon, ' ', max_lat, ')''::BOX3D, 4326)');
    END
$_$;


ALTER FUNCTION public.fn_boundingbox(public.geometry) OWNER TO t3r_flightgear;

--
-- TOC entry 844 (class 1255 OID 4858298)
-- Name: fn_csmerge(character varying); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_csmerge(grasslayer character varying) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        getcslayers varchar := $$SELECT f_table_name FROM geometry_columns WHERE f_table_name LIKE 'cs_%' AND type LIKE 'POLYGON' ORDER BY f_table_name;$$;
        bboxtest varchar;
        xstest varchar;
        intest varchar;
        delobj varchar;
        diffobj varchar;
        backdiff varchar;
        newcslayers varchar := 'SELECT DISTINCT pglayer FROM newcs_full ORDER BY pglayer;';
        addnewlayer varchar;
        intersects bool;
        within bool;
        cslayer record;
        ogcfid record;
        pglayer record;
    BEGIN
        DROP TABLE IF EXISTS newcs_hole;
        CREATE TABLE newcs_hole AS SELECT ST_MakeValid(ST_Collect(wkb_geometry)) AS wkb_geometry FROM newcs_collect;
        ALTER TABLE newcs_hole ADD COLUMN ogc_fid serial NOT NULL;
        ALTER TABLE newcs_hole ADD CONSTRAINT "enforce_dims_wkb_geometry" CHECK (ST_NDims(wkb_geometry) = 2);
        ALTER TABLE newcs_hole ADD CONSTRAINT "enforce_geotype_wkb_geometry" CHECK (GeometryType(wkb_geometry) = 'MULTIPOLYGON'::text);
        ALTER TABLE newcs_hole ADD CONSTRAINT "enforce_srid_wkb_geometry" CHECK (ST_SRID(wkb_geometry) = 4326);
        ALTER TABLE newcs_hole ADD CONSTRAINT "enforce_valid_wkb_geometry" CHECK (ST_IsValid(wkb_geometry));

        FOR cslayer IN
            EXECUTE getcslayers
        LOOP  -- through layers
            bboxtest := concat('SELECT ogc_fid FROM ', quote_ident(cslayer.f_table_name), ' WHERE wkb_geometry && (SELECT wkb_geometry FROM newcs_hole) ORDER BY ogc_fid;');
            FOR ogcfid IN
                EXECUTE bboxtest
            LOOP  -- through candidate objects
                xstest := concat('SELECT ST_Intersects((SELECT wkb_geometry FROM newcs_hole), (SELECT wkb_geometry FROM ', quote_ident(cslayer.f_table_name), ' WHERE ogc_fid = ', ogcfid.ogc_fid, '));');
                EXECUTE xstest INTO intersects;
                CASE WHEN intersects IS TRUE THEN
                    intest := concat('SELECT ST_Within((SELECT wkb_geometry FROM ', quote_ident(cslayer.f_table_name), ' WHERE ogc_fid = ', ogcfid.ogc_fid, '), (SELECT wkb_geometry FROM newcs_hole));');
                    EXECUTE intest INTO within;
                    CASE WHEN within IS FALSE THEN
                        DROP TABLE IF EXISTS newcs_diff;
                        diffobj := concat('CREATE TABLE newcs_diff AS SELECT (ST_Dump(ST_MakeValid(ST_Difference((SELECT ST_MakeValid(wkb_geometry) FROM ', quote_ident(cslayer.f_table_name), ' WHERE ogc_fid = ', ogcfid.ogc_fid, '), (SELECT wkb_geometry FROM newcs_hole))))).geom AS wkb_geometry;');
                        RAISE NOTICE '%', diffobj;
                        EXECUTE diffobj;
                        ALTER TABLE newcs_diff ADD COLUMN ogc_fid serial NOT NULL;
                        ALTER TABLE newcs_diff ADD CONSTRAINT "enforce_valid_wkb_geometry" CHECK (ST_IsValid(wkb_geometry));
                        backdiff := concat('INSERT INTO ', quote_ident(cslayer.f_table_name), ' (wkb_geometry) (SELECT wkb_geometry FROM newcs_diff);');
                        EXECUTE backdiff;
                    ELSE NULL;
                    END CASE;
                    delobj := concat('DELETE FROM ', quote_ident(cslayer.f_table_name), ' WHERE ogc_fid = ', ogcfid.ogc_fid, ';');
                    EXECUTE delobj;
                ELSE NULL;
                END CASE;
            END LOOP;
        END LOOP;

        FOR pglayer IN
            EXECUTE newcslayers
        LOOP
            addnewlayer := concat('INSERT INTO ', quote_ident(pglayer.pglayer), $$ (wkb_geometry) (SELECT wkb_geometry FROM newcs_full WHERE pglayer LIKE '$$, quote_ident(pglayer.pglayer), $$');$$);
            EXECUTE addnewlayer;
        END LOOP;
    END;
$_$;


ALTER FUNCTION public.fn_csmerge(grasslayer character varying) OWNER TO t3r_flightgear;

--
-- TOC entry 711 (class 1255 OID 4858299)
-- Name: fn_dlaction(character varying, character varying); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_dlaction(character varying, character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$ 
    DECLARE
        pattern varchar;
        myuuid varchar;
        recordlayer record;
        temptable varchar;
        worklayer varchar;
        selectsql varchar;
        dropsql varchar;
        copysql varchar;
    BEGIN
        pattern := $1;
        myuuid := $2;
        selectsql := (SELECT * FROM geometry_columns WHERE f_table_name LIKE pattern);
        FOR recordlayer IN
            EXECUTE selectsql
        LOOP
            worklayer := recordlayer.f_table_name;
            temptable := concat(myuuid, '_', worklayer);
            dropsql := concat('DROP TABLE IF EXISTS "', temptable, '";');
            EXECUTE dropsql;
            copysql := concat('CREATE TABLE "', temptable, '" AS SELECT * FROM ', worklayer, $$ WHERE wkb_geometry && (SELECT wkb_geometry FROM download WHERE uuid LIKE '$$, myuuid, $$');$$);
            EXECUTE copysql;
        END LOOP;
    END;
$_$;


ALTER FUNCTION public.fn_dlaction(character varying, character varying) OWNER TO t3r_flightgear;

--
-- TOC entry 316 (class 1255 OID 4858300)
-- Name: fn_dltable(uuid); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_dltable(uuid) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        tab record;
        item varchar;
        selectsql varchar;
        countsql varchar;
    BEGIN
        item := feature FROM download WHERE uuid = $1;
        selectsql := concat('SELECT * FROM geometry_columns WHERE f_table_name LIKE $$', item, '_%$$;');
        FOR tab IN
            EXECUTE selectsql
        LOOP
            countsql := concat('SELECT CASE WHEN COUNT(wkb_geometry)::integer > 0 THEN $$', quote_ident(tab.f_table_name), '$$ ELSE NULL END FROM ', quote_ident(tab.f_table_name), ' WHERE wkb_geometry && (SELECT wkb_geometry FROM download WHERE uuid = $$', $1, '$$);');
            RETURN QUERY EXECUTE countsql;
        END LOOP;
    RETURN;
    END;
$_$;


ALTER FUNCTION public.fn_dltable(uuid) OWNER TO t3r_flightgear;

--
-- TOC entry 422 (class 1255 OID 4858301)
-- Name: fn_dumpstgrows(integer); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_dumpstgrows(integer) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        tileno integer = $1;
    BEGIN
        RETURN QUERY
        WITH modelitems AS (SELECT mo_id AS id,
            (CASE WHEN mo_shared > 0 THEN 1 ELSE 0 END) AS shared,
            mg_path AS path,
            mo_path AS name,
            trim(trailing '.' FROM to_char(ST_X(wkb_geometry), 'FM990D999999999')) AS lon,
            trim(trailing '.' FROM to_char(ST_Y(wkb_geometry), 'FM990D999999999')) AS lat,
            trim(trailing '.' FROM to_char(fn_StgElevation(ob_gndelev, ob_elevoffset)::float, 'FM99990D999999999')) AS stgelev,
            trim(trailing '.' FROM to_char(fn_StgHeading(ob_heading)::float, 'FM990D999999999')) AS stgheading
        FROM fgs_objects, fgs_models, fgs_modelgroups
        WHERE ob_tile = tileno
            AND ob_valid IS TRUE AND ob_tile IS NOT NULL
            AND ob_model = mo_id AND ob_gndelev > -9999
            AND mo_shared = mg_id),

        signitems AS (SELECT si_definition AS name,
            trim(trailing '.' FROM to_char(ST_X(wkb_geometry), 'FM990D999999999')) AS lon,
            trim(trailing '.' FROM to_char(ST_Y(wkb_geometry), 'FM990D999999999')) AS lat,
            trim(trailing '.' FROM to_char(si_gndelev::float, 'FM99990D999999999')) AS stgelev,
            trim(trailing '.' FROM to_char(fn_StgHeading(si_heading)::float, 'FM990D999999999')) AS stgheading
        FROM fgs_signs
        WHERE si_tile = tileno
            AND si_valid IS TRUE AND si_tile IS NOT NULL
            AND si_gndelev > -9999),

        modelrow AS (SELECT concat((CASE WHEN shared > 0 THEN concat('OBJECT_SHARED Models/', path) ELSE 'OBJECT_STATIC '  END),
            name, ' ', lon, ' ', lat, ' ', stgelev, ' ', stgheading)::text AS object
        FROM modelitems
        ORDER BY shared DESC, id, lon::float, lat::float,
            stgelev::float, stgheading::float),

        signrow AS (SELECT concat('OBJECT_SIGN ',
            name, ' ', lon, ' ', lat, ' ', stgelev, ' ', stgheading)::text AS object
        FROM signitems
        ORDER BY lon::float, lat::float,
            stgelev::float, stgheading::float),

        mo AS (SELECT string_agg(object, E'\n') AS mo FROM modelrow),
        si AS (SELECT string_agg(object, E'\n') AS si FROM signrow)

        SELECT (CASE
            WHEN COUNT(mo) = 1 AND COUNT(si) = 1 THEN concat(mo, E'\n', si)
            WHEN COUNT(mo) = 1 AND COUNT(si) = 0 THEN mo
            WHEN COUNT(mo) = 0 AND COUNT(si) = 1 THEN si
        END) AS ret
        FROM mo, si
        WHERE (SELECT COUNT(mo) FROM mo) > 0
            OR (SELECT COUNT(si) FROM si) > 0
        GROUP BY mo, si;

    END;
$_$;


ALTER FUNCTION public.fn_dumpstgrows(integer) OWNER TO t3r_flightgear;

--
-- TOC entry 495 (class 1255 OID 4858302)
-- Name: fn_freqrange(numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_freqrange(numeric, numeric, numeric) RETURNS SETOF json
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        lon numeric := $1;
        lat numeric := $2;
        range numeric := $3;
    BEGIN
        RETURN QUERY
        WITH res AS (SELECT icao,
            CAST(
                ST_Distance_Spheroid(
                    ST_PointFromText(concat('POINT(6.5 51.5)'), 4326),
                    wkb_geometry,
                    'SPHEROID["WGS84",6378137.000,298.257223563]')
                AS numeric) AS dist
        FROM apt_airfield)

        SELECT array_to_json(array_agg(row_to_json(t))) AS freq
        FROM (
            SELECT f.icao,
                f.freq_name,
                f.freq_mhz,
                round(res.dist / 1852.01, 1)
                AS dist
            FROM apt_freq AS f,
                res
            WHERE res.dist < range * 1852.01
            AND f.icao = res.icao
            ORDER BY res.dist, f.icao, f.freq_name)
        AS t;
    END;
$_$;


ALTER FUNCTION public.fn_freqrange(numeric, numeric, numeric) OWNER TO t3r_flightgear;

--
-- TOC entry 432 (class 1255 OID 4858303)
-- Name: fn_getcountrycodetwo(public.geometry); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_getcountrycodetwo(lg public.geometry) RETURNS character
    LANGUAGE sql
    AS $$
    SELECT co_code FROM gadm2, fgs_countries WHERE ST_Within(lg, gadm2.wkb_geometry) AND gadm2.iso ILIKE fgs_countries.co_three;
$$;


ALTER FUNCTION public.fn_getcountrycodetwo(lg public.geometry) OWNER TO t3r_flightgear;

--
-- TOC entry 766 (class 1255 OID 4858304)
-- Name: fn_getdistanceinmeters(public.geometry, public.geometry); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_getdistanceinmeters(lg1 public.geometry, lg2 public.geometry) RETURNS double precision
    LANGUAGE sql
    AS $$
    SELECT ST_Distance(lg1::geography,lg2::geography);
$$;


ALTER FUNCTION public.fn_getdistanceinmeters(lg1 public.geometry, lg2 public.geometry) OWNER TO t3r_flightgear;

--
-- TOC entry 297 (class 1255 OID 4858305)
-- Name: fn_getmodelpath(integer); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_getmodelpath(model integer) RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
    r RECORD;
BEGIN
    SELECT INTO r mg_path,mo_path FROM fgs_models  LEFT OUTER JOIN fgs_modelgroups  ON mo_shared=mg_id WHERE mo_id=model;
    IF NOT FOUND THEN
       RETURN '';
    ELSE
       RETURN 'Models/'||r.mg_path||r.mo_path;
    END IF;
END;
$$;


ALTER FUNCTION public.fn_getmodelpath(model integer) OWNER TO t3r_flightgear;

--
-- TOC entry 811 (class 1255 OID 4858306)
-- Name: fn_getnearestobject(integer, numeric, numeric); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_getnearestobject(model_id integer, lon numeric, lat numeric) RETURNS bigint
    LANGUAGE sql
    AS $$
      SELECT 
        COUNT(*) 
        FROM fgs_objects 
        WHERE ob_model=model_id AND ST_DWithin(wkb_geometry,ST_PointFromText('POINT('||lon::text||' '||lat::text||')', 4326),0.000135,false);

$$;


ALTER FUNCTION public.fn_getnearestobject(model_id integer, lon numeric, lat numeric) OWNER TO t3r_flightgear;

--
-- TOC entry 1045 (class 1255 OID 4858307)
-- Name: fn_gettilenumber(public.geometry); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_gettilenumber(lg public.geometry) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    epsilon CONSTANT float := 0.0000001;
    dlon float;
    dlat float;
    lon integer;
    lat integer;
    difflon float;
    difflat float;
    bx integer;
    a integer;
    b integer;
    l float;
    r integer;
    w float;
    x integer;
    y integer;
BEGIN
    dlon := ST_X(lg);
    dlat := ST_Y(lg);

    IF abs(difflon) < epsilon THEN
       lon := trunc(dlon);
    ELSIF dlon >= 0 THEN
       lon := trunc(dlon);
    ELSE
       lon := floor(dlon);
    END IF;
       difflon := (dlon-lon);

    IF abs(difflat) < epsilon THEN
       lat := trunc(dlat);
    ELSIF dlat >= 0 THEN
       lat := trunc(dlat);
    ELSE
       lat := floor(dlat);
    END IF;
       difflat := (dlat-lat);

    IF    dlat >= 89.0 THEN
       w := 12.0;
    ELSIF dlat >= 86.0 THEN 
       w := 4.0;
    ELSIF dlat >= 83.0 THEN 
       w := 2.0;
    ELSIF dlat >= 76.0 THEN 
       w := 1.0;
    ELSIF dlat >= 62.0 THEN 
       w := 0.5;
    ELSIF dlat >= 22.0 THEN 
       w := 0.25;
    ELSIF dlat >= -22.0 THEN
       w := 0.125;
    ELSIF dlat >= -62.0 THEN 
       w := 0.25;
    ELSIF dlat >= -76.0 THEN 
       w := 0.5;
    ELSIF dlat >= -83.0 THEN 
       w := 1.0;
    ELSIF dlat >= -86.0 THEN 
       w := 2.0;
    ELSIF dlat >= -89.0 THEN 
       w := 4.0;
    ELSE
       w := 12.0;
    END IF;
	
    IF w <= 1.0 THEN 
       x := trunc(difflon/w);
    ELSE
       lon := floor(floor((lon + epsilon)/w)*w);
       IF lon < -180 THEN
          lon := -180;
       END IF;
       x := 0;
    END IF;
	
    y := trunc(difflat*8);
    y := y<<3;

    a := (lon+180)<<14;
    b := (lat+90)<<6;
    r := a+b+y+x;

    RETURN r;
END;
$$;


ALTER FUNCTION public.fn_gettilenumber(lg public.geometry) OWNER TO t3r_flightgear;

--
-- TOC entry 1132 (class 1255 OID 4858308)
-- Name: fn_gettilenumberxy(double precision, double precision); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_gettilenumberxy(lon double precision, lat double precision) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    x text;
    n integer;
BEGIN
    x := 'SRID=4326;POINT('||lon::text||' '||lat::text||')';
    n := fn_GetTileNumber(ST_GeomFromEWKT(x));
    RETURN n;
END;
$$;


ALTER FUNCTION public.fn_gettilenumberxy(lon double precision, lat double precision) OWNER TO t3r_flightgear;

--
-- TOC entry 1010 (class 1255 OID 4858309)
-- Name: fn_importrecordposttrigger(); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_importrecordposttrigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (TG_OP = 'UPDATE') OR (TG_OP = 'INSERT') THEN
       NEW.ob_country:=fn_GetCountryCodeTwo(NEW.wkb_geometry);
       NEW.ob_tile:=fn_GetTileNumber(NEW.wkb_geometry);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_importrecordposttrigger() OWNER TO t3r_flightgear;

--
-- TOC entry 365 (class 1255 OID 4858310)
-- Name: fn_scenedir(public.geometry); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_scenedir(public.geometry) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        min_lon integer;
        min_lat integer;
        lon_char char(1);
        lat_char char(1);
    BEGIN
        min_lon := Abs(floor(floor(ST_X($1)) / 10) * 10);
        min_lat := Abs(floor(floor(ST_Y($1)) / 10) * 10);
        lon_char := (CASE WHEN (ST_X($1)) < 0 THEN 'w' ELSE 'e' END);
        lat_char := (CASE WHEN (ST_Y($1)) < 0 THEN 's' ELSE 'n' END);
        return concat(lon_char, lpad(CAST(min_lon AS varchar), 3, '0'), lat_char, lpad(CAST(min_lat AS varchar), 2, '0'));
    END
$_$;


ALTER FUNCTION public.fn_scenedir(public.geometry) OWNER TO t3r_flightgear;

--
-- TOC entry 1047 (class 1255 OID 4858311)
-- Name: fn_scenesubdir(public.geometry); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_scenesubdir(public.geometry) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        min_lon integer;
        min_lat integer;
        lon_char char(1);
        lat_char char(1);
    BEGIN
        min_lon := Abs(floor(ST_X($1)));
        min_lat := Abs(floor(ST_Y($1)));
        lon_char := (CASE WHEN (ST_X($1)) < 0 THEN 'w' ELSE 'e' END);
        lat_char := (CASE WHEN (ST_Y($1)) < 0 THEN 's' ELSE 'n' END);
        return concat(lon_char, lpad(CAST(min_lon AS varchar), 3, '0'), lat_char, lpad(CAST(min_lat AS varchar), 2, '0'));
    END
$_$;


ALTER FUNCTION public.fn_scenesubdir(public.geometry) OWNER TO t3r_flightgear;

--
-- TOC entry 969 (class 1255 OID 4858312)
-- Name: fn_setcsmodtime(); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_setcsmodtime() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  NEW.ch_date = now();
  RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_setcsmodtime() OWNER TO t3r_flightgear;

--
-- TOC entry 425 (class 1255 OID 4858313)
-- Name: fn_setdate(); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_setdate() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  NEW.date = now();
  RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_setdate() OWNER TO t3r_flightgear;

--
-- TOC entry 855 (class 1255 OID 4858314)
-- Name: fn_setmodelmodtime(); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_setmodelmodtime() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  NEW.mo_modified = now();
  RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_setmodelmodtime() OWNER TO t3r_flightgear;

--
-- TOC entry 1127 (class 1255 OID 4858315)
-- Name: fn_setnewsmodtime(); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_setnewsmodtime() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  NEW.ne_timestamp = now();
  RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_setnewsmodtime() OWNER TO t3r_flightgear;

--
-- TOC entry 669 (class 1255 OID 4858316)
-- Name: fn_setobjectmodtime(); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_setobjectmodtime() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  NEW.ob_modified = now();
  RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_setobjectmodtime() OWNER TO t3r_flightgear;

--
-- TOC entry 652 (class 1255 OID 4858317)
-- Name: fn_setsignmodtime(); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_setsignmodtime() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  NEW.si_modified = now();
  RETURN NEW;
END
$$;


ALTER FUNCTION public.fn_setsignmodtime() OWNER TO t3r_flightgear;

--
-- TOC entry 825 (class 1255 OID 4858318)
-- Name: fn_stgelevation(numeric, numeric); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_stgelevation(numeric, numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        stgelevation numeric(7,2);
    BEGIN
        stgelevation := CASE WHEN $2 IS NOT NULL THEN ($1 + $2) ELSE $1 END;
        return stgelevation;
    END
$_$;


ALTER FUNCTION public.fn_stgelevation(numeric, numeric) OWNER TO t3r_flightgear;

--
-- TOC entry 602 (class 1255 OID 4858319)
-- Name: fn_stgheading(numeric); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_stgheading(numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        stgheading numeric(5,2);
    BEGIN
        stgheading := CASE WHEN $1 > 180 THEN (540 - $1) ELSE (180 - $1) END;
        return stgheading;
    END
$_$;


ALTER FUNCTION public.fn_stgheading(numeric) OWNER TO t3r_flightgear;

--
-- TOC entry 620 (class 1255 OID 4858320)
-- Name: fn_unrollmulti(character varying); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.fn_unrollmulti(layer character varying) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        getpkey varchar := $$SELECT a.attname AS pkey FROM pg_index AS i JOIN pg_attribute AS a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey) WHERE i.indrelid = 'osm_naturalwater'::regclass AND i.indisprimary;$$;
        testmulti varchar;
        unrollmulti varchar;
        delmulti varchar;
        pkey varchar;
        multifid record;
    BEGIN
        EXECUTE getpkey INTO pkey;
        testmulti := concat('SELECT ', pkey, ' AS pkey FROM osm_naturalwater WHERE ST_NumGeometries(wkb_geometry) IS NOT NULL ORDER BY ', pkey, ';');
        RAISE NOTICE '%', testmulti;
        FOR multifid IN
            EXECUTE testmulti
        LOOP
            unrollmulti := concat('INSERT INTO osm_naturalwater (wkb_geometry) (SELECT (ST_Dump(wkb_geometry)).geom FROM osm_naturalwater WHERE ', pkey, ' = ', multifid.pkey, ');');
            RAISE NOTICE '%', unrollmulti;
            delmulti := concat('DELETE FROM osm_naturalwater WHERE ', pkey, ' = ', multifid.pkey, ';');
            RAISE NOTICE '%', delmulti;
            EXECUTE unrollmulti;
            EXECUTE delmulti;
        END LOOP;
    END;
$_$;


ALTER FUNCTION public.fn_unrollmulti(layer character varying) OWNER TO t3r_flightgear;

--
-- TOC entry 436 (class 1255 OID 4858321)
-- Name: icaorange(); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.icaorange() RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$

DECLARE
    searchsql text := '';
    distsql text := '';
    myvar text := '';

BEGIN
    searchsql := 'SELECT icao FROM apt_airfield WHERE
        ST_DWithin(
            (SELECT ST_Transform(wkb_geometry, 900913) FROM apt_airfield WHERE icao LIKE ''LSZH''),
            ST_Transform(wkb_geometry, 900913),
            50*1000*1.85201
        )';

    distsql := 'SELECT (ST_Distance_Spheroid(
            (SELECT wkb_geometry FROM apt_airfield WHERE icao LIKE ''LSZH''),
            (SELECT wkb_geometry FROM apt_airfield WHERE icao LIKE myvar),
            ''SPHEROID["WGS84",6378137.000,298.257223563]''
        )/1000)::decimal(9,3) AS Km';

    FOR myvar IN EXECUTE(searchsql) LOOP
        
    RETURN NEXT myvar;
    END LOOP;

END;
$$;


ALTER FUNCTION public.icaorange() OWNER TO t3r_flightgear;

--
-- TOC entry 1098 (class 1255 OID 4858322)
-- Name: icaorange(text); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.icaorange(text) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
    DECLARE
        searchsql text := '';
        distsql text := '';
        myvar text := '';
    BEGIN
        searchsql := 'SELECT icao FROM apt_airfield WHERE
            ST_DWithin(
                (SELECT ST_Transform(wkb_geometry, 3857) FROM apt_airfield WHERE icao LIKE ''LSZH''),
                ST_Transform(wkb_geometry, 3857),
                50*1000*1.85201
            )';
        distsql := 'SELECT (ST_Distance_Spheroid(
                (SELECT wkb_geometry FROM apt_airfield WHERE icao LIKE ''LSZH''),
                (SELECT wkb_geometry FROM apt_airfield WHERE icao LIKE myvar),
                ''SPHEROID["WGS84",6378137.000,298.257223563]''
            )/1000)::decimal(9,3) AS Km';

        FOR myvar IN EXECUTE(searchsql()) LOOP
        RETURN NEXT myvar;
        END LOOP;
    END;
$$;


ALTER FUNCTION public.icaorange(text) OWNER TO t3r_flightgear;

--
-- TOC entry 897 (class 1255 OID 4858323)
-- Name: icaorange(character varying); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.icaorange(character varying) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        searchsql text := '';
        distsql text := '';
        myvar text := '';
    BEGIN
        searchsql := 'SELECT icao FROM apt_airfield WHERE
            ST_DWithin(
                (SELECT ST_Transform(wkb_geometry, 900913) FROM apt_airfield WHERE icao LIKE $1),
                ST_Transform(wkb_geometry, 900913),
                50*1000*1.85201
            )';
        distsql := 'SELECT (ST_Distance_Spheroid(
                (SELECT wkb_geometry FROM apt_airfield WHERE icao LIKE ''LSZH''),
                (SELECT wkb_geometry FROM apt_airfield WHERE icao LIKE myvar),
                ''SPHEROID["WGS84",6378137.000,298.257223563]''
            )/1000)::decimal(9,3) AS Km';

        FOR myvar IN EXECUTE(searchsql($1)) LOOP
        RETURN NEXT myvar;
        END LOOP;
    END;
$_$;


ALTER FUNCTION public.icaorange(character varying) OWNER TO t3r_flightgear;

--
-- TOC entry 393 (class 1255 OID 4858324)
-- Name: next_mo_id(integer); Type: FUNCTION; Schema: public; Owner: t3r_flightgear
--

CREATE FUNCTION public.next_mo_id(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
    new_id integer;
  BEGIN
    SELECT nextval(fgs_models_mo_id_seq);
  END;
$$;


ALTER FUNCTION public.next_mo_id(integer) OWNER TO t3r_flightgear;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 223 (class 1259 OID 4858325)
-- Name: apt_runway; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.apt_runway (
    wkb_geometry public.geometry(Polygon,4326) NOT NULL,
    icao character varying,
    atype integer,
    rwy_num1 character varying(3),
    rwy_num2 character varying(3),
    length_m double precision,
    width_m double precision,
    true_heading_deg numeric(6,2),
    surface character varying(11),
    smoothness numeric(4,2),
    shoulder character varying(8),
    centerline_lights numeric(1,0),
    edge_lighting character(6),
    distance_remaining_signs numeric(1,0),
    ogc_fid integer NOT NULL,
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(wkb_geometry) = 2)),
    CONSTRAINT enforce_geotype_wkb_geometry CHECK ((public.geometrytype(wkb_geometry) = 'POLYGON'::text)),
    CONSTRAINT enforce_srid_wkb_geometry CHECK ((public.st_srid(wkb_geometry) = 4326))
);


ALTER TABLE public.apt_runway OWNER TO t3r_flightgear;

--
-- TOC entry 224 (class 1259 OID 4858333)
-- Name: apt_runway_ogc_fid_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.apt_runway_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.apt_runway_ogc_fid_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6251 (class 0 OID 0)
-- Dependencies: 224
-- Name: apt_runway_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.apt_runway_ogc_fid_seq OWNED BY public.apt_runway.ogc_fid;


--
-- TOC entry 225 (class 1259 OID 4858334)
-- Name: country_codes; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.country_codes (
    vmap character(2),
    fibs character(2),
    iso3166 character(2),
    name character varying NOT NULL,
    comment character varying,
    src_id numeric(5,0),
    maint_id numeric(5,0)
);


ALTER TABLE public.country_codes OWNER TO t3r_flightgear;

--
-- TOC entry 226 (class 1259 OID 4858339)
-- Name: fgs_aircraft; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_aircraft (
    ac_id integer NOT NULL,
    ac_model character(80),
    ac_livery character(20),
    ac_airline character(4),
    ac_type character(20),
    ac_offset integer,
    ac_radius integer,
    ac_performance character(20),
    ac_heavy boolean,
    ac_reqcode character(15)
);


ALTER TABLE public.fgs_aircraft OWNER TO t3r_flightgear;

--
-- TOC entry 227 (class 1259 OID 4858342)
-- Name: fgs_aircraft_ac_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_aircraft_ac_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_aircraft_ac_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6255 (class 0 OID 0)
-- Dependencies: 227
-- Name: fgs_aircraft_ac_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_aircraft_ac_id_seq OWNED BY public.fgs_aircraft.ac_id;


--
-- TOC entry 228 (class 1259 OID 4858343)
-- Name: fgs_airline; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_airline (
    al_id integer NOT NULL,
    al_icao character(4),
    al_name character(60),
    al_callsign character varying(15)
);


ALTER TABLE public.fgs_airline OWNER TO t3r_flightgear;

--
-- TOC entry 229 (class 1259 OID 4858346)
-- Name: fgs_airline_al_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_airline_al_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_airline_al_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6258 (class 0 OID 0)
-- Dependencies: 229
-- Name: fgs_airline_al_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_airline_al_id_seq OWNED BY public.fgs_airline.al_id;


--
-- TOC entry 230 (class 1259 OID 4858347)
-- Name: fgs_airport; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_airport (
    ap_id integer NOT NULL,
    ap_icao character(4) NOT NULL,
    ap_name character(40) NOT NULL
);


ALTER TABLE public.fgs_airport OWNER TO t3r_flightgear;

--
-- TOC entry 231 (class 1259 OID 4858350)
-- Name: fgs_airport_ap_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_airport_ap_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_airport_ap_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6261 (class 0 OID 0)
-- Dependencies: 231
-- Name: fgs_airport_ap_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_airport_ap_id_seq OWNED BY public.fgs_airport.ap_id;


--
-- TOC entry 232 (class 1259 OID 4858351)
-- Name: fgs_authors; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_authors (
    au_id integer NOT NULL,
    au_name character varying(40),
    au_email character varying(40),
    au_notes character varying,
    au_modeldir character(3)
);


ALTER TABLE public.fgs_authors OWNER TO t3r_flightgear;

--
-- TOC entry 233 (class 1259 OID 4858356)
-- Name: fgs_authors_au_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_authors_au_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_authors_au_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6264 (class 0 OID 0)
-- Dependencies: 233
-- Name: fgs_authors_au_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_authors_au_id_seq OWNED BY public.fgs_authors.au_id;


--
-- TOC entry 234 (class 1259 OID 4858357)
-- Name: fgs_clean; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_clean (
    ob_id integer NOT NULL,
    ob_modified timestamp without time zone,
    ob_deleted timestamp without time zone DEFAULT '1970-01-01 00:00:01'::timestamp without time zone NOT NULL,
    ob_text character varying(100),
    wkb_geometry public.geometry(Point,4326) NOT NULL,
    ob_gndelev numeric(7,2) DEFAULT '-9999'::integer,
    ob_elevoffset numeric(5,2) DEFAULT NULL::numeric,
    ob_peakelev numeric(7,2),
    ob_heading numeric(5,2) DEFAULT 0,
    ob_country character(2) DEFAULT NULL::bpchar,
    ob_model integer,
    ob_group integer,
    ob_tile integer,
    ob_reference character varying(20) DEFAULT NULL::character varying,
    ob_submitter character varying(16) DEFAULT 'unknown'::character varying,
    ob_valid boolean DEFAULT true,
    ob_class character varying(10),
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(wkb_geometry) = 2)),
    CONSTRAINT enforce_geotype_wkb_geometry CHECK ((public.geometrytype(wkb_geometry) = 'POINT'::text)),
    CONSTRAINT enforce_srid_wkb_geometry CHECK ((public.st_srid(wkb_geometry) = 4326))
);


ALTER TABLE public.fgs_clean OWNER TO t3r_flightgear;

--
-- TOC entry 235 (class 1259 OID 4858373)
-- Name: fgs_clean_ob_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_clean_ob_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_clean_ob_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6267 (class 0 OID 0)
-- Dependencies: 235
-- Name: fgs_clean_ob_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_clean_ob_id_seq OWNED BY public.fgs_clean.ob_id;


--
-- TOC entry 236 (class 1259 OID 4858374)
-- Name: fgs_countries; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_countries (
    co_code character(2) NOT NULL,
    co_name character(50),
    co_three character(3)
);


ALTER TABLE public.fgs_countries OWNER TO t3r_flightgear;

--
-- TOC entry 237 (class 1259 OID 4858377)
-- Name: fgs_extuserids; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_extuserids (
    eu_authority integer,
    eu_external_id text,
    eu_author_id integer,
    eu_lastlogin timestamp without time zone
);


ALTER TABLE public.fgs_extuserids OWNER TO t3r_flightgear;

--
-- TOC entry 6270 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE fgs_extuserids; Type: COMMENT; Schema: public; Owner: t3r_flightgear
--

COMMENT ON TABLE public.fgs_extuserids IS 'External user-ids for oauth logins';


--
-- TOC entry 6271 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN fgs_extuserids.eu_authority; Type: COMMENT; Schema: public; Owner: t3r_flightgear
--

COMMENT ON COLUMN public.fgs_extuserids.eu_authority IS '1: github, 2: google, 3: facebook, 4:twitter';


--
-- TOC entry 238 (class 1259 OID 4858382)
-- Name: fgs_fixes; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_fixes (
    fx_name character varying(32) NOT NULL,
    wkb_geometry public.geometry(Point,4326) NOT NULL,
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(wkb_geometry) = 2)),
    CONSTRAINT enforce_geotype_wkb_geometry CHECK ((public.geometrytype(wkb_geometry) = 'POINT'::text)),
    CONSTRAINT enforce_srid_wkb_geometry CHECK ((public.st_srid(wkb_geometry) = 4326)),
    CONSTRAINT enforce_valid_wkb_geometry CHECK (public.st_isvalid(wkb_geometry))
);


ALTER TABLE public.fgs_fixes OWNER TO t3r_flightgear;

--
-- TOC entry 239 (class 1259 OID 4858391)
-- Name: fgs_fleet; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_fleet (
    fl_id integer NOT NULL,
    fl_airline character(4),
    fl_livery character(20),
    fl_reqcode character(20),
    fl_homeapt character(4),
    fl_actype character(15),
    fl_reg character(8),
    fl_flighttype character(6) DEFAULT 'gate'::bpchar
);


ALTER TABLE public.fgs_fleet OWNER TO t3r_flightgear;

--
-- TOC entry 240 (class 1259 OID 4858395)
-- Name: fgs_fleet_fl_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_fleet_fl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_fleet_fl_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6275 (class 0 OID 0)
-- Dependencies: 240
-- Name: fgs_fleet_fl_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_fleet_fl_id_seq OWNED BY public.fgs_fleet.fl_id;


--
-- TOC entry 241 (class 1259 OID 4858396)
-- Name: fgs_flight; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_flight (
    ft_id integer NOT NULL,
    ft_callsign character(30),
    ft_airline character(4),
    ft_reqcode character(20),
    ft_ifr boolean,
    ft_origapt character(4),
    ft_origday integer,
    ft_origtime time without time zone,
    ft_cruiselevel integer,
    ft_destapt character(4),
    ft_destday integer,
    ft_desttime time without time zone,
    ft_repeat character(5)
);


ALTER TABLE public.fgs_flight OWNER TO t3r_flightgear;

--
-- TOC entry 242 (class 1259 OID 4858399)
-- Name: fgs_flight_ft_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_flight_ft_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_flight_ft_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6278 (class 0 OID 0)
-- Dependencies: 242
-- Name: fgs_flight_ft_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_flight_ft_id_seq OWNED BY public.fgs_flight.ft_id;


--
-- TOC entry 243 (class 1259 OID 4858400)
-- Name: fgs_groups; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_groups (
    gp_id integer NOT NULL,
    gp_name character varying(16) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.fgs_groups OWNER TO t3r_flightgear;

--
-- TOC entry 244 (class 1259 OID 4858404)
-- Name: fgs_groups_gp_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_groups_gp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_groups_gp_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6281 (class 0 OID 0)
-- Dependencies: 244
-- Name: fgs_groups_gp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_groups_gp_id_seq OWNED BY public.fgs_groups.gp_id;


--
-- TOC entry 245 (class 1259 OID 4858405)
-- Name: fgs_modelclass; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_modelclass (
    mc_id integer NOT NULL,
    mc_model integer NOT NULL,
    mc_class character(10),
    mc_minheight numeric(7,2),
    mc_maxheight numeric(7,2)
);


ALTER TABLE public.fgs_modelclass OWNER TO t3r_flightgear;

--
-- TOC entry 246 (class 1259 OID 4858408)
-- Name: fgs_modelclass_mc_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_modelclass_mc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_modelclass_mc_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6284 (class 0 OID 0)
-- Dependencies: 246
-- Name: fgs_modelclass_mc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_modelclass_mc_id_seq OWNED BY public.fgs_modelclass.mc_id;


--
-- TOC entry 247 (class 1259 OID 4858409)
-- Name: fgs_modelgroups; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_modelgroups (
    mg_id integer NOT NULL,
    mg_name character varying(40),
    mg_path character varying(30)
);


ALTER TABLE public.fgs_modelgroups OWNER TO t3r_flightgear;

--
-- TOC entry 248 (class 1259 OID 4858412)
-- Name: fgs_modelgroups_mg_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_modelgroups_mg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_modelgroups_mg_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6287 (class 0 OID 0)
-- Dependencies: 248
-- Name: fgs_modelgroups_mg_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_modelgroups_mg_id_seq OWNED BY public.fgs_modelgroups.mg_id;


--
-- TOC entry 249 (class 1259 OID 4858413)
-- Name: fgs_models_mo_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_models_mo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_models_mo_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 250 (class 1259 OID 4858414)
-- Name: fgs_models; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_models (
    mo_id integer DEFAULT nextval('public.fgs_models_mo_id_seq'::regclass) NOT NULL,
    mo_path character varying(100) NOT NULL,
    mo_modified timestamp without time zone,
    mo_author integer,
    mo_name character varying(100),
    mo_notes character varying,
    mo_thumbfile character varying,
    mo_modelfile character varying NOT NULL,
    mo_shared integer,
    mo_modified_by integer
);


ALTER TABLE public.fgs_models OWNER TO t3r_flightgear;

--
-- TOC entry 251 (class 1259 OID 4858420)
-- Name: fgs_navaids; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_navaids (
    na_id integer NOT NULL,
    na_type public.fgs_navtype,
    na_position public.geometry(Point,4326),
    na_elevation numeric,
    na_frequency integer,
    na_range numeric,
    na_multiuse numeric,
    na_ident text,
    na_name text,
    na_airport_id text,
    na_runway text,
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(na_position) = 2)),
    CONSTRAINT enforce_geotype_wkb_geometry CHECK ((public.geometrytype(na_position) = 'POINT'::text)),
    CONSTRAINT enforce_srid_wkb_geometry CHECK ((public.st_srid(na_position) = 4326)),
    CONSTRAINT enforce_valid_wkb_geometry CHECK (public.st_isvalid(na_position))
);


ALTER TABLE public.fgs_navaids OWNER TO t3r_flightgear;

--
-- TOC entry 6291 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE fgs_navaids; Type: COMMENT; Schema: public; Owner: t3r_flightgear
--

COMMENT ON TABLE public.fgs_navaids IS 'Navaids, origially created from nav.dat';


--
-- TOC entry 252 (class 1259 OID 4858429)
-- Name: fgs_navaids_na_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_navaids_na_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_navaids_na_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6293 (class 0 OID 0)
-- Dependencies: 252
-- Name: fgs_navaids_na_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_navaids_na_id_seq OWNED BY public.fgs_navaids.na_id;


--
-- TOC entry 253 (class 1259 OID 4858430)
-- Name: fgs_news; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_news (
    ne_id integer NOT NULL,
    ne_timestamp timestamp without time zone NOT NULL,
    ne_author integer DEFAULT 0 NOT NULL,
    ne_text text NOT NULL
);


ALTER TABLE public.fgs_news OWNER TO t3r_flightgear;

--
-- TOC entry 254 (class 1259 OID 4858436)
-- Name: fgs_news_ne_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_news_ne_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_news_ne_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6296 (class 0 OID 0)
-- Dependencies: 254
-- Name: fgs_news_ne_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_news_ne_id_seq OWNED BY public.fgs_news.ne_id;


--
-- TOC entry 255 (class 1259 OID 4858437)
-- Name: fgs_objects; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_objects (
    ob_id integer NOT NULL,
    ob_modified timestamp without time zone,
    ob_deleted timestamp without time zone DEFAULT '1970-01-01 00:00:01'::timestamp without time zone NOT NULL,
    ob_text character varying(100),
    wkb_geometry public.geometry(Point,4326) NOT NULL,
    ob_gndelev numeric(7,2) DEFAULT '-9999'::integer,
    ob_elevoffset numeric(5,2) DEFAULT NULL::numeric,
    ob_peakelev numeric(7,2),
    ob_heading numeric(5,2) DEFAULT 0,
    ob_country character(2) DEFAULT NULL::bpchar,
    ob_model integer,
    ob_group integer,
    ob_tile integer,
    ob_reference character varying(20) DEFAULT NULL::character varying,
    ob_submitter character varying(16) DEFAULT 'unknown'::character varying,
    ob_valid boolean DEFAULT true,
    ob_class character varying(10),
    ob_modified_by integer,
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(wkb_geometry) = 2)),
    CONSTRAINT enforce_geotype_wkb_geometry CHECK ((public.geometrytype(wkb_geometry) = 'POINT'::text)),
    CONSTRAINT enforce_srid_wkb_geometry CHECK ((public.st_srid(wkb_geometry) = 4326)),
    CONSTRAINT enforce_valid_wkb_geometry CHECK (public.st_isvalid(wkb_geometry))
);


ALTER TABLE public.fgs_objects OWNER TO t3r_flightgear;

--
-- TOC entry 256 (class 1259 OID 4858454)
-- Name: fgs_objects_ob_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_objects_ob_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_objects_ob_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6299 (class 0 OID 0)
-- Dependencies: 256
-- Name: fgs_objects_ob_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_objects_ob_id_seq OWNED BY public.fgs_objects.ob_id;


--
-- TOC entry 257 (class 1259 OID 4858455)
-- Name: fgs_position_requests; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_position_requests (
    spr_id integer NOT NULL,
    spr_hash character varying,
    spr_base64_sqlz character varying
);


ALTER TABLE public.fgs_position_requests OWNER TO t3r_flightgear;

--
-- TOC entry 258 (class 1259 OID 4858460)
-- Name: fgs_position_requests_spr_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_position_requests_spr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_position_requests_spr_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6302 (class 0 OID 0)
-- Dependencies: 258
-- Name: fgs_position_requests_spr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_position_requests_spr_id_seq OWNED BY public.fgs_position_requests.spr_id;


--
-- TOC entry 259 (class 1259 OID 4858461)
-- Name: fgs_procedures_pr_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_procedures_pr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_procedures_pr_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 260 (class 1259 OID 4858462)
-- Name: fgs_procedures; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_procedures (
    pr_id integer DEFAULT nextval('public.fgs_procedures_pr_id_seq'::regclass) NOT NULL,
    pr_airport character varying(32) NOT NULL,
    pr_runways character varying(128),
    pr_name character varying(32) NOT NULL,
    pr_type public.fgs_procedure_types NOT NULL
);


ALTER TABLE public.fgs_procedures OWNER TO t3r_flightgear;

--
-- TOC entry 261 (class 1259 OID 4858466)
-- Name: fgs_signs; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_signs (
    si_id integer NOT NULL,
    si_modified timestamp without time zone,
    si_text character varying(100),
    wkb_geometry public.geometry NOT NULL,
    si_icao character(4) NOT NULL,
    si_gndelev numeric(7,2) DEFAULT '-9999.00'::numeric,
    si_heading numeric(5,2) DEFAULT 0.00,
    si_country character(2),
    si_definition character varying(60),
    si_tile integer,
    si_submitter character varying(16),
    si_valid boolean DEFAULT true,
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(wkb_geometry) = 2)),
    CONSTRAINT enforce_geotype_wkb_geometry CHECK ((public.geometrytype(wkb_geometry) = 'POINT'::text)),
    CONSTRAINT enforce_srid_wkb_geometry CHECK ((public.st_srid(wkb_geometry) = 4326))
);


ALTER TABLE public.fgs_signs OWNER TO t3r_flightgear;

--
-- TOC entry 262 (class 1259 OID 4858477)
-- Name: fgs_signs_si_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_signs_si_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_signs_si_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6307 (class 0 OID 0)
-- Dependencies: 262
-- Name: fgs_signs_si_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.fgs_signs_si_id_seq OWNED BY public.fgs_signs.si_id;


--
-- TOC entry 263 (class 1259 OID 4858478)
-- Name: fgs_statistics; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_statistics (
    st_date date,
    st_objects bigint,
    st_models bigint,
    st_authors bigint,
    st_navaids bigint,
    st_signs bigint
);


ALTER TABLE public.fgs_statistics OWNER TO t3r_flightgear;

--
-- TOC entry 264 (class 1259 OID 4858481)
-- Name: fgs_timestamps; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_timestamps (
    ti_type integer,
    ti_stamp timestamp without time zone
);


ALTER TABLE public.fgs_timestamps OWNER TO t3r_flightgear;

--
-- TOC entry 265 (class 1259 OID 4858484)
-- Name: fgs_waypoints_wp_id_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.fgs_waypoints_wp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fgs_waypoints_wp_id_seq OWNER TO t3r_flightgear;

--
-- TOC entry 266 (class 1259 OID 4858485)
-- Name: fgs_waypoints; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.fgs_waypoints (
    wp_id integer DEFAULT nextval('public.fgs_waypoints_wp_id_seq'::regclass) NOT NULL,
    wp_prid integer,
    wp_name character(32) NOT NULL,
    wp_type public.fgs_waypoint_type NOT NULL,
    wkb_geometry public.geometry(Point,4326) NOT NULL,
    wp_speed integer,
    wp_altitude integer,
    wp_altitude_cons integer,
    wp_altitude_restriction public.fgs_waypoint_altitude_restriction,
    wp_hold_inbound boolean,
    wp_hold_distance boolean,
    wp_hold_radial integer,
    wp_hold_righthand boolean,
    wp_hold_td numeric(4,1),
    wp_course_heading integer,
    wp_dme_distance numeric(4,1),
    wp_radial integer,
    wp_fly_over boolean,
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(wkb_geometry) = 2)),
    CONSTRAINT enforce_geotype_wkb_geometry CHECK ((public.geometrytype(wkb_geometry) = 'POINT'::text)),
    CONSTRAINT enforce_srid_wkb_geometry CHECK ((public.st_srid(wkb_geometry) = 4326)),
    CONSTRAINT enforce_valid_wkb_geometry CHECK (public.st_isvalid(wkb_geometry))
);


ALTER TABLE public.fgs_waypoints OWNER TO t3r_flightgear;

--
-- TOC entry 267 (class 1259 OID 4858495)
-- Name: gadm2; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.gadm2 (
    ogc_fid integer NOT NULL,
    wkb_geometry public.geometry NOT NULL,
    objectid numeric(9,0),
    id_0 numeric(9,0),
    iso character varying(3),
    name_0 character varying(75),
    id_1 numeric(9,0),
    name_1 character varying(75),
    varname_1 character varying(150),
    nl_name_1 character varying(50),
    hasc_1 character varying(15),
    cc_1 character varying(15),
    type_1 character varying(50),
    engtype_1 character varying(50),
    validfr_1 character varying(25),
    validto_1 character varying(25),
    remarks_1 character varying(125),
    id_2 numeric(9,0),
    name_2 character varying(75),
    varname_2 character varying(150),
    nl_name_2 character varying(75),
    hasc_2 character varying(15),
    cc_2 character varying(15),
    type_2 character varying(50),
    engtype_2 character varying(50),
    validfr_2 character varying(25),
    validto_2 character varying(25),
    remarks_2 character varying(100),
    id_3 numeric(9,0),
    name_3 character varying(75),
    varname_3 character varying(100),
    nl_name_3 character varying(75),
    hasc_3 character varying(25),
    type_3 character varying(50),
    engtype_3 character varying(50),
    validfr_3 character varying(25),
    validto_3 character varying(25),
    remarks_3 character varying(50),
    id_4 numeric(9,0),
    name_4 character varying(100),
    varname_4 character varying(100),
    type4 character varying(25),
    engtype4 character varying(25),
    type_4 character varying(35),
    engtype_4 character varying(35),
    validfr_4 character varying(25),
    validto_4 character varying(25),
    remarks_4 character varying(50),
    id_5 numeric(9,0),
    name_5 character varying(75),
    type_5 character varying(25),
    engtype_5 character varying(25),
    shape_leng numeric(19,11),
    shape_area numeric(19,11),
    CONSTRAINT enforce_dims_wkb_geometry CHECK ((public.st_ndims(wkb_geometry) = 2)),
    CONSTRAINT enforce_geotype_wkb_geometry CHECK (((public.geometrytype(wkb_geometry) = 'POLYGON'::text) OR (public.geometrytype(wkb_geometry) = 'MULTIPOLYGON'::text))),
    CONSTRAINT enforce_srid_wkb_geometry CHECK ((public.st_srid(wkb_geometry) = 4326))
);


ALTER TABLE public.gadm2 OWNER TO t3r_flightgear;

--
-- TOC entry 268 (class 1259 OID 4858503)
-- Name: gadm2_meta; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.gadm2_meta (
    iso character varying(3) NOT NULL,
    shape_sqm double precision
);


ALTER TABLE public.gadm2_meta OWNER TO t3r_flightgear;

--
-- TOC entry 269 (class 1259 OID 4858506)
-- Name: gadm2_ogc_fid_seq; Type: SEQUENCE; Schema: public; Owner: t3r_flightgear
--

CREATE SEQUENCE public.gadm2_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gadm2_ogc_fid_seq OWNER TO t3r_flightgear;

--
-- TOC entry 6315 (class 0 OID 0)
-- Dependencies: 269
-- Name: gadm2_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: t3r_flightgear
--

ALTER SEQUENCE public.gadm2_ogc_fid_seq OWNED BY public.gadm2.ogc_fid;


--
-- TOC entry 270 (class 1259 OID 4858507)
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: t3r_flightgear
--

CREATE TABLE public.user_sessions (
    sid character varying NOT NULL,
    sess json NOT NULL,
    expire timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.user_sessions OWNER TO t3r_flightgear;

--
-- TOC entry 5057 (class 2604 OID 4858512)
-- Name: apt_runway ogc_fid; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.apt_runway ALTER COLUMN ogc_fid SET DEFAULT nextval('public.apt_runway_ogc_fid_seq'::regclass);


--
-- TOC entry 5058 (class 2604 OID 4858513)
-- Name: fgs_aircraft ac_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_aircraft ALTER COLUMN ac_id SET DEFAULT nextval('public.fgs_aircraft_ac_id_seq'::regclass);


--
-- TOC entry 5059 (class 2604 OID 4858514)
-- Name: fgs_airline al_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_airline ALTER COLUMN al_id SET DEFAULT nextval('public.fgs_airline_al_id_seq'::regclass);


--
-- TOC entry 5060 (class 2604 OID 4858515)
-- Name: fgs_airport ap_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_airport ALTER COLUMN ap_id SET DEFAULT nextval('public.fgs_airport_ap_id_seq'::regclass);


--
-- TOC entry 5061 (class 2604 OID 4858516)
-- Name: fgs_authors au_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_authors ALTER COLUMN au_id SET DEFAULT nextval('public.fgs_authors_au_id_seq'::regclass);


--
-- TOC entry 5062 (class 2604 OID 4858517)
-- Name: fgs_clean ob_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_clean ALTER COLUMN ob_id SET DEFAULT nextval('public.fgs_clean_ob_id_seq'::regclass);


--
-- TOC entry 5071 (class 2604 OID 4858518)
-- Name: fgs_fleet fl_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_fleet ALTER COLUMN fl_id SET DEFAULT nextval('public.fgs_fleet_fl_id_seq'::regclass);


--
-- TOC entry 5073 (class 2604 OID 4858519)
-- Name: fgs_flight ft_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_flight ALTER COLUMN ft_id SET DEFAULT nextval('public.fgs_flight_ft_id_seq'::regclass);


--
-- TOC entry 5074 (class 2604 OID 4858520)
-- Name: fgs_groups gp_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_groups ALTER COLUMN gp_id SET DEFAULT nextval('public.fgs_groups_gp_id_seq'::regclass);


--
-- TOC entry 5076 (class 2604 OID 4858521)
-- Name: fgs_modelclass mc_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_modelclass ALTER COLUMN mc_id SET DEFAULT nextval('public.fgs_modelclass_mc_id_seq'::regclass);


--
-- TOC entry 5077 (class 2604 OID 4858522)
-- Name: fgs_modelgroups mg_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_modelgroups ALTER COLUMN mg_id SET DEFAULT nextval('public.fgs_modelgroups_mg_id_seq'::regclass);


--
-- TOC entry 5079 (class 2604 OID 4858523)
-- Name: fgs_navaids na_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_navaids ALTER COLUMN na_id SET DEFAULT nextval('public.fgs_navaids_na_id_seq'::regclass);


--
-- TOC entry 5080 (class 2604 OID 4858524)
-- Name: fgs_news ne_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_news ALTER COLUMN ne_id SET DEFAULT nextval('public.fgs_news_ne_id_seq'::regclass);


--
-- TOC entry 5082 (class 2604 OID 4858525)
-- Name: fgs_objects ob_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_objects ALTER COLUMN ob_id SET DEFAULT nextval('public.fgs_objects_ob_id_seq'::regclass);


--
-- TOC entry 5091 (class 2604 OID 4858526)
-- Name: fgs_position_requests spr_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_position_requests ALTER COLUMN spr_id SET DEFAULT nextval('public.fgs_position_requests_spr_id_seq'::regclass);


--
-- TOC entry 5093 (class 2604 OID 4858527)
-- Name: fgs_signs si_id; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_signs ALTER COLUMN si_id SET DEFAULT nextval('public.fgs_signs_si_id_seq'::regclass);


--
-- TOC entry 5098 (class 2604 OID 4858528)
-- Name: gadm2 ogc_fid; Type: DEFAULT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.gadm2 ALTER COLUMN ogc_fid SET DEFAULT nextval('public.gadm2_ogc_fid_seq'::regclass);


--
-- TOC entry 5133 (class 2606 OID 4920630)
-- Name: apt_runway apt_runway_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.apt_runway
    ADD CONSTRAINT apt_runway_pkey PRIMARY KEY (ogc_fid);


--
-- TOC entry 5136 (class 2606 OID 4920632)
-- Name: fgs_authors fgs_authors_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_authors
    ADD CONSTRAINT fgs_authors_pkey PRIMARY KEY (au_id);


--
-- TOC entry 5146 (class 2606 OID 4920634)
-- Name: fgs_clean fgs_clean_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_clean
    ADD CONSTRAINT fgs_clean_pkey PRIMARY KEY (ob_id);


--
-- TOC entry 5152 (class 2606 OID 4920636)
-- Name: fgs_countries fgs_countries_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_countries
    ADD CONSTRAINT fgs_countries_pkey PRIMARY KEY (co_code);


--
-- TOC entry 5155 (class 2606 OID 4920638)
-- Name: fgs_extuserids fgs_ext_auth_id_key; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_extuserids
    ADD CONSTRAINT fgs_ext_auth_id_key UNIQUE (eu_authority, eu_external_id);


--
-- TOC entry 5161 (class 2606 OID 4920640)
-- Name: fgs_groups fgs_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_groups
    ADD CONSTRAINT fgs_groups_pkey PRIMARY KEY (gp_id);


--
-- TOC entry 5164 (class 2606 OID 4920642)
-- Name: fgs_modelgroups fgs_modelgroups_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_modelgroups
    ADD CONSTRAINT fgs_modelgroups_pkey PRIMARY KEY (mg_id);


--
-- TOC entry 5171 (class 2606 OID 4920644)
-- Name: fgs_models fgs_models_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_models
    ADD CONSTRAINT fgs_models_pkey PRIMARY KEY (mo_id);


--
-- TOC entry 5174 (class 2606 OID 4920646)
-- Name: fgs_navaids fgs_navaids_na_id_key; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_navaids
    ADD CONSTRAINT fgs_navaids_na_id_key UNIQUE (na_id);


--
-- TOC entry 5176 (class 2606 OID 4920648)
-- Name: fgs_news fgs_news_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_news
    ADD CONSTRAINT fgs_news_pkey PRIMARY KEY (ne_id);


--
-- TOC entry 5187 (class 2606 OID 4920650)
-- Name: fgs_objects fgs_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_objects
    ADD CONSTRAINT fgs_objects_pkey PRIMARY KEY (ob_id);


--
-- TOC entry 5193 (class 2606 OID 4920652)
-- Name: fgs_position_requests fgs_position_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_position_requests
    ADD CONSTRAINT fgs_position_requests_pkey PRIMARY KEY (spr_id);


--
-- TOC entry 5201 (class 2606 OID 4920654)
-- Name: fgs_signs fgs_signs_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.fgs_signs
    ADD CONSTRAINT fgs_signs_pkey PRIMARY KEY (si_id);


--
-- TOC entry 5208 (class 2606 OID 4920656)
-- Name: gadm2_meta gadm2_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.gadm2_meta
    ADD CONSTRAINT gadm2_meta_pkey PRIMARY KEY (iso);


--
-- TOC entry 5206 (class 2606 OID 4920658)
-- Name: gadm2 gadm2_pk; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.gadm2
    ADD CONSTRAINT gadm2_pk PRIMARY KEY (ogc_fid);


--
-- TOC entry 5211 (class 2606 OID 4920660)
-- Name: user_sessions session_pkey; Type: CONSTRAINT; Schema: public; Owner: t3r_flightgear
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT session_pkey PRIMARY KEY (sid);


--
-- TOC entry 5209 (class 1259 OID 4920661)
-- Name: IDX_session_expire; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX "IDX_session_expire" ON public.user_sessions USING btree (expire);


--
-- TOC entry 5130 (class 1259 OID 4920662)
-- Name: apt_runway_gindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX apt_runway_gindex ON public.apt_runway USING gist (wkb_geometry);

ALTER TABLE public.apt_runway CLUSTER ON apt_runway_gindex;


--
-- TOC entry 5131 (class 1259 OID 4920663)
-- Name: apt_runway_icindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX apt_runway_icindex ON public.apt_runway USING btree (icao);


--
-- TOC entry 5134 (class 1259 OID 4920664)
-- Name: apt_runway_rwyindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX apt_runway_rwyindex ON public.apt_runway USING btree (rwy_num1, rwy_num2);


--
-- TOC entry 5178 (class 1259 OID 4920665)
-- Name: dumpstg_objects; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX dumpstg_objects ON public.fgs_objects USING btree (ob_tile, ob_model, ob_gndelev, ob_modified);


--
-- TOC entry 5194 (class 1259 OID 4920666)
-- Name: dumpstg_tiles; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX dumpstg_tiles ON public.fgs_signs USING btree (si_tile, si_valid, si_gndelev);


--
-- TOC entry 5137 (class 1259 OID 4920667)
-- Name: fgs_authors_uindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_authors_uindex ON public.fgs_authors USING btree (au_id);

ALTER TABLE public.fgs_authors CLUSTER ON fgs_authors_uindex;


--
-- TOC entry 5138 (class 1259 OID 4920668)
-- Name: fgs_clean_clindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_clindex ON public.fgs_clean USING btree (ob_class);


--
-- TOC entry 5139 (class 1259 OID 4920669)
-- Name: fgs_clean_coindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_coindex ON public.fgs_clean USING btree (ob_country);


--
-- TOC entry 5140 (class 1259 OID 4920670)
-- Name: fgs_clean_elindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_elindex ON public.fgs_clean USING btree (ob_gndelev);


--
-- TOC entry 5141 (class 1259 OID 4920671)
-- Name: fgs_clean_gindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_gindex ON public.fgs_clean USING gist (wkb_geometry);


--
-- TOC entry 5142 (class 1259 OID 4920672)
-- Name: fgs_clean_grindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_grindex ON public.fgs_clean USING btree (ob_group);


--
-- TOC entry 5143 (class 1259 OID 4920673)
-- Name: fgs_clean_mdindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_mdindex ON public.fgs_clean USING btree (ob_model);


--
-- TOC entry 5144 (class 1259 OID 4920674)
-- Name: fgs_clean_moindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_moindex ON public.fgs_clean USING btree (ob_modified);


--
-- TOC entry 5147 (class 1259 OID 4920675)
-- Name: fgs_clean_rindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_rindex ON public.fgs_clean USING btree (ob_reference);


--
-- TOC entry 5148 (class 1259 OID 4920676)
-- Name: fgs_clean_tindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_tindex ON public.fgs_clean USING btree (ob_tile);


--
-- TOC entry 5149 (class 1259 OID 4920677)
-- Name: fgs_clean_uindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_clean_uindex ON public.fgs_clean USING btree (ob_id);


--
-- TOC entry 5150 (class 1259 OID 4920678)
-- Name: fgs_clean_vindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_clean_vindex ON public.fgs_clean USING btree (ob_valid);


--
-- TOC entry 5153 (class 1259 OID 4920679)
-- Name: fgs_countries_uindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_countries_uindex ON public.fgs_countries USING btree (co_code);

ALTER TABLE public.fgs_countries CLUSTER ON fgs_countries_uindex;


--
-- TOC entry 5156 (class 1259 OID 4920680)
-- Name: fgs_extern_authority_id_index; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_extern_authority_id_index ON public.fgs_extuserids USING btree (eu_authority, eu_external_id);


--
-- TOC entry 5157 (class 1259 OID 4920681)
-- Name: fgs_fixes_gindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_fixes_gindex ON public.fgs_fixes USING gist (wkb_geometry);


--
-- TOC entry 5158 (class 1259 OID 4920682)
-- Name: fgs_fixes_nindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_fixes_nindex ON public.fgs_fixes USING btree (fx_name);


--
-- TOC entry 5159 (class 1259 OID 4920683)
-- Name: fgs_groups_gpindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_groups_gpindex ON public.fgs_groups USING btree (gp_id);


--
-- TOC entry 5162 (class 1259 OID 4920684)
-- Name: fgs_groups_uindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_groups_uindex ON public.fgs_groups USING btree (gp_id);

ALTER TABLE public.fgs_groups CLUSTER ON fgs_groups_uindex;


--
-- TOC entry 5165 (class 1259 OID 4920685)
-- Name: fgs_modelgroups_uindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_modelgroups_uindex ON public.fgs_modelgroups USING btree (mg_id);

ALTER TABLE public.fgs_modelgroups CLUSTER ON fgs_modelgroups_uindex;


--
-- TOC entry 5166 (class 1259 OID 4920686)
-- Name: fgs_models_auindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_models_auindex ON public.fgs_models USING btree (mo_author);


--
-- TOC entry 5167 (class 1259 OID 4920687)
-- Name: fgs_models_moindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_models_moindex ON public.fgs_models USING btree (mo_modified);


--
-- TOC entry 5168 (class 1259 OID 4920688)
-- Name: fgs_models_moshared; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_models_moshared ON public.fgs_models USING btree (mo_shared);


--
-- TOC entry 5169 (class 1259 OID 4920689)
-- Name: fgs_models_paindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_models_paindex ON public.fgs_models USING btree (mo_path);


--
-- TOC entry 5172 (class 1259 OID 4920690)
-- Name: fgs_models_uindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_models_uindex ON public.fgs_models USING btree (mo_id);

ALTER TABLE public.fgs_models CLUSTER ON fgs_models_uindex;


--
-- TOC entry 5177 (class 1259 OID 4920691)
-- Name: fgs_news_uindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_news_uindex ON public.fgs_news USING btree (ne_timestamp);

ALTER TABLE public.fgs_news CLUSTER ON fgs_news_uindex;


--
-- TOC entry 5179 (class 1259 OID 4920692)
-- Name: fgs_objects_clindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_clindex ON public.fgs_objects USING btree (ob_class);


--
-- TOC entry 5180 (class 1259 OID 4920693)
-- Name: fgs_objects_coindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_coindex ON public.fgs_objects USING btree (ob_country);


--
-- TOC entry 5181 (class 1259 OID 4920694)
-- Name: fgs_objects_elindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_elindex ON public.fgs_objects USING btree (ob_gndelev);


--
-- TOC entry 5182 (class 1259 OID 4920695)
-- Name: fgs_objects_gindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_gindex ON public.fgs_objects USING gist (wkb_geometry);


--
-- TOC entry 5183 (class 1259 OID 4920696)
-- Name: fgs_objects_grindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_grindex ON public.fgs_objects USING btree (ob_group);


--
-- TOC entry 5184 (class 1259 OID 4920697)
-- Name: fgs_objects_mdindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_mdindex ON public.fgs_objects USING btree (ob_model);


--
-- TOC entry 5185 (class 1259 OID 4920698)
-- Name: fgs_objects_moindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_moindex ON public.fgs_objects USING btree (ob_modified);


--
-- TOC entry 5188 (class 1259 OID 4920699)
-- Name: fgs_objects_rindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_rindex ON public.fgs_objects USING btree (ob_reference);


--
-- TOC entry 5189 (class 1259 OID 4920700)
-- Name: fgs_objects_tindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_tindex ON public.fgs_objects USING btree (ob_tile);


--
-- TOC entry 5190 (class 1259 OID 4920701)
-- Name: fgs_objects_uindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_objects_uindex ON public.fgs_objects USING btree (ob_id);


--
-- TOC entry 5191 (class 1259 OID 4920702)
-- Name: fgs_objects_vindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_objects_vindex ON public.fgs_objects USING btree (ob_valid);


--
-- TOC entry 5195 (class 1259 OID 4920703)
-- Name: fgs_signs_coindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_signs_coindex ON public.fgs_signs USING btree (si_country);


--
-- TOC entry 5196 (class 1259 OID 4920704)
-- Name: fgs_signs_elindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_signs_elindex ON public.fgs_signs USING btree (si_gndelev);


--
-- TOC entry 5197 (class 1259 OID 4920705)
-- Name: fgs_signs_gindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_signs_gindex ON public.fgs_signs USING gist (wkb_geometry);

ALTER TABLE public.fgs_signs CLUSTER ON fgs_signs_gindex;


--
-- TOC entry 5198 (class 1259 OID 4920706)
-- Name: fgs_signs_icindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_signs_icindex ON public.fgs_signs USING btree (si_icao);


--
-- TOC entry 5199 (class 1259 OID 4920707)
-- Name: fgs_signs_moindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_signs_moindex ON public.fgs_signs USING btree (si_modified);


--
-- TOC entry 5202 (class 1259 OID 4920708)
-- Name: fgs_signs_tindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX fgs_signs_tindex ON public.fgs_signs USING btree (si_tile);


--
-- TOC entry 5203 (class 1259 OID 4920709)
-- Name: fgs_signs_uindex; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE UNIQUE INDEX fgs_signs_uindex ON public.fgs_signs USING btree (si_id);


--
-- TOC entry 5204 (class 1259 OID 4920710)
-- Name: gadm2_geom_idx; Type: INDEX; Schema: public; Owner: t3r_flightgear
--

CREATE INDEX gadm2_geom_idx ON public.gadm2 USING gist (wkb_geometry);


--
-- TOC entry 5212 (class 2620 OID 4920711)
-- Name: fgs_clean fgs_clean_modtime; Type: TRIGGER; Schema: public; Owner: t3r_flightgear
--

CREATE TRIGGER fgs_clean_modtime BEFORE INSERT OR UPDATE ON public.fgs_clean FOR EACH ROW EXECUTE FUNCTION public.fn_setobjectmodtime();


--
-- TOC entry 5213 (class 2620 OID 4920712)
-- Name: fgs_models fgs_models_modtime; Type: TRIGGER; Schema: public; Owner: t3r_flightgear
--

CREATE TRIGGER fgs_models_modtime BEFORE INSERT OR UPDATE ON public.fgs_models FOR EACH ROW EXECUTE FUNCTION public.fn_setmodelmodtime();


--
-- TOC entry 5214 (class 2620 OID 4920713)
-- Name: fgs_news fgs_news_modtime; Type: TRIGGER; Schema: public; Owner: t3r_flightgear
--

CREATE TRIGGER fgs_news_modtime BEFORE INSERT OR UPDATE ON public.fgs_news FOR EACH ROW EXECUTE FUNCTION public.fn_setnewsmodtime();


--
-- TOC entry 5215 (class 2620 OID 4920714)
-- Name: fgs_objects fgs_objects_modtime; Type: TRIGGER; Schema: public; Owner: t3r_flightgear
--

CREATE TRIGGER fgs_objects_modtime BEFORE INSERT OR UPDATE ON public.fgs_objects FOR EACH ROW EXECUTE FUNCTION public.fn_setobjectmodtime();


--
-- TOC entry 5216 (class 2620 OID 4920715)
-- Name: fgs_signs fgs_signs_modtime; Type: TRIGGER; Schema: public; Owner: t3r_flightgear
--

CREATE TRIGGER fgs_signs_modtime BEFORE INSERT OR UPDATE ON public.fgs_signs FOR EACH ROW EXECUTE FUNCTION public.fn_setsignmodtime();


--
-- TOC entry 5370 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: t3r
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO t3r_flightgear;
GRANT USAGE ON SCHEMA public TO t3r_grafana;


--
-- TOC entry 5374 (class 0 OID 0)
-- Dependencies: 604
-- Name: FUNCTION box2d_in(cstring); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box2d_in(cstring) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box2d_in(cstring) TO t3r;
GRANT ALL ON FUNCTION public.box2d_in(cstring) TO t3r_grafana;


--
-- TOC entry 5375 (class 0 OID 0)
-- Dependencies: 983
-- Name: FUNCTION box2d_out(public.box2d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO t3r;
GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO t3r_grafana;


--
-- TOC entry 5376 (class 0 OID 0)
-- Dependencies: 448
-- Name: FUNCTION box2df_in(cstring); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box2df_in(cstring) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box2df_in(cstring) TO t3r;
GRANT ALL ON FUNCTION public.box2df_in(cstring) TO t3r_grafana;


--
-- TOC entry 5377 (class 0 OID 0)
-- Dependencies: 1104
-- Name: FUNCTION box2df_out(public.box2df); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO t3r;
GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO t3r_grafana;


--
-- TOC entry 5378 (class 0 OID 0)
-- Dependencies: 1083
-- Name: FUNCTION box3d_in(cstring); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box3d_in(cstring) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box3d_in(cstring) TO t3r;
GRANT ALL ON FUNCTION public.box3d_in(cstring) TO t3r_grafana;


--
-- TOC entry 5379 (class 0 OID 0)
-- Dependencies: 685
-- Name: FUNCTION box3d_out(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO t3r_grafana;


--
-- TOC entry 5380 (class 0 OID 0)
-- Dependencies: 826
-- Name: FUNCTION geography_analyze(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_analyze(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_analyze(internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_analyze(internal) TO t3r_grafana;


--
-- TOC entry 5381 (class 0 OID 0)
-- Dependencies: 569
-- Name: FUNCTION geography_in(cstring, oid, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO t3r;
GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO t3r_grafana;


--
-- TOC entry 5382 (class 0 OID 0)
-- Dependencies: 1082
-- Name: FUNCTION geography_out(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_out(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_out(public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_out(public.geography) TO t3r_grafana;


--
-- TOC entry 5383 (class 0 OID 0)
-- Dependencies: 644
-- Name: FUNCTION geography_recv(internal, oid, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO t3r;
GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO t3r_grafana;


--
-- TOC entry 5384 (class 0 OID 0)
-- Dependencies: 794
-- Name: FUNCTION geography_send(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_send(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_send(public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_send(public.geography) TO t3r_grafana;


--
-- TOC entry 5385 (class 0 OID 0)
-- Dependencies: 1067
-- Name: FUNCTION geography_typmod_in(cstring[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO t3r;
GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO t3r_grafana;


--
-- TOC entry 5386 (class 0 OID 0)
-- Dependencies: 557
-- Name: FUNCTION geography_typmod_out(integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO t3r;
GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO t3r_grafana;


--
-- TOC entry 5387 (class 0 OID 0)
-- Dependencies: 734
-- Name: FUNCTION geometry_analyze(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO t3r_grafana;


--
-- TOC entry 5388 (class 0 OID 0)
-- Dependencies: 312
-- Name: FUNCTION geometry_in(cstring); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_in(cstring) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_in(cstring) TO t3r;
GRANT ALL ON FUNCTION public.geometry_in(cstring) TO t3r_grafana;


--
-- TOC entry 5389 (class 0 OID 0)
-- Dependencies: 599
-- Name: FUNCTION geometry_out(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO t3r_grafana;


--
-- TOC entry 5390 (class 0 OID 0)
-- Dependencies: 947
-- Name: FUNCTION geometry_recv(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_recv(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_recv(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_recv(internal) TO t3r_grafana;


--
-- TOC entry 5391 (class 0 OID 0)
-- Dependencies: 1100
-- Name: FUNCTION geometry_send(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO t3r_grafana;


--
-- TOC entry 5392 (class 0 OID 0)
-- Dependencies: 613
-- Name: FUNCTION geometry_typmod_in(cstring[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO t3r;
GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO t3r_grafana;


--
-- TOC entry 5393 (class 0 OID 0)
-- Dependencies: 1038
-- Name: FUNCTION geometry_typmod_out(integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO t3r;
GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO t3r_grafana;


--
-- TOC entry 5394 (class 0 OID 0)
-- Dependencies: 990
-- Name: FUNCTION ghstore_in(cstring); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_in(cstring) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_in(cstring) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_in(cstring) TO t3r_grafana;


--
-- TOC entry 5395 (class 0 OID 0)
-- Dependencies: 617
-- Name: FUNCTION ghstore_out(public.ghstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_out(public.ghstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_out(public.ghstore) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_out(public.ghstore) TO t3r_grafana;


--
-- TOC entry 5396 (class 0 OID 0)
-- Dependencies: 957
-- Name: FUNCTION gidx_in(cstring); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gidx_in(cstring) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gidx_in(cstring) TO t3r;
GRANT ALL ON FUNCTION public.gidx_in(cstring) TO t3r_grafana;


--
-- TOC entry 5397 (class 0 OID 0)
-- Dependencies: 903
-- Name: FUNCTION gidx_out(public.gidx); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO t3r;
GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO t3r_grafana;


--
-- TOC entry 5398 (class 0 OID 0)
-- Dependencies: 568
-- Name: FUNCTION hstore_in(cstring); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_in(cstring) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_in(cstring) TO t3r;
GRANT ALL ON FUNCTION public.hstore_in(cstring) TO t3r_grafana;


--
-- TOC entry 5399 (class 0 OID 0)
-- Dependencies: 902
-- Name: FUNCTION hstore_out(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_out(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_out(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_out(public.hstore) TO t3r_grafana;


--
-- TOC entry 5400 (class 0 OID 0)
-- Dependencies: 722
-- Name: FUNCTION hstore_recv(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_recv(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_recv(internal) TO t3r;
GRANT ALL ON FUNCTION public.hstore_recv(internal) TO t3r_grafana;


--
-- TOC entry 5401 (class 0 OID 0)
-- Dependencies: 1042
-- Name: FUNCTION hstore_send(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_send(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_send(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_send(public.hstore) TO t3r_grafana;


--
-- TOC entry 5402 (class 0 OID 0)
-- Dependencies: 286
-- Name: FUNCTION hstore_subscript_handler(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_subscript_handler(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_subscript_handler(internal) TO t3r;
GRANT ALL ON FUNCTION public.hstore_subscript_handler(internal) TO t3r_grafana;


--
-- TOC entry 5403 (class 0 OID 0)
-- Dependencies: 418
-- Name: FUNCTION spheroid_in(cstring); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO t3r;
GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO t3r_grafana;


--
-- TOC entry 5404 (class 0 OID 0)
-- Dependencies: 420
-- Name: FUNCTION spheroid_out(public.spheroid); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO t3r;
GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO t3r_grafana;


--
-- TOC entry 5405 (class 0 OID 0)
-- Dependencies: 770
-- Name: FUNCTION hstore(text[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore(text[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore(text[]) TO t3r;
GRANT ALL ON FUNCTION public.hstore(text[]) TO t3r_grafana;


--
-- TOC entry 5406 (class 0 OID 0)
-- Dependencies: 684
-- Name: FUNCTION box3d(public.box2d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box3d(public.box2d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box3d(public.box2d) TO t3r;
GRANT ALL ON FUNCTION public.box3d(public.box2d) TO t3r_grafana;


--
-- TOC entry 5407 (class 0 OID 0)
-- Dependencies: 629
-- Name: FUNCTION geometry(public.box2d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry(public.box2d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry(public.box2d) TO t3r;
GRANT ALL ON FUNCTION public.geometry(public.box2d) TO t3r_grafana;


--
-- TOC entry 5408 (class 0 OID 0)
-- Dependencies: 913
-- Name: FUNCTION box(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.box(public.box3d) TO t3r_grafana;


--
-- TOC entry 5409 (class 0 OID 0)
-- Dependencies: 1029
-- Name: FUNCTION box2d(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box2d(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box2d(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.box2d(public.box3d) TO t3r_grafana;


--
-- TOC entry 5410 (class 0 OID 0)
-- Dependencies: 772
-- Name: FUNCTION geometry(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.geometry(public.box3d) TO t3r_grafana;


--
-- TOC entry 5411 (class 0 OID 0)
-- Dependencies: 762
-- Name: FUNCTION geography(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography(bytea) TO t3r;
GRANT ALL ON FUNCTION public.geography(bytea) TO t3r_grafana;


--
-- TOC entry 5412 (class 0 OID 0)
-- Dependencies: 731
-- Name: FUNCTION geometry(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry(bytea) TO t3r;
GRANT ALL ON FUNCTION public.geometry(bytea) TO t3r_grafana;


--
-- TOC entry 5413 (class 0 OID 0)
-- Dependencies: 852
-- Name: FUNCTION bytea(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.bytea(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.bytea(public.geography) TO t3r;
GRANT ALL ON FUNCTION public.bytea(public.geography) TO t3r_grafana;


--
-- TOC entry 5414 (class 0 OID 0)
-- Dependencies: 454
-- Name: FUNCTION geography(public.geography, integer, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO t3r;
GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO t3r_grafana;


--
-- TOC entry 5415 (class 0 OID 0)
-- Dependencies: 528
-- Name: FUNCTION geometry(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry(public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geometry(public.geography) TO t3r_grafana;


--
-- TOC entry 5416 (class 0 OID 0)
-- Dependencies: 738
-- Name: FUNCTION box(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.box(public.geometry) TO t3r_grafana;


--
-- TOC entry 5417 (class 0 OID 0)
-- Dependencies: 636
-- Name: FUNCTION box2d(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box2d(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box2d(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.box2d(public.geometry) TO t3r_grafana;


--
-- TOC entry 5418 (class 0 OID 0)
-- Dependencies: 890
-- Name: FUNCTION box3d(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box3d(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box3d(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.box3d(public.geometry) TO t3r_grafana;


--
-- TOC entry 5419 (class 0 OID 0)
-- Dependencies: 459
-- Name: FUNCTION bytea(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.bytea(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.bytea(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.bytea(public.geometry) TO t3r_grafana;


--
-- TOC entry 5420 (class 0 OID 0)
-- Dependencies: 820
-- Name: FUNCTION geography(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geography(public.geometry) TO t3r_grafana;


--
-- TOC entry 5421 (class 0 OID 0)
-- Dependencies: 948
-- Name: FUNCTION geometry(public.geometry, integer, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO t3r;
GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO t3r_grafana;


--
-- TOC entry 5422 (class 0 OID 0)
-- Dependencies: 324
-- Name: FUNCTION json(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.json(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.json(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.json(public.geometry) TO t3r_grafana;


--
-- TOC entry 5423 (class 0 OID 0)
-- Dependencies: 1040
-- Name: FUNCTION jsonb(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO t3r_grafana;


--
-- TOC entry 5424 (class 0 OID 0)
-- Dependencies: 430
-- Name: FUNCTION path(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.path(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.path(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.path(public.geometry) TO t3r_grafana;


--
-- TOC entry 5425 (class 0 OID 0)
-- Dependencies: 846
-- Name: FUNCTION point(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.point(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.point(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.point(public.geometry) TO t3r_grafana;


--
-- TOC entry 5426 (class 0 OID 0)
-- Dependencies: 444
-- Name: FUNCTION polygon(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.polygon(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.polygon(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.polygon(public.geometry) TO t3r_grafana;


--
-- TOC entry 5427 (class 0 OID 0)
-- Dependencies: 757
-- Name: FUNCTION text(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.text(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.text(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.text(public.geometry) TO t3r_grafana;


--
-- TOC entry 5428 (class 0 OID 0)
-- Dependencies: 1049
-- Name: FUNCTION hstore_to_json(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_to_json(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_to_json(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_to_json(public.hstore) TO t3r_grafana;


--
-- TOC entry 5429 (class 0 OID 0)
-- Dependencies: 584
-- Name: FUNCTION hstore_to_jsonb(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_to_jsonb(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_to_jsonb(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_to_jsonb(public.hstore) TO t3r_grafana;


--
-- TOC entry 5430 (class 0 OID 0)
-- Dependencies: 889
-- Name: FUNCTION geometry(path); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry(path) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry(path) TO t3r;
GRANT ALL ON FUNCTION public.geometry(path) TO t3r_grafana;


--
-- TOC entry 5431 (class 0 OID 0)
-- Dependencies: 875
-- Name: FUNCTION geometry(point); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry(point) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry(point) TO t3r;
GRANT ALL ON FUNCTION public.geometry(point) TO t3r_grafana;


--
-- TOC entry 5432 (class 0 OID 0)
-- Dependencies: 1041
-- Name: FUNCTION geometry(polygon); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry(polygon) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry(polygon) TO t3r;
GRANT ALL ON FUNCTION public.geometry(polygon) TO t3r_grafana;


--
-- TOC entry 5433 (class 0 OID 0)
-- Dependencies: 319
-- Name: FUNCTION geometry(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry(text) TO t3r;
GRANT ALL ON FUNCTION public.geometry(text) TO t3r_grafana;


--
-- TOC entry 5434 (class 0 OID 0)
-- Dependencies: 1005
-- Name: FUNCTION _postgis_deprecate(oldname text, newname text, version text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO t3r;
GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO t3r_grafana;


--
-- TOC entry 5435 (class 0 OID 0)
-- Dependencies: 638
-- Name: FUNCTION _postgis_index_extent(tbl regclass, col text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO t3r;
GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO t3r_grafana;


--
-- TOC entry 5436 (class 0 OID 0)
-- Dependencies: 1135
-- Name: FUNCTION _postgis_join_selectivity(regclass, text, regclass, text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO t3r;
GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO t3r_grafana;


--
-- TOC entry 5437 (class 0 OID 0)
-- Dependencies: 968
-- Name: FUNCTION _postgis_pgsql_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO t3r;
GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO t3r_grafana;


--
-- TOC entry 5438 (class 0 OID 0)
-- Dependencies: 798
-- Name: FUNCTION _postgis_scripts_pgsql_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO t3r;
GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO t3r_grafana;


--
-- TOC entry 5439 (class 0 OID 0)
-- Dependencies: 572
-- Name: FUNCTION _postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO t3r;
GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO t3r_grafana;


--
-- TOC entry 5440 (class 0 OID 0)
-- Dependencies: 435
-- Name: FUNCTION _postgis_stats(tbl regclass, att_name text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO t3r;
GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO t3r_grafana;


--
-- TOC entry 5441 (class 0 OID 0)
-- Dependencies: 287
-- Name: FUNCTION _st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5442 (class 0 OID 0)
-- Dependencies: 593
-- Name: FUNCTION _st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5443 (class 0 OID 0)
-- Dependencies: 395
-- Name: FUNCTION _st_3dintersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5444 (class 0 OID 0)
-- Dependencies: 1056
-- Name: FUNCTION _st_asgml(integer, public.geometry, integer, integer, text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO t3r;
GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO t3r_grafana;


--
-- TOC entry 5445 (class 0 OID 0)
-- Dependencies: 474
-- Name: FUNCTION _st_asx3d(integer, public.geometry, integer, integer, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO t3r;
GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO t3r_grafana;


--
-- TOC entry 5446 (class 0 OID 0)
-- Dependencies: 641
-- Name: FUNCTION _st_bestsrid(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO t3r;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO t3r_grafana;


--
-- TOC entry 5447 (class 0 OID 0)
-- Dependencies: 1007
-- Name: FUNCTION _st_bestsrid(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5448 (class 0 OID 0)
-- Dependencies: 961
-- Name: FUNCTION _st_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5449 (class 0 OID 0)
-- Dependencies: 720
-- Name: FUNCTION _st_containsproperly(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5450 (class 0 OID 0)
-- Dependencies: 822
-- Name: FUNCTION _st_coveredby(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO t3r;
GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO t3r_grafana;


--
-- TOC entry 5451 (class 0 OID 0)
-- Dependencies: 849
-- Name: FUNCTION _st_coveredby(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5452 (class 0 OID 0)
-- Dependencies: 840
-- Name: FUNCTION _st_covers(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO t3r;
GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO t3r_grafana;


--
-- TOC entry 5453 (class 0 OID 0)
-- Dependencies: 1009
-- Name: FUNCTION _st_covers(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5454 (class 0 OID 0)
-- Dependencies: 805
-- Name: FUNCTION _st_crosses(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5455 (class 0 OID 0)
-- Dependencies: 355
-- Name: FUNCTION _st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5456 (class 0 OID 0)
-- Dependencies: 1055
-- Name: FUNCTION _st_distancetree(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5457 (class 0 OID 0)
-- Dependencies: 1101
-- Name: FUNCTION _st_distancetree(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO t3r;
GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO t3r_grafana;


--
-- TOC entry 5458 (class 0 OID 0)
-- Dependencies: 651
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5459 (class 0 OID 0)
-- Dependencies: 1103
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO t3r;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO t3r_grafana;


--
-- TOC entry 5460 (class 0 OID 0)
-- Dependencies: 1011
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO t3r;
GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO t3r_grafana;


--
-- TOC entry 5461 (class 0 OID 0)
-- Dependencies: 742
-- Name: FUNCTION _st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5462 (class 0 OID 0)
-- Dependencies: 1063
-- Name: FUNCTION _st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 5463 (class 0 OID 0)
-- Dependencies: 830
-- Name: FUNCTION _st_dwithinuncached(public.geography, public.geography, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO t3r;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO t3r_grafana;


--
-- TOC entry 5464 (class 0 OID 0)
-- Dependencies: 1004
-- Name: FUNCTION _st_dwithinuncached(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO t3r;
GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO t3r_grafana;


--
-- TOC entry 5465 (class 0 OID 0)
-- Dependencies: 306
-- Name: FUNCTION _st_equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5466 (class 0 OID 0)
-- Dependencies: 700
-- Name: FUNCTION _st_expand(public.geography, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO t3r;
GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO t3r_grafana;


--
-- TOC entry 5467 (class 0 OID 0)
-- Dependencies: 1061
-- Name: FUNCTION _st_geomfromgml(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO t3r;
GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO t3r_grafana;


--
-- TOC entry 5468 (class 0 OID 0)
-- Dependencies: 424
-- Name: FUNCTION _st_intersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5469 (class 0 OID 0)
-- Dependencies: 493
-- Name: FUNCTION _st_linecrossingdirection(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5470 (class 0 OID 0)
-- Dependencies: 703
-- Name: FUNCTION _st_longestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5471 (class 0 OID 0)
-- Dependencies: 924
-- Name: FUNCTION _st_maxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5472 (class 0 OID 0)
-- Dependencies: 709
-- Name: FUNCTION _st_orderingequals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5473 (class 0 OID 0)
-- Dependencies: 326
-- Name: FUNCTION _st_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5474 (class 0 OID 0)
-- Dependencies: 457
-- Name: FUNCTION _st_pointoutside(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO t3r;
GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO t3r_grafana;


--
-- TOC entry 5475 (class 0 OID 0)
-- Dependencies: 1088
-- Name: FUNCTION _st_sortablehash(geom public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO t3r_grafana;


--
-- TOC entry 5476 (class 0 OID 0)
-- Dependencies: 606
-- Name: FUNCTION _st_touches(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5477 (class 0 OID 0)
-- Dependencies: 886
-- Name: FUNCTION _st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO t3r;
GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO t3r_grafana;


--
-- TOC entry 5478 (class 0 OID 0)
-- Dependencies: 682
-- Name: FUNCTION _st_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5479 (class 0 OID 0)
-- Dependencies: 663
-- Name: FUNCTION addauth(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.addauth(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.addauth(text) TO t3r;
GRANT ALL ON FUNCTION public.addauth(text) TO t3r_grafana;


--
-- TOC entry 5480 (class 0 OID 0)
-- Dependencies: 275
-- Name: FUNCTION addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO t3r;
GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO t3r_grafana;


--
-- TOC entry 5481 (class 0 OID 0)
-- Dependencies: 1096
-- Name: FUNCTION addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO t3r;
GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO t3r_grafana;


--
-- TOC entry 5482 (class 0 OID 0)
-- Dependencies: 1060
-- Name: FUNCTION addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO t3r;
GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO t3r_grafana;


--
-- TOC entry 5483 (class 0 OID 0)
-- Dependencies: 1090
-- Name: FUNCTION akeys(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.akeys(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.akeys(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.akeys(public.hstore) TO t3r_grafana;


--
-- TOC entry 5484 (class 0 OID 0)
-- Dependencies: 995
-- Name: FUNCTION avals(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.avals(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.avals(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.avals(public.hstore) TO t3r_grafana;


--
-- TOC entry 5485 (class 0 OID 0)
-- Dependencies: 847
-- Name: FUNCTION box3dtobox(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO t3r_grafana;


--
-- TOC entry 5486 (class 0 OID 0)
-- Dependencies: 387
-- Name: FUNCTION checkauth(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.checkauth(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.checkauth(text, text) TO t3r;
GRANT ALL ON FUNCTION public.checkauth(text, text) TO t3r_grafana;


--
-- TOC entry 5487 (class 0 OID 0)
-- Dependencies: 1108
-- Name: FUNCTION checkauth(text, text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO t3r;
GRANT ALL ON FUNCTION public.checkauth(text, text, text) TO t3r_grafana;


--
-- TOC entry 5488 (class 0 OID 0)
-- Dependencies: 729
-- Name: FUNCTION checkauthtrigger(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.checkauthtrigger() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.checkauthtrigger() TO t3r;
GRANT ALL ON FUNCTION public.checkauthtrigger() TO t3r_grafana;


--
-- TOC entry 5489 (class 0 OID 0)
-- Dependencies: 482
-- Name: FUNCTION contains_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO t3r;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO t3r_grafana;


--
-- TOC entry 5490 (class 0 OID 0)
-- Dependencies: 555
-- Name: FUNCTION contains_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO t3r_grafana;


--
-- TOC entry 5491 (class 0 OID 0)
-- Dependencies: 959
-- Name: FUNCTION contains_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO t3r;
GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO t3r_grafana;


--
-- TOC entry 5492 (class 0 OID 0)
-- Dependencies: 999
-- Name: FUNCTION defined(public.hstore, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.defined(public.hstore, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.defined(public.hstore, text) TO t3r;
GRANT ALL ON FUNCTION public.defined(public.hstore, text) TO t3r_grafana;


--
-- TOC entry 5493 (class 0 OID 0)
-- Dependencies: 274
-- Name: FUNCTION delete(public.hstore, text[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.delete(public.hstore, text[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.delete(public.hstore, text[]) TO t3r;
GRANT ALL ON FUNCTION public.delete(public.hstore, text[]) TO t3r_grafana;


--
-- TOC entry 5494 (class 0 OID 0)
-- Dependencies: 433
-- Name: FUNCTION delete(public.hstore, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.delete(public.hstore, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.delete(public.hstore, text) TO t3r;
GRANT ALL ON FUNCTION public.delete(public.hstore, text) TO t3r_grafana;


--
-- TOC entry 5495 (class 0 OID 0)
-- Dependencies: 364
-- Name: FUNCTION delete(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.delete(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.delete(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.delete(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5496 (class 0 OID 0)
-- Dependencies: 607
-- Name: FUNCTION disablelongtransactions(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.disablelongtransactions() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.disablelongtransactions() TO t3r;
GRANT ALL ON FUNCTION public.disablelongtransactions() TO t3r_grafana;


--
-- TOC entry 5497 (class 0 OID 0)
-- Dependencies: 908
-- Name: FUNCTION dropgeometrycolumn(table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO t3r;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO t3r_grafana;


--
-- TOC entry 5498 (class 0 OID 0)
-- Dependencies: 605
-- Name: FUNCTION dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO t3r;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO t3r_grafana;


--
-- TOC entry 5499 (class 0 OID 0)
-- Dependencies: 645
-- Name: FUNCTION dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO t3r;
GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO t3r_grafana;


--
-- TOC entry 5500 (class 0 OID 0)
-- Dependencies: 660
-- Name: FUNCTION dropgeometrytable(table_name character varying); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO t3r;
GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO t3r_grafana;


--
-- TOC entry 5501 (class 0 OID 0)
-- Dependencies: 529
-- Name: FUNCTION dropgeometrytable(schema_name character varying, table_name character varying); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO t3r;
GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO t3r_grafana;


--
-- TOC entry 5502 (class 0 OID 0)
-- Dependencies: 283
-- Name: FUNCTION dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO t3r;
GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO t3r_grafana;


--
-- TOC entry 5503 (class 0 OID 0)
-- Dependencies: 351
-- Name: FUNCTION each(hs public.hstore, OUT key text, OUT value text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.each(hs public.hstore, OUT key text, OUT value text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.each(hs public.hstore, OUT key text, OUT value text) TO t3r;
GRANT ALL ON FUNCTION public.each(hs public.hstore, OUT key text, OUT value text) TO t3r_grafana;


--
-- TOC entry 5504 (class 0 OID 0)
-- Dependencies: 356
-- Name: FUNCTION enablelongtransactions(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.enablelongtransactions() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.enablelongtransactions() TO t3r;
GRANT ALL ON FUNCTION public.enablelongtransactions() TO t3r_grafana;


--
-- TOC entry 5505 (class 0 OID 0)
-- Dependencies: 298
-- Name: FUNCTION equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5506 (class 0 OID 0)
-- Dependencies: 632
-- Name: FUNCTION exist(public.hstore, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.exist(public.hstore, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.exist(public.hstore, text) TO t3r;
GRANT ALL ON FUNCTION public.exist(public.hstore, text) TO t3r_grafana;


--
-- TOC entry 5507 (class 0 OID 0)
-- Dependencies: 1014
-- Name: FUNCTION exists_all(public.hstore, text[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.exists_all(public.hstore, text[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.exists_all(public.hstore, text[]) TO t3r;
GRANT ALL ON FUNCTION public.exists_all(public.hstore, text[]) TO t3r_grafana;


--
-- TOC entry 5508 (class 0 OID 0)
-- Dependencies: 637
-- Name: FUNCTION exists_any(public.hstore, text[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.exists_any(public.hstore, text[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.exists_any(public.hstore, text[]) TO t3r;
GRANT ALL ON FUNCTION public.exists_any(public.hstore, text[]) TO t3r_grafana;


--
-- TOC entry 5509 (class 0 OID 0)
-- Dependencies: 863
-- Name: FUNCTION fetchval(public.hstore, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.fetchval(public.hstore, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.fetchval(public.hstore, text) TO t3r;
GRANT ALL ON FUNCTION public.fetchval(public.hstore, text) TO t3r_grafana;


--
-- TOC entry 5510 (class 0 OID 0)
-- Dependencies: 977
-- Name: FUNCTION find_srid(character varying, character varying, character varying); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO t3r;
GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO t3r_grafana;


--
-- TOC entry 5511 (class 0 OID 0)
-- Dependencies: 404
-- Name: FUNCTION fn_alignendpylon(p1 public.geometry, p2 public.geometry); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_alignendpylon(p1 public.geometry, p2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.fn_alignendpylon(p1 public.geometry, p2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5512 (class 0 OID 0)
-- Dependencies: 803
-- Name: FUNCTION fn_alignmiddlepylon(p1 public.geometry, p2 public.geometry, p3 public.geometry); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_alignmiddlepylon(p1 public.geometry, p2 public.geometry, p3 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.fn_alignmiddlepylon(p1 public.geometry, p2 public.geometry, p3 public.geometry) TO t3r_grafana;


--
-- TOC entry 5513 (class 0 OID 0)
-- Dependencies: 443
-- Name: FUNCTION fn_boundingbox(public.geometry); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_boundingbox(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.fn_boundingbox(public.geometry) TO t3r_grafana;


--
-- TOC entry 5514 (class 0 OID 0)
-- Dependencies: 844
-- Name: FUNCTION fn_csmerge(grasslayer character varying); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_csmerge(grasslayer character varying) TO t3r;
GRANT ALL ON FUNCTION public.fn_csmerge(grasslayer character varying) TO t3r_grafana;


--
-- TOC entry 5515 (class 0 OID 0)
-- Dependencies: 711
-- Name: FUNCTION fn_dlaction(character varying, character varying); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_dlaction(character varying, character varying) TO t3r;
GRANT ALL ON FUNCTION public.fn_dlaction(character varying, character varying) TO t3r_grafana;


--
-- TOC entry 5516 (class 0 OID 0)
-- Dependencies: 316
-- Name: FUNCTION fn_dltable(uuid); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_dltable(uuid) TO t3r;
GRANT ALL ON FUNCTION public.fn_dltable(uuid) TO t3r_grafana;


--
-- TOC entry 5517 (class 0 OID 0)
-- Dependencies: 422
-- Name: FUNCTION fn_dumpstgrows(integer); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_dumpstgrows(integer) TO t3r;
GRANT ALL ON FUNCTION public.fn_dumpstgrows(integer) TO t3r_grafana;


--
-- TOC entry 5518 (class 0 OID 0)
-- Dependencies: 495
-- Name: FUNCTION fn_freqrange(numeric, numeric, numeric); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_freqrange(numeric, numeric, numeric) TO t3r;
GRANT ALL ON FUNCTION public.fn_freqrange(numeric, numeric, numeric) TO t3r_grafana;


--
-- TOC entry 5519 (class 0 OID 0)
-- Dependencies: 432
-- Name: FUNCTION fn_getcountrycodetwo(lg public.geometry); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_getcountrycodetwo(lg public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.fn_getcountrycodetwo(lg public.geometry) TO t3r_grafana;


--
-- TOC entry 5520 (class 0 OID 0)
-- Dependencies: 766
-- Name: FUNCTION fn_getdistanceinmeters(lg1 public.geometry, lg2 public.geometry); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_getdistanceinmeters(lg1 public.geometry, lg2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.fn_getdistanceinmeters(lg1 public.geometry, lg2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5521 (class 0 OID 0)
-- Dependencies: 297
-- Name: FUNCTION fn_getmodelpath(model integer); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_getmodelpath(model integer) TO t3r;
GRANT ALL ON FUNCTION public.fn_getmodelpath(model integer) TO t3r_grafana;


--
-- TOC entry 5522 (class 0 OID 0)
-- Dependencies: 811
-- Name: FUNCTION fn_getnearestobject(model_id integer, lon numeric, lat numeric); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_getnearestobject(model_id integer, lon numeric, lat numeric) TO t3r;
GRANT ALL ON FUNCTION public.fn_getnearestobject(model_id integer, lon numeric, lat numeric) TO t3r_grafana;


--
-- TOC entry 5523 (class 0 OID 0)
-- Dependencies: 1045
-- Name: FUNCTION fn_gettilenumber(lg public.geometry); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_gettilenumber(lg public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.fn_gettilenumber(lg public.geometry) TO t3r_grafana;


--
-- TOC entry 5524 (class 0 OID 0)
-- Dependencies: 1132
-- Name: FUNCTION fn_gettilenumberxy(lon double precision, lat double precision); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_gettilenumberxy(lon double precision, lat double precision) TO t3r;
GRANT ALL ON FUNCTION public.fn_gettilenumberxy(lon double precision, lat double precision) TO t3r_grafana;


--
-- TOC entry 5525 (class 0 OID 0)
-- Dependencies: 1010
-- Name: FUNCTION fn_importrecordposttrigger(); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_importrecordposttrigger() TO t3r;
GRANT ALL ON FUNCTION public.fn_importrecordposttrigger() TO t3r_grafana;


--
-- TOC entry 5526 (class 0 OID 0)
-- Dependencies: 365
-- Name: FUNCTION fn_scenedir(public.geometry); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_scenedir(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.fn_scenedir(public.geometry) TO t3r_grafana;


--
-- TOC entry 5527 (class 0 OID 0)
-- Dependencies: 1047
-- Name: FUNCTION fn_scenesubdir(public.geometry); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_scenesubdir(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.fn_scenesubdir(public.geometry) TO t3r_grafana;


--
-- TOC entry 5528 (class 0 OID 0)
-- Dependencies: 969
-- Name: FUNCTION fn_setcsmodtime(); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_setcsmodtime() TO t3r;
GRANT ALL ON FUNCTION public.fn_setcsmodtime() TO t3r_grafana;


--
-- TOC entry 5529 (class 0 OID 0)
-- Dependencies: 425
-- Name: FUNCTION fn_setdate(); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_setdate() TO t3r;
GRANT ALL ON FUNCTION public.fn_setdate() TO t3r_grafana;


--
-- TOC entry 5530 (class 0 OID 0)
-- Dependencies: 855
-- Name: FUNCTION fn_setmodelmodtime(); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_setmodelmodtime() TO t3r;
GRANT ALL ON FUNCTION public.fn_setmodelmodtime() TO t3r_grafana;


--
-- TOC entry 5531 (class 0 OID 0)
-- Dependencies: 1127
-- Name: FUNCTION fn_setnewsmodtime(); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_setnewsmodtime() TO t3r;
GRANT ALL ON FUNCTION public.fn_setnewsmodtime() TO t3r_grafana;


--
-- TOC entry 5532 (class 0 OID 0)
-- Dependencies: 669
-- Name: FUNCTION fn_setobjectmodtime(); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_setobjectmodtime() TO t3r;
GRANT ALL ON FUNCTION public.fn_setobjectmodtime() TO t3r_grafana;


--
-- TOC entry 5533 (class 0 OID 0)
-- Dependencies: 652
-- Name: FUNCTION fn_setsignmodtime(); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_setsignmodtime() TO t3r;
GRANT ALL ON FUNCTION public.fn_setsignmodtime() TO t3r_grafana;


--
-- TOC entry 5534 (class 0 OID 0)
-- Dependencies: 825
-- Name: FUNCTION fn_stgelevation(numeric, numeric); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_stgelevation(numeric, numeric) TO t3r;
GRANT ALL ON FUNCTION public.fn_stgelevation(numeric, numeric) TO t3r_grafana;


--
-- TOC entry 5535 (class 0 OID 0)
-- Dependencies: 602
-- Name: FUNCTION fn_stgheading(numeric); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_stgheading(numeric) TO t3r;
GRANT ALL ON FUNCTION public.fn_stgheading(numeric) TO t3r_grafana;


--
-- TOC entry 5536 (class 0 OID 0)
-- Dependencies: 620
-- Name: FUNCTION fn_unrollmulti(layer character varying); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.fn_unrollmulti(layer character varying) TO t3r;
GRANT ALL ON FUNCTION public.fn_unrollmulti(layer character varying) TO t3r_grafana;


--
-- TOC entry 5537 (class 0 OID 0)
-- Dependencies: 920
-- Name: FUNCTION geog_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r_grafana;


--
-- TOC entry 5538 (class 0 OID 0)
-- Dependencies: 1012
-- Name: FUNCTION geography_cmp(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5539 (class 0 OID 0)
-- Dependencies: 690
-- Name: FUNCTION geography_distance_knn(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5540 (class 0 OID 0)
-- Dependencies: 656
-- Name: FUNCTION geography_eq(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5541 (class 0 OID 0)
-- Dependencies: 837
-- Name: FUNCTION geography_ge(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5542 (class 0 OID 0)
-- Dependencies: 916
-- Name: FUNCTION geography_gist_compress(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO t3r_grafana;


--
-- TOC entry 5543 (class 0 OID 0)
-- Dependencies: 588
-- Name: FUNCTION geography_gist_consistent(internal, public.geography, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO t3r;
GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO t3r_grafana;


--
-- TOC entry 5544 (class 0 OID 0)
-- Dependencies: 513
-- Name: FUNCTION geography_gist_decompress(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO t3r_grafana;


--
-- TOC entry 5545 (class 0 OID 0)
-- Dependencies: 1018
-- Name: FUNCTION geography_gist_distance(internal, public.geography, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO t3r;
GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO t3r_grafana;


--
-- TOC entry 5546 (class 0 OID 0)
-- Dependencies: 412
-- Name: FUNCTION geography_gist_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO t3r_grafana;


--
-- TOC entry 5547 (class 0 OID 0)
-- Dependencies: 545
-- Name: FUNCTION geography_gist_picksplit(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO t3r_grafana;


--
-- TOC entry 5548 (class 0 OID 0)
-- Dependencies: 802
-- Name: FUNCTION geography_gist_same(public.box2d, public.box2d, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO t3r_grafana;


--
-- TOC entry 5549 (class 0 OID 0)
-- Dependencies: 1129
-- Name: FUNCTION geography_gist_union(bytea, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO t3r_grafana;


--
-- TOC entry 5550 (class 0 OID 0)
-- Dependencies: 556
-- Name: FUNCTION geography_gt(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5551 (class 0 OID 0)
-- Dependencies: 1059
-- Name: FUNCTION geography_le(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5552 (class 0 OID 0)
-- Dependencies: 966
-- Name: FUNCTION geography_lt(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5553 (class 0 OID 0)
-- Dependencies: 997
-- Name: FUNCTION geography_overlaps(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5554 (class 0 OID 0)
-- Dependencies: 1123
-- Name: FUNCTION geography_spgist_choose_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5555 (class 0 OID 0)
-- Dependencies: 1001
-- Name: FUNCTION geography_spgist_compress_nd(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO t3r_grafana;


--
-- TOC entry 5556 (class 0 OID 0)
-- Dependencies: 791
-- Name: FUNCTION geography_spgist_config_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5557 (class 0 OID 0)
-- Dependencies: 598
-- Name: FUNCTION geography_spgist_inner_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5558 (class 0 OID 0)
-- Dependencies: 309
-- Name: FUNCTION geography_spgist_leaf_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5559 (class 0 OID 0)
-- Dependencies: 815
-- Name: FUNCTION geography_spgist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5560 (class 0 OID 0)
-- Dependencies: 705
-- Name: FUNCTION geom2d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r_grafana;


--
-- TOC entry 5561 (class 0 OID 0)
-- Dependencies: 1015
-- Name: FUNCTION geom3d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r_grafana;


--
-- TOC entry 5562 (class 0 OID 0)
-- Dependencies: 810
-- Name: FUNCTION geom4d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO t3r_grafana;


--
-- TOC entry 5563 (class 0 OID 0)
-- Dependencies: 615
-- Name: FUNCTION geometry_above(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5564 (class 0 OID 0)
-- Dependencies: 542
-- Name: FUNCTION geometry_below(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5565 (class 0 OID 0)
-- Dependencies: 1032
-- Name: FUNCTION geometry_cmp(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5566 (class 0 OID 0)
-- Dependencies: 727
-- Name: FUNCTION geometry_contained_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5567 (class 0 OID 0)
-- Dependencies: 938
-- Name: FUNCTION geometry_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5568 (class 0 OID 0)
-- Dependencies: 958
-- Name: FUNCTION geometry_contains_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5569 (class 0 OID 0)
-- Dependencies: 477
-- Name: FUNCTION geometry_contains_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 5570 (class 0 OID 0)
-- Dependencies: 1023
-- Name: FUNCTION geometry_distance_box(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5571 (class 0 OID 0)
-- Dependencies: 402
-- Name: FUNCTION geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5572 (class 0 OID 0)
-- Dependencies: 747
-- Name: FUNCTION geometry_distance_centroid_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 5573 (class 0 OID 0)
-- Dependencies: 332
-- Name: FUNCTION geometry_distance_cpa(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 5574 (class 0 OID 0)
-- Dependencies: 1026
-- Name: FUNCTION geometry_eq(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5575 (class 0 OID 0)
-- Dependencies: 818
-- Name: FUNCTION geometry_ge(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5576 (class 0 OID 0)
-- Dependencies: 299
-- Name: FUNCTION geometry_gist_compress_2d(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO t3r_grafana;


--
-- TOC entry 5577 (class 0 OID 0)
-- Dependencies: 464
-- Name: FUNCTION geometry_gist_compress_nd(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO t3r_grafana;


--
-- TOC entry 5578 (class 0 OID 0)
-- Dependencies: 293
-- Name: FUNCTION geometry_gist_consistent_2d(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5579 (class 0 OID 0)
-- Dependencies: 832
-- Name: FUNCTION geometry_gist_consistent_nd(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5580 (class 0 OID 0)
-- Dependencies: 971
-- Name: FUNCTION geometry_gist_decompress_2d(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO t3r_grafana;


--
-- TOC entry 5581 (class 0 OID 0)
-- Dependencies: 773
-- Name: FUNCTION geometry_gist_decompress_nd(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO t3r_grafana;


--
-- TOC entry 5582 (class 0 OID 0)
-- Dependencies: 521
-- Name: FUNCTION geometry_gist_distance_2d(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5583 (class 0 OID 0)
-- Dependencies: 1076
-- Name: FUNCTION geometry_gist_distance_nd(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5584 (class 0 OID 0)
-- Dependencies: 904
-- Name: FUNCTION geometry_gist_penalty_2d(internal, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO t3r_grafana;


--
-- TOC entry 5585 (class 0 OID 0)
-- Dependencies: 906
-- Name: FUNCTION geometry_gist_penalty_nd(internal, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO t3r_grafana;


--
-- TOC entry 5586 (class 0 OID 0)
-- Dependencies: 451
-- Name: FUNCTION geometry_gist_picksplit_2d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5587 (class 0 OID 0)
-- Dependencies: 976
-- Name: FUNCTION geometry_gist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5588 (class 0 OID 0)
-- Dependencies: 845
-- Name: FUNCTION geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO t3r_grafana;


--
-- TOC entry 5589 (class 0 OID 0)
-- Dependencies: 612
-- Name: FUNCTION geometry_gist_same_nd(public.geometry, public.geometry, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO t3r_grafana;


--
-- TOC entry 5590 (class 0 OID 0)
-- Dependencies: 746
-- Name: FUNCTION geometry_gist_sortsupport_2d(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO t3r_grafana;


--
-- TOC entry 5591 (class 0 OID 0)
-- Dependencies: 743
-- Name: FUNCTION geometry_gist_union_2d(bytea, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO t3r_grafana;


--
-- TOC entry 5592 (class 0 OID 0)
-- Dependencies: 949
-- Name: FUNCTION geometry_gist_union_nd(bytea, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO t3r_grafana;


--
-- TOC entry 5593 (class 0 OID 0)
-- Dependencies: 1048
-- Name: FUNCTION geometry_gt(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5594 (class 0 OID 0)
-- Dependencies: 831
-- Name: FUNCTION geometry_hash(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO t3r_grafana;


--
-- TOC entry 5595 (class 0 OID 0)
-- Dependencies: 1008
-- Name: FUNCTION geometry_le(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5596 (class 0 OID 0)
-- Dependencies: 964
-- Name: FUNCTION geometry_left(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5597 (class 0 OID 0)
-- Dependencies: 438
-- Name: FUNCTION geometry_lt(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5598 (class 0 OID 0)
-- Dependencies: 288
-- Name: FUNCTION geometry_overabove(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5599 (class 0 OID 0)
-- Dependencies: 939
-- Name: FUNCTION geometry_overbelow(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5600 (class 0 OID 0)
-- Dependencies: 1033
-- Name: FUNCTION geometry_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5601 (class 0 OID 0)
-- Dependencies: 784
-- Name: FUNCTION geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5602 (class 0 OID 0)
-- Dependencies: 945
-- Name: FUNCTION geometry_overlaps_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 5603 (class 0 OID 0)
-- Dependencies: 591
-- Name: FUNCTION geometry_overleft(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5604 (class 0 OID 0)
-- Dependencies: 329
-- Name: FUNCTION geometry_overright(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5605 (class 0 OID 0)
-- Dependencies: 771
-- Name: FUNCTION geometry_right(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5606 (class 0 OID 0)
-- Dependencies: 497
-- Name: FUNCTION geometry_same(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5607 (class 0 OID 0)
-- Dependencies: 350
-- Name: FUNCTION geometry_same_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5608 (class 0 OID 0)
-- Dependencies: 940
-- Name: FUNCTION geometry_same_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 5609 (class 0 OID 0)
-- Dependencies: 610
-- Name: FUNCTION geometry_sortsupport(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO t3r_grafana;


--
-- TOC entry 5610 (class 0 OID 0)
-- Dependencies: 373
-- Name: FUNCTION geometry_spgist_choose_2d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5611 (class 0 OID 0)
-- Dependencies: 358
-- Name: FUNCTION geometry_spgist_choose_3d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5612 (class 0 OID 0)
-- Dependencies: 541
-- Name: FUNCTION geometry_spgist_choose_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5613 (class 0 OID 0)
-- Dependencies: 868
-- Name: FUNCTION geometry_spgist_compress_2d(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO t3r_grafana;


--
-- TOC entry 5614 (class 0 OID 0)
-- Dependencies: 405
-- Name: FUNCTION geometry_spgist_compress_3d(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO t3r_grafana;


--
-- TOC entry 5615 (class 0 OID 0)
-- Dependencies: 421
-- Name: FUNCTION geometry_spgist_compress_nd(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO t3r_grafana;


--
-- TOC entry 5616 (class 0 OID 0)
-- Dependencies: 580
-- Name: FUNCTION geometry_spgist_config_2d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5617 (class 0 OID 0)
-- Dependencies: 416
-- Name: FUNCTION geometry_spgist_config_3d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5618 (class 0 OID 0)
-- Dependencies: 308
-- Name: FUNCTION geometry_spgist_config_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5619 (class 0 OID 0)
-- Dependencies: 419
-- Name: FUNCTION geometry_spgist_inner_consistent_2d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5620 (class 0 OID 0)
-- Dependencies: 549
-- Name: FUNCTION geometry_spgist_inner_consistent_3d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5621 (class 0 OID 0)
-- Dependencies: 576
-- Name: FUNCTION geometry_spgist_inner_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5622 (class 0 OID 0)
-- Dependencies: 912
-- Name: FUNCTION geometry_spgist_leaf_consistent_2d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5623 (class 0 OID 0)
-- Dependencies: 858
-- Name: FUNCTION geometry_spgist_leaf_consistent_3d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5624 (class 0 OID 0)
-- Dependencies: 807
-- Name: FUNCTION geometry_spgist_leaf_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5625 (class 0 OID 0)
-- Dependencies: 483
-- Name: FUNCTION geometry_spgist_picksplit_2d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5626 (class 0 OID 0)
-- Dependencies: 821
-- Name: FUNCTION geometry_spgist_picksplit_3d(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO t3r_grafana;


--
-- TOC entry 5627 (class 0 OID 0)
-- Dependencies: 496
-- Name: FUNCTION geometry_spgist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO t3r_grafana;


--
-- TOC entry 5628 (class 0 OID 0)
-- Dependencies: 413
-- Name: FUNCTION geometry_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5629 (class 0 OID 0)
-- Dependencies: 327
-- Name: FUNCTION geometry_within_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 5630 (class 0 OID 0)
-- Dependencies: 751
-- Name: FUNCTION geometrytype(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO t3r;
GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO t3r_grafana;


--
-- TOC entry 5631 (class 0 OID 0)
-- Dependencies: 631
-- Name: FUNCTION geometrytype(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO t3r_grafana;


--
-- TOC entry 5632 (class 0 OID 0)
-- Dependencies: 647
-- Name: FUNCTION geomfromewkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO t3r_grafana;


--
-- TOC entry 5633 (class 0 OID 0)
-- Dependencies: 1046
-- Name: FUNCTION geomfromewkt(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.geomfromewkt(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.geomfromewkt(text) TO t3r;
GRANT ALL ON FUNCTION public.geomfromewkt(text) TO t3r_grafana;


--
-- TOC entry 5634 (class 0 OID 0)
-- Dependencies: 1069
-- Name: FUNCTION get_proj4_from_srid(integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO t3r;
GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO t3r_grafana;


--
-- TOC entry 5635 (class 0 OID 0)
-- Dependencies: 303
-- Name: FUNCTION gettransactionid(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gettransactionid() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gettransactionid() TO t3r;
GRANT ALL ON FUNCTION public.gettransactionid() TO t3r_grafana;


--
-- TOC entry 5636 (class 0 OID 0)
-- Dependencies: 1050
-- Name: FUNCTION ghstore_compress(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_compress(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_compress(internal) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_compress(internal) TO t3r_grafana;


--
-- TOC entry 5637 (class 0 OID 0)
-- Dependencies: 984
-- Name: FUNCTION ghstore_consistent(internal, public.hstore, smallint, oid, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_consistent(internal, public.hstore, smallint, oid, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_consistent(internal, public.hstore, smallint, oid, internal) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_consistent(internal, public.hstore, smallint, oid, internal) TO t3r_grafana;


--
-- TOC entry 5638 (class 0 OID 0)
-- Dependencies: 475
-- Name: FUNCTION ghstore_decompress(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_decompress(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_decompress(internal) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_decompress(internal) TO t3r_grafana;


--
-- TOC entry 5639 (class 0 OID 0)
-- Dependencies: 633
-- Name: FUNCTION ghstore_options(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_options(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_options(internal) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_options(internal) TO t3r_grafana;


--
-- TOC entry 5640 (class 0 OID 0)
-- Dependencies: 461
-- Name: FUNCTION ghstore_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_penalty(internal, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_penalty(internal, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_penalty(internal, internal, internal) TO t3r_grafana;


--
-- TOC entry 5641 (class 0 OID 0)
-- Dependencies: 403
-- Name: FUNCTION ghstore_picksplit(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_picksplit(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_picksplit(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_picksplit(internal, internal) TO t3r_grafana;


--
-- TOC entry 5642 (class 0 OID 0)
-- Dependencies: 986
-- Name: FUNCTION ghstore_same(public.ghstore, public.ghstore, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_same(public.ghstore, public.ghstore, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_same(public.ghstore, public.ghstore, internal) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_same(public.ghstore, public.ghstore, internal) TO t3r_grafana;


--
-- TOC entry 5643 (class 0 OID 0)
-- Dependencies: 468
-- Name: FUNCTION ghstore_union(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.ghstore_union(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.ghstore_union(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.ghstore_union(internal, internal) TO t3r_grafana;


--
-- TOC entry 5644 (class 0 OID 0)
-- Dependencies: 1034
-- Name: FUNCTION gin_consistent_hstore(internal, smallint, public.hstore, integer, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gin_consistent_hstore(internal, smallint, public.hstore, integer, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gin_consistent_hstore(internal, smallint, public.hstore, integer, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.gin_consistent_hstore(internal, smallint, public.hstore, integer, internal, internal) TO t3r_grafana;


--
-- TOC entry 5645 (class 0 OID 0)
-- Dependencies: 823
-- Name: FUNCTION gin_extract_hstore(public.hstore, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gin_extract_hstore(public.hstore, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gin_extract_hstore(public.hstore, internal) TO t3r;
GRANT ALL ON FUNCTION public.gin_extract_hstore(public.hstore, internal) TO t3r_grafana;


--
-- TOC entry 5646 (class 0 OID 0)
-- Dependencies: 502
-- Name: FUNCTION gin_extract_hstore_query(public.hstore, internal, smallint, internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gin_extract_hstore_query(public.hstore, internal, smallint, internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gin_extract_hstore_query(public.hstore, internal, smallint, internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.gin_extract_hstore_query(public.hstore, internal, smallint, internal, internal) TO t3r_grafana;


--
-- TOC entry 5647 (class 0 OID 0)
-- Dependencies: 714
-- Name: FUNCTION gserialized_gist_joinsel_2d(internal, oid, internal, smallint); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO t3r;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO t3r_grafana;


--
-- TOC entry 5648 (class 0 OID 0)
-- Dependencies: 305
-- Name: FUNCTION gserialized_gist_joinsel_nd(internal, oid, internal, smallint); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO t3r;
GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO t3r_grafana;


--
-- TOC entry 5649 (class 0 OID 0)
-- Dependencies: 406
-- Name: FUNCTION gserialized_gist_sel_2d(internal, oid, internal, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO t3r;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO t3r_grafana;


--
-- TOC entry 5650 (class 0 OID 0)
-- Dependencies: 423
-- Name: FUNCTION gserialized_gist_sel_nd(internal, oid, internal, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO t3r;
GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO t3r_grafana;


--
-- TOC entry 5651 (class 0 OID 0)
-- Dependencies: 695
-- Name: FUNCTION hs_concat(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hs_concat(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hs_concat(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hs_concat(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5652 (class 0 OID 0)
-- Dependencies: 657
-- Name: FUNCTION hs_contained(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hs_contained(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hs_contained(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hs_contained(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5653 (class 0 OID 0)
-- Dependencies: 551
-- Name: FUNCTION hs_contains(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hs_contains(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hs_contains(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hs_contains(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5654 (class 0 OID 0)
-- Dependencies: 769
-- Name: FUNCTION hstore(record); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore(record) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore(record) TO t3r;
GRANT ALL ON FUNCTION public.hstore(record) TO t3r_grafana;


--
-- TOC entry 5655 (class 0 OID 0)
-- Dependencies: 540
-- Name: FUNCTION hstore(text[], text[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore(text[], text[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore(text[], text[]) TO t3r;
GRANT ALL ON FUNCTION public.hstore(text[], text[]) TO t3r_grafana;


--
-- TOC entry 5656 (class 0 OID 0)
-- Dependencies: 931
-- Name: FUNCTION hstore(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore(text, text) TO t3r;
GRANT ALL ON FUNCTION public.hstore(text, text) TO t3r_grafana;


--
-- TOC entry 5657 (class 0 OID 0)
-- Dependencies: 708
-- Name: FUNCTION hstore_cmp(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_cmp(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_cmp(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_cmp(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5658 (class 0 OID 0)
-- Dependencies: 375
-- Name: FUNCTION hstore_eq(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_eq(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_eq(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_eq(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5659 (class 0 OID 0)
-- Dependencies: 799
-- Name: FUNCTION hstore_ge(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_ge(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_ge(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_ge(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5660 (class 0 OID 0)
-- Dependencies: 780
-- Name: FUNCTION hstore_gt(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_gt(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_gt(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_gt(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5661 (class 0 OID 0)
-- Dependencies: 865
-- Name: FUNCTION hstore_hash(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_hash(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_hash(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_hash(public.hstore) TO t3r_grafana;


--
-- TOC entry 5662 (class 0 OID 0)
-- Dependencies: 1095
-- Name: FUNCTION hstore_hash_extended(public.hstore, bigint); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_hash_extended(public.hstore, bigint) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_hash_extended(public.hstore, bigint) TO t3r;
GRANT ALL ON FUNCTION public.hstore_hash_extended(public.hstore, bigint) TO t3r_grafana;


--
-- TOC entry 5663 (class 0 OID 0)
-- Dependencies: 401
-- Name: FUNCTION hstore_le(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_le(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_le(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_le(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5664 (class 0 OID 0)
-- Dependencies: 450
-- Name: FUNCTION hstore_lt(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_lt(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_lt(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_lt(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5665 (class 0 OID 0)
-- Dependencies: 1128
-- Name: FUNCTION hstore_ne(public.hstore, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_ne(public.hstore, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_ne(public.hstore, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_ne(public.hstore, public.hstore) TO t3r_grafana;


--
-- TOC entry 5666 (class 0 OID 0)
-- Dependencies: 328
-- Name: FUNCTION hstore_to_array(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_to_array(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_to_array(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_to_array(public.hstore) TO t3r_grafana;


--
-- TOC entry 5667 (class 0 OID 0)
-- Dependencies: 434
-- Name: FUNCTION hstore_to_json_loose(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_to_json_loose(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_to_json_loose(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_to_json_loose(public.hstore) TO t3r_grafana;


--
-- TOC entry 5668 (class 0 OID 0)
-- Dependencies: 752
-- Name: FUNCTION hstore_to_jsonb_loose(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_to_jsonb_loose(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_to_jsonb_loose(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_to_jsonb_loose(public.hstore) TO t3r_grafana;


--
-- TOC entry 5669 (class 0 OID 0)
-- Dependencies: 498
-- Name: FUNCTION hstore_to_matrix(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_to_matrix(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_to_matrix(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_to_matrix(public.hstore) TO t3r_grafana;


--
-- TOC entry 5670 (class 0 OID 0)
-- Dependencies: 505
-- Name: FUNCTION hstore_version_diag(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.hstore_version_diag(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.hstore_version_diag(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.hstore_version_diag(public.hstore) TO t3r_grafana;


--
-- TOC entry 5671 (class 0 OID 0)
-- Dependencies: 436
-- Name: FUNCTION icaorange(); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.icaorange() TO t3r;
GRANT ALL ON FUNCTION public.icaorange() TO t3r_grafana;


--
-- TOC entry 5672 (class 0 OID 0)
-- Dependencies: 1098
-- Name: FUNCTION icaorange(text); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.icaorange(text) TO t3r;
GRANT ALL ON FUNCTION public.icaorange(text) TO t3r_grafana;


--
-- TOC entry 5673 (class 0 OID 0)
-- Dependencies: 897
-- Name: FUNCTION icaorange(character varying); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.icaorange(character varying) TO t3r;
GRANT ALL ON FUNCTION public.icaorange(character varying) TO t3r_grafana;


--
-- TOC entry 5674 (class 0 OID 0)
-- Dependencies: 501
-- Name: FUNCTION is_contained_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO t3r;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO t3r_grafana;


--
-- TOC entry 5675 (class 0 OID 0)
-- Dependencies: 503
-- Name: FUNCTION is_contained_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO t3r_grafana;


--
-- TOC entry 5676 (class 0 OID 0)
-- Dependencies: 481
-- Name: FUNCTION is_contained_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO t3r;
GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO t3r_grafana;


--
-- TOC entry 5677 (class 0 OID 0)
-- Dependencies: 300
-- Name: FUNCTION isdefined(public.hstore, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.isdefined(public.hstore, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.isdefined(public.hstore, text) TO t3r;
GRANT ALL ON FUNCTION public.isdefined(public.hstore, text) TO t3r_grafana;


--
-- TOC entry 5678 (class 0 OID 0)
-- Dependencies: 775
-- Name: FUNCTION isexists(public.hstore, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.isexists(public.hstore, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.isexists(public.hstore, text) TO t3r;
GRANT ALL ON FUNCTION public.isexists(public.hstore, text) TO t3r_grafana;


--
-- TOC entry 5679 (class 0 OID 0)
-- Dependencies: 376
-- Name: FUNCTION lockrow(text, text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO t3r;
GRANT ALL ON FUNCTION public.lockrow(text, text, text) TO t3r_grafana;


--
-- TOC entry 5680 (class 0 OID 0)
-- Dependencies: 487
-- Name: FUNCTION lockrow(text, text, text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO t3r;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text) TO t3r_grafana;


--
-- TOC entry 5681 (class 0 OID 0)
-- Dependencies: 917
-- Name: FUNCTION lockrow(text, text, text, timestamp without time zone); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO t3r;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO t3r_grafana;


--
-- TOC entry 5682 (class 0 OID 0)
-- Dependencies: 926
-- Name: FUNCTION lockrow(text, text, text, text, timestamp without time zone); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO t3r;
GRANT ALL ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO t3r_grafana;


--
-- TOC entry 5683 (class 0 OID 0)
-- Dependencies: 942
-- Name: FUNCTION longtransactionsenabled(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.longtransactionsenabled() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.longtransactionsenabled() TO t3r;
GRANT ALL ON FUNCTION public.longtransactionsenabled() TO t3r_grafana;


--
-- TOC entry 5684 (class 0 OID 0)
-- Dependencies: 393
-- Name: FUNCTION next_mo_id(integer); Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON FUNCTION public.next_mo_id(integer) TO t3r;
GRANT ALL ON FUNCTION public.next_mo_id(integer) TO t3r_grafana;


--
-- TOC entry 5685 (class 0 OID 0)
-- Dependencies: 639
-- Name: FUNCTION overlaps_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO t3r;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO t3r_grafana;


--
-- TOC entry 5686 (class 0 OID 0)
-- Dependencies: 563
-- Name: FUNCTION overlaps_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO t3r_grafana;


--
-- TOC entry 5687 (class 0 OID 0)
-- Dependencies: 524
-- Name: FUNCTION overlaps_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO t3r;
GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO t3r_grafana;


--
-- TOC entry 5688 (class 0 OID 0)
-- Dependencies: 885
-- Name: FUNCTION overlaps_geog(public.geography, public.gidx); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO t3r;
GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO t3r_grafana;


--
-- TOC entry 5689 (class 0 OID 0)
-- Dependencies: 595
-- Name: FUNCTION overlaps_geog(public.gidx, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO t3r_grafana;


--
-- TOC entry 5690 (class 0 OID 0)
-- Dependencies: 893
-- Name: FUNCTION overlaps_geog(public.gidx, public.gidx); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO t3r;
GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO t3r_grafana;


--
-- TOC entry 5691 (class 0 OID 0)
-- Dependencies: 347
-- Name: FUNCTION overlaps_nd(public.geometry, public.gidx); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO t3r;
GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO t3r_grafana;


--
-- TOC entry 5692 (class 0 OID 0)
-- Dependencies: 774
-- Name: FUNCTION overlaps_nd(public.gidx, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO t3r_grafana;


--
-- TOC entry 5693 (class 0 OID 0)
-- Dependencies: 898
-- Name: FUNCTION overlaps_nd(public.gidx, public.gidx); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO t3r;
GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO t3r_grafana;


--
-- TOC entry 5694 (class 0 OID 0)
-- Dependencies: 374
-- Name: FUNCTION pgis_asflatgeobuf_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5695 (class 0 OID 0)
-- Dependencies: 359
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO t3r_grafana;


--
-- TOC entry 5696 (class 0 OID 0)
-- Dependencies: 414
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO t3r_grafana;


--
-- TOC entry 5697 (class 0 OID 0)
-- Dependencies: 882
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO t3r_grafana;


--
-- TOC entry 5698 (class 0 OID 0)
-- Dependencies: 1113
-- Name: FUNCTION pgis_asgeobuf_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5699 (class 0 OID 0)
-- Dependencies: 869
-- Name: FUNCTION pgis_asgeobuf_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO t3r_grafana;


--
-- TOC entry 5700 (class 0 OID 0)
-- Dependencies: 841
-- Name: FUNCTION pgis_asgeobuf_transfn(internal, anyelement, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO t3r_grafana;


--
-- TOC entry 5701 (class 0 OID 0)
-- Dependencies: 699
-- Name: FUNCTION pgis_asmvt_combinefn(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO t3r_grafana;


--
-- TOC entry 5702 (class 0 OID 0)
-- Dependencies: 465
-- Name: FUNCTION pgis_asmvt_deserialfn(bytea, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO t3r_grafana;


--
-- TOC entry 5703 (class 0 OID 0)
-- Dependencies: 294
-- Name: FUNCTION pgis_asmvt_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5704 (class 0 OID 0)
-- Dependencies: 935
-- Name: FUNCTION pgis_asmvt_serialfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO t3r_grafana;


--
-- TOC entry 5705 (class 0 OID 0)
-- Dependencies: 492
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO t3r_grafana;


--
-- TOC entry 5706 (class 0 OID 0)
-- Dependencies: 760
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO t3r_grafana;


--
-- TOC entry 5707 (class 0 OID 0)
-- Dependencies: 1044
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO t3r_grafana;


--
-- TOC entry 5708 (class 0 OID 0)
-- Dependencies: 499
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO t3r_grafana;


--
-- TOC entry 5709 (class 0 OID 0)
-- Dependencies: 384
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer, text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO t3r;
GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO t3r_grafana;


--
-- TOC entry 5710 (class 0 OID 0)
-- Dependencies: 512
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO t3r_grafana;


--
-- TOC entry 5711 (class 0 OID 0)
-- Dependencies: 932
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5712 (class 0 OID 0)
-- Dependencies: 409
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO t3r_grafana;


--
-- TOC entry 5713 (class 0 OID 0)
-- Dependencies: 531
-- Name: FUNCTION pgis_geometry_clusterintersecting_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5714 (class 0 OID 0)
-- Dependencies: 514
-- Name: FUNCTION pgis_geometry_clusterwithin_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5715 (class 0 OID 0)
-- Dependencies: 567
-- Name: FUNCTION pgis_geometry_collect_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5716 (class 0 OID 0)
-- Dependencies: 411
-- Name: FUNCTION pgis_geometry_coverageunion_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_coverageunion_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_coverageunion_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_coverageunion_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5717 (class 0 OID 0)
-- Dependencies: 1116
-- Name: FUNCTION pgis_geometry_makeline_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5718 (class 0 OID 0)
-- Dependencies: 640
-- Name: FUNCTION pgis_geometry_polygonize_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5719 (class 0 OID 0)
-- Dependencies: 318
-- Name: FUNCTION pgis_geometry_union_parallel_combinefn(internal, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO t3r_grafana;


--
-- TOC entry 5720 (class 0 OID 0)
-- Dependencies: 1068
-- Name: FUNCTION pgis_geometry_union_parallel_deserialfn(bytea, internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO t3r_grafana;


--
-- TOC entry 5721 (class 0 OID 0)
-- Dependencies: 928
-- Name: FUNCTION pgis_geometry_union_parallel_finalfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO t3r_grafana;


--
-- TOC entry 5722 (class 0 OID 0)
-- Dependencies: 362
-- Name: FUNCTION pgis_geometry_union_parallel_serialfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO t3r_grafana;


--
-- TOC entry 5723 (class 0 OID 0)
-- Dependencies: 955
-- Name: FUNCTION pgis_geometry_union_parallel_transfn(internal, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO t3r_grafana;


--
-- TOC entry 5724 (class 0 OID 0)
-- Dependencies: 649
-- Name: FUNCTION pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5725 (class 0 OID 0)
-- Dependencies: 594
-- Name: FUNCTION populate_geometry_columns(use_typmod boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO t3r;
GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO t3r_grafana;


--
-- TOC entry 5726 (class 0 OID 0)
-- Dependencies: 697
-- Name: FUNCTION populate_geometry_columns(tbl_oid oid, use_typmod boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO t3r;
GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO t3r_grafana;


--
-- TOC entry 5727 (class 0 OID 0)
-- Dependencies: 950
-- Name: FUNCTION populate_record(anyelement, public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.populate_record(anyelement, public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.populate_record(anyelement, public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.populate_record(anyelement, public.hstore) TO t3r_grafana;


--
-- TOC entry 5728 (class 0 OID 0)
-- Dependencies: 279
-- Name: FUNCTION postgis_addbbox(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO t3r_grafana;


--
-- TOC entry 5729 (class 0 OID 0)
-- Dependencies: 936
-- Name: FUNCTION postgis_cache_bbox(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO t3r;
GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO t3r_grafana;


--
-- TOC entry 5730 (class 0 OID 0)
-- Dependencies: 590
-- Name: FUNCTION postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO t3r;
GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO t3r_grafana;


--
-- TOC entry 5731 (class 0 OID 0)
-- Dependencies: 538
-- Name: FUNCTION postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO t3r;
GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO t3r_grafana;


--
-- TOC entry 5732 (class 0 OID 0)
-- Dependencies: 525
-- Name: FUNCTION postgis_constraint_type(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO t3r;
GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO t3r_grafana;


--
-- TOC entry 5733 (class 0 OID 0)
-- Dependencies: 975
-- Name: FUNCTION postgis_dropbbox(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO t3r_grafana;


--
-- TOC entry 5734 (class 0 OID 0)
-- Dependencies: 877
-- Name: FUNCTION postgis_extensions_upgrade(target_version text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_extensions_upgrade(target_version text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_extensions_upgrade(target_version text) TO t3r;
GRANT ALL ON FUNCTION public.postgis_extensions_upgrade(target_version text) TO t3r_grafana;


--
-- TOC entry 5735 (class 0 OID 0)
-- Dependencies: 301
-- Name: FUNCTION postgis_full_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_full_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_full_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_full_version() TO t3r_grafana;


--
-- TOC entry 5736 (class 0 OID 0)
-- Dependencies: 737
-- Name: FUNCTION postgis_geos_compiled_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_geos_compiled_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_geos_compiled_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_geos_compiled_version() TO t3r_grafana;


--
-- TOC entry 5737 (class 0 OID 0)
-- Dependencies: 311
-- Name: FUNCTION postgis_geos_noop(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO t3r_grafana;


--
-- TOC entry 5738 (class 0 OID 0)
-- Dependencies: 321
-- Name: FUNCTION postgis_geos_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_geos_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_geos_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_geos_version() TO t3r_grafana;


--
-- TOC entry 5739 (class 0 OID 0)
-- Dependencies: 476
-- Name: FUNCTION postgis_getbbox(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO t3r_grafana;


--
-- TOC entry 5740 (class 0 OID 0)
-- Dependencies: 290
-- Name: FUNCTION postgis_hasbbox(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO t3r_grafana;


--
-- TOC entry 5741 (class 0 OID 0)
-- Dependencies: 666
-- Name: FUNCTION postgis_index_supportfn(internal); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO t3r;
GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO t3r_grafana;


--
-- TOC entry 5742 (class 0 OID 0)
-- Dependencies: 314
-- Name: FUNCTION postgis_lib_build_date(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO t3r;
GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO t3r_grafana;


--
-- TOC entry 5743 (class 0 OID 0)
-- Dependencies: 523
-- Name: FUNCTION postgis_lib_revision(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_lib_revision() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_lib_revision() TO t3r;
GRANT ALL ON FUNCTION public.postgis_lib_revision() TO t3r_grafana;


--
-- TOC entry 5744 (class 0 OID 0)
-- Dependencies: 658
-- Name: FUNCTION postgis_lib_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_lib_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_lib_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_lib_version() TO t3r_grafana;


--
-- TOC entry 5745 (class 0 OID 0)
-- Dependencies: 973
-- Name: FUNCTION postgis_libjson_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_libjson_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_libjson_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_libjson_version() TO t3r_grafana;


--
-- TOC entry 5746 (class 0 OID 0)
-- Dependencies: 1006
-- Name: FUNCTION postgis_liblwgeom_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO t3r_grafana;


--
-- TOC entry 5747 (class 0 OID 0)
-- Dependencies: 490
-- Name: FUNCTION postgis_libprotobuf_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO t3r_grafana;


--
-- TOC entry 5748 (class 0 OID 0)
-- Dependencies: 449
-- Name: FUNCTION postgis_libxml_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_libxml_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_libxml_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_libxml_version() TO t3r_grafana;


--
-- TOC entry 5749 (class 0 OID 0)
-- Dependencies: 779
-- Name: FUNCTION postgis_noop(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO t3r_grafana;


--
-- TOC entry 5750 (class 0 OID 0)
-- Dependencies: 417
-- Name: FUNCTION postgis_proj_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_proj_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_proj_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_proj_version() TO t3r_grafana;


--
-- TOC entry 5751 (class 0 OID 0)
-- Dependencies: 758
-- Name: FUNCTION postgis_scripts_build_date(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO t3r;
GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO t3r_grafana;


--
-- TOC entry 5752 (class 0 OID 0)
-- Dependencies: 519
-- Name: FUNCTION postgis_scripts_installed(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO t3r;
GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO t3r_grafana;


--
-- TOC entry 5753 (class 0 OID 0)
-- Dependencies: 712
-- Name: FUNCTION postgis_scripts_released(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_scripts_released() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_scripts_released() TO t3r;
GRANT ALL ON FUNCTION public.postgis_scripts_released() TO t3r_grafana;


--
-- TOC entry 5754 (class 0 OID 0)
-- Dependencies: 749
-- Name: FUNCTION postgis_srs(auth_name text, auth_srid text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_srs(auth_name text, auth_srid text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_srs(auth_name text, auth_srid text) TO t3r;
GRANT ALL ON FUNCTION public.postgis_srs(auth_name text, auth_srid text) TO t3r_grafana;


--
-- TOC entry 5755 (class 0 OID 0)
-- Dependencies: 1064
-- Name: FUNCTION postgis_srs_all(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_srs_all() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_srs_all() TO t3r;
GRANT ALL ON FUNCTION public.postgis_srs_all() TO t3r_grafana;


--
-- TOC entry 5756 (class 0 OID 0)
-- Dependencies: 978
-- Name: FUNCTION postgis_srs_codes(auth_name text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_srs_codes(auth_name text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_srs_codes(auth_name text) TO t3r;
GRANT ALL ON FUNCTION public.postgis_srs_codes(auth_name text) TO t3r_grafana;


--
-- TOC entry 5757 (class 0 OID 0)
-- Dependencies: 479
-- Name: FUNCTION postgis_srs_search(bounds public.geometry, authname text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_srs_search(bounds public.geometry, authname text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_srs_search(bounds public.geometry, authname text) TO t3r;
GRANT ALL ON FUNCTION public.postgis_srs_search(bounds public.geometry, authname text) TO t3r_grafana;


--
-- TOC entry 5758 (class 0 OID 0)
-- Dependencies: 918
-- Name: FUNCTION postgis_svn_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_svn_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_svn_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_svn_version() TO t3r_grafana;


--
-- TOC entry 5759 (class 0 OID 0)
-- Dependencies: 768
-- Name: FUNCTION postgis_transform_geometry(geom public.geometry, text, text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO t3r;
GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO t3r_grafana;


--
-- TOC entry 5760 (class 0 OID 0)
-- Dependencies: 891
-- Name: FUNCTION postgis_transform_pipeline_geometry(geom public.geometry, pipeline text, forward boolean, to_srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_transform_pipeline_geometry(geom public.geometry, pipeline text, forward boolean, to_srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_transform_pipeline_geometry(geom public.geometry, pipeline text, forward boolean, to_srid integer) TO t3r;
GRANT ALL ON FUNCTION public.postgis_transform_pipeline_geometry(geom public.geometry, pipeline text, forward boolean, to_srid integer) TO t3r_grafana;


--
-- TOC entry 5761 (class 0 OID 0)
-- Dependencies: 934
-- Name: FUNCTION postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO t3r;
GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO t3r_grafana;


--
-- TOC entry 5762 (class 0 OID 0)
-- Dependencies: 883
-- Name: FUNCTION postgis_typmod_dims(integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO t3r;
GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO t3r_grafana;


--
-- TOC entry 5763 (class 0 OID 0)
-- Dependencies: 827
-- Name: FUNCTION postgis_typmod_srid(integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO t3r;
GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO t3r_grafana;


--
-- TOC entry 5764 (class 0 OID 0)
-- Dependencies: 970
-- Name: FUNCTION postgis_typmod_type(integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO t3r;
GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO t3r_grafana;


--
-- TOC entry 5765 (class 0 OID 0)
-- Dependencies: 719
-- Name: FUNCTION postgis_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_version() TO t3r_grafana;


--
-- TOC entry 5766 (class 0 OID 0)
-- Dependencies: 407
-- Name: FUNCTION postgis_wagyu_version(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO t3r;
GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO t3r_grafana;


--
-- TOC entry 5767 (class 0 OID 0)
-- Dependencies: 878
-- Name: FUNCTION skeys(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.skeys(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.skeys(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.skeys(public.hstore) TO t3r_grafana;


--
-- TOC entry 5768 (class 0 OID 0)
-- Dependencies: 696
-- Name: FUNCTION slice(public.hstore, text[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.slice(public.hstore, text[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.slice(public.hstore, text[]) TO t3r;
GRANT ALL ON FUNCTION public.slice(public.hstore, text[]) TO t3r_grafana;


--
-- TOC entry 5769 (class 0 OID 0)
-- Dependencies: 1085
-- Name: FUNCTION slice_array(public.hstore, text[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.slice_array(public.hstore, text[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.slice_array(public.hstore, text[]) TO t3r;
GRANT ALL ON FUNCTION public.slice_array(public.hstore, text[]) TO t3r_grafana;


--
-- TOC entry 5770 (class 0 OID 0)
-- Dependencies: 892
-- Name: FUNCTION st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5771 (class 0 OID 0)
-- Dependencies: 664
-- Name: FUNCTION st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5772 (class 0 OID 0)
-- Dependencies: 601
-- Name: FUNCTION st_3ddistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5773 (class 0 OID 0)
-- Dependencies: 642
-- Name: FUNCTION st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5774 (class 0 OID 0)
-- Dependencies: 963
-- Name: FUNCTION st_3dintersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5775 (class 0 OID 0)
-- Dependencies: 271
-- Name: FUNCTION st_3dlength(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO t3r_grafana;


--
-- TOC entry 5776 (class 0 OID 0)
-- Dependencies: 980
-- Name: FUNCTION st_3dlineinterpolatepoint(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5777 (class 0 OID 0)
-- Dependencies: 608
-- Name: FUNCTION st_3dlongestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5778 (class 0 OID 0)
-- Dependencies: 793
-- Name: FUNCTION st_3dmakebox(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5779 (class 0 OID 0)
-- Dependencies: 668
-- Name: FUNCTION st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5780 (class 0 OID 0)
-- Dependencies: 446
-- Name: FUNCTION st_3dperimeter(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO t3r_grafana;


--
-- TOC entry 5781 (class 0 OID 0)
-- Dependencies: 1058
-- Name: FUNCTION st_3dshortestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5782 (class 0 OID 0)
-- Dependencies: 704
-- Name: FUNCTION st_addmeasure(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 5783 (class 0 OID 0)
-- Dependencies: 370
-- Name: FUNCTION st_addpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5784 (class 0 OID 0)
-- Dependencies: 510
-- Name: FUNCTION st_addpoint(geom1 public.geometry, geom2 public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5785 (class 0 OID 0)
-- Dependencies: 452
-- Name: FUNCTION st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 5786 (class 0 OID 0)
-- Dependencies: 1105
-- Name: FUNCTION st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 5787 (class 0 OID 0)
-- Dependencies: 618
-- Name: FUNCTION st_angle(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5788 (class 0 OID 0)
-- Dependencies: 861
-- Name: FUNCTION st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO t3r_grafana;


--
-- TOC entry 5789 (class 0 OID 0)
-- Dependencies: 673
-- Name: FUNCTION st_area(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_area(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_area(text) TO t3r;
GRANT ALL ON FUNCTION public.st_area(text) TO t3r_grafana;


--
-- TOC entry 5790 (class 0 OID 0)
-- Dependencies: 806
-- Name: FUNCTION st_area(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_area(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_area(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_area(public.geometry) TO t3r_grafana;


--
-- TOC entry 5791 (class 0 OID 0)
-- Dependencies: 930
-- Name: FUNCTION st_area(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 5792 (class 0 OID 0)
-- Dependencies: 881
-- Name: FUNCTION st_area2d(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO t3r_grafana;


--
-- TOC entry 5793 (class 0 OID 0)
-- Dependencies: 1134
-- Name: FUNCTION st_asbinary(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO t3r_grafana;


--
-- TOC entry 5794 (class 0 OID 0)
-- Dependencies: 546
-- Name: FUNCTION st_asbinary(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO t3r_grafana;


--
-- TOC entry 5795 (class 0 OID 0)
-- Dependencies: 866
-- Name: FUNCTION st_asbinary(public.geography, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO t3r;
GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO t3r_grafana;


--
-- TOC entry 5796 (class 0 OID 0)
-- Dependencies: 511
-- Name: FUNCTION st_asbinary(public.geometry, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO t3r;
GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO t3r_grafana;


--
-- TOC entry 5797 (class 0 OID 0)
-- Dependencies: 919
-- Name: FUNCTION st_asencodedpolyline(geom public.geometry, nprecision integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO t3r;
GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO t3r_grafana;


--
-- TOC entry 5798 (class 0 OID 0)
-- Dependencies: 284
-- Name: FUNCTION st_asewkb(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO t3r_grafana;


--
-- TOC entry 5799 (class 0 OID 0)
-- Dependencies: 1078
-- Name: FUNCTION st_asewkb(public.geometry, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO t3r;
GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO t3r_grafana;


--
-- TOC entry 5800 (class 0 OID 0)
-- Dependencies: 1112
-- Name: FUNCTION st_asewkt(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asewkt(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asewkt(text) TO t3r;
GRANT ALL ON FUNCTION public.st_asewkt(text) TO t3r_grafana;


--
-- TOC entry 5801 (class 0 OID 0)
-- Dependencies: 1130
-- Name: FUNCTION st_asewkt(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO t3r_grafana;


--
-- TOC entry 5802 (class 0 OID 0)
-- Dependencies: 701
-- Name: FUNCTION st_asewkt(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO t3r_grafana;


--
-- TOC entry 5803 (class 0 OID 0)
-- Dependencies: 707
-- Name: FUNCTION st_asewkt(public.geography, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO t3r_grafana;


--
-- TOC entry 5804 (class 0 OID 0)
-- Dependencies: 740
-- Name: FUNCTION st_asewkt(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5805 (class 0 OID 0)
-- Dependencies: 671
-- Name: FUNCTION st_asgeojson(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgeojson(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgeojson(text) TO t3r;
GRANT ALL ON FUNCTION public.st_asgeojson(text) TO t3r_grafana;


--
-- TOC entry 5806 (class 0 OID 0)
-- Dependencies: 894
-- Name: FUNCTION st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO t3r;
GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO t3r_grafana;


--
-- TOC entry 5807 (class 0 OID 0)
-- Dependencies: 730
-- Name: FUNCTION st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO t3r;
GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO t3r_grafana;


--
-- TOC entry 5808 (class 0 OID 0)
-- Dependencies: 455
-- Name: FUNCTION st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO t3r_grafana;


--
-- TOC entry 5809 (class 0 OID 0)
-- Dependencies: 790
-- Name: FUNCTION st_asgml(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgml(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgml(text) TO t3r;
GRANT ALL ON FUNCTION public.st_asgml(text) TO t3r_grafana;


--
-- TOC entry 5810 (class 0 OID 0)
-- Dependencies: 951
-- Name: FUNCTION st_asgml(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO t3r;
GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO t3r_grafana;


--
-- TOC entry 5811 (class 0 OID 0)
-- Dependencies: 941
-- Name: FUNCTION st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO t3r;
GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO t3r_grafana;


--
-- TOC entry 5812 (class 0 OID 0)
-- Dependencies: 998
-- Name: FUNCTION st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO t3r;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO t3r_grafana;


--
-- TOC entry 5813 (class 0 OID 0)
-- Dependencies: 574
-- Name: FUNCTION st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO t3r;
GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO t3r_grafana;


--
-- TOC entry 5814 (class 0 OID 0)
-- Dependencies: 1079
-- Name: FUNCTION st_ashexewkb(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO t3r_grafana;


--
-- TOC entry 5815 (class 0 OID 0)
-- Dependencies: 1062
-- Name: FUNCTION st_ashexewkb(public.geometry, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO t3r;
GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO t3r_grafana;


--
-- TOC entry 5816 (class 0 OID 0)
-- Dependencies: 592
-- Name: FUNCTION st_askml(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_askml(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_askml(text) TO t3r;
GRANT ALL ON FUNCTION public.st_askml(text) TO t3r_grafana;


--
-- TOC entry 5817 (class 0 OID 0)
-- Dependencies: 391
-- Name: FUNCTION st_askml(geog public.geography, maxdecimaldigits integer, nprefix text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO t3r;
GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO t3r_grafana;


--
-- TOC entry 5818 (class 0 OID 0)
-- Dependencies: 735
-- Name: FUNCTION st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO t3r;
GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO t3r_grafana;


--
-- TOC entry 5819 (class 0 OID 0)
-- Dependencies: 331
-- Name: FUNCTION st_aslatlontext(geom public.geometry, tmpl text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO t3r;
GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO t3r_grafana;


--
-- TOC entry 5820 (class 0 OID 0)
-- Dependencies: 680
-- Name: FUNCTION st_asmarc21(geom public.geometry, format text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO t3r;
GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO t3r_grafana;


--
-- TOC entry 5821 (class 0 OID 0)
-- Dependencies: 710
-- Name: FUNCTION st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO t3r_grafana;


--
-- TOC entry 5822 (class 0 OID 0)
-- Dependencies: 453
-- Name: FUNCTION st_assvg(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_assvg(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_assvg(text) TO t3r;
GRANT ALL ON FUNCTION public.st_assvg(text) TO t3r_grafana;


--
-- TOC entry 5823 (class 0 OID 0)
-- Dependencies: 281
-- Name: FUNCTION st_assvg(geog public.geography, rel integer, maxdecimaldigits integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO t3r;
GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO t3r_grafana;


--
-- TOC entry 5824 (class 0 OID 0)
-- Dependencies: 313
-- Name: FUNCTION st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO t3r;
GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO t3r_grafana;


--
-- TOC entry 5825 (class 0 OID 0)
-- Dependencies: 987
-- Name: FUNCTION st_astext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_astext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_astext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_astext(text) TO t3r_grafana;


--
-- TOC entry 5826 (class 0 OID 0)
-- Dependencies: 589
-- Name: FUNCTION st_astext(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_astext(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_astext(public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_astext(public.geography) TO t3r_grafana;


--
-- TOC entry 5827 (class 0 OID 0)
-- Dependencies: 1075
-- Name: FUNCTION st_astext(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO t3r_grafana;


--
-- TOC entry 5828 (class 0 OID 0)
-- Dependencies: 630
-- Name: FUNCTION st_astext(public.geography, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO t3r_grafana;


--
-- TOC entry 5829 (class 0 OID 0)
-- Dependencies: 862
-- Name: FUNCTION st_astext(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5830 (class 0 OID 0)
-- Dependencies: 400
-- Name: FUNCTION st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO t3r_grafana;


--
-- TOC entry 5831 (class 0 OID 0)
-- Dependencies: 1126
-- Name: FUNCTION st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO t3r_grafana;


--
-- TOC entry 5832 (class 0 OID 0)
-- Dependencies: 1030
-- Name: FUNCTION st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO t3r;
GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO t3r_grafana;


--
-- TOC entry 5833 (class 0 OID 0)
-- Dependencies: 1093
-- Name: FUNCTION st_azimuth(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO t3r_grafana;


--
-- TOC entry 5834 (class 0 OID 0)
-- Dependencies: 653
-- Name: FUNCTION st_azimuth(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5835 (class 0 OID 0)
-- Dependencies: 609
-- Name: FUNCTION st_bdmpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 5836 (class 0 OID 0)
-- Dependencies: 353
-- Name: FUNCTION st_bdpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 5837 (class 0 OID 0)
-- Dependencies: 292
-- Name: FUNCTION st_boundary(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO t3r_grafana;


--
-- TOC entry 5838 (class 0 OID 0)
-- Dependencies: 834
-- Name: FUNCTION st_boundingdiagonal(geom public.geometry, fits boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO t3r_grafana;


--
-- TOC entry 5839 (class 0 OID 0)
-- Dependencies: 726
-- Name: FUNCTION st_box2dfromgeohash(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO t3r_grafana;


--
-- TOC entry 5840 (class 0 OID 0)
-- Dependencies: 967
-- Name: FUNCTION st_buffer(text, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO t3r_grafana;


--
-- TOC entry 5841 (class 0 OID 0)
-- Dependencies: 860
-- Name: FUNCTION st_buffer(public.geography, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO t3r_grafana;


--
-- TOC entry 5842 (class 0 OID 0)
-- Dependencies: 952
-- Name: FUNCTION st_buffer(text, double precision, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO t3r_grafana;


--
-- TOC entry 5843 (class 0 OID 0)
-- Dependencies: 343
-- Name: FUNCTION st_buffer(text, double precision, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO t3r;
GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO t3r_grafana;


--
-- TOC entry 5844 (class 0 OID 0)
-- Dependencies: 460
-- Name: FUNCTION st_buffer(public.geography, double precision, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO t3r_grafana;


--
-- TOC entry 5845 (class 0 OID 0)
-- Dependencies: 360
-- Name: FUNCTION st_buffer(public.geography, double precision, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO t3r;
GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO t3r_grafana;


--
-- TOC entry 5846 (class 0 OID 0)
-- Dependencies: 689
-- Name: FUNCTION st_buffer(geom public.geometry, radius double precision, quadsegs integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO t3r;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO t3r_grafana;


--
-- TOC entry 5847 (class 0 OID 0)
-- Dependencies: 996
-- Name: FUNCTION st_buffer(geom public.geometry, radius double precision, options text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO t3r;
GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO t3r_grafana;


--
-- TOC entry 5848 (class 0 OID 0)
-- Dependencies: 754
-- Name: FUNCTION st_buildarea(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO t3r_grafana;


--
-- TOC entry 5849 (class 0 OID 0)
-- Dependencies: 874
-- Name: FUNCTION st_centroid(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_centroid(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_centroid(text) TO t3r;
GRANT ALL ON FUNCTION public.st_centroid(text) TO t3r_grafana;


--
-- TOC entry 5850 (class 0 OID 0)
-- Dependencies: 797
-- Name: FUNCTION st_centroid(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO t3r_grafana;


--
-- TOC entry 5851 (class 0 OID 0)
-- Dependencies: 559
-- Name: FUNCTION st_centroid(public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 5852 (class 0 OID 0)
-- Dependencies: 462
-- Name: FUNCTION st_chaikinsmoothing(public.geometry, integer, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO t3r_grafana;


--
-- TOC entry 5853 (class 0 OID 0)
-- Dependencies: 323
-- Name: FUNCTION st_cleangeometry(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO t3r_grafana;


--
-- TOC entry 5854 (class 0 OID 0)
-- Dependencies: 1122
-- Name: FUNCTION st_clipbybox2d(geom public.geometry, box public.box2d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO t3r;
GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO t3r_grafana;


--
-- TOC entry 5855 (class 0 OID 0)
-- Dependencies: 558
-- Name: FUNCTION st_closestpoint(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_closestpoint(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_closestpoint(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_closestpoint(text, text) TO t3r_grafana;


--
-- TOC entry 5856 (class 0 OID 0)
-- Dependencies: 534
-- Name: FUNCTION st_closestpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5857 (class 0 OID 0)
-- Dependencies: 1110
-- Name: FUNCTION st_closestpoint(public.geography, public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_closestpoint(public.geography, public.geography, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_closestpoint(public.geography, public.geography, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_closestpoint(public.geography, public.geography, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 5858 (class 0 OID 0)
-- Dependencies: 872
-- Name: FUNCTION st_closestpointofapproach(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 5859 (class 0 OID 0)
-- Dependencies: 1027
-- Name: FUNCTION st_clusterdbscan(public.geometry, eps double precision, minpoints integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO t3r;
GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO t3r_grafana;


--
-- TOC entry 5860 (class 0 OID 0)
-- Dependencies: 388
-- Name: FUNCTION st_clusterintersecting(public.geometry[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO t3r;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO t3r_grafana;


--
-- TOC entry 5861 (class 0 OID 0)
-- Dependencies: 539
-- Name: FUNCTION st_clusterintersectingwin(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_clusterintersectingwin(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_clusterintersectingwin(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_clusterintersectingwin(public.geometry) TO t3r_grafana;


--
-- TOC entry 5862 (class 0 OID 0)
-- Dependencies: 338
-- Name: FUNCTION st_clusterkmeans(geom public.geometry, k integer, max_radius double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO t3r_grafana;


--
-- TOC entry 5863 (class 0 OID 0)
-- Dependencies: 472
-- Name: FUNCTION st_clusterwithin(public.geometry[], double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO t3r_grafana;


--
-- TOC entry 5864 (class 0 OID 0)
-- Dependencies: 377
-- Name: FUNCTION st_clusterwithinwin(public.geometry, distance double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_clusterwithinwin(public.geometry, distance double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_clusterwithinwin(public.geometry, distance double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_clusterwithinwin(public.geometry, distance double precision) TO t3r_grafana;


--
-- TOC entry 5865 (class 0 OID 0)
-- Dependencies: 873
-- Name: FUNCTION st_collect(public.geometry[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO t3r;
GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO t3r_grafana;


--
-- TOC entry 5866 (class 0 OID 0)
-- Dependencies: 334
-- Name: FUNCTION st_collect(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5867 (class 0 OID 0)
-- Dependencies: 1081
-- Name: FUNCTION st_collectionextract(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO t3r_grafana;


--
-- TOC entry 5868 (class 0 OID 0)
-- Dependencies: 839
-- Name: FUNCTION st_collectionextract(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5869 (class 0 OID 0)
-- Dependencies: 1028
-- Name: FUNCTION st_collectionhomogenize(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO t3r_grafana;


--
-- TOC entry 5870 (class 0 OID 0)
-- Dependencies: 386
-- Name: FUNCTION st_combinebbox(public.box2d, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO t3r_grafana;


--
-- TOC entry 5871 (class 0 OID 0)
-- Dependencies: 276
-- Name: FUNCTION st_combinebbox(public.box3d, public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO t3r_grafana;


--
-- TOC entry 5872 (class 0 OID 0)
-- Dependencies: 725
-- Name: FUNCTION st_combinebbox(public.box3d, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO t3r_grafana;


--
-- TOC entry 5873 (class 0 OID 0)
-- Dependencies: 1094
-- Name: FUNCTION st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO t3r_grafana;


--
-- TOC entry 5874 (class 0 OID 0)
-- Dependencies: 389
-- Name: FUNCTION st_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5875 (class 0 OID 0)
-- Dependencies: 960
-- Name: FUNCTION st_containsproperly(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5876 (class 0 OID 0)
-- Dependencies: 1099
-- Name: FUNCTION st_convexhull(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO t3r_grafana;


--
-- TOC entry 5877 (class 0 OID 0)
-- Dependencies: 596
-- Name: FUNCTION st_coorddim(geometry public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO t3r_grafana;


--
-- TOC entry 5878 (class 0 OID 0)
-- Dependencies: 280
-- Name: FUNCTION st_coverageinvalidedges(geom public.geometry, tolerance double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_coverageinvalidedges(geom public.geometry, tolerance double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_coverageinvalidedges(geom public.geometry, tolerance double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_coverageinvalidedges(geom public.geometry, tolerance double precision) TO t3r_grafana;


--
-- TOC entry 5879 (class 0 OID 0)
-- Dependencies: 295
-- Name: FUNCTION st_coveragesimplify(geom public.geometry, tolerance double precision, simplifyboundary boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_coveragesimplify(geom public.geometry, tolerance double precision, simplifyboundary boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_coveragesimplify(geom public.geometry, tolerance double precision, simplifyboundary boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_coveragesimplify(geom public.geometry, tolerance double precision, simplifyboundary boolean) TO t3r_grafana;


--
-- TOC entry 5880 (class 0 OID 0)
-- Dependencies: 1043
-- Name: FUNCTION st_coverageunion(public.geometry[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry[]) TO t3r;
GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry[]) TO t3r_grafana;


--
-- TOC entry 5881 (class 0 OID 0)
-- Dependencies: 717
-- Name: FUNCTION st_coveredby(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO t3r_grafana;


--
-- TOC entry 5882 (class 0 OID 0)
-- Dependencies: 859
-- Name: FUNCTION st_coveredby(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO t3r_grafana;


--
-- TOC entry 5883 (class 0 OID 0)
-- Dependencies: 676
-- Name: FUNCTION st_coveredby(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5884 (class 0 OID 0)
-- Dependencies: 1070
-- Name: FUNCTION st_covers(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_covers(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_covers(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_covers(text, text) TO t3r_grafana;


--
-- TOC entry 5885 (class 0 OID 0)
-- Dependencies: 857
-- Name: FUNCTION st_covers(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO t3r_grafana;


--
-- TOC entry 5886 (class 0 OID 0)
-- Dependencies: 982
-- Name: FUNCTION st_covers(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5887 (class 0 OID 0)
-- Dependencies: 723
-- Name: FUNCTION st_cpawithin(public.geometry, public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5888 (class 0 OID 0)
-- Dependencies: 532
-- Name: FUNCTION st_crosses(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5889 (class 0 OID 0)
-- Dependencies: 371
-- Name: FUNCTION st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO t3r;
GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO t3r_grafana;


--
-- TOC entry 5890 (class 0 OID 0)
-- Dependencies: 688
-- Name: FUNCTION st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO t3r;
GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO t3r_grafana;


--
-- TOC entry 5891 (class 0 OID 0)
-- Dependencies: 1107
-- Name: FUNCTION st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5892 (class 0 OID 0)
-- Dependencies: 379
-- Name: FUNCTION st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r_grafana;


--
-- TOC entry 5893 (class 0 OID 0)
-- Dependencies: 410
-- Name: FUNCTION st_dimension(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO t3r_grafana;


--
-- TOC entry 5894 (class 0 OID 0)
-- Dependencies: 796
-- Name: FUNCTION st_disjoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5895 (class 0 OID 0)
-- Dependencies: 349
-- Name: FUNCTION st_distance(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_distance(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_distance(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_distance(text, text) TO t3r_grafana;


--
-- TOC entry 5896 (class 0 OID 0)
-- Dependencies: 854
-- Name: FUNCTION st_distance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5897 (class 0 OID 0)
-- Dependencies: 953
-- Name: FUNCTION st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 5898 (class 0 OID 0)
-- Dependencies: 344
-- Name: FUNCTION st_distancecpa(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 5899 (class 0 OID 0)
-- Dependencies: 776
-- Name: FUNCTION st_distancesphere(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5900 (class 0 OID 0)
-- Dependencies: 809
-- Name: FUNCTION st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO t3r_grafana;


--
-- TOC entry 5901 (class 0 OID 0)
-- Dependencies: 706
-- Name: FUNCTION st_distancespheroid(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5902 (class 0 OID 0)
-- Dependencies: 693
-- Name: FUNCTION st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO t3r;
GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO t3r_grafana;


--
-- TOC entry 5903 (class 0 OID 0)
-- Dependencies: 340
-- Name: FUNCTION st_dump(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO t3r_grafana;


--
-- TOC entry 5904 (class 0 OID 0)
-- Dependencies: 579
-- Name: FUNCTION st_dumppoints(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO t3r_grafana;


--
-- TOC entry 5905 (class 0 OID 0)
-- Dependencies: 786
-- Name: FUNCTION st_dumprings(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO t3r_grafana;


--
-- TOC entry 5906 (class 0 OID 0)
-- Dependencies: 946
-- Name: FUNCTION st_dumpsegments(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO t3r_grafana;


--
-- TOC entry 5907 (class 0 OID 0)
-- Dependencies: 750
-- Name: FUNCTION st_dwithin(text, text, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO t3r_grafana;


--
-- TOC entry 5908 (class 0 OID 0)
-- Dependencies: 469
-- Name: FUNCTION st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5909 (class 0 OID 0)
-- Dependencies: 544
-- Name: FUNCTION st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 5910 (class 0 OID 0)
-- Dependencies: 677
-- Name: FUNCTION st_endpoint(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO t3r_grafana;


--
-- TOC entry 5911 (class 0 OID 0)
-- Dependencies: 915
-- Name: FUNCTION st_envelope(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO t3r_grafana;


--
-- TOC entry 5912 (class 0 OID 0)
-- Dependencies: 650
-- Name: FUNCTION st_equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5913 (class 0 OID 0)
-- Dependencies: 456
-- Name: FUNCTION st_estimatedextent(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO t3r_grafana;


--
-- TOC entry 5914 (class 0 OID 0)
-- Dependencies: 478
-- Name: FUNCTION st_estimatedextent(text, text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO t3r_grafana;


--
-- TOC entry 5915 (class 0 OID 0)
-- Dependencies: 1084
-- Name: FUNCTION st_estimatedextent(text, text, text, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO t3r_grafana;


--
-- TOC entry 5916 (class 0 OID 0)
-- Dependencies: 336
-- Name: FUNCTION st_expand(public.box2d, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO t3r_grafana;


--
-- TOC entry 5917 (class 0 OID 0)
-- Dependencies: 489
-- Name: FUNCTION st_expand(public.box3d, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO t3r_grafana;


--
-- TOC entry 5918 (class 0 OID 0)
-- Dependencies: 817
-- Name: FUNCTION st_expand(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5919 (class 0 OID 0)
-- Dependencies: 480
-- Name: FUNCTION st_expand(box public.box2d, dx double precision, dy double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO t3r_grafana;


--
-- TOC entry 5920 (class 0 OID 0)
-- Dependencies: 341
-- Name: FUNCTION st_expand(box public.box3d, dx double precision, dy double precision, dz double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO t3r_grafana;


--
-- TOC entry 5921 (class 0 OID 0)
-- Dependencies: 315
-- Name: FUNCTION st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO t3r_grafana;


--
-- TOC entry 5922 (class 0 OID 0)
-- Dependencies: 486
-- Name: FUNCTION st_exteriorring(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO t3r_grafana;


--
-- TOC entry 5923 (class 0 OID 0)
-- Dependencies: 1124
-- Name: FUNCTION st_filterbym(public.geometry, double precision, double precision, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO t3r_grafana;


--
-- TOC entry 5924 (class 0 OID 0)
-- Dependencies: 835
-- Name: FUNCTION st_findextent(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_findextent(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_findextent(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_findextent(text, text) TO t3r_grafana;


--
-- TOC entry 5925 (class 0 OID 0)
-- Dependencies: 670
-- Name: FUNCTION st_findextent(text, text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO t3r_grafana;


--
-- TOC entry 5926 (class 0 OID 0)
-- Dependencies: 871
-- Name: FUNCTION st_flipcoordinates(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO t3r_grafana;


--
-- TOC entry 5927 (class 0 OID 0)
-- Dependencies: 573
-- Name: FUNCTION st_force2d(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO t3r_grafana;


--
-- TOC entry 5928 (class 0 OID 0)
-- Dependencies: 1131
-- Name: FUNCTION st_force3d(geom public.geometry, zvalue double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO t3r_grafana;


--
-- TOC entry 5929 (class 0 OID 0)
-- Dependencies: 564
-- Name: FUNCTION st_force3dm(geom public.geometry, mvalue double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO t3r_grafana;


--
-- TOC entry 5930 (class 0 OID 0)
-- Dependencies: 842
-- Name: FUNCTION st_force3dz(geom public.geometry, zvalue double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO t3r_grafana;


--
-- TOC entry 5931 (class 0 OID 0)
-- Dependencies: 494
-- Name: FUNCTION st_force4d(geom public.geometry, zvalue double precision, mvalue double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO t3r_grafana;


--
-- TOC entry 5932 (class 0 OID 0)
-- Dependencies: 473
-- Name: FUNCTION st_forcecollection(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO t3r_grafana;


--
-- TOC entry 5933 (class 0 OID 0)
-- Dependencies: 570
-- Name: FUNCTION st_forcecurve(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO t3r_grafana;


--
-- TOC entry 5934 (class 0 OID 0)
-- Dependencies: 603
-- Name: FUNCTION st_forcepolygonccw(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO t3r_grafana;


--
-- TOC entry 5935 (class 0 OID 0)
-- Dependencies: 1133
-- Name: FUNCTION st_forcepolygoncw(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO t3r_grafana;


--
-- TOC entry 5936 (class 0 OID 0)
-- Dependencies: 566
-- Name: FUNCTION st_forcerhr(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO t3r_grafana;


--
-- TOC entry 5937 (class 0 OID 0)
-- Dependencies: 900
-- Name: FUNCTION st_forcesfs(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO t3r_grafana;


--
-- TOC entry 5938 (class 0 OID 0)
-- Dependencies: 272
-- Name: FUNCTION st_forcesfs(public.geometry, version text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO t3r;
GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO t3r_grafana;


--
-- TOC entry 5939 (class 0 OID 0)
-- Dependencies: 278
-- Name: FUNCTION st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5940 (class 0 OID 0)
-- Dependencies: 585
-- Name: FUNCTION st_fromflatgeobuf(anyelement, bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO t3r_grafana;


--
-- TOC entry 5941 (class 0 OID 0)
-- Dependencies: 965
-- Name: FUNCTION st_fromflatgeobuftotable(text, text, bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO t3r_grafana;


--
-- TOC entry 5942 (class 0 OID 0)
-- Dependencies: 369
-- Name: FUNCTION st_generatepoints(area public.geometry, npoints integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO t3r;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO t3r_grafana;


--
-- TOC entry 5943 (class 0 OID 0)
-- Dependencies: 1037
-- Name: FUNCTION st_generatepoints(area public.geometry, npoints integer, seed integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO t3r;
GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO t3r_grafana;


--
-- TOC entry 5944 (class 0 OID 0)
-- Dependencies: 732
-- Name: FUNCTION st_geogfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO t3r_grafana;


--
-- TOC entry 5945 (class 0 OID 0)
-- Dependencies: 635
-- Name: FUNCTION st_geogfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 5946 (class 0 OID 0)
-- Dependencies: 833
-- Name: FUNCTION st_geographyfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO t3r_grafana;


--
-- TOC entry 5947 (class 0 OID 0)
-- Dependencies: 724
-- Name: FUNCTION st_geohash(geog public.geography, maxchars integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO t3r_grafana;


--
-- TOC entry 5948 (class 0 OID 0)
-- Dependencies: 296
-- Name: FUNCTION st_geohash(geom public.geometry, maxchars integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO t3r_grafana;


--
-- TOC entry 5949 (class 0 OID 0)
-- Dependencies: 317
-- Name: FUNCTION st_geomcollfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO t3r_grafana;


--
-- TOC entry 5950 (class 0 OID 0)
-- Dependencies: 500
-- Name: FUNCTION st_geomcollfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 5951 (class 0 OID 0)
-- Dependencies: 901
-- Name: FUNCTION st_geomcollfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 5952 (class 0 OID 0)
-- Dependencies: 944
-- Name: FUNCTION st_geomcollfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 5953 (class 0 OID 0)
-- Dependencies: 659
-- Name: FUNCTION st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO t3r_grafana;


--
-- TOC entry 5954 (class 0 OID 0)
-- Dependencies: 516
-- Name: FUNCTION st_geometryfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO t3r_grafana;


--
-- TOC entry 5955 (class 0 OID 0)
-- Dependencies: 674
-- Name: FUNCTION st_geometryfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 5956 (class 0 OID 0)
-- Dependencies: 972
-- Name: FUNCTION st_geometryn(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5957 (class 0 OID 0)
-- Dependencies: 522
-- Name: FUNCTION st_geometrytype(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO t3r_grafana;


--
-- TOC entry 5958 (class 0 OID 0)
-- Dependencies: 838
-- Name: FUNCTION st_geomfromewkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO t3r_grafana;


--
-- TOC entry 5959 (class 0 OID 0)
-- Dependencies: 485
-- Name: FUNCTION st_geomfromewkt(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO t3r_grafana;


--
-- TOC entry 5960 (class 0 OID 0)
-- Dependencies: 578
-- Name: FUNCTION st_geomfromgeohash(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO t3r_grafana;


--
-- TOC entry 5961 (class 0 OID 0)
-- Dependencies: 829
-- Name: FUNCTION st_geomfromgeojson(json); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO t3r_grafana;


--
-- TOC entry 5962 (class 0 OID 0)
-- Dependencies: 625
-- Name: FUNCTION st_geomfromgeojson(jsonb); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO t3r_grafana;


--
-- TOC entry 5963 (class 0 OID 0)
-- Dependencies: 819
-- Name: FUNCTION st_geomfromgeojson(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO t3r_grafana;


--
-- TOC entry 5964 (class 0 OID 0)
-- Dependencies: 993
-- Name: FUNCTION st_geomfromgml(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO t3r_grafana;


--
-- TOC entry 5965 (class 0 OID 0)
-- Dependencies: 1071
-- Name: FUNCTION st_geomfromgml(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO t3r_grafana;


--
-- TOC entry 5966 (class 0 OID 0)
-- Dependencies: 713
-- Name: FUNCTION st_geomfromkml(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO t3r_grafana;


--
-- TOC entry 5967 (class 0 OID 0)
-- Dependencies: 408
-- Name: FUNCTION st_geomfrommarc21(marc21xml text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO t3r_grafana;


--
-- TOC entry 5968 (class 0 OID 0)
-- Dependencies: 440
-- Name: FUNCTION st_geomfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO t3r_grafana;


--
-- TOC entry 5969 (class 0 OID 0)
-- Dependencies: 550
-- Name: FUNCTION st_geomfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 5970 (class 0 OID 0)
-- Dependencies: 856
-- Name: FUNCTION st_geomfromtwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO t3r_grafana;


--
-- TOC entry 5971 (class 0 OID 0)
-- Dependencies: 646
-- Name: FUNCTION st_geomfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 5972 (class 0 OID 0)
-- Dependencies: 1000
-- Name: FUNCTION st_geomfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 5973 (class 0 OID 0)
-- Dependencies: 848
-- Name: FUNCTION st_gmltosql(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_gmltosql(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_gmltosql(text) TO t3r;
GRANT ALL ON FUNCTION public.st_gmltosql(text) TO t3r_grafana;


--
-- TOC entry 5974 (class 0 OID 0)
-- Dependencies: 655
-- Name: FUNCTION st_gmltosql(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO t3r_grafana;


--
-- TOC entry 5975 (class 0 OID 0)
-- Dependencies: 812
-- Name: FUNCTION st_hasarc(geometry public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO t3r_grafana;


--
-- TOC entry 5976 (class 0 OID 0)
-- Dependencies: 1106
-- Name: FUNCTION st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5977 (class 0 OID 0)
-- Dependencies: 1022
-- Name: FUNCTION st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 5978 (class 0 OID 0)
-- Dependencies: 956
-- Name: FUNCTION st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO t3r_grafana;


--
-- TOC entry 5979 (class 0 OID 0)
-- Dependencies: 428
-- Name: FUNCTION st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO t3r;
GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO t3r_grafana;


--
-- TOC entry 5980 (class 0 OID 0)
-- Dependencies: 850
-- Name: FUNCTION st_interiorringn(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5981 (class 0 OID 0)
-- Dependencies: 333
-- Name: FUNCTION st_interpolatepoint(line public.geometry, point public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO t3r_grafana;


--
-- TOC entry 5982 (class 0 OID 0)
-- Dependencies: 382
-- Name: FUNCTION st_intersection(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_intersection(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_intersection(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_intersection(text, text) TO t3r_grafana;


--
-- TOC entry 5983 (class 0 OID 0)
-- Dependencies: 648
-- Name: FUNCTION st_intersection(public.geography, public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO t3r_grafana;


--
-- TOC entry 5984 (class 0 OID 0)
-- Dependencies: 565
-- Name: FUNCTION st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r_grafana;


--
-- TOC entry 5985 (class 0 OID 0)
-- Dependencies: 937
-- Name: FUNCTION st_intersects(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_intersects(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_intersects(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_intersects(text, text) TO t3r_grafana;


--
-- TOC entry 5986 (class 0 OID 0)
-- Dependencies: 518
-- Name: FUNCTION st_intersects(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO t3r_grafana;


--
-- TOC entry 5987 (class 0 OID 0)
-- Dependencies: 345
-- Name: FUNCTION st_intersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 5988 (class 0 OID 0)
-- Dependencies: 366
-- Name: FUNCTION st_inversetransformpipeline(geom public.geometry, pipeline text, to_srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_inversetransformpipeline(geom public.geometry, pipeline text, to_srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_inversetransformpipeline(geom public.geometry, pipeline text, to_srid integer) TO t3r;
GRANT ALL ON FUNCTION public.st_inversetransformpipeline(geom public.geometry, pipeline text, to_srid integer) TO t3r_grafana;


--
-- TOC entry 5989 (class 0 OID 0)
-- Dependencies: 876
-- Name: FUNCTION st_isclosed(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO t3r_grafana;


--
-- TOC entry 5990 (class 0 OID 0)
-- Dependencies: 307
-- Name: FUNCTION st_iscollection(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO t3r_grafana;


--
-- TOC entry 5991 (class 0 OID 0)
-- Dependencies: 342
-- Name: FUNCTION st_isempty(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO t3r_grafana;


--
-- TOC entry 5992 (class 0 OID 0)
-- Dependencies: 537
-- Name: FUNCTION st_ispolygonccw(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO t3r_grafana;


--
-- TOC entry 5993 (class 0 OID 0)
-- Dependencies: 914
-- Name: FUNCTION st_ispolygoncw(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO t3r_grafana;


--
-- TOC entry 5994 (class 0 OID 0)
-- Dependencies: 1125
-- Name: FUNCTION st_isring(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO t3r_grafana;


--
-- TOC entry 5995 (class 0 OID 0)
-- Dependencies: 1036
-- Name: FUNCTION st_issimple(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO t3r_grafana;


--
-- TOC entry 5996 (class 0 OID 0)
-- Dependencies: 778
-- Name: FUNCTION st_isvalid(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO t3r_grafana;


--
-- TOC entry 5997 (class 0 OID 0)
-- Dependencies: 1020
-- Name: FUNCTION st_isvalid(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 5998 (class 0 OID 0)
-- Dependencies: 836
-- Name: FUNCTION st_isvaliddetail(geom public.geometry, flags integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO t3r;
GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO t3r_grafana;


--
-- TOC entry 5999 (class 0 OID 0)
-- Dependencies: 634
-- Name: FUNCTION st_isvalidreason(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO t3r_grafana;


--
-- TOC entry 6000 (class 0 OID 0)
-- Dependencies: 954
-- Name: FUNCTION st_isvalidreason(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 6001 (class 0 OID 0)
-- Dependencies: 385
-- Name: FUNCTION st_isvalidtrajectory(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO t3r_grafana;


--
-- TOC entry 6002 (class 0 OID 0)
-- Dependencies: 354
-- Name: FUNCTION st_largestemptycircle(geom public.geometry, tolerance double precision, boundary public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_largestemptycircle(geom public.geometry, tolerance double precision, boundary public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_largestemptycircle(geom public.geometry, tolerance double precision, boundary public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_largestemptycircle(geom public.geometry, tolerance double precision, boundary public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO t3r_grafana;


--
-- TOC entry 6003 (class 0 OID 0)
-- Dependencies: 571
-- Name: FUNCTION st_length(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_length(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_length(text) TO t3r;
GRANT ALL ON FUNCTION public.st_length(text) TO t3r_grafana;


--
-- TOC entry 6004 (class 0 OID 0)
-- Dependencies: 804
-- Name: FUNCTION st_length(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_length(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_length(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_length(public.geometry) TO t3r_grafana;


--
-- TOC entry 6005 (class 0 OID 0)
-- Dependencies: 397
-- Name: FUNCTION st_length(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 6006 (class 0 OID 0)
-- Dependencies: 509
-- Name: FUNCTION st_length2d(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO t3r_grafana;


--
-- TOC entry 6007 (class 0 OID 0)
-- Dependencies: 320
-- Name: FUNCTION st_length2dspheroid(public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO t3r;
GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO t3r_grafana;


--
-- TOC entry 6008 (class 0 OID 0)
-- Dependencies: 348
-- Name: FUNCTION st_lengthspheroid(public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO t3r;
GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO t3r_grafana;


--
-- TOC entry 6009 (class 0 OID 0)
-- Dependencies: 756
-- Name: FUNCTION st_letters(letters text, font json); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO t3r;
GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO t3r_grafana;


--
-- TOC entry 6010 (class 0 OID 0)
-- Dependencies: 698
-- Name: FUNCTION st_linecrossingdirection(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6011 (class 0 OID 0)
-- Dependencies: 352
-- Name: FUNCTION st_lineextend(geom public.geometry, distance_forward double precision, distance_backward double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_lineextend(geom public.geometry, distance_forward double precision, distance_backward double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_lineextend(geom public.geometry, distance_forward double precision, distance_backward double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_lineextend(geom public.geometry, distance_forward double precision, distance_backward double precision) TO t3r_grafana;


--
-- TOC entry 6012 (class 0 OID 0)
-- Dependencies: 681
-- Name: FUNCTION st_linefromencodedpolyline(txtin text, nprecision integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO t3r;
GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO t3r_grafana;


--
-- TOC entry 6013 (class 0 OID 0)
-- Dependencies: 808
-- Name: FUNCTION st_linefrommultipoint(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO t3r_grafana;


--
-- TOC entry 6014 (class 0 OID 0)
-- Dependencies: 764
-- Name: FUNCTION st_linefromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linefromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linefromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_linefromtext(text) TO t3r_grafana;


--
-- TOC entry 6015 (class 0 OID 0)
-- Dependencies: 526
-- Name: FUNCTION st_linefromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 6016 (class 0 OID 0)
-- Dependencies: 1073
-- Name: FUNCTION st_linefromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6017 (class 0 OID 0)
-- Dependencies: 795
-- Name: FUNCTION st_linefromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6018 (class 0 OID 0)
-- Dependencies: 621
-- Name: FUNCTION st_lineinterpolatepoint(text, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(text, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(text, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(text, double precision) TO t3r_grafana;


--
-- TOC entry 6019 (class 0 OID 0)
-- Dependencies: 380
-- Name: FUNCTION st_lineinterpolatepoint(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6020 (class 0 OID 0)
-- Dependencies: 277
-- Name: FUNCTION st_lineinterpolatepoint(public.geography, double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geography, double precision, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geography, double precision, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geography, double precision, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 6021 (class 0 OID 0)
-- Dependencies: 739
-- Name: FUNCTION st_lineinterpolatepoints(text, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(text, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(text, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(text, double precision) TO t3r_grafana;


--
-- TOC entry 6022 (class 0 OID 0)
-- Dependencies: 372
-- Name: FUNCTION st_lineinterpolatepoints(public.geometry, double precision, repeat boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO t3r_grafana;


--
-- TOC entry 6023 (class 0 OID 0)
-- Dependencies: 398
-- Name: FUNCTION st_lineinterpolatepoints(public.geography, double precision, use_spheroid boolean, repeat boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geography, double precision, use_spheroid boolean, repeat boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geography, double precision, use_spheroid boolean, repeat boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geography, double precision, use_spheroid boolean, repeat boolean) TO t3r_grafana;


--
-- TOC entry 6024 (class 0 OID 0)
-- Dependencies: 777
-- Name: FUNCTION st_linelocatepoint(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linelocatepoint(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_linelocatepoint(text, text) TO t3r_grafana;


--
-- TOC entry 6025 (class 0 OID 0)
-- Dependencies: 1102
-- Name: FUNCTION st_linelocatepoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6026 (class 0 OID 0)
-- Dependencies: 394
-- Name: FUNCTION st_linelocatepoint(public.geography, public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(public.geography, public.geography, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linelocatepoint(public.geography, public.geography, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_linelocatepoint(public.geography, public.geography, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 6027 (class 0 OID 0)
-- Dependencies: 991
-- Name: FUNCTION st_linemerge(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO t3r_grafana;


--
-- TOC entry 6028 (class 0 OID 0)
-- Dependencies: 687
-- Name: FUNCTION st_linemerge(public.geometry, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO t3r_grafana;


--
-- TOC entry 6029 (class 0 OID 0)
-- Dependencies: 614
-- Name: FUNCTION st_linestringfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6030 (class 0 OID 0)
-- Dependencies: 515
-- Name: FUNCTION st_linestringfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6031 (class 0 OID 0)
-- Dependencies: 628
-- Name: FUNCTION st_linesubstring(text, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linesubstring(text, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linesubstring(text, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_linesubstring(text, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6032 (class 0 OID 0)
-- Dependencies: 745
-- Name: FUNCTION st_linesubstring(public.geography, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linesubstring(public.geography, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linesubstring(public.geography, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_linesubstring(public.geography, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6033 (class 0 OID 0)
-- Dependencies: 624
-- Name: FUNCTION st_linesubstring(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6034 (class 0 OID 0)
-- Dependencies: 623
-- Name: FUNCTION st_linetocurve(geometry public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO t3r_grafana;


--
-- TOC entry 6035 (class 0 OID 0)
-- Dependencies: 619
-- Name: FUNCTION st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO t3r_grafana;


--
-- TOC entry 6036 (class 0 OID 0)
-- Dependencies: 337
-- Name: FUNCTION st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO t3r_grafana;


--
-- TOC entry 6037 (class 0 OID 0)
-- Dependencies: 1025
-- Name: FUNCTION st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO t3r_grafana;


--
-- TOC entry 6038 (class 0 OID 0)
-- Dependencies: 654
-- Name: FUNCTION st_longestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6039 (class 0 OID 0)
-- Dependencies: 390
-- Name: FUNCTION st_m(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_m(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_m(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_m(public.geometry) TO t3r_grafana;


--
-- TOC entry 6040 (class 0 OID 0)
-- Dependencies: 383
-- Name: FUNCTION st_makebox2d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6041 (class 0 OID 0)
-- Dependencies: 721
-- Name: FUNCTION st_makeenvelope(double precision, double precision, double precision, double precision, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO t3r_grafana;


--
-- TOC entry 6042 (class 0 OID 0)
-- Dependencies: 1039
-- Name: FUNCTION st_makeline(public.geometry[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO t3r;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO t3r_grafana;


--
-- TOC entry 6043 (class 0 OID 0)
-- Dependencies: 1080
-- Name: FUNCTION st_makeline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6044 (class 0 OID 0)
-- Dependencies: 1017
-- Name: FUNCTION st_makepoint(double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6045 (class 0 OID 0)
-- Dependencies: 597
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6046 (class 0 OID 0)
-- Dependencies: 864
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6047 (class 0 OID 0)
-- Dependencies: 692
-- Name: FUNCTION st_makepointm(double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6048 (class 0 OID 0)
-- Dependencies: 755
-- Name: FUNCTION st_makepolygon(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO t3r_grafana;


--
-- TOC entry 6049 (class 0 OID 0)
-- Dependencies: 339
-- Name: FUNCTION st_makepolygon(public.geometry, public.geometry[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO t3r;
GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO t3r_grafana;


--
-- TOC entry 6050 (class 0 OID 0)
-- Dependencies: 285
-- Name: FUNCTION st_makevalid(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO t3r_grafana;


--
-- TOC entry 6051 (class 0 OID 0)
-- Dependencies: 399
-- Name: FUNCTION st_makevalid(geom public.geometry, params text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO t3r;
GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO t3r_grafana;


--
-- TOC entry 6052 (class 0 OID 0)
-- Dependencies: 302
-- Name: FUNCTION st_maxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6053 (class 0 OID 0)
-- Dependencies: 759
-- Name: FUNCTION st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO t3r_grafana;


--
-- TOC entry 6054 (class 0 OID 0)
-- Dependencies: 484
-- Name: FUNCTION st_memsize(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO t3r_grafana;


--
-- TOC entry 6055 (class 0 OID 0)
-- Dependencies: 816
-- Name: FUNCTION st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO t3r;
GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO t3r_grafana;


--
-- TOC entry 6056 (class 0 OID 0)
-- Dependencies: 801
-- Name: FUNCTION st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO t3r_grafana;


--
-- TOC entry 6057 (class 0 OID 0)
-- Dependencies: 1057
-- Name: FUNCTION st_minimumclearance(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO t3r_grafana;


--
-- TOC entry 6058 (class 0 OID 0)
-- Dependencies: 536
-- Name: FUNCTION st_minimumclearanceline(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO t3r_grafana;


--
-- TOC entry 6059 (class 0 OID 0)
-- Dependencies: 1065
-- Name: FUNCTION st_mlinefromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO t3r_grafana;


--
-- TOC entry 6060 (class 0 OID 0)
-- Dependencies: 622
-- Name: FUNCTION st_mlinefromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 6061 (class 0 OID 0)
-- Dependencies: 1091
-- Name: FUNCTION st_mlinefromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6062 (class 0 OID 0)
-- Dependencies: 611
-- Name: FUNCTION st_mlinefromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6063 (class 0 OID 0)
-- Dependencies: 520
-- Name: FUNCTION st_mpointfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO t3r_grafana;


--
-- TOC entry 6064 (class 0 OID 0)
-- Dependencies: 471
-- Name: FUNCTION st_mpointfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 6065 (class 0 OID 0)
-- Dependencies: 888
-- Name: FUNCTION st_mpointfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6066 (class 0 OID 0)
-- Dependencies: 627
-- Name: FUNCTION st_mpointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6067 (class 0 OID 0)
-- Dependencies: 748
-- Name: FUNCTION st_mpolyfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO t3r_grafana;


--
-- TOC entry 6068 (class 0 OID 0)
-- Dependencies: 667
-- Name: FUNCTION st_mpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 6069 (class 0 OID 0)
-- Dependencies: 491
-- Name: FUNCTION st_mpolyfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6070 (class 0 OID 0)
-- Dependencies: 447
-- Name: FUNCTION st_mpolyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6071 (class 0 OID 0)
-- Dependencies: 1016
-- Name: FUNCTION st_multi(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO t3r_grafana;


--
-- TOC entry 6072 (class 0 OID 0)
-- Dependencies: 367
-- Name: FUNCTION st_multilinefromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6073 (class 0 OID 0)
-- Dependencies: 543
-- Name: FUNCTION st_multilinestringfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO t3r_grafana;


--
-- TOC entry 6074 (class 0 OID 0)
-- Dependencies: 922
-- Name: FUNCTION st_multilinestringfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 6075 (class 0 OID 0)
-- Dependencies: 765
-- Name: FUNCTION st_multipointfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO t3r_grafana;


--
-- TOC entry 6076 (class 0 OID 0)
-- Dependencies: 828
-- Name: FUNCTION st_multipointfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6077 (class 0 OID 0)
-- Dependencies: 527
-- Name: FUNCTION st_multipointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6078 (class 0 OID 0)
-- Dependencies: 426
-- Name: FUNCTION st_multipolyfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6079 (class 0 OID 0)
-- Dependencies: 767
-- Name: FUNCTION st_multipolyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6080 (class 0 OID 0)
-- Dependencies: 923
-- Name: FUNCTION st_multipolygonfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO t3r_grafana;


--
-- TOC entry 6081 (class 0 OID 0)
-- Dependencies: 1024
-- Name: FUNCTION st_multipolygonfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 6082 (class 0 OID 0)
-- Dependencies: 467
-- Name: FUNCTION st_ndims(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO t3r_grafana;


--
-- TOC entry 6083 (class 0 OID 0)
-- Dependencies: 535
-- Name: FUNCTION st_node(g public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO t3r_grafana;


--
-- TOC entry 6084 (class 0 OID 0)
-- Dependencies: 586
-- Name: FUNCTION st_normalize(geom public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO t3r_grafana;


--
-- TOC entry 6085 (class 0 OID 0)
-- Dependencies: 548
-- Name: FUNCTION st_npoints(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO t3r_grafana;


--
-- TOC entry 6086 (class 0 OID 0)
-- Dependencies: 683
-- Name: FUNCTION st_nrings(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO t3r_grafana;


--
-- TOC entry 6087 (class 0 OID 0)
-- Dependencies: 415
-- Name: FUNCTION st_numgeometries(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO t3r_grafana;


--
-- TOC entry 6088 (class 0 OID 0)
-- Dependencies: 357
-- Name: FUNCTION st_numinteriorring(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO t3r_grafana;


--
-- TOC entry 6089 (class 0 OID 0)
-- Dependencies: 988
-- Name: FUNCTION st_numinteriorrings(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO t3r_grafana;


--
-- TOC entry 6090 (class 0 OID 0)
-- Dependencies: 675
-- Name: FUNCTION st_numpatches(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO t3r_grafana;


--
-- TOC entry 6091 (class 0 OID 0)
-- Dependencies: 905
-- Name: FUNCTION st_numpoints(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO t3r_grafana;


--
-- TOC entry 6092 (class 0 OID 0)
-- Dependencies: 282
-- Name: FUNCTION st_offsetcurve(line public.geometry, distance double precision, params text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO t3r;
GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO t3r_grafana;


--
-- TOC entry 6093 (class 0 OID 0)
-- Dependencies: 530
-- Name: FUNCTION st_orderingequals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6094 (class 0 OID 0)
-- Dependencies: 867
-- Name: FUNCTION st_orientedenvelope(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO t3r_grafana;


--
-- TOC entry 6095 (class 0 OID 0)
-- Dependencies: 672
-- Name: FUNCTION st_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6096 (class 0 OID 0)
-- Dependencies: 662
-- Name: FUNCTION st_patchn(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 6097 (class 0 OID 0)
-- Dependencies: 1092
-- Name: FUNCTION st_perimeter(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO t3r_grafana;


--
-- TOC entry 6098 (class 0 OID 0)
-- Dependencies: 289
-- Name: FUNCTION st_perimeter(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 6099 (class 0 OID 0)
-- Dependencies: 552
-- Name: FUNCTION st_perimeter2d(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO t3r_grafana;


--
-- TOC entry 6100 (class 0 OID 0)
-- Dependencies: 1097
-- Name: FUNCTION st_point(double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6101 (class 0 OID 0)
-- Dependencies: 1086
-- Name: FUNCTION st_point(double precision, double precision, srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO t3r;
GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO t3r_grafana;


--
-- TOC entry 6102 (class 0 OID 0)
-- Dependencies: 466
-- Name: FUNCTION st_pointfromgeohash(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO t3r_grafana;


--
-- TOC entry 6103 (class 0 OID 0)
-- Dependencies: 583
-- Name: FUNCTION st_pointfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO t3r_grafana;


--
-- TOC entry 6104 (class 0 OID 0)
-- Dependencies: 1114
-- Name: FUNCTION st_pointfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 6105 (class 0 OID 0)
-- Dependencies: 1109
-- Name: FUNCTION st_pointfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6106 (class 0 OID 0)
-- Dependencies: 994
-- Name: FUNCTION st_pointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6107 (class 0 OID 0)
-- Dependencies: 814
-- Name: FUNCTION st_pointinsidecircle(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6108 (class 0 OID 0)
-- Dependencies: 1002
-- Name: FUNCTION st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO t3r;
GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO t3r_grafana;


--
-- TOC entry 6109 (class 0 OID 0)
-- Dependencies: 335
-- Name: FUNCTION st_pointn(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 6110 (class 0 OID 0)
-- Dependencies: 506
-- Name: FUNCTION st_pointonsurface(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO t3r_grafana;


--
-- TOC entry 6111 (class 0 OID 0)
-- Dependencies: 785
-- Name: FUNCTION st_points(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_points(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_points(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_points(public.geometry) TO t3r_grafana;


--
-- TOC entry 6112 (class 0 OID 0)
-- Dependencies: 884
-- Name: FUNCTION st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO t3r;
GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO t3r_grafana;


--
-- TOC entry 6113 (class 0 OID 0)
-- Dependencies: 909
-- Name: FUNCTION st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO t3r;
GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO t3r_grafana;


--
-- TOC entry 6114 (class 0 OID 0)
-- Dependencies: 741
-- Name: FUNCTION st_polyfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO t3r_grafana;


--
-- TOC entry 6115 (class 0 OID 0)
-- Dependencies: 665
-- Name: FUNCTION st_polyfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 6116 (class 0 OID 0)
-- Dependencies: 346
-- Name: FUNCTION st_polyfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6117 (class 0 OID 0)
-- Dependencies: 851
-- Name: FUNCTION st_polyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6118 (class 0 OID 0)
-- Dependencies: 981
-- Name: FUNCTION st_polygon(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 6119 (class 0 OID 0)
-- Dependencies: 979
-- Name: FUNCTION st_polygonfromtext(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO t3r;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO t3r_grafana;


--
-- TOC entry 6120 (class 0 OID 0)
-- Dependencies: 445
-- Name: FUNCTION st_polygonfromtext(text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO t3r_grafana;


--
-- TOC entry 6121 (class 0 OID 0)
-- Dependencies: 1111
-- Name: FUNCTION st_polygonfromwkb(bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO t3r_grafana;


--
-- TOC entry 6122 (class 0 OID 0)
-- Dependencies: 974
-- Name: FUNCTION st_polygonfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO t3r_grafana;


--
-- TOC entry 6123 (class 0 OID 0)
-- Dependencies: 896
-- Name: FUNCTION st_polygonize(public.geometry[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO t3r;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO t3r_grafana;


--
-- TOC entry 6124 (class 0 OID 0)
-- Dependencies: 616
-- Name: FUNCTION st_project(geog public.geography, distance double precision, azimuth double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO t3r_grafana;


--
-- TOC entry 6125 (class 0 OID 0)
-- Dependencies: 880
-- Name: FUNCTION st_project(geog_from public.geography, geog_to public.geography, distance double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_project(geog_from public.geography, geog_to public.geography, distance double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_project(geog_from public.geography, geog_to public.geography, distance double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_project(geog_from public.geography, geog_to public.geography, distance double precision) TO t3r_grafana;


--
-- TOC entry 6126 (class 0 OID 0)
-- Dependencies: 381
-- Name: FUNCTION st_project(geom1 public.geometry, distance double precision, azimuth double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, distance double precision, azimuth double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, distance double precision, azimuth double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, distance double precision, azimuth double precision) TO t3r_grafana;


--
-- TOC entry 6127 (class 0 OID 0)
-- Dependencies: 470
-- Name: FUNCTION st_project(geom1 public.geometry, geom2 public.geometry, distance double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, geom2 public.geometry, distance double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, geom2 public.geometry, distance double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, geom2 public.geometry, distance double precision) TO t3r_grafana;


--
-- TOC entry 6128 (class 0 OID 0)
-- Dependencies: 626
-- Name: FUNCTION st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO t3r;
GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO t3r_grafana;


--
-- TOC entry 6129 (class 0 OID 0)
-- Dependencies: 1051
-- Name: FUNCTION st_reduceprecision(geom public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO t3r_grafana;


--
-- TOC entry 6130 (class 0 OID 0)
-- Dependencies: 488
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6131 (class 0 OID 0)
-- Dependencies: 1054
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 6132 (class 0 OID 0)
-- Dependencies: 1119
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO t3r;
GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO t3r_grafana;


--
-- TOC entry 6133 (class 0 OID 0)
-- Dependencies: 437
-- Name: FUNCTION st_relatematch(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO t3r_grafana;


--
-- TOC entry 6134 (class 0 OID 0)
-- Dependencies: 553
-- Name: FUNCTION st_removepoint(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 6135 (class 0 OID 0)
-- Dependencies: 322
-- Name: FUNCTION st_removerepeatedpoints(geom public.geometry, tolerance double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO t3r_grafana;


--
-- TOC entry 6136 (class 0 OID 0)
-- Dependencies: 507
-- Name: FUNCTION st_reverse(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO t3r_grafana;


--
-- TOC entry 6137 (class 0 OID 0)
-- Dependencies: 782
-- Name: FUNCTION st_rotate(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6138 (class 0 OID 0)
-- Dependencies: 853
-- Name: FUNCTION st_rotate(public.geometry, double precision, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO t3r_grafana;


--
-- TOC entry 6139 (class 0 OID 0)
-- Dependencies: 587
-- Name: FUNCTION st_rotate(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6140 (class 0 OID 0)
-- Dependencies: 1019
-- Name: FUNCTION st_rotatex(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6141 (class 0 OID 0)
-- Dependencies: 1074
-- Name: FUNCTION st_rotatey(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6142 (class 0 OID 0)
-- Dependencies: 686
-- Name: FUNCTION st_rotatez(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6143 (class 0 OID 0)
-- Dependencies: 1031
-- Name: FUNCTION st_scale(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 6144 (class 0 OID 0)
-- Dependencies: 643
-- Name: FUNCTION st_scale(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6145 (class 0 OID 0)
-- Dependencies: 363
-- Name: FUNCTION st_scale(public.geometry, public.geometry, origin public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO t3r_grafana;


--
-- TOC entry 6146 (class 0 OID 0)
-- Dependencies: 691
-- Name: FUNCTION st_scale(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6147 (class 0 OID 0)
-- Dependencies: 1013
-- Name: FUNCTION st_scroll(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO t3r_grafana;


--
-- TOC entry 6148 (class 0 OID 0)
-- Dependencies: 1072
-- Name: FUNCTION st_segmentize(geog public.geography, max_segment_length double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO t3r_grafana;


--
-- TOC entry 6149 (class 0 OID 0)
-- Dependencies: 1120
-- Name: FUNCTION st_segmentize(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6150 (class 0 OID 0)
-- Dependencies: 508
-- Name: FUNCTION st_seteffectivearea(public.geometry, double precision, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO t3r_grafana;


--
-- TOC entry 6151 (class 0 OID 0)
-- Dependencies: 1052
-- Name: FUNCTION st_setpoint(public.geometry, integer, public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO t3r_grafana;


--
-- TOC entry 6152 (class 0 OID 0)
-- Dependencies: 962
-- Name: FUNCTION st_setsrid(geog public.geography, srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO t3r;
GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO t3r_grafana;


--
-- TOC entry 6153 (class 0 OID 0)
-- Dependencies: 788
-- Name: FUNCTION st_setsrid(geom public.geometry, srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO t3r;
GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO t3r_grafana;


--
-- TOC entry 6154 (class 0 OID 0)
-- Dependencies: 1021
-- Name: FUNCTION st_sharedpaths(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6155 (class 0 OID 0)
-- Dependencies: 733
-- Name: FUNCTION st_shiftlongitude(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO t3r_grafana;


--
-- TOC entry 6156 (class 0 OID 0)
-- Dependencies: 517
-- Name: FUNCTION st_shortestline(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_shortestline(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_shortestline(text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_shortestline(text, text) TO t3r_grafana;


--
-- TOC entry 6157 (class 0 OID 0)
-- Dependencies: 718
-- Name: FUNCTION st_shortestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6158 (class 0 OID 0)
-- Dependencies: 1121
-- Name: FUNCTION st_shortestline(public.geography, public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_shortestline(public.geography, public.geography, use_spheroid boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_shortestline(public.geography, public.geography, use_spheroid boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_shortestline(public.geography, public.geography, use_spheroid boolean) TO t3r_grafana;


--
-- TOC entry 6159 (class 0 OID 0)
-- Dependencies: 694
-- Name: FUNCTION st_simplify(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6160 (class 0 OID 0)
-- Dependencies: 547
-- Name: FUNCTION st_simplify(public.geometry, double precision, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO t3r_grafana;


--
-- TOC entry 6161 (class 0 OID 0)
-- Dependencies: 929
-- Name: FUNCTION st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO t3r_grafana;


--
-- TOC entry 6162 (class 0 OID 0)
-- Dependencies: 577
-- Name: FUNCTION st_simplifypreservetopology(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6163 (class 0 OID 0)
-- Dependencies: 911
-- Name: FUNCTION st_simplifyvw(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6164 (class 0 OID 0)
-- Dependencies: 702
-- Name: FUNCTION st_snap(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6165 (class 0 OID 0)
-- Dependencies: 562
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6166 (class 0 OID 0)
-- Dependencies: 1115
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6167 (class 0 OID 0)
-- Dependencies: 378
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6168 (class 0 OID 0)
-- Dependencies: 787
-- Name: FUNCTION st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6169 (class 0 OID 0)
-- Dependencies: 870
-- Name: FUNCTION st_split(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6170 (class 0 OID 0)
-- Dependencies: 895
-- Name: FUNCTION st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO t3r_grafana;


--
-- TOC entry 6171 (class 0 OID 0)
-- Dependencies: 985
-- Name: FUNCTION st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO t3r;
GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO t3r_grafana;


--
-- TOC entry 6172 (class 0 OID 0)
-- Dependencies: 679
-- Name: FUNCTION st_srid(geog public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO t3r_grafana;


--
-- TOC entry 6173 (class 0 OID 0)
-- Dependencies: 1053
-- Name: FUNCTION st_srid(geom public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO t3r_grafana;


--
-- TOC entry 6174 (class 0 OID 0)
-- Dependencies: 441
-- Name: FUNCTION st_startpoint(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO t3r_grafana;


--
-- TOC entry 6175 (class 0 OID 0)
-- Dependencies: 761
-- Name: FUNCTION st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO t3r_grafana;


--
-- TOC entry 6176 (class 0 OID 0)
-- Dependencies: 304
-- Name: FUNCTION st_summary(public.geography); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_summary(public.geography) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_summary(public.geography) TO t3r;
GRANT ALL ON FUNCTION public.st_summary(public.geography) TO t3r_grafana;


--
-- TOC entry 6177 (class 0 OID 0)
-- Dependencies: 678
-- Name: FUNCTION st_summary(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO t3r_grafana;


--
-- TOC entry 6178 (class 0 OID 0)
-- Dependencies: 581
-- Name: FUNCTION st_swapordinates(geom public.geometry, ords cstring); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO t3r;
GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO t3r_grafana;


--
-- TOC entry 6179 (class 0 OID 0)
-- Dependencies: 753
-- Name: FUNCTION st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r_grafana;


--
-- TOC entry 6180 (class 0 OID 0)
-- Dependencies: 1089
-- Name: FUNCTION st_symmetricdifference(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6181 (class 0 OID 0)
-- Dependencies: 992
-- Name: FUNCTION st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO t3r_grafana;


--
-- TOC entry 6182 (class 0 OID 0)
-- Dependencies: 843
-- Name: FUNCTION st_touches(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6183 (class 0 OID 0)
-- Dependencies: 789
-- Name: FUNCTION st_transform(public.geometry, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO t3r_grafana;


--
-- TOC entry 6184 (class 0 OID 0)
-- Dependencies: 458
-- Name: FUNCTION st_transform(geom public.geometry, to_proj text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO t3r;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO t3r_grafana;


--
-- TOC entry 6185 (class 0 OID 0)
-- Dependencies: 661
-- Name: FUNCTION st_transform(geom public.geometry, from_proj text, to_srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO t3r;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO t3r_grafana;


--
-- TOC entry 6186 (class 0 OID 0)
-- Dependencies: 887
-- Name: FUNCTION st_transform(geom public.geometry, from_proj text, to_proj text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO t3r;
GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO t3r_grafana;


--
-- TOC entry 6187 (class 0 OID 0)
-- Dependencies: 728
-- Name: FUNCTION st_transformpipeline(geom public.geometry, pipeline text, to_srid integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_transformpipeline(geom public.geometry, pipeline text, to_srid integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_transformpipeline(geom public.geometry, pipeline text, to_srid integer) TO t3r;
GRANT ALL ON FUNCTION public.st_transformpipeline(geom public.geometry, pipeline text, to_srid integer) TO t3r_grafana;


--
-- TOC entry 6188 (class 0 OID 0)
-- Dependencies: 910
-- Name: FUNCTION st_translate(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6189 (class 0 OID 0)
-- Dependencies: 921
-- Name: FUNCTION st_translate(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6190 (class 0 OID 0)
-- Dependencies: 1118
-- Name: FUNCTION st_transscale(public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO t3r_grafana;


--
-- TOC entry 6191 (class 0 OID 0)
-- Dependencies: 879
-- Name: FUNCTION st_triangulatepolygon(g1 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO t3r_grafana;


--
-- TOC entry 6192 (class 0 OID 0)
-- Dependencies: 800
-- Name: FUNCTION st_unaryunion(public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO t3r_grafana;


--
-- TOC entry 6193 (class 0 OID 0)
-- Dependencies: 744
-- Name: FUNCTION st_union(public.geometry[]); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO t3r;
GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO t3r_grafana;


--
-- TOC entry 6194 (class 0 OID 0)
-- Dependencies: 582
-- Name: FUNCTION st_union(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6195 (class 0 OID 0)
-- Dependencies: 463
-- Name: FUNCTION st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO t3r_grafana;


--
-- TOC entry 6196 (class 0 OID 0)
-- Dependencies: 554
-- Name: FUNCTION st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO t3r_grafana;


--
-- TOC entry 6197 (class 0 OID 0)
-- Dependencies: 736
-- Name: FUNCTION st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO t3r_grafana;


--
-- TOC entry 6198 (class 0 OID 0)
-- Dependencies: 330
-- Name: FUNCTION st_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO t3r_grafana;


--
-- TOC entry 6199 (class 0 OID 0)
-- Dependencies: 533
-- Name: FUNCTION st_wkbtosql(wkb bytea); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO t3r;
GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO t3r_grafana;


--
-- TOC entry 6200 (class 0 OID 0)
-- Dependencies: 824
-- Name: FUNCTION st_wkttosql(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_wkttosql(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_wkttosql(text) TO t3r;
GRANT ALL ON FUNCTION public.st_wkttosql(text) TO t3r_grafana;


--
-- TOC entry 6201 (class 0 OID 0)
-- Dependencies: 1066
-- Name: FUNCTION st_wrapx(geom public.geometry, wrap double precision, move double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO t3r_grafana;


--
-- TOC entry 6202 (class 0 OID 0)
-- Dependencies: 561
-- Name: FUNCTION st_x(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_x(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_x(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_x(public.geometry) TO t3r_grafana;


--
-- TOC entry 6203 (class 0 OID 0)
-- Dependencies: 899
-- Name: FUNCTION st_xmax(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO t3r_grafana;


--
-- TOC entry 6204 (class 0 OID 0)
-- Dependencies: 783
-- Name: FUNCTION st_xmin(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO t3r_grafana;


--
-- TOC entry 6205 (class 0 OID 0)
-- Dependencies: 600
-- Name: FUNCTION st_y(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_y(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_y(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_y(public.geometry) TO t3r_grafana;


--
-- TOC entry 6206 (class 0 OID 0)
-- Dependencies: 273
-- Name: FUNCTION st_ymax(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO t3r_grafana;


--
-- TOC entry 6207 (class 0 OID 0)
-- Dependencies: 392
-- Name: FUNCTION st_ymin(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO t3r_grafana;


--
-- TOC entry 6208 (class 0 OID 0)
-- Dependencies: 715
-- Name: FUNCTION st_z(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_z(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_z(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_z(public.geometry) TO t3r_grafana;


--
-- TOC entry 6209 (class 0 OID 0)
-- Dependencies: 925
-- Name: FUNCTION st_zmax(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO t3r_grafana;


--
-- TOC entry 6210 (class 0 OID 0)
-- Dependencies: 1035
-- Name: FUNCTION st_zmflag(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO t3r_grafana;


--
-- TOC entry 6211 (class 0 OID 0)
-- Dependencies: 1003
-- Name: FUNCTION st_zmin(public.box3d); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO t3r;
GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO t3r_grafana;


--
-- TOC entry 6212 (class 0 OID 0)
-- Dependencies: 813
-- Name: FUNCTION svals(public.hstore); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.svals(public.hstore) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.svals(public.hstore) TO t3r;
GRANT ALL ON FUNCTION public.svals(public.hstore) TO t3r_grafana;


--
-- TOC entry 6213 (class 0 OID 0)
-- Dependencies: 781
-- Name: FUNCTION tconvert(text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.tconvert(text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.tconvert(text, text) TO t3r;
GRANT ALL ON FUNCTION public.tconvert(text, text) TO t3r_grafana;


--
-- TOC entry 6214 (class 0 OID 0)
-- Dependencies: 439
-- Name: FUNCTION unlockrows(text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.unlockrows(text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.unlockrows(text) TO t3r;
GRANT ALL ON FUNCTION public.unlockrows(text) TO t3r_grafana;


--
-- TOC entry 6215 (class 0 OID 0)
-- Dependencies: 504
-- Name: FUNCTION updategeometrysrid(character varying, character varying, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO t3r;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO t3r_grafana;


--
-- TOC entry 6216 (class 0 OID 0)
-- Dependencies: 716
-- Name: FUNCTION updategeometrysrid(character varying, character varying, character varying, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO t3r;
GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO t3r_grafana;


--
-- TOC entry 6217 (class 0 OID 0)
-- Dependencies: 442
-- Name: FUNCTION updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO t3r;
GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO t3r_grafana;


--
-- TOC entry 6218 (class 0 OID 0)
-- Dependencies: 792
-- Name: FUNCTION uuid_generate_v1(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_generate_v1() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_generate_v1() TO t3r;
GRANT ALL ON FUNCTION public.uuid_generate_v1() TO t3r_grafana;


--
-- TOC entry 6219 (class 0 OID 0)
-- Dependencies: 325
-- Name: FUNCTION uuid_generate_v1mc(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_generate_v1mc() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_generate_v1mc() TO t3r;
GRANT ALL ON FUNCTION public.uuid_generate_v1mc() TO t3r_grafana;


--
-- TOC entry 6220 (class 0 OID 0)
-- Dependencies: 933
-- Name: FUNCTION uuid_generate_v3(namespace uuid, name text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_generate_v3(namespace uuid, name text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_generate_v3(namespace uuid, name text) TO t3r;
GRANT ALL ON FUNCTION public.uuid_generate_v3(namespace uuid, name text) TO t3r_grafana;


--
-- TOC entry 6221 (class 0 OID 0)
-- Dependencies: 763
-- Name: FUNCTION uuid_generate_v4(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_generate_v4() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_generate_v4() TO t3r;
GRANT ALL ON FUNCTION public.uuid_generate_v4() TO t3r_grafana;


--
-- TOC entry 6222 (class 0 OID 0)
-- Dependencies: 431
-- Name: FUNCTION uuid_generate_v5(namespace uuid, name text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_generate_v5(namespace uuid, name text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_generate_v5(namespace uuid, name text) TO t3r;
GRANT ALL ON FUNCTION public.uuid_generate_v5(namespace uuid, name text) TO t3r_grafana;


--
-- TOC entry 6223 (class 0 OID 0)
-- Dependencies: 310
-- Name: FUNCTION uuid_nil(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_nil() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_nil() TO t3r;
GRANT ALL ON FUNCTION public.uuid_nil() TO t3r_grafana;


--
-- TOC entry 6224 (class 0 OID 0)
-- Dependencies: 361
-- Name: FUNCTION uuid_ns_dns(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_ns_dns() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_ns_dns() TO t3r;
GRANT ALL ON FUNCTION public.uuid_ns_dns() TO t3r_grafana;


--
-- TOC entry 6225 (class 0 OID 0)
-- Dependencies: 291
-- Name: FUNCTION uuid_ns_oid(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_ns_oid() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_ns_oid() TO t3r;
GRANT ALL ON FUNCTION public.uuid_ns_oid() TO t3r_grafana;


--
-- TOC entry 6226 (class 0 OID 0)
-- Dependencies: 1117
-- Name: FUNCTION uuid_ns_url(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_ns_url() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_ns_url() TO t3r;
GRANT ALL ON FUNCTION public.uuid_ns_url() TO t3r_grafana;


--
-- TOC entry 6227 (class 0 OID 0)
-- Dependencies: 1077
-- Name: FUNCTION uuid_ns_x500(); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.uuid_ns_x500() TO t3r_flightgear;
GRANT ALL ON FUNCTION public.uuid_ns_x500() TO t3r;
GRANT ALL ON FUNCTION public.uuid_ns_x500() TO t3r_grafana;


--
-- TOC entry 6228 (class 0 OID 0)
-- Dependencies: 1901
-- Name: FUNCTION st_3dextent(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO t3r_grafana;


--
-- TOC entry 6229 (class 0 OID 0)
-- Dependencies: 1900
-- Name: FUNCTION st_asflatgeobuf(anyelement); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO t3r;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO t3r_grafana;


--
-- TOC entry 6230 (class 0 OID 0)
-- Dependencies: 1904
-- Name: FUNCTION st_asflatgeobuf(anyelement, boolean); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO t3r;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO t3r_grafana;


--
-- TOC entry 6231 (class 0 OID 0)
-- Dependencies: 1895
-- Name: FUNCTION st_asflatgeobuf(anyelement, boolean, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO t3r;
GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO t3r_grafana;


--
-- TOC entry 6232 (class 0 OID 0)
-- Dependencies: 1896
-- Name: FUNCTION st_asgeobuf(anyelement); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO t3r;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO t3r_grafana;


--
-- TOC entry 6233 (class 0 OID 0)
-- Dependencies: 1897
-- Name: FUNCTION st_asgeobuf(anyelement, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO t3r;
GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO t3r_grafana;


--
-- TOC entry 6234 (class 0 OID 0)
-- Dependencies: 1905
-- Name: FUNCTION st_asmvt(anyelement); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO t3r;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO t3r_grafana;


--
-- TOC entry 6235 (class 0 OID 0)
-- Dependencies: 1906
-- Name: FUNCTION st_asmvt(anyelement, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO t3r;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO t3r_grafana;


--
-- TOC entry 6236 (class 0 OID 0)
-- Dependencies: 1907
-- Name: FUNCTION st_asmvt(anyelement, text, integer); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO t3r;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO t3r_grafana;


--
-- TOC entry 6237 (class 0 OID 0)
-- Dependencies: 1894
-- Name: FUNCTION st_asmvt(anyelement, text, integer, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO t3r;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO t3r_grafana;


--
-- TOC entry 6238 (class 0 OID 0)
-- Dependencies: 1908
-- Name: FUNCTION st_asmvt(anyelement, text, integer, text, text); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO t3r;
GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO t3r_grafana;


--
-- TOC entry 6239 (class 0 OID 0)
-- Dependencies: 1902
-- Name: FUNCTION st_clusterintersecting(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO t3r_grafana;


--
-- TOC entry 6240 (class 0 OID 0)
-- Dependencies: 1903
-- Name: FUNCTION st_clusterwithin(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6241 (class 0 OID 0)
-- Dependencies: 1893
-- Name: FUNCTION st_collect(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO t3r_grafana;


--
-- TOC entry 6242 (class 0 OID 0)
-- Dependencies: 1888
-- Name: FUNCTION st_coverageunion(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry) TO t3r_grafana;


--
-- TOC entry 6243 (class 0 OID 0)
-- Dependencies: 1898
-- Name: FUNCTION st_extent(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO t3r_grafana;


--
-- TOC entry 6244 (class 0 OID 0)
-- Dependencies: 1899
-- Name: FUNCTION st_makeline(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO t3r_grafana;


--
-- TOC entry 6245 (class 0 OID 0)
-- Dependencies: 1889
-- Name: FUNCTION st_memcollect(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO t3r_grafana;


--
-- TOC entry 6246 (class 0 OID 0)
-- Dependencies: 1890
-- Name: FUNCTION st_memunion(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO t3r_grafana;


--
-- TOC entry 6247 (class 0 OID 0)
-- Dependencies: 1909
-- Name: FUNCTION st_polygonize(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO t3r_grafana;


--
-- TOC entry 6248 (class 0 OID 0)
-- Dependencies: 1891
-- Name: FUNCTION st_union(public.geometry); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_union(public.geometry) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_union(public.geometry) TO t3r;
GRANT ALL ON FUNCTION public.st_union(public.geometry) TO t3r_grafana;


--
-- TOC entry 6249 (class 0 OID 0)
-- Dependencies: 1892
-- Name: FUNCTION st_union(public.geometry, double precision); Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO t3r_flightgear;
GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO t3r;
GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO t3r_grafana;


--
-- TOC entry 6250 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE apt_runway; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.apt_runway TO t3r;
GRANT SELECT ON TABLE public.apt_runway TO t3r_grafana;


--
-- TOC entry 6252 (class 0 OID 0)
-- Dependencies: 224
-- Name: SEQUENCE apt_runway_ogc_fid_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.apt_runway_ogc_fid_seq TO t3r;
GRANT SELECT ON SEQUENCE public.apt_runway_ogc_fid_seq TO t3r_grafana;


--
-- TOC entry 6253 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE country_codes; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.country_codes TO t3r;
GRANT SELECT ON TABLE public.country_codes TO t3r_grafana;


--
-- TOC entry 6254 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE fgs_aircraft; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_aircraft TO t3r;
GRANT SELECT ON TABLE public.fgs_aircraft TO t3r_grafana;


--
-- TOC entry 6256 (class 0 OID 0)
-- Dependencies: 227
-- Name: SEQUENCE fgs_aircraft_ac_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_aircraft_ac_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_aircraft_ac_id_seq TO t3r_grafana;


--
-- TOC entry 6257 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE fgs_airline; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_airline TO t3r;
GRANT SELECT ON TABLE public.fgs_airline TO t3r_grafana;


--
-- TOC entry 6259 (class 0 OID 0)
-- Dependencies: 229
-- Name: SEQUENCE fgs_airline_al_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_airline_al_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_airline_al_id_seq TO t3r_grafana;


--
-- TOC entry 6260 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE fgs_airport; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_airport TO t3r;
GRANT SELECT ON TABLE public.fgs_airport TO t3r_grafana;


--
-- TOC entry 6262 (class 0 OID 0)
-- Dependencies: 231
-- Name: SEQUENCE fgs_airport_ap_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_airport_ap_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_airport_ap_id_seq TO t3r_grafana;


--
-- TOC entry 6263 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE fgs_authors; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_authors TO t3r;
GRANT SELECT ON TABLE public.fgs_authors TO t3r_grafana;


--
-- TOC entry 6265 (class 0 OID 0)
-- Dependencies: 233
-- Name: SEQUENCE fgs_authors_au_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_authors_au_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_authors_au_id_seq TO t3r_grafana;


--
-- TOC entry 6266 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE fgs_clean; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_clean TO t3r;
GRANT SELECT ON TABLE public.fgs_clean TO t3r_grafana;


--
-- TOC entry 6268 (class 0 OID 0)
-- Dependencies: 235
-- Name: SEQUENCE fgs_clean_ob_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_clean_ob_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_clean_ob_id_seq TO t3r_grafana;


--
-- TOC entry 6269 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE fgs_countries; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_countries TO t3r;
GRANT SELECT ON TABLE public.fgs_countries TO t3r_grafana;


--
-- TOC entry 6272 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE fgs_extuserids; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_extuserids TO t3r;
GRANT SELECT ON TABLE public.fgs_extuserids TO t3r_grafana;


--
-- TOC entry 6273 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE fgs_fixes; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_fixes TO t3r;
GRANT SELECT ON TABLE public.fgs_fixes TO t3r_grafana;


--
-- TOC entry 6274 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE fgs_fleet; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_fleet TO t3r;
GRANT SELECT ON TABLE public.fgs_fleet TO t3r_grafana;


--
-- TOC entry 6276 (class 0 OID 0)
-- Dependencies: 240
-- Name: SEQUENCE fgs_fleet_fl_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_fleet_fl_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_fleet_fl_id_seq TO t3r_grafana;


--
-- TOC entry 6277 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE fgs_flight; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_flight TO t3r;
GRANT SELECT ON TABLE public.fgs_flight TO t3r_grafana;


--
-- TOC entry 6279 (class 0 OID 0)
-- Dependencies: 242
-- Name: SEQUENCE fgs_flight_ft_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_flight_ft_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_flight_ft_id_seq TO t3r_grafana;


--
-- TOC entry 6280 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE fgs_groups; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_groups TO t3r;
GRANT SELECT ON TABLE public.fgs_groups TO t3r_grafana;


--
-- TOC entry 6282 (class 0 OID 0)
-- Dependencies: 244
-- Name: SEQUENCE fgs_groups_gp_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_groups_gp_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_groups_gp_id_seq TO t3r_grafana;


--
-- TOC entry 6283 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE fgs_modelclass; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_modelclass TO t3r;
GRANT SELECT ON TABLE public.fgs_modelclass TO t3r_grafana;


--
-- TOC entry 6285 (class 0 OID 0)
-- Dependencies: 246
-- Name: SEQUENCE fgs_modelclass_mc_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_modelclass_mc_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_modelclass_mc_id_seq TO t3r_grafana;


--
-- TOC entry 6286 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE fgs_modelgroups; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_modelgroups TO t3r;
GRANT SELECT ON TABLE public.fgs_modelgroups TO t3r_grafana;


--
-- TOC entry 6288 (class 0 OID 0)
-- Dependencies: 248
-- Name: SEQUENCE fgs_modelgroups_mg_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_modelgroups_mg_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_modelgroups_mg_id_seq TO t3r_grafana;


--
-- TOC entry 6289 (class 0 OID 0)
-- Dependencies: 249
-- Name: SEQUENCE fgs_models_mo_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_models_mo_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_models_mo_id_seq TO t3r_grafana;


--
-- TOC entry 6290 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE fgs_models; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_models TO t3r;
GRANT SELECT ON TABLE public.fgs_models TO t3r_grafana;


--
-- TOC entry 6292 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE fgs_navaids; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_navaids TO t3r;
GRANT SELECT ON TABLE public.fgs_navaids TO t3r_grafana;


--
-- TOC entry 6294 (class 0 OID 0)
-- Dependencies: 252
-- Name: SEQUENCE fgs_navaids_na_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_navaids_na_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_navaids_na_id_seq TO t3r_grafana;


--
-- TOC entry 6295 (class 0 OID 0)
-- Dependencies: 253
-- Name: TABLE fgs_news; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_news TO t3r;
GRANT SELECT ON TABLE public.fgs_news TO t3r_grafana;


--
-- TOC entry 6297 (class 0 OID 0)
-- Dependencies: 254
-- Name: SEQUENCE fgs_news_ne_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_news_ne_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_news_ne_id_seq TO t3r_grafana;


--
-- TOC entry 6298 (class 0 OID 0)
-- Dependencies: 255
-- Name: TABLE fgs_objects; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_objects TO t3r;
GRANT SELECT ON TABLE public.fgs_objects TO t3r_grafana;


--
-- TOC entry 6300 (class 0 OID 0)
-- Dependencies: 256
-- Name: SEQUENCE fgs_objects_ob_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_objects_ob_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_objects_ob_id_seq TO t3r_grafana;


--
-- TOC entry 6301 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE fgs_position_requests; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_position_requests TO t3r;
GRANT SELECT ON TABLE public.fgs_position_requests TO t3r_grafana;


--
-- TOC entry 6303 (class 0 OID 0)
-- Dependencies: 258
-- Name: SEQUENCE fgs_position_requests_spr_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_position_requests_spr_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_position_requests_spr_id_seq TO t3r_grafana;


--
-- TOC entry 6304 (class 0 OID 0)
-- Dependencies: 259
-- Name: SEQUENCE fgs_procedures_pr_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_procedures_pr_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_procedures_pr_id_seq TO t3r_grafana;


--
-- TOC entry 6305 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE fgs_procedures; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_procedures TO t3r;
GRANT SELECT ON TABLE public.fgs_procedures TO t3r_grafana;


--
-- TOC entry 6306 (class 0 OID 0)
-- Dependencies: 261
-- Name: TABLE fgs_signs; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_signs TO t3r;
GRANT SELECT ON TABLE public.fgs_signs TO t3r_grafana;


--
-- TOC entry 6308 (class 0 OID 0)
-- Dependencies: 262
-- Name: SEQUENCE fgs_signs_si_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_signs_si_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_signs_si_id_seq TO t3r_grafana;


--
-- TOC entry 6309 (class 0 OID 0)
-- Dependencies: 263
-- Name: TABLE fgs_statistics; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_statistics TO t3r;
GRANT SELECT ON TABLE public.fgs_statistics TO t3r_grafana;


--
-- TOC entry 6310 (class 0 OID 0)
-- Dependencies: 264
-- Name: TABLE fgs_timestamps; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_timestamps TO t3r;
GRANT SELECT ON TABLE public.fgs_timestamps TO t3r_grafana;


--
-- TOC entry 6311 (class 0 OID 0)
-- Dependencies: 265
-- Name: SEQUENCE fgs_waypoints_wp_id_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.fgs_waypoints_wp_id_seq TO t3r;
GRANT SELECT ON SEQUENCE public.fgs_waypoints_wp_id_seq TO t3r_grafana;


--
-- TOC entry 6312 (class 0 OID 0)
-- Dependencies: 266
-- Name: TABLE fgs_waypoints; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.fgs_waypoints TO t3r;
GRANT SELECT ON TABLE public.fgs_waypoints TO t3r_grafana;


--
-- TOC entry 6313 (class 0 OID 0)
-- Dependencies: 267
-- Name: TABLE gadm2; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.gadm2 TO t3r;
GRANT SELECT ON TABLE public.gadm2 TO t3r_grafana;


--
-- TOC entry 6314 (class 0 OID 0)
-- Dependencies: 268
-- Name: TABLE gadm2_meta; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.gadm2_meta TO t3r;
GRANT SELECT ON TABLE public.gadm2_meta TO t3r_grafana;


--
-- TOC entry 6316 (class 0 OID 0)
-- Dependencies: 269
-- Name: SEQUENCE gadm2_ogc_fid_seq; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON SEQUENCE public.gadm2_ogc_fid_seq TO t3r;
GRANT SELECT ON SEQUENCE public.gadm2_ogc_fid_seq TO t3r_grafana;


--
-- TOC entry 6317 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE geography_columns; Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON TABLE public.geography_columns TO t3r_flightgear;
GRANT ALL ON TABLE public.geography_columns TO t3r;
GRANT SELECT ON TABLE public.geography_columns TO t3r_grafana;


--
-- TOC entry 6318 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE geometry_columns; Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON TABLE public.geometry_columns TO t3r_flightgear;
GRANT ALL ON TABLE public.geometry_columns TO t3r;
GRANT SELECT ON TABLE public.geometry_columns TO t3r_grafana;


--
-- TOC entry 6319 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE spatial_ref_sys; Type: ACL; Schema: public; Owner: _root
--

GRANT ALL ON TABLE public.spatial_ref_sys TO t3r_flightgear;
GRANT ALL ON TABLE public.spatial_ref_sys TO t3r;
GRANT SELECT ON TABLE public.spatial_ref_sys TO t3r_grafana;


--
-- TOC entry 6320 (class 0 OID 0)
-- Dependencies: 270
-- Name: TABLE user_sessions; Type: ACL; Schema: public; Owner: t3r_flightgear
--

GRANT ALL ON TABLE public.user_sessions TO t3r;
GRANT SELECT ON TABLE public.user_sessions TO t3r_grafana;


--
-- TOC entry 3214 (class 826 OID 4922408)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: -; Owner: t3r
--

ALTER DEFAULT PRIVILEGES FOR ROLE t3r GRANT ALL ON SEQUENCES TO t3r_flightgear;
ALTER DEFAULT PRIVILEGES FOR ROLE t3r GRANT SELECT ON SEQUENCES TO t3r_grafana;


--
-- TOC entry 3211 (class 826 OID 4922414)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: -; Owner: t3r_flightgear
--

ALTER DEFAULT PRIVILEGES FOR ROLE t3r_flightgear GRANT ALL ON SEQUENCES TO t3r;
ALTER DEFAULT PRIVILEGES FOR ROLE t3r_flightgear GRANT SELECT ON SEQUENCES TO t3r_grafana;


--
-- TOC entry 3215 (class 826 OID 4922409)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: -; Owner: t3r
--

ALTER DEFAULT PRIVILEGES FOR ROLE t3r GRANT ALL ON FUNCTIONS TO t3r_flightgear;
ALTER DEFAULT PRIVILEGES FOR ROLE t3r GRANT ALL ON FUNCTIONS TO t3r_grafana;


--
-- TOC entry 3212 (class 826 OID 4922415)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: -; Owner: t3r_flightgear
--

ALTER DEFAULT PRIVILEGES FOR ROLE t3r_flightgear GRANT ALL ON FUNCTIONS TO t3r;
ALTER DEFAULT PRIVILEGES FOR ROLE t3r_flightgear GRANT ALL ON FUNCTIONS TO t3r_grafana;


--
-- TOC entry 3213 (class 826 OID 4922407)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: -; Owner: t3r
--

ALTER DEFAULT PRIVILEGES FOR ROLE t3r GRANT ALL ON TABLES TO t3r_flightgear;
ALTER DEFAULT PRIVILEGES FOR ROLE t3r GRANT SELECT ON TABLES TO t3r_grafana;


--
-- TOC entry 3210 (class 826 OID 4922413)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: -; Owner: t3r_flightgear
--

ALTER DEFAULT PRIVILEGES FOR ROLE t3r_flightgear GRANT ALL ON TABLES TO t3r;
ALTER DEFAULT PRIVILEGES FOR ROLE t3r_flightgear GRANT SELECT ON TABLES TO t3r_grafana;


-- Completed on 2026-03-10 22:02:18 CET

--
-- PostgreSQL database dump complete
--

\unrestrict 2ogUer4OVSEoOrHl2FbeZR645gELNwseGtScRDvXNGMByqz4X7bLIPKr4HnxWuL

