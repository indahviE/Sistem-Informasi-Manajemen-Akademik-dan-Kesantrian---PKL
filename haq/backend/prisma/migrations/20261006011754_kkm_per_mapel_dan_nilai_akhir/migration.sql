-- AlterTable
ALTER TABLE `mata_pelajarans` ADD COLUMN `kkm` DOUBLE NOT NULL DEFAULT 75;

-- AlterTable
ALTER TABLE `remedials` ADD COLUMN `nilaiAkhir` DOUBLE NULL,
    MODIFY `status` ENUM('BELUM_TES', 'PROSES', 'TUNTAS', 'BELUM_TUNTAS') NOT NULL DEFAULT 'BELUM_TES';

-- Data: KKM mapel diambil dari KKM ujian terbaru milik mapel tersebut
UPDATE `mata_pelajarans` m
JOIN (
  SELECT u.mapelId, u.kkm
  FROM `ujians` u
  JOIN (
    SELECT mapelId, MAX(createdAt) AS maxc
    FROM `ujians`
    WHERE mapelId IS NOT NULL
    GROUP BY mapelId
  ) x ON x.mapelId = u.mapelId AND x.maxc = u.createdAt
) t ON t.mapelId = m.id
SET m.kkm = t.kkm;

-- Data: hitung nilaiAkhir dan status untuk remedial lama yang nilai perbaikannya sudah terisi
UPDATE `remedials` r
JOIN `ujians` u ON u.id = r.ujianId
LEFT JOIN `mata_pelajarans` m ON m.id = u.mapelId
SET
  r.nilaiAkhir = LEAST((r.nilaiAwal + r.nilaiRemedial) / 2, COALESCE(m.kkm, u.kkm)),
  r.status = IF((r.nilaiAwal + r.nilaiRemedial) / 2 >= COALESCE(m.kkm, u.kkm), 'TUNTAS', 'BELUM_TUNTAS')
WHERE r.nilaiRemedial IS NOT NULL
  AND r.nilaiAwal IS NOT NULL;