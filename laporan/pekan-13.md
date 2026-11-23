**Laporan Progres Pekan 13**

Kelompok	: 8  
Proses bisnis	: Produksi  
Status		: Hijau / Kuning / Merah

1. Target dan capaian

| Target Pekan Ini | Status | Bukti |
| ----- | :---: | ----- |
| Salin semua tabel sumber yang dibutuhkan ke staging. | Hijau | [sql/staging\_ddl.sql](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/sql/staging_ddl.sql): DDL 9 tabel staging. [etl/t01\_ekstrak.ktr](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/t01_ekstrak.ktr) |
| Transformasi tiap dimensi | Hijau | [t02\_dim\_produk.ktr](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/t02_dim_produk.ktr): 607 baris. [t03\_dim\_alasan\_scrap.ktr](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/t03_dim_alasan_scrap.ktr): 18 baris. [t04\_dim\_lokasi.ktr](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/t04_dim_lokasi.ktr) |
| Minimal satu dimensi SCD tipe 2 | Hijau | [t02\_dim\_produk.ktr](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/t02_dim_produk.ktr): versi produk dengan berlaku\_mulai, berlaku\_sampai, is\_current; 505 baris aktif untuk 504 produk, ditambah row unknown |
| Transformasi fakta | Hijau | [t05\_fact\_produksi.ktr](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/t05_fact_produksi.ktr): 72.591 baris, 0 error, tanpa key unknown. [t06\_fact\_produksi\_tahap.ktr](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/t06_fact_produksi_tahap.ktr) |
| Ekstrak, kosongkan, dimensi, fakta. job\_utama.kjb berjalan lewat Kitchen dari terminal  | Hijau | [etl/job\_utama.kjb, etl/log\_kitchen.txt.](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/job_utama.kjb) Hasil: HASIL=SUKSES, tidak ada "Finished with errors" |
| Rekonsiliasi, Job dijalankan dua kali dan tidak ada data ganda  | Hijau | Putaran 1: [log\_kitchen\_putaran1.txt](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/log_kitchen_putaran1.txt). Putaran 2: [log\_kitchen\_putaran2.txt](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/etl/log_kitchen_putaran2.txt). Query: [sql/rekonsiliasi.sql](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/sql/rekonsiliasi.sql). Fakta tetap 72.591 dan 67.131 di kedua putaran, tidak ada data ganda |
| Hasil rekonsiliasi tersimpan, selisih dijelaskan jika ada  | Hijau  | [docs/rekonsiliasi/](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/tree/main/docs/rekonsiliasi), [sql/rekonsiliasi.sql](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/blob/main/sql/rekonsiliasi.sql). Sumber \= staging \= fakta untuk jumlah baris dan total orderqty, scrappedqty, jam, dan biaya. Selisih: tidak ada |
| Semua file .ktr dan .kjb ada di folder etl/  | Hijau | [folder etl](https://github.com/AndinaKanaya/dbwarehouse-Kelompok-8/tree/main/etl): t01 sampai t06 dan job\_utama.kjb |
| Laporan laporan/pekan-12.md siap | Hijau | laporan/pekan-13.md |

2. Kendala pengerjaan : \-

3. Kendala tim : \-

4. Keputusan yang butuh persetujuan sponsor : \-

5. Rencana pekan depan :

| Target  | Penanggung Jawab |
| ----- | :---: |
| olap/schema.xml  | Khonsa |
| Dimensi Waktu lewat DimensionUsage | Firman |
| Minimal satu calculated member | Riska |
| Minimal 5 query MDX | Jamila |
| Bukti MDX sama dengan SQL | Andina |

6. Kontribusi anggota

| Nama | Peran | Yang Dikerjakan Pekan Ini |
| ----- | ----- | ----- |
| Riska Febriana Rahmawati | Project Manager | Membuat job\_utama.kjb dan mengujinya lewat Kitchen. Menjalankan rekonsiliasi. |
| Jamila Farhana | Dashboard Developer | Membuat t01\_ekstrak.ktr, t03\_dim\_alasan\_scrap.ktr, dan t04\_dim\_lokasi.ktr. |
| Andina Kanaya Azzahra | ETL Developer | Membuat t05\_fact\_produksi.ktr (lookup ke dim\_produk SCD2, dim\_tanggal, dan dim\_alasan\_scrap, lalu load ke fact\_produksi) |
| Khonsa Abidah | OLAP Developer | Membuat t06\_fact\_produksi\_tahap.ktr. Menjalankan rekonsiliasi. |
| Moh. Firman Bahri A | Data Modeler | Membuat t02\_dim\_produk.ktr (SCD Tipe 2\) dan sql/rekonsiliasi.sql |

