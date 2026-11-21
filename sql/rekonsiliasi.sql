-- Rekonsiliasi dim_produk (Kelompok 8, tugas Firman)

-- 1. Semua produk staging ada di dimensi (harus sama: 504 dan 504)
SELECT (SELECT COUNT(*) FROM stg_product) AS staging,
       (SELECT COUNT(DISTINCT produk_id) FROM dim_produk WHERE produk_key <> -1) AS dw;

-- 2. Tiap produk tepat satu versi aktif (harus 0 baris)
SELECT produk_id FROM dim_produk
WHERE produk_key <> -1
GROUP BY produk_id HAVING SUM(is_current::int) <> 1;

-- 3. Periode tidak tumpang tindih (harus 0 baris)
SELECT a.produk_id
FROM dim_produk a JOIN dim_produk b
  ON a.produk_id = b.produk_id AND a.produk_key < b.produk_key
 AND a.berlaku_mulai <= b.berlaku_sampai AND b.berlaku_mulai <= a.berlaku_sampai;

-- 4. Tidak ada kunci ganda setelah job dijalankan berulang (harus 0 baris)
SELECT produk_id, berlaku_mulai, COUNT(*)
FROM dim_produk GROUP BY produk_id, berlaku_mulai HAVING COUNT(*) > 1;

-- 5. Setiap work order menemukan versi produk (harus 0)
SELECT COUNT(*) AS wo_tanpa_versi
FROM stg_workorder w
WHERE NOT EXISTS (
  SELECT 1 FROM dim_produk d
  WHERE d.produk_id = w.productid
    AND w.startdate::date BETWEEN d.berlaku_mulai AND d.berlaku_sampai);

-- 6. Jumlah baris dimensi (catat per run, harus sama: 607)
SELECT COUNT(*) FROM dim_produk;

-- 7. Setelah fakta terisi, bandingkan dengan sumber
--    Di database adventureworks:
--      SELECT COUNT(*), SUM(orderqty), SUM(scrappedqty) FROM production.workorder;
--      SELECT COUNT(*) FROM production.workorderrouting;
--    Di database dw_kelompok_8:
--      SELECT COUNT(*), SUM(orderqty), SUM(scrappedqty) FROM fact_produksi;
--      SELECT COUNT(*) FROM fact_produksi_tahap;