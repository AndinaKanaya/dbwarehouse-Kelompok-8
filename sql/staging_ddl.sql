-- =====================================================================
--  sql/staging_ddl.sql  |  Tabel staging  |  Kelompok 8  |  PostgreSQL
--  Database : dw_kelompok_8
--  Fungsi   : membuat 9 tabel staging (stg_) tempat data sumber disalin
--             oleh etl/t01_ekstrak.ktr sebelum masuk ke dimensi dan fakta.
--  Sifat    : bisa dijalankan ulang. Tabel stg_ dihapus lalu dibuat lagi
--             (kosong). Tabel dim_ dan fact_ tidak disentuh.
--  Catatan  : tipe dibuat sedikit lebih longgar dari sumber supaya semua
--             data pasti muat. Semua kolom boleh NULL, karena NULL baru
--             dibersihkan di tahap transformasi.
-- =====================================================================

DROP TABLE IF EXISTS stg_workorder;
DROP TABLE IF EXISTS stg_workorderrouting;
DROP TABLE IF EXISTS stg_product;
DROP TABLE IF EXISTS stg_productsubcategory;
DROP TABLE IF EXISTS stg_productcategory;
DROP TABLE IF EXISTS stg_productcosthistory;
DROP TABLE IF EXISTS stg_productlistpricehistory;
DROP TABLE IF EXISTS stg_scrapreason;
DROP TABLE IF EXISTS stg_location;

-- production.workorder
CREATE TABLE stg_workorder (
    workorderid   INTEGER,
    productid     INTEGER,
    orderqty      INTEGER,
    stockedqty    INTEGER,
    scrappedqty   INTEGER,
    startdate     TIMESTAMP,
    enddate       TIMESTAMP,
    duedate       TIMESTAMP,
    scrapreasonid INTEGER
);

-- production.workorderrouting
CREATE TABLE stg_workorderrouting (
    workorderid        INTEGER,
    productid          INTEGER,
    operationsequence  INTEGER,
    locationid         INTEGER,
    scheduledstartdate TIMESTAMP,
    scheduledenddate   TIMESTAMP,
    actualstartdate    TIMESTAMP,
    actualenddate      TIMESTAMP,
    actualresourcehrs  NUMERIC(19,4),
    plannedcost        NUMERIC(19,4),
    actualcost         NUMERIC(19,4)
);

-- production.product
CREATE TABLE stg_product (
    productid            INTEGER,
    name                 VARCHAR(100),
    productnumber        VARCHAR(50),
    color                VARCHAR(50),
    standardcost         NUMERIC(19,4),
    listprice            NUMERIC(19,4),
    productsubcategoryid INTEGER,
    sellstartdate        TIMESTAMP,
    sellenddate          TIMESTAMP
);

-- production.productsubcategory
CREATE TABLE stg_productsubcategory (
    productsubcategoryid INTEGER,
    productcategoryid    INTEGER,
    name                 VARCHAR(100)
);

-- production.productcategory
CREATE TABLE stg_productcategory (
    productcategoryid INTEGER,
    name              VARCHAR(100)
);

-- production.productcosthistory
CREATE TABLE stg_productcosthistory (
    productid    INTEGER,
    startdate    TIMESTAMP,
    enddate      TIMESTAMP,
    standardcost NUMERIC(19,4)
);

-- production.productlistpricehistory
CREATE TABLE stg_productlistpricehistory (
    productid INTEGER,
    startdate TIMESTAMP,
    enddate   TIMESTAMP,
    listprice NUMERIC(19,4)
);

-- production.scrapreason
CREATE TABLE stg_scrapreason (
    scrapreasonid INTEGER,
    name          VARCHAR(100)
);

-- production.location
CREATE TABLE stg_location (
    locationid   INTEGER,
    name         VARCHAR(100),
    costrate     NUMERIC(19,4),
    availability NUMERIC(19,2)
);

-- ---------------------------------------------------------------------
--  Pemeriksaan: 9 tabel staging ada dan masih kosong
-- ---------------------------------------------------------------------
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name LIKE 'stg\_%'
ORDER BY table_name;

-- ---------------------------------------------------------------------
--  Query untuk step Table input di etl/t01_ekstrak.ktr
--  (dijalankan di database SUMBER adventureworks, bukan di sini).
--  Nama kolom di SELECT harus sama dengan kolom tabel stg_ di atas.
-- ---------------------------------------------------------------------
-- stg_workorder
--   SELECT workorderid, productid, orderqty, stockedqty, scrappedqty,
--          startdate, enddate, duedate, scrapreasonid
--   FROM production.workorder
-- stg_workorderrouting
--   SELECT workorderid, productid, operationsequence, locationid,
--          scheduledstartdate, scheduledenddate, actualstartdate,
--          actualenddate, actualresourcehrs, plannedcost, actualcost
--   FROM production.workorderrouting
-- stg_product
--   SELECT productid, name, productnumber, color, standardcost, listprice,
--          productsubcategoryid, sellstartdate, sellenddate
--   FROM production.product
-- stg_productsubcategory
--   SELECT productsubcategoryid, productcategoryid, name
--   FROM production.productsubcategory
-- stg_productcategory
--   SELECT productcategoryid, name FROM production.productcategory
-- stg_productcosthistory
--   SELECT productid, startdate, enddate, standardcost
--   FROM production.productcosthistory
-- stg_productlistpricehistory
--   SELECT productid, startdate, enddate, listprice
--   FROM production.productlistpricehistory
-- stg_scrapreason
--   SELECT scrapreasonid, name FROM production.scrapreason
-- stg_location
--   SELECT locationid, name, costrate, availability
--   FROM production.location
