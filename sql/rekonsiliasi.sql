-- =====================================================
-- REKONSILIASI ETL: PROSES PRODUKSI (Kelompok 8)
-- =====================================================


-- =====================================================
-- BAGIAN A. SUMBER (jalankan di database: adventureworks)
-- =====================================================

-- A1. Work order di sumber
SELECT 'workorder' AS tabel, COUNT(*) AS jumlah_baris,
       SUM(orderqty) AS orderqty, SUM(stockedqty) AS stockedqty, SUM(scrappedqty) AS scrappedqty
FROM production.workorder;

-- A2. Tahap kerja di sumber
SELECT 'workorderrouting' AS tabel, COUNT(*) AS jumlah_baris,
       SUM(actualresourcehrs) AS jam, SUM(plannedcost) AS biaya_rencana, SUM(actualcost) AS biaya_aktual
FROM production.workorderrouting;


-- =====================================================
-- BAGIAN B. STAGING vs FAKTA (jalankan di database: dw_kelompok_8)
-- Baris dan total harus sama persis.
-- =====================================================

-- B1. Work order: staging vs fact_produksi
SELECT 'staging' AS sumber, COUNT(*) AS jumlah_baris,
       SUM(orderqty) AS orderqty, SUM(stockedqty) AS stockedqty, SUM(scrappedqty) AS scrappedqty
FROM stg_workorder
UNION ALL
SELECT 'fakta', COUNT(*), SUM(orderqty), SUM(stockedqty), SUM(scrappedqty)
FROM fact_produksi;

-- B2. Tahap kerja: staging vs fact_produksi_tahap
SELECT 'staging' AS sumber, COUNT(*) AS jumlah_baris,
       SUM(actualresourcehrs) AS jam, SUM(plannedcost) AS biaya_rencana, SUM(actualcost) AS biaya_aktual
FROM stg_workorderrouting
UNION ALL
SELECT 'fakta', COUNT(*), SUM(jam_sumber_daya_aktual), SUM(biaya_rencana), SUM(biaya_aktual)
FROM fact_produksi_tahap;


-- =====================================================
-- BAGIAN C. BARIS YANG JATUH KE "TIDAK DIKETAHUI" (key -1)
-- Idealnya 0. Kalau tidak, jelaskan penyebabnya di laporan.
-- =====================================================

-- C1. fact_produksi
SELECT SUM(CASE WHEN produk_key = -1 THEN 1 ELSE 0 END)              AS produk_tidak_diketahui,
       SUM(CASE WHEN alasan_scrap_key = -1 THEN 1 ELSE 0 END)        AS scrap_tidak_diketahui,
       SUM(CASE WHEN tanggal_mulai_key = -1 THEN 1 ELSE 0 END)       AS mulai_tidak_diketahui,
       SUM(CASE WHEN tanggal_selesai_key = -1 THEN 1 ELSE 0 END)     AS selesai_tidak_diketahui,
       SUM(CASE WHEN tanggal_jatuh_tempo_key = -1 THEN 1 ELSE 0 END) AS tempo_tidak_diketahui,
       COUNT(*) AS total_baris
FROM fact_produksi;

-- C2. fact_produksi_tahap
SELECT SUM(CASE WHEN produk_key = -1 THEN 1 ELSE 0 END) AS produk_tidak_diketahui,
       SUM(CASE WHEN lokasi_key = -1 THEN 1 ELSE 0 END) AS lokasi_tidak_diketahui,
       COUNT(*) AS total_baris
FROM fact_produksi_tahap;


-- =====================================================
-- BAGIAN D. DATA GANDA (hasil kedua query harus kosong)
-- =====================================================

-- D1
SELECT workorder_id, COUNT(*) AS jumlah
FROM fact_produksi GROUP BY workorder_id HAVING COUNT(*) > 1;

-- D2
SELECT workorder_id, operation_sequence, COUNT(*) AS jumlah
FROM fact_produksi_tahap GROUP BY workorder_id, operation_sequence HAVING COUNT(*) > 1;


-- =====================================================
-- BAGIAN E. DIMENSI TIDAK BERLIPAT SETELAH JOB DIJALANKAN DUA KALI
-- Hasilnya harus sama antara putaran 1 dan putaran 2.
-- =====================================================

-- E1
SELECT 'dim_produk (baris)'   AS tabel, COUNT(*) AS jumlah FROM dim_produk WHERE produk_key <> -1
UNION ALL SELECT 'dim_produk (produk)', COUNT(DISTINCT produk_id) FROM dim_produk WHERE produk_key <> -1
UNION ALL SELECT 'dim_alasan_scrap',    COUNT(*) FROM dim_alasan_scrap
UNION ALL SELECT 'dim_lokasi',          COUNT(*) FROM dim_lokasi;