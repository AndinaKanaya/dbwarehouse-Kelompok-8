-- ============================================================
-- ddl.sql - Data warehouse Produksi (dw_kelompok_8, PostgreSQL)
-- Kelompok 8 | Star schema v2
--
-- Satu skrip membangun SEMUA tabel: dim_tanggal (standar sponsor v1.0,
-- disisipkan apa adanya di bagian 2), dimensi tim, dan fakta.
-- Aman dijalankan berulang kali (hapus lalu buat ulang).
-- PERINGATAN: menjalankan ulang MENGHAPUS isi semua tabel di bawah.
--             Jalankan ETL lagi setelahnya.
-- Cara jalan: psql -U postgres -d dw_kelompok_8 -v ON_ERROR_STOP=1 -f ddl.sql
-- ============================================================

BEGIN;

-- ============================================================
-- 1. Hapus semua tabel (fakta dulu, lalu dimensi)
--    Fakta dihapus lebih dulu, sehingga dim_tanggal tidak lagi dirujuk
--    dan bisa dihapus oleh skrip sponsor di bagian 2.
-- ============================================================

DROP TABLE IF EXISTS fact_produksi_tahap;
DROP TABLE IF EXISTS fact_produksi;
DROP TABLE IF EXISTS dim_produk;
DROP TABLE IF EXISTS dim_alasan_scrap;
DROP TABLE IF EXISTS dim_lokasi;
DROP TABLE IF EXISTS dim_tanggal;

-- ============================================================
-- 2. dim_tanggal - skrip standar sponsor v1.0 (DISISIPKAN APA ADANYA)
-- ============================================================

-- =====================================================================
--  dim_tanggal  standar kelas Data Warehouse  |  versi 1.0  |  PostgreSQL
--  Disediakan oleh sponsor. JANGAN mengubah struktur atau isi tabel ini.
--  Butuh atribut lain (misalnya hari libur)? Buat tabel tambahan yang
--  terhubung lewat tanggal_key.
--
--  Cara pakai : jalankan di database DW kelompok (bukan database sumber),
--               SEBELUM membuat tabel fakta.
--  Rentang    : 2010-01-01 s.d. 2015-12-31, ditambah baris -1.
-- =====================================================================

-- Tabel ini gagal dihapus jika sudah dirujuk tabel fakta. Itu disengaja,
-- supaya tidak terhapus tanpa sengaja.
DROP TABLE IF EXISTS dim_tanggal;

CREATE TABLE dim_tanggal (
    tanggal_key          INTEGER      PRIMARY KEY,  -- format YYYYMMDD, -1 = tidak diketahui
    tanggal              DATE         NOT NULL UNIQUE,
    tahun                INTEGER      NOT NULL,
    semester             INTEGER      NOT NULL,     -- 1 = Jan-Jun, 2 = Jul-Des
    kuartal              INTEGER      NOT NULL,     -- 1 s.d. 4
    bulan                INTEGER      NOT NULL,     -- 1 s.d. 12
    nama_bulan           VARCHAR(15)  NOT NULL,     -- Januari ... Desember
    minggu_dalam_tahun   INTEGER      NOT NULL,     -- minggu ISO 8601, 1 s.d. 53
    tanggal_dalam_bulan  INTEGER      NOT NULL,     -- 1 s.d. 31
    hari_dalam_minggu    INTEGER      NOT NULL,     -- Senin = 1 ... Minggu = 7
    nama_hari            VARCHAR(15)  NOT NULL,     -- Senin ... Minggu
    is_akhir_pekan       BOOLEAN      NOT NULL      -- true untuk Sabtu dan Minggu
);

