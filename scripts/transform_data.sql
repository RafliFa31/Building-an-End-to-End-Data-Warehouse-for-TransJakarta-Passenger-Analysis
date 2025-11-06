-- scripts/transform_data.sql (REVISI FINAL 6 - ELT Transformation)

-- Buat Schema DWH jika belum ada
CREATE SCHEMA IF NOT EXISTS dwh;

-- 1. Buat Dimension Table: dim_halte
DROP TABLE IF EXISTS dwh.dim_halte;
CREATE TABLE dwh.dim_halte AS
SELECT
    "no_registrasi" AS halte_key,
    "no_registrasi",
    "wilayah",
    "lokasi_alamat" AS nama_halte,
    "jenis_halte",
    "lintang",
    "bujur"
FROM
    staging.stg_halte;

ALTER TABLE dwh.dim_halte ADD PRIMARY KEY (halte_key);

-- 2. Buat Dimension Table: dim_koridor (Mengatasi duplikasi key dan menambah 'jenis_layanan')
DROP TABLE IF EXISTS dwh.dim_koridor;
CREATE TABLE dwh.dim_koridor AS
SELECT
    "corridorID" AS koridor_key,
    "corridorID",
    MAX("corridorName") AS "corridorName",
    
    -- Menambahkan kolom 'jenis_layanan' (CASE WHEN)
    CASE
        WHEN "corridorID" LIKE 'JAK%' THEN 'JakLingko (Mikrotrans)'
        WHEN "corridorID" LIKE 'M%' THEN 'Angkutan Malam Hari (AMARI)'
        WHEN "corridorID" LIKE 'BW%' THEN 'Bus Wisata'
        WHEN "corridorID" LIKE 'JIS%' THEN 'Rute JIS'
        WHEN "corridorID" LIKE 'B%' THEN 'Rute Bekasi'
        WHEN "corridorID" LIKE 'D%' THEN 'Rute Depok'
        WHEN "corridorID" LIKE 'S%' THEN 'Rute Serpong/Tangsel'
        WHEN "corridorID" LIKE 'T%' THEN 'Rute Tangerang'
        ELSE 'Koridor Utama / Feeder'
    END AS "jenis_layanan"
    
FROM
    staging.stg_transactions
WHERE "corridorID" IS NOT NULL
GROUP BY
    "corridorID";

ALTER TABLE dwh.dim_koridor ADD PRIMARY KEY (koridor_key);

-- 3. Buat Dimension Table: dim_penumpang (Mengatasi masalah tipe data 'bigint to date')
DROP TABLE IF EXISTS dwh.dim_penumpang;
CREATE TABLE dwh.dim_penumpang AS
SELECT DISTINCT
    "payCardID" AS penumpang_key,
    "payCardID",
    "payCardBank",
    "payCardSex",
    "payCardBirthDate"::integer AS tahun_lahir, -- Diubah menjadi integer
    (EXTRACT(YEAR FROM NOW()) - "payCardBirthDate"::integer) AS umur
FROM
    staging.stg_transactions
WHERE "payCardID" IS NOT NULL;

ALTER TABLE dwh.dim_penumpang ADD PRIMARY KEY (penumpang_key);


-- 4. Buat Dimension Table: dim_waktu
DROP TABLE IF EXISTS dwh.dim_waktu;
CREATE TABLE dwh.dim_waktu AS
WITH all_times AS (
    SELECT "tapInTime" AS ts FROM staging.stg_transactions
    UNION
    SELECT "tapOutTime" AS ts FROM staging.stg_transactions
)
SELECT DISTINCT
    TO_CHAR(TO_TIMESTAMP(ts), 'YYYYMMDDHH24') AS waktu_key,
    TO_TIMESTAMP(ts)::date AS tanggal,
    EXTRACT(YEAR FROM TO_TIMESTAMP(ts)) AS tahun,
    EXTRACT(MONTH FROM TO_TIMESTAMP(ts)) AS bulan,
    EXTRACT(DAY FROM TO_TIMESTAMP(ts)) AS hari,
    EXTRACT(HOUR FROM TO_TIMESTAMP(ts)) AS jam,
    EXTRACT(ISODOW FROM TO_TIMESTAMP(ts)) AS hari_ke, -- 1=Senin, 7=Minggu
    CASE
        WHEN EXTRACT(ISODOW FROM TO_TIMESTAMP(ts)) IN (6, 7) THEN true
        ELSE false
    END AS is_weekend
FROM all_times
WHERE ts IS NOT NULL;

ALTER TABLE dwh.dim_waktu ADD PRIMARY KEY (waktu_key);


-- 5. Buat Fact Table: fct_perjalanan (Mengatasi masalah NULL pada Foreign Keys)
DROP TABLE IF EXISTS dwh.fct_perjalanan;
CREATE TABLE dwh.fct_perjalanan AS
SELECT
    t."transID" AS perjalanan_id,
    
    -- Foreign Keys
    COALESCE(dh_in."halte_key", 'UNKNOWN') AS halte_tap_in_key,
    COALESCE(dh_out."halte_key", 'UNKNOWN') AS halte_tap_out_key,
    COALESCE(dk."koridor_key", 'UNKNOWN') AS koridor_key,
    COALESCE(dp."penumpang_key", 0) AS penumpang_key, -- Diberi 0 (integer) untuk key yang NULL
    COALESCE(dw_in."waktu_key", 'UNKNOWN') AS waktu_tap_in_key,
    COALESCE(dw_out."waktu_key", 'UNKNOWN') AS waktu_tap_out_key,

    -- Timestamps
    TO_TIMESTAMP(t."tapInTime") AS tap_in_datetime,
    TO_TIMESTAMP(t."tapOutTime") AS tap_out_datetime,
    
    -- Measures
    (t."tapOutTime" - t."tapInTime") / 60.0 AS durasi_menit, 
    t."payAmount" AS jumlah_bayar
FROM
    staging.stg_transactions t
-- JOIN untuk mendapatkan Foreign Keys
LEFT JOIN
    dwh.dim_halte dh_in ON t."tapInStops" = dh_in.no_registrasi
LEFT JOIN
    dwh.dim_halte dh_out ON t."tapOutStops" = dh_out.no_registrasi
LEFT JOIN
    dwh.dim_koridor dk ON t."corridorID" = dk.koridor_key
LEFT JOIN
    dwh.dim_penumpang dp ON t."payCardID" = dp.penumpang_key
-- JOIN ke dim_waktu
LEFT JOIN
    dwh.dim_waktu dw_in ON TO_CHAR(TO_TIMESTAMP(t."tapInTime"), 'YYYYMMDDHH24') = dw_in.waktu_key
LEFT JOIN
    dwh.dim_waktu dw_out ON TO_CHAR(TO_TIMESTAMP(t."tapOutTime"), 'YYYYMMDDHH24') = dw_out.waktu_key;