-- Satu baris per hari
INSERT INTO dim_tanggal
SELECT
    TO_CHAR(g.d, 'YYYYMMDD')::INTEGER,
    g.d::DATE,
    EXTRACT(YEAR    FROM g.d)::INTEGER,
    CASE WHEN EXTRACT(MONTH FROM g.d) <= 6 THEN 1 ELSE 2 END,
    EXTRACT(QUARTER FROM g.d)::INTEGER,
    EXTRACT(MONTH   FROM g.d)::INTEGER,
    (ARRAY['Januari','Februari','Maret','April','Mei','Juni','Juli',
           'Agustus','September','Oktober','November','Desember'])[EXTRACT(MONTH FROM g.d)::INTEGER],
    EXTRACT(WEEK    FROM g.d)::INTEGER,   -- WEEK di PostgreSQL = minggu ISO
    EXTRACT(DAY     FROM g.d)::INTEGER,
    EXTRACT(ISODOW  FROM g.d)::INTEGER,   -- ISODOW: Senin = 1
    (ARRAY['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'])[EXTRACT(ISODOW FROM g.d)::INTEGER],
    EXTRACT(ISODOW  FROM g.d) IN (6, 7)
FROM generate_series(DATE '2010-01-01', DATE '2015-12-31', INTERVAL '1 day') AS g(d);

-- Baris "Tidak diketahui" untuk fakta yang tanggalnya kosong
INSERT INTO dim_tanggal VALUES
    (-1, DATE '1900-01-01', 0, 0, 0, 0, 'Tidak diketahui', 0, 0, 0, 'Tidak diketahui', FALSE);

COMMENT ON TABLE dim_tanggal IS 'Dimensi tanggal standar kelas DW, versi 1.0';

-- ---------------------------------------------------------------------
--  Pemeriksaan (hasil yang diharapkan ada di komentar)
-- ---------------------------------------------------------------------
-- 1. Jumlah baris: 2191 hari + 1 baris tidak diketahui = 2192
SELECT COUNT(*) AS jumlah_baris FROM dim_tanggal;

-- 2. Rentang tanggal: 2010-01-01 s.d. 2015-12-31
SELECT MIN(tanggal) AS awal, MAX(tanggal) AS akhir FROM dim_tanggal WHERE tanggal_key > 0;

-- 3. Contoh: 2013-03-15 adalah Jumat, kuartal 1, minggu ISO 11
SELECT * FROM dim_tanggal WHERE tanggal_key = 20130315;

-- 4. Perhatikan: 1 Januari bisa masuk minggu ISO 52/53 tahun sebelumnya
SELECT tanggal, nama_hari, minggu_dalam_tahun FROM dim_tanggal
WHERE tanggal IN (DATE '2010-01-01', DATE '2011-01-01', DATE '2012-01-01');

-- ============================================================
-- 3. Dimensi tim
-- ============================================================

-- dim_produk (SCD tipe 0, 1, 2) - struktur standar kelas
CREATE TABLE dim_produk (
    produk_key      INTEGER GENERATED BY DEFAULT AS IDENTITY,
    produk_id       INTEGER       NOT NULL,
    nama_produk     VARCHAR(50)   NOT NULL,
    nomor_produk    VARCHAR(25)   NOT NULL,
    warna           VARCHAR(15)   NOT NULL,
    subkategori     VARCHAR(50)   NOT NULL,
    kategori        VARCHAR(50)   NOT NULL,
    biaya_standar   NUMERIC(12,4) NOT NULL,
    harga_jual      NUMERIC(12,4) NOT NULL,
    berlaku_mulai   DATE          NOT NULL,
    berlaku_sampai  DATE          NOT NULL,
    is_current      BOOLEAN       NOT NULL,
    CONSTRAINT pk_dim_produk PRIMARY KEY (produk_key),
    CONSTRAINT uq_dim_produk_versi UNIQUE (produk_id, berlaku_mulai),
    CONSTRAINT ck_dim_produk_periode CHECK (berlaku_sampai >= berlaku_mulai)
);

-- dim_alasan_scrap (SCD tipe 1)
CREATE TABLE dim_alasan_scrap (
    alasan_scrap_key INTEGER GENERATED BY DEFAULT AS IDENTITY,
    alasan_scrap_id  INTEGER     NOT NULL,
    nama_alasan      VARCHAR(50) NOT NULL,
    CONSTRAINT pk_dim_alasan_scrap PRIMARY KEY (alasan_scrap_key),
    CONSTRAINT uq_dim_alasan_scrap_id UNIQUE (alasan_scrap_id)
);

-- dim_lokasi (SCD tipe 1)
CREATE TABLE dim_lokasi (
    lokasi_key    INTEGER GENERATED BY DEFAULT AS IDENTITY,
    lokasi_id     INTEGER       NOT NULL,
    nama_lokasi   VARCHAR(50)   NOT NULL,
    tarif_biaya   NUMERIC(12,4) NOT NULL DEFAULT 0,
    ketersediaan  NUMERIC(9,2)  NOT NULL DEFAULT 0,
    CONSTRAINT pk_dim_lokasi PRIMARY KEY (lokasi_key),
    CONSTRAINT uq_dim_lokasi_id UNIQUE (lokasi_id)
);

-- ============================================================
-- 4. Baris default (key -1 di setiap dimensi tim)
--    (baris -1 untuk dim_tanggal sudah dibuat di bagian 2)
-- ============================================================

INSERT INTO dim_produk
    (produk_key, produk_id, nama_produk, nomor_produk, warna, subkategori, kategori,
     biaya_standar, harga_jual, berlaku_mulai, berlaku_sampai, is_current)
VALUES
    (-1, -1, 'Tidak diketahui', 'Tidak diketahui', 'Tidak diketahui', 'Tidak diketahui', 'Tidak diketahui',
     0, 0, DATE '1900-01-01', DATE '9999-12-31', TRUE);

INSERT INTO dim_alasan_scrap (alasan_scrap_key, alasan_scrap_id, nama_alasan)
VALUES
    (-1, -1, 'Tidak diketahui'),
    ( 0,  0, 'Tidak ada scrap');

INSERT INTO dim_lokasi (lokasi_key, lokasi_id, nama_lokasi, tarif_biaya, ketersediaan)
VALUES
    (-1, -1, 'Tidak diketahui', 0, 0);

-- ============================================================
-- 5. Fakta
-- ============================================================

-- fact_produksi (grain: satu baris per work order)
CREATE TABLE fact_produksi (
    workorder_id            INTEGER NOT NULL,
    produk_key              INTEGER NOT NULL,
    tanggal_mulai_key       INTEGER NOT NULL,
    tanggal_selesai_key     INTEGER NOT NULL,
    tanggal_jatuh_tempo_key INTEGER NOT NULL,
    alasan_scrap_key        INTEGER NOT NULL,
    orderqty                INTEGER NOT NULL DEFAULT 0,
    stockedqty              INTEGER NOT NULL DEFAULT 0,
    scrappedqty             INTEGER NOT NULL DEFAULT 0,
    lama_produksi_hari      INTEGER,
    hari_terlambat          INTEGER,
    CONSTRAINT pk_fact_produksi PRIMARY KEY (workorder_id),
    CONSTRAINT fk_fact_produksi_produk
        FOREIGN KEY (produk_key) REFERENCES dim_produk (produk_key),
    CONSTRAINT fk_fact_produksi_tanggal_mulai
        FOREIGN KEY (tanggal_mulai_key) REFERENCES dim_tanggal (tanggal_key),
    CONSTRAINT fk_fact_produksi_tanggal_selesai
        FOREIGN KEY (tanggal_selesai_key) REFERENCES dim_tanggal (tanggal_key),
    CONSTRAINT fk_fact_produksi_tanggal_jatuh_tempo
        FOREIGN KEY (tanggal_jatuh_tempo_key) REFERENCES dim_tanggal (tanggal_key),
    CONSTRAINT fk_fact_produksi_alasan_scrap
        FOREIGN KEY (alasan_scrap_key) REFERENCES dim_alasan_scrap (alasan_scrap_key),
    CONSTRAINT ck_fact_produksi_qty CHECK (orderqty >= 0 AND scrappedqty >= 0)
);

-- fact_produksi_tahap (grain: satu baris per tahap kerja per work order)
CREATE TABLE fact_produksi_tahap (
    workorder_id               INTEGER NOT NULL,
    operation_sequence         INTEGER NOT NULL,
    produk_key                 INTEGER NOT NULL,
    lokasi_key                 INTEGER NOT NULL,
    tanggal_jadwal_mulai_key   INTEGER NOT NULL,
    tanggal_jadwal_selesai_key INTEGER NOT NULL,
    tanggal_aktual_mulai_key   INTEGER NOT NULL,
    tanggal_aktual_selesai_key INTEGER NOT NULL,
    jam_sumber_daya_aktual     NUMERIC(9,4)  NOT NULL DEFAULT 0,
    biaya_rencana              NUMERIC(12,4) NOT NULL DEFAULT 0,
    biaya_aktual               NUMERIC(12,4) NOT NULL DEFAULT 0,
    selisih_biaya              NUMERIC(12,4),
    durasi_aktual_hari         INTEGER,
    selisih_jadwal_hari        INTEGER,
    CONSTRAINT pk_fact_produksi_tahap PRIMARY KEY (workorder_id, operation_sequence),
    CONSTRAINT fk_fact_tahap_produk
        FOREIGN KEY (produk_key) REFERENCES dim_produk (produk_key),
    CONSTRAINT fk_fact_tahap_lokasi
        FOREIGN KEY (lokasi_key) REFERENCES dim_lokasi (lokasi_key),
    CONSTRAINT fk_fact_tahap_jadwal_mulai
        FOREIGN KEY (tanggal_jadwal_mulai_key) REFERENCES dim_tanggal (tanggal_key),
    CONSTRAINT fk_fact_tahap_jadwal_selesai
        FOREIGN KEY (tanggal_jadwal_selesai_key) REFERENCES dim_tanggal (tanggal_key),
    CONSTRAINT fk_fact_tahap_aktual_mulai
        FOREIGN KEY (tanggal_aktual_mulai_key) REFERENCES dim_tanggal (tanggal_key),
    CONSTRAINT fk_fact_tahap_aktual_selesai
        FOREIGN KEY (tanggal_aktual_selesai_key) REFERENCES dim_tanggal (tanggal_key)
);

-- ============================================================
-- 6. Index pada foreign key fakta
-- ============================================================

CREATE INDEX idx_fact_produksi_produk          ON fact_produksi (produk_key);
CREATE INDEX idx_fact_produksi_tgl_mulai       ON fact_produksi (tanggal_mulai_key);
CREATE INDEX idx_fact_produksi_tgl_selesai     ON fact_produksi (tanggal_selesai_key);
CREATE INDEX idx_fact_produksi_tgl_jatuh_tempo ON fact_produksi (tanggal_jatuh_tempo_key);
CREATE INDEX idx_fact_produksi_alasan_scrap    ON fact_produksi (alasan_scrap_key);

CREATE INDEX idx_fact_tahap_produk             ON fact_produksi_tahap (produk_key);
CREATE INDEX idx_fact_tahap_lokasi             ON fact_produksi_tahap (lokasi_key);
CREATE INDEX idx_fact_tahap_jadwal_mulai       ON fact_produksi_tahap (tanggal_jadwal_mulai_key);
CREATE INDEX idx_fact_tahap_jadwal_selesai     ON fact_produksi_tahap (tanggal_jadwal_selesai_key);
CREATE INDEX idx_fact_tahap_aktual_mulai       ON fact_produksi_tahap (tanggal_aktual_mulai_key);
CREATE INDEX idx_fact_tahap_aktual_selesai     ON fact_produksi_tahap (tanggal_aktual_selesai_key);

COMMIT;

-- ============================================================
-- 7. Pemeriksaan: baris -1 ada di setiap dimensi
-- ============================================================

SELECT 'dim_tanggal'      AS tabel, COUNT(*) AS baris_minus_1 FROM dim_tanggal      WHERE tanggal_key      = -1
UNION ALL
SELECT 'dim_produk'       AS tabel, COUNT(*)                  FROM dim_produk       WHERE produk_key       = -1
UNION ALL
SELECT 'dim_alasan_scrap' AS tabel, COUNT(*)                  FROM dim_alasan_scrap WHERE alasan_scrap_key = -1
UNION ALL
SELECT 'dim_lokasi'       AS tabel, COUNT(*)                  FROM dim_lokasi       WHERE lokasi_key       = -1;